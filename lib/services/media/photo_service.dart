import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Wraps `image_picker` for camera & gallery capture. Returns a `data:` URI
/// (base64) so the picked image works on every platform (web included),
/// persists in Hive, and renders through the same path as network photos.
///
/// Cloud upload (Firebase Storage) is the deferred step — see the Integrations
/// screen; locally the data URI is all the demo needs.
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromCamera() => _pick(ImageSource.camera);
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<String?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 72,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return 'data:${_mimeFor(file.name)};base64,${base64Encode(bytes)}';
  }

  String _mimeFor(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
