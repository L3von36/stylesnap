import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/backend_api.dart';

/// Global app state: onboarding, settings, server status.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  final BackendApi api = BackendApi();

  // ----- Onboarding / profile -----
  bool _onboarded = false;
  String _size = 'M';
  List<String> _stylePrefs = [];

  bool get onboarded => _onboarded;
  String get size => _size;
  List<String> get stylePrefs => List.unmodifiable(_stylePrefs);

  // ----- Settings -----
  bool _demoMode = true;
  String _backendUrl = AppConstants.defaultBackendUrl;

  bool get demoMode => _demoMode;
  String get backendUrl => _backendUrl;
  ServerStatus serverStatus = ServerStatus.unknown;
  String serverInfo = '';

  void _load() {
    _onboarded = _prefs.getBool('onboarded') ?? false;
    _size = _prefs.getString('size') ?? 'M';
    _stylePrefs = _prefs.getStringList('stylePrefs') ?? [];
    _demoMode = _prefs.getBool('demoMode') ?? true;
    _backendUrl = _prefs.getString('backendUrl') ?? AppConstants.defaultBackendUrl;
    api.baseUrl = _backendUrl;
  }

  Future<void> completeOnboarding({
    required String size,
    required List<String> stylePrefs,
  }) async {
    _size = size;
    _stylePrefs = stylePrefs;
    _onboarded = true;
    await _prefs.setBool('onboarded', true);
    await _prefs.setString('size', size);
    await _prefs.setStringList('stylePrefs', stylePrefs);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _onboarded = false;
    await _prefs.setBool('onboarded', false);
    notifyListeners();
  }

  Future<void> setDemoMode(bool value) async {
    _demoMode = value;
    await _prefs.setBool('demoMode', value);
    notifyListeners();
  }

  Future<void> setBackendUrl(String url) async {
    _backendUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await _prefs.setString('backendUrl', _backendUrl);
    api.baseUrl = _backendUrl;
    serverStatus = ServerStatus.unknown;
    notifyListeners();
  }

  /// Ping the StyleSnap bridge server (not the GPU server directly).
  Future<bool> checkServer() async {
    serverStatus = ServerStatus.checking;
    serverInfo = '';
    notifyListeners();
    try {
      final health = await api.health().timeout(const Duration(seconds: 6));
      serverStatus = ServerStatus.online;
      serverInfo = health.backend;
    } catch (_) {
      serverStatus = ServerStatus.offline;
      serverInfo = '';
    }
    notifyListeners();
    return serverStatus == ServerStatus.online;
  }

}

/// Wardrobe state — persisted saved looks.
class WardrobeProvider extends ChangeNotifier {
  WardrobeProvider(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  final List<TryOnLook> _looks = [];

  List<TryOnLook> get looks => List.unmodifiable(_looks.reversed);

  void _load() {
    final raw = _prefs.getStringList('wardrobe') ?? [];
    _looks
      ..clear()
      ..addAll(raw.map((e) => TryOnLook.fromJson(jsonDecode(e) as Map<String, dynamic>)));
  }

  Future<void> _persist() async {
    await _prefs.setStringList(
      'wardrobe',
      _looks.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> add(TryOnLook look) async {
    _looks.add(look);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _looks.removeWhere((l) => l.id == id);
    await _persist();
    notifyListeners();
  }
}
