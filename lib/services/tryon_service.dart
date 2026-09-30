import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'backend_api.dart';

/// The result of a try-on run.
class TryOnOutcome {
  final String resultPath;
  final String? beforePath;
  final bool isDemo;
  final String note;
  const TryOnOutcome({
    required this.resultPath,
    this.beforePath,
    required this.isDemo,
    this.note = '',
  });
}

/// Progress stages surfaced to the processing UI.
class TryOnProgress {
  final double value; // 0..1
  final String stage;
  const TryOnProgress(this.value, this.stage);
}

/// Facade that picks demo vs real backend execution.
class TryOnService {
  TryOnService(this._state);
  final AppState _state;

  final _progressCtrl = StreamController<TryOnProgress>.broadcast();
  Stream<TryOnProgress> get progress => _progressCtrl.stream;

  void _emit(double v, String stage) {
    if (!_progressCtrl.isClosed) _progressCtrl.add(TryOnProgress(v, stage));
  }

  Future<String> _materializeAsset(String asset, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    if (!file.existsSync()) {
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file.path;
  }

  /// Photo-mode try-on. [personPath] may be null → uses the bundled sample model.
  Future<TryOnOutcome> tryOnPhoto({
    required Garment garment,
    String? personPath,
  }) async {
    final useDemo = _state.demoMode || _state.serverStatus == ServerStatus.offline;

    if (personPath == null) {
      personPath =
          await _materializeAsset('assets/demo/model_base.png', 'sample_model.png');
    }

    if (useDemo) {
      return _runDemo(garment, personPath);
    }
    try {
      return await _runBackend(garment, personPath);
    } catch (_) {
      // Graceful fallback so the journey never dead-ends.
      return _runDemo(garment, personPath,
          fallbackNote: 'Backend unreachable — showing demo preview');
    }
  }

  Future<TryOnOutcome> _runDemo(Garment garment, String? personPath,
      {String fallbackNote = 'Demo preview — connect a GPU server for real results'}) async {
    const stages = [
      (0.12, 'Reading body silhouette'),
      (0.34, 'Understanding garment drape'),
      (0.58, 'Draping onto the body'),
      (0.82, 'Refining fabric details'),
      (1.0, 'Finishing'),
    ];
    for (final (v, s) in stages) {
      await Future.delayed(const Duration(milliseconds: 620));
      _emit(v, s);
    }

    // Prefer a pre-rendered demo pair; otherwise reuse the sample model.
    final asset = garment.demoResultAsset ?? 'assets/demo/model_base.png';
    final outPath = await _materializeAsset(
        asset, 'demo_${garment.id}_result.png');
    final beforePath = await _materializeAsset(
        'assets/demo/model_base.png', 'demo_model_base.png');

    return TryOnOutcome(
      resultPath: outPath,
      beforePath: beforePath,
      isDemo: true,
      note: fallbackNote,
    );
  }

  Future<TryOnOutcome> _runBackend(Garment garment, String? personPath) async {
    _emit(0.08, 'Uploading to GPU server');
    final personBytes = await File(personPath!).readAsBytes();
    final garmentBytes =
        (await rootBundle.load(garment.imageAsset)).buffer.asUint8List();

    // Animate gentle progress while the request is in flight.
    var p = 0.08;
    final timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (p < 0.92) {
        p += 0.04;
        _emit(p, 'AI editing in progress');
      }
    });

    try {
      final instruction = AppConstants.tryOnInstructionTemplate
          .replaceAll('{garment}', garment.instructionNoun);
      final resultBytes = await _state.api.photoTryOn(
        personBytes: personBytes,
        garmentBytes: garmentBytes,
        instruction: instruction,
        garmentName: garment.name,
      );
      _emit(1.0, 'Done');
      final dir = await getApplicationDocumentsDirectory();
      final out = File(
          '${dir.path}/result_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await out.writeAsBytes(resultBytes, flush: true);
      return TryOnOutcome(
        resultPath: out.path,
        beforePath: personPath,
        isDemo: false,
      );
    } finally {
      timer.cancel();
    }
  }

  void dispose() => _progressCtrl.close();
}
