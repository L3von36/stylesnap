import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Live-mirror engine.
///
/// Talks to the StyleSnap bridge (`/ws/live`), which transparently proxies the
/// JoyAI-Video-Edit WebSocket protocol:
///   out: {"type":"start", ...} → for each frame: {"type":"frame_meta",...} + binary JPEG
///   in : JSON acks/queue messages + binary edited JPEG frames
/// In demo mode it runs fully offline and produces a stylized local simulation.
class LiveMirrorEngine {
  LiveMirrorEngine({required this.backendUrl, required this.demoMode});

  final String backendUrl;
  final bool demoMode;

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  int _seq = 0;
  int _lastSentMs = 0;
  bool _busy = false;
  bool _running = false;

  final _outputCtrl = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get outputs => _outputCtrl.stream;

  final _statusCtrl = StreamController<String>.broadcast();
  Stream<String> get status => _statusCtrl.stream;

  final _metricsCtrl = StreamController<LiveMetrics>.broadcast();
  Stream<LiveMetrics> get metrics => _metricsCtrl.stream;

  int _sent = 0;
  int _received = 0;
  DateTime? _startedAt;
  double get outFps {
    final s = _startedAt == null ? 0 : DateTime.now().difference(_startedAt!).inSeconds;
    return s < 1 ? 0 : _received / s;
  }

  CameraController? _camera;
  List<CameraDescription>? _cameras;

  Future<void> startCamera() async {
    _cameras ??= await availableCameras();
    final front = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );
    final ctrl = CameraController(
      front,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
    );
    await ctrl.initialize();
    _camera = ctrl;
  }

  CameraController? get camera => _camera;

  /// Starts streaming + editing. [garmentBytes] is the RV2V reference image.
  Future<void> start({
    required String instruction,
    Uint8List? garmentBytes,
  }) async {
    _seq = 0;
    _sent = 0;
    _received = 0;
    _startedAt = DateTime.now();
    _running = true;

    if (demoMode) {
      _statusCtrl.add('Demo simulation · running on-device');
    } else {
      _statusCtrl.add('Connecting to server …');
      try {
        _channel = WebSocketChannel.connect(Uri.parse('$backendUrl/ws/live'));
        await _channel!.ready;
      } catch (e) {
        _running = false;
        _statusCtrl.add('Connection failed — check backend URL in Profile');
        rethrow;
      }

      final startMsg = <String, dynamic>{
        'type': 'start',
        'session_id': 'stylesnap_${DateTime.now().millisecondsSinceEpoch}',
        'prompt': instruction,
        'width': 480,
        'height': 640,
        'input_codec': 'mjpeg',
        'output_codec': 'mjpeg',
        'fps': 12,
        'num_inference_steps': 4,
      };
      if (garmentBytes != null) {
        startMsg['ref_image'] =
            'data:image/jpeg;base64,${base64Encode(garmentBytes)}';
      }
      _channel!.sink.add(jsonEncode(startMsg));
      _statusCtrl.add('Live · editing');

      _channel!.stream.listen(
        (data) {
          if (data is List<int>) {
            _received++;
            if (!_outputCtrl.isClosed) {
              _outputCtrl.add(Uint8List.fromList(data));
            }
          } else if (data is String) {
            _handleServerMessage(data);
          }
          _pushMetrics();
        },
        onDone: () => _statusCtrl.add('Disconnected'),
        onError: (_) => _statusCtrl.add('Connection error'),
      );

      _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _safeSend(jsonEncode({
          'type': 'ping',
          't': DateTime.now().millisecondsSinceEpoch,
        }));
      });
    }

    // Continuous camera frames → encode → send (or simulate locally).
    final ctrl = _camera;
    if (ctrl != null && ctrl.value.isInitialized) {
      await ctrl.startImageStream((CameraImage image) async {
        if (_busy || !_running) return;
        _busy = true;
        try {
          final jpeg = await _convertAndEncode(image);
          if (jpeg != null) await _onFrame(jpeg);
        } catch (_) {
          // skip frame
        } finally {
          _busy = false;
        }
      });
    }
  }

  Future<void> _onFrame(Uint8List jpeg) async {
    // Throttle to ~12 fps upstream.
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSentMs < 80) return;
    _lastSentMs = now;

    if (demoMode) {
      // Local stylized simulation of the editing effect.
      final decoded = img.decodeJpg(jpeg);
      if (decoded != null) {
        final t = (_seq % 8) / 8.0;
        img.adjustColor(decoded,
            saturation: 1.10 + 0.06 * t, brightness: 1.0 + 0.03 * t);
        final out = Uint8List.fromList(img.encodeJpg(decoded, quality: 82));
        _received++;
        if (!_outputCtrl.isClosed) _outputCtrl.add(out);
      }
      _sent++;
      _seq++;
      _pushMetrics();
      return;
    }

    _safeSend(jsonEncode({
      'type': 'frame_meta',
      'seq': _seq,
      't_capture_ms': now,
    }));
    _safeSend(jpeg);
    _sent++;
    _seq++;
    _pushMetrics();
  }

  void _handleServerMessage(String data) {
    try {
      final msg = jsonDecode(data) as Map<String, dynamic>;
      switch (msg['type']) {
        case 'queue_position':
          _statusCtrl.add('In queue · #${msg['ahead'] ?? msg['position'] ?? 0}');
          break;
        case 'error':
          _statusCtrl.add('Server: ${msg['message'] ?? 'error'}');
          break;
        case 'pong':
        default:
          break;
      }
    } catch (_) {}
  }

  void _safeSend(Object payload) {
    try {
      _channel?.sink.add(payload);
    } catch (_) {}
  }

  void _pushMetrics() {
    if (!_metricsCtrl.isClosed) {
      _metricsCtrl.add(LiveMetrics(sent: _sent, received: _received, outFps: outFps));
    }
  }

  /// YUV420 (Android NV21-ish) → RGBA.
  Uint8List? _yuvToRgba(CameraImage image) {
    try {
      final width = image.width;
      final height = image.height;
      if (image.planes.length < 3) return null; // not yuv420
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      final out = Uint8List(width * height * 4);
      final yRowStride = yPlane.bytesPerRow;
      final yPixStride = yPlane.pixelStride;
      final uRowStride = uPlane.bytesPerRow;
      final uPixStride = uPlane.pixelStride;
      final vRowStride = vPlane.bytesPerRow;
      final vPixStride = vPlane.pixelStride;

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final yi = y * yRowStride + x * yPixStride;
          final uvx = x ~/ 2;
          final uvy = y ~/ 2;
          final uu = uPlane.bytes[uvy * uRowStride + uvx * uPixStride] - 128;
          final vv = vPlane.bytes[uvy * vRowStride + uvx * vPixStride] - 128;
          final yy = yPlane.bytes[yi].toDouble();
          var r = (yy + 1.402 * vv).round();
          var g = (yy - 0.344136 * uu - 0.714136 * vv).round();
          var b = (yy + 1.772 * uu).round();
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);
          final oi = (y * width + x) * 4;
          out[oi] = r;
          out[oi + 1] = g;
          out[oi + 2] = b;
          out[oi + 3] = 255;
        }
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _convertAndEncode(CameraImage image) async {
    // iOS may already deliver JPEG.
    if (image.format.group == ImageFormatGroup.jpeg) {
      return Uint8List.fromList(image.planes[0].bytes);
    }
    final rgba = _yuvToRgba(image);
    if (rgba == null) return null;
    final im = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: rgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    final scaled = img.copyResize(im, width: 480);
    return Uint8List.fromList(img.encodeJpg(scaled, quality: 70));
  }

  Future<void> stop() async {
    _running = false;
    _pingTimer?.cancel();
    try {
      if (!demoMode) {
        _safeSend(jsonEncode({'type': 'stop'}));
        await _channel?.sink.close();
      }
    } catch (_) {}
    _channel = null;
    try {
      await _camera?.stopImageStream();
      await _camera?.dispose();
    } catch (_) {}
    _camera = null;
  }

  void dispose() {
    _outputCtrl.close();
    _statusCtrl.close();
    _metricsCtrl.close();
  }
}

class LiveMetrics {
  final int sent;
  final int received;
  final double outFps;
  const LiveMetrics({required this.sent, required this.received, required this.outFps});
}
