import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/live_mirror_engine.dart';
import '../state/app_state.dart';
import '../widgets/ui_kit.dart';
import 'result_screen.dart';
import '../data/catalog.dart';

/// Live mirror — real-time try-on streamed through the backend bridge.
/// Demo mode shows a stylized on-device simulation.
class LiveMirrorScreen extends StatefulWidget {
  final Garment? garment;
  const LiveMirrorScreen({super.key, this.garment});

  @override
  State<LiveMirrorScreen> createState() => _LiveMirrorScreenState();
}

class _LiveMirrorScreenState extends State<LiveMirrorScreen> {
  LiveMirrorEngine? _engine;
  Garment? _garment;
  String _instruction = '';
  bool _running = false;
  bool _starting = false;
  String _status = '';
  LiveMetrics _metrics = const LiveMetrics(sent: 0, received: 0, outFps: 0);
  Uint8List? _latestFrame;
  String _sessionMode = ''; // 'demo' | 'live'

  @override
  void initState() {
    super.initState();
    _garment = widget.garment;
    _instruction = AppConstants.tryOnInstructionTemplate.replaceAll(
      '{garment}',
      _garment?.instructionNoun ?? 'outfit',
    );
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    final app = context.read<AppState>();
    final engine = LiveMirrorEngine(
      backendUrl: app.backendUrl,
      demoMode: app.demoMode,
    );
    setState(() => _starting = true);

    try {
      await engine.startCamera();
      engine.outputs.listen((frame) {
        if (mounted) setState(() => _latestFrame = frame);
      });
      engine.status.listen((s) {
        if (mounted) setState(() => _status = s);
      });
      engine.metrics.listen((m) {
        if (mounted) setState(() => _metrics = m);
      });

      Uint8List? garmentBytes;
      if (_garment != null && !app.demoMode) {
        final data = await rootBundle.load(_garment!.imageAsset);
        garmentBytes = data.buffer.asUint8List();
      }

      await engine.start(instruction: _instruction, garmentBytes: garmentBytes);
      _engine = engine;
      setState(() {
        _running = true;
        _sessionMode = app.demoMode ? 'demo' : 'live';
        _starting = false;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _starting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start: $e')),
        );
      }
    }
  }

  Future<void> _stop() async {
    await _engine?.stop();
    _engine?.dispose();
    _engine = null;
    setState(() {
      _running = false;
      _latestFrame = null;
    });
  }

  Future<void> _snapshot() async {
    if (_latestFrame == null) return;
    final dir = await Directory.systemTemp.createTemp('snap');
    final path = '${dir.path}/live_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(path).writeAsBytes(_latestFrame!, flush: true);
    if (!mounted) return;
    Navigator.of(context).push(FadeSlideRoute(
      page: ResultScreen(
        garment: _garment ?? kCatalog.first,
        resultPath: path,
        beforePath: '',
        isDemo: _sessionMode == 'demo',
        mode: 'live',
      ),
    ));
  }

  Future<void> _pickGarment() async {
    final app = context.read<AppState>();
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          children: [
            Eyebrow('Choose a garment as reference'),
            const SizedBox(height: 14),
            ...kCatalog.map(
              (g) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(g.imageAsset,
                      width: 46, height: 60, fit: BoxFit.cover),
                ),
                title: Text(g.name,
                    style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text('${g.category} · ${money(g.price)}',
                    style: Theme.of(context).textTheme.bodySmall),
                trailing: _garment?.id == g.id
                    ? const Icon(Icons.check_rounded, color: AppColors.sage)
                    : null,
                onTap: () {
                  setState(() {
                    _garment = g;
                    _instruction = AppConstants.tryOnInstructionTemplate
                        .replaceAll('{garment}', g.instructionNoun);
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
    // Restart applies the new reference.
    if (_running) {
      await _stop();
      await _start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cam = _engine?.camera;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ---- Feed ----
          if (_running && _latestFrame != null)
            Image.memory(_latestFrame!, fit: BoxFit.cover, gaplessPlayback: true)
          else if (_running && cam != null && cam.value.isInitialized)
            CameraPreview(cam)
          else
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: Color(0x22FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_outlined,
                        color: AppColors.surface, size: 34),
                  ),
                  const SizedBox(height: 22),
                  Text('Live Mirror',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: AppColors.surface)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      app.demoMode
                          ? 'Runs in demo simulation. Connect a GPU server in Profile for real-time AI editing.'
                          : 'Streams your camera to the GPU server and edits in real time. Front camera works best.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: const Color(0xB3FFFFFF)),
                    ),
                  ),
                ],
              ),
            ),

          // ---- Top bar ----
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _glassChip(
                    _sessionMode == 'demo'
                        ? 'DEMO'
                        : _sessionMode == 'live'
                            ? 'LIVE'
                            : (app.demoMode ? 'DEMO MODE' : 'SERVER MODE'),
                    color: _sessionMode == 'live'
                        ? AppColors.danger
                        : AppColors.gold,
                  ),
                  const Spacer(),
                  if (_running)
                    _glassChip(
                        '↑${_metrics.sent} ↓${_metrics.received} · ${_metrics.outFps.toStringAsFixed(1)} fps',
                        color: AppColors.surface),
                ],
              ),
            ),
          ),

          // ---- Bottom controls ----
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _running ? null : _pickGarment,
                        child: Row(
                          children: [
                            if (_garment != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(_garment!.imageAsset,
                                    width: 40, height: 52, fit: BoxFit.cover),
                              )
                            else
                              Container(
                                width: 40,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.beige,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.checkroom, size: 18),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _garment?.name ?? 'Pick a garment',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontSize: 13.5),
                                  ),
                                  Text(
                                    _running
                                        ? _status
                                        : 'Tap to change reference garment',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (!_running)
                            Expanded(
                              child: PrimaryButton(
                                label: _starting ? 'Starting…' : 'Start live',
                                icon: Icons.play_arrow_rounded,
                                onTap: _starting ? null : _start,
                              ),
                            )
                          else ...[
                            Expanded(
                              child: SecondaryButton(
                                label: 'Stop',
                                icon: Icons.stop_rounded,
                                onTap: _stop,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Snapshot',
                                icon: Icons.camera_alt_rounded,
                                color: AppColors.sage,
                                onTap:
                                    _latestFrame == null ? null : _snapshot,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassChip(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 9.5,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
