import 'dart:convert';

const int maxItemTags = 10;
const int maxItemTagLength = 30;

const List<String> suggestedItemTags = [
  'Tool',
  'Book',
  'Bag',
  'Electronics',
  'Documents',
  'Spare Part',
  'Clothing',
  'Kitchen',
  'Office',
  'Other',
];

List<String> normalizeItemTags(Iterable<dynamic> values) {
  final tags = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final tag = value.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
    if (tag.isEmpty || tag.length > maxItemTagLength) continue;
    if (seen.add(tag.toLowerCase())) tags.add(tag);
    if (tags.length == maxItemTags) break;
  }
  return tags;
}

List<String> decodeItemTags(dynamic value) {
  if (value is List) return normalizeItemTags(value);
  if (value == null) return [];

  final source = value.toString().trim();
  if (source.isEmpty) return [];
  try {
    final decoded = json.decode(source);
    if (decoded is List) return normalizeItemTags(decoded);
  } catch (_) {
    // Accept comma-separated values from an older API or manual import.
  }
  return normalizeItemTags(source.split(','));
}

String encodeItemTags(Iterable<String> tags) =>
    json.encode(normalizeItemTags(tags));
