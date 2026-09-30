"""
Client for the JoyAI-Video-Edit streaming WebSocket protocol.

Protocol (matches the official deploy/static/index.html client):
  → {"type":"start", "session_id":..., "prompt":..., "width":..., "height":...,
     "input_codec":"mjpeg", "output_codec":"mjpeg", "fps":..., "ref_image":"data:..."}
  → per frame: {"type":"frame_meta","seq":N,"t_capture_ms":T} followed by
     the binary JPEG frame
  → {"type":"ping", ...} / {"type":"stop", ...}
  ← JSON acks (queue_position, presence gating, errors…) and binary
     edited frames (mjpeg or h264 chunks)
"""

import base64
import json
import time
import uuid
from typing import List, Optional

import websockets


class JoyAIStreamClient:
    def __init__(
        self,
        upstream: str,
        session_id: Optional[str] = None,
        num_inference_steps: int = 4,
    ):
        self.upstream = upstream.rstrip("/")
        self.session_id = session_id or f"stylesnap_{uuid.uuid4().hex[:10]}"
        self.num_inference_steps = num_inference_steps
        self._ws: Optional[websockets.WebSocketClientProtocol] = None
        self._stopped = False

    async def connect(self):
        uri = f"{self.upstream.replace('http', 'ws', 1)}/ws"
        self._ws = await websockets.connect(uri, max_size=None, ping_interval=None)

    async def start(
        self,
        prompt: str,
        width: int,
        height: int,
        input_codec: str = "mjpeg",
        output_codec: str = "mjpeg",
        fps: int = 12,
        ref_image_bytes: Optional[bytes] = None,
    ):
        payload = {
            "type": "start",
            "session_id": self.session_id,
            "prompt": prompt,
            "width": width,
            "height": height,
            "num_inference_steps": self.num_inference_steps,
            "input_codec": input_codec,
            "output_codec": output_codec,
            "fps": fps,
            "output_quality": 85,
            "gate_enabled": False,
        }
        if ref_image_bytes is not None:
            payload["ref_image"] = (
                "data:image/jpeg;base64,"
                + base64.b64encode(ref_image_bytes).decode()
            )
        await self._send_json(payload)

    async def send_frame(self, jpeg: bytes, seq: int):
        await self._send_json(
            {
                "type": "frame_meta",
                "session_id": self.session_id,
                "seq": seq,
                "t_capture_ms": int(time.time() * 1000),
            }
        )
        await self._ws.send(jpeg)

    async def collect_outputs(self, sink: List[bytes], max_frames: int = 4096):
        try:
            async for msg in self._ws:
                if isinstance(msg, (bytes, bytearray)):
                    sink.append(bytes(msg))
                    if len(sink) >= max_frames:
                        break
                else:
                    try:
                        data = json.loads(msg)
                    except Exception:
                        continue
                    t = data.get("type")
                    if t == "error":
                        print(f"[joyai] server error: {data}")
                    elif t == "queue_position":
                        print(f"[joyai] queue: {data}")
        except Exception:
            pass

    async def stop(self):
        self._stopped = True
        await self._send_json({"type": "stop", "session_id": self.session_id})

    async def close(self):
        try:
            if self._ws is not None:
                await self._ws.close()
        except Exception:
            pass
        self._ws = None

    async def _send_json(self, obj: dict):
        if self._ws is not None:
            await self._ws.send(json.dumps(obj))
