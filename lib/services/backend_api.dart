import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// HTTP client for the StyleSnap backend bridge.
/// The bridge sits between the app and the JoyAI-Video-Edit GPU server.
class BackendApi {
  String baseUrl = 'http://10.0.2.2:8600';

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// GET /health — checks bridge + upstream GPU availability.
  Future<HealthInfo> health() async {
    final res = await http.get(_uri('/health')).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) {
      throw Exception('health ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return HealthInfo(
      status: (json['status'] as String?) ?? 'unknown',
      backend: (json['backend'] as String?) ?? 'mock',
      gpu: (json['gpu'] as bool?) ?? false,
      version: (json['version'] as String?) ?? '',
    );
  }

  /// POST /api/tryon/photo — person photo + garment image → try-on result (JPEG bytes).
  Future<Uint8List> photoTryOn({
    required Uint8List personBytes,
    required Uint8List garmentBytes,
    required String instruction,
    required String garmentName,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/api/tryon/photo'))
      ..fields['instruction'] = instruction
      ..fields['garment_name'] = garmentName
      ..files.add(http.MultipartFile.fromBytes('person', personBytes,
          filename: 'person.jpg'))
      ..files.add(http.MultipartFile.fromBytes('garment', garmentBytes,
          filename: 'garment.jpg'));
    final streamed =
        await req.send().timeout(const Duration(minutes: 3));
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw Exception('tryon failed ${streamed.statusCode}: $body');
    }
    final collector = await streamed.stream.toBytes();
    return Uint8List.fromList(collector);
  }
}

class HealthInfo {
  final String status;
  final String backend; // 'joyai' when GPU upstream is connected, else 'mock'
  final bool gpu;
  final String version;
  const HealthInfo({
    required this.status,
    required this.backend,
    required this.gpu,
    required this.version,
  });

  bool get upstreamReady => backend == 'joyai' && gpu;
}
