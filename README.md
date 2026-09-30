# StyleSnap 👗 — AI Virtual Try-On (Flutter Android)

A polished virtual clothes try-on Android app built with **Flutter**, powered by
**[JoyAI-Video-Edit](https://github.com/jd-opensource/JoyAI-Video-Edit)**
(real-time open-ended video editing with autoregressive diffusion).

```
┌──────────────────────┐        ┌─────────────────────┐        ┌────────────────────────────┐
│  StyleSnap (Flutter) │  HTTP/ │  StyleSnap Bridge   │  WS    │  JoyAI-Video-Edit          │
│  Android app         │ ⇄  WS  │  FastAPI (8600)     │ ⇄      │  GPU server (8080)         │
│  camera · catalog    │        │  mock + proxy       │        │  16B DiT · RV2V try-on     │
└──────────────────────┘        └─────────────────────┘        └────────────────────────────┘
```

**Works out of the box in Demo mode** (bundled sample results, no GPU needed) —
connect a GPU server later for real AI try-on.

## Features

- **Photo try-on** — take/upload a full-body photo, pick a garment, the model
  drapes it onto you (RV2V: *"Put the coat from Image 1 on the person"*).
- **Live mirror** — real-time camera try-on streamed through the JoyAI
  WebSocket protocol (`start` → `frame_meta` + MJPEG frames).
- **Curated catalog** — 8 garments with product photography, categories,
  prices, size pre-selection from onboarding.
- **Garment uploads** — send any product image as the RV2V reference.
- **Wardrobe** — saved looks persisted locally, before/after comparison
  slider, share via Android share sheet.
- **Demo mode** — full journey with staged AI-progress UI and bundled sample
  try-on pairs; honest fallback when the GPU server is unreachable.
- **Design system** — light-minimal editorial style (Inter, warm whites,
  ink CTAs, sage accents), motion tokens, hero transitions, haptics.

## Project layout

```
stylesnap/
├── lib/
│   ├── core/          theme (colors/typography/motion), routes, constants
│   ├── models/        Garment, TryOnLook, ServerStatus
│   ├── data/          seed catalog (matches bundled assets)
│   ├── services/      tryon_service (demo/real), live_mirror_engine (WS),
│   │                  backend_api (REST client)
│   ├── state/         AppState + WardrobeProvider (provider + shared_preferences)
│   ├── widgets/       ui_kit (buttons/chips/shimmer), GarmentCard,
│   │                  BeforeAfterSlider
│   └── screens/       splash · onboarding · main_shell (bottom nav) · home ·
│                      garment_detail (+processing) · result · live_mirror ·
│                      wardrobe · profile
├── assets/            garments/ demo/ brand/ (AI-generated product photography)
├── backend/           StyleSnap Bridge (FastAPI) — see backend/README.md
├── .github/           CI: build-apk.yml workflow + Android prep script
└── pubspec.yaml
```

## Build the APK with GitHub Actions (no local SDK needed)

The repo ships a workflow — `.github/workflows/build-apk.yml` — that builds a
release APK on GitHub's runners and **attaches it to GitHub Releases**
automatically. You never need to install Flutter or Android Studio.

1. **Push this folder to a GitHub repo** (branch `main`). The workflow runs on
   every push and produces:
   - a downloadable artifact: **Actions → Build APK → your run → Artifacts**;
   - a rolling prerelease **"StyleSnap — development build"** containing
     `StyleSnap-dev.apk` under **Releases** (always overwritten with the
     newest build).
2. **Cut a stable release** by pushing a version tag:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

   This creates a GitHub Release **"StyleSnap v1.0.0"** with
   `StyleSnap-v1.0.0.apk` (universal arm64 + armeabi-v7a + x86_64 APK) and
   auto-generated release notes.
3. **Manual builds**: *Actions → Build APK → Run workflow*.

What the workflow does for you: it generates the missing Android scaffolding
with `flutter create . --platforms=android`, injects CAMERA/INTERNET
permissions, cleartext-HTTP for the bridge and the app label
(`.github/scripts/prepare_android.sh`), runs `flutter analyze`
(informational), builds `--release`, uploads the APK as an artifact and
publishes it to Releases.

Notes:

- The APK is signed with the **debug key** (the Flutter template default), so
  it installs on any device via "Install unknown apps". For Play Store
  distribution add your own keystore + signing config to
  `android/app/build.gradle`.
- If the release step fails with `403`, go to **repo Settings → Actions →
  General → Workflow permissions** and select *Read and write permissions*.
- Split per-ABI builds (smaller downloads): change the build step to
  `flutter build apk --release --split-per-abi`.

## Run the app locally

Requirements: Flutter SDK ≥ 3.24, Android SDK, a device or emulator.

```bash
cd stylesnap

# 1) Generate the Android/iOS platform scaffolding around this code
flutter create . --org com.stylesnap --project-name stylesnap

# 2) Add camera permission — open android/app/src/main/AndroidManifest.xml
#    and add these two lines above <application ...>:
#      <uses-permission android:name="android.permission.CAMERA" />
#      <uses-feature android:name="android.hardware.camera" android:required="false" />
#    Internet permission is already included by the Flutter template.

# 3) Run
flutter pub get
flutter run
```

> `flutter create .` keeps all existing files (`lib/`, `assets/`, `pubspec.yaml`)
> and only adds the missing platform folders.

The app starts in **Demo mode** — every screen is fully explorable. To connect
the real AI:

1. Start the bridge (next section).
2. In the app: **Profile → Bridge server URL** → `http://<host>:8600` → **Test**
   (green dot = connected).
3. Toggle **Demo mode** off. Photo and live try-on now run through the GPU.

## Run the bridge

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

uvicorn main:app --host 0.0.0.0 --port 8600            # mock mode
# or with the GPU server running:
JOYAI_UPSTREAM_URL=http://localhost:8080 \
uvicorn main:app --host 0.0.0.0 --port 8600            # full mode
```

See **backend/README.md** for the JoyAI-Video-Edit GPU deployment, protocol
details, and production notes (HTTPS, auth, scaling).

## How the AI try-on works

- **Live mode** uses the exact WebSocket protocol of the official JoyAI
  web client: a `start` message carrying the instruction and the garment as a
  `ref_image` data-URL (RV2V reference), then `frame_meta` + binary MJPEG
  frames at ~12 fps; edited frames stream back and replace the preview.
- **Photo mode** streams the still photo as a short clip (≈48 frames) through
  the same pipeline and returns a temporally stable late frame — the trick the
  repo's own demos use for image inputs.
- Default instruction: *"Put the {garment} from Image 1 on the person in the
  video. Keep the face, pose and background unchanged."*

## Hardware requirements (real mode)

| Component | Minimum | Comfortable |
|---|---|---|
| GPU | RTX 5090 32 GB → 840×480 @ 24 FPS | RTX PRO 6000 / B200 → 720p @ 16–30 FPS |
| Weights | ~51 GB (DiT + VAE + MiMo-VL + detectors) | + compile caches |
| Phone | Any with camera (frame capture + display only) | — |

## Notes

- Garment photography, demo pairs and the app icon are AI-generated placeholders
  — swap `assets/garments/*` for your real product shots.
- The wardrobe stores results in the app documents directory; clearing app data
  resets it.
- Licenses: this project code — MIT; JoyAI-Video-Edit — Apache 2.0.
