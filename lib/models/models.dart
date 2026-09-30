/// A garment in the StyleSnap catalog.
class Garment {
  final String id;
  final String name;
  final String brand;
  final String category; // Tops / Outerwear / Dresses
  final double price;
  final String imageAsset; // asset path of the product shot
  final String? demoResultAsset; // bundled demo try-on result (optional)
  final String material;
  final String fit;
  final List<String> sizes;

  const Garment({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.imageAsset,
    this.demoResultAsset,
    required this.material,
    required this.fit,
    this.sizes = const ['XS', 'S', 'M', 'L', 'XL'],
  });

  /// Garment noun used inside the try-on instruction.
  String get instructionNoun {
    switch (category) {
      case 'Dresses':
        return 'dress';
      case 'Outerwear':
        return 'coat';
      default:
        return name.toLowerCase().contains('hoodie')
            ? 'hoodie'
            : name.toLowerCase().contains('turtleneck')
                ? 'turtleneck sweater'
                : 'shirt';
    }
  }
}

/// A saved try-on look in the user's wardrobe.
class TryOnLook {
  final String id;
  final String garmentId;
  final String garmentName;
  final String resultPath; // local file path of the result image
  final String? beforePath; // optional original photo
  final DateTime createdAt;
  final String mode; // 'photo' | 'live' | 'demo'

  const TryOnLook({
    required this.id,
    required this.garmentId,
    required this.garmentName,
    required this.resultPath,
    this.beforePath,
    required this.createdAt,
    required this.mode,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'garmentId': garmentId,
        'garmentName': garmentName,
        'resultPath': resultPath,
        'beforePath': beforePath,
        'createdAt': createdAt.toIso8601String(),
        'mode': mode,
      };

  factory TryOnLook.fromJson(Map<String, dynamic> json) => TryOnLook(
        id: json['id'] as String,
        garmentId: json['garmentId'] as String,
        garmentName: json['garmentName'] as String,
        resultPath: json['resultPath'] as String,
        beforePath: json['beforePath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        mode: (json['mode'] as String?) ?? 'photo',
      );
}

/// Live-mirror connection status.
enum ServerStatus { unknown, checking, online, offline }
