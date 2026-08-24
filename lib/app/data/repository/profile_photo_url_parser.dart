/// Extracts a photo URL from heterogeneous backend upload responses.
String? extractUploadedPhotoUrl(dynamic payload) {
  if (payload == null) return null;
  if (payload is String && payload.trim().isNotEmpty) {
    final trimmed = payload.trim();
    if (trimmed.startsWith('http')) return trimmed;
  }
  if (payload is Map) {
    for (final key in [
      'photoUrl',
      'photo',
      'url',
      'secure_url',
      'imageUrl',
      'image',
      'path',
    ]) {
      final value = payload[key]?.toString().trim();
      if (value != null &&
          value.isNotEmpty &&
          (value.startsWith('http') || value.startsWith('/'))) {
        return value;
      }
    }
    for (final nested in payload.values) {
      final found = extractUploadedPhotoUrl(nested);
      if (found != null && found.isNotEmpty) return found;
    }
  }
  if (payload is List) {
    for (final item in payload) {
      final found = extractUploadedPhotoUrl(item);
      if (found != null && found.isNotEmpty) return found;
    }
  }
  return null;
}