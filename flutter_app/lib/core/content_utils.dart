import 'dart:convert';

/// Unescape HTML entities that Flutter web / Dio web adapter may introduce.
String _unescapeHtml(String input) {
  return input
      .replaceAll('&quot;', '"')
      .replaceAll('&#34;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
}

/// Parse Delta JSON content (which may be a String, List, or HTML-escaped)
/// and return the extracted plain text. Safe for use in previews.
String extractPreviewText(dynamic content, {int maxLength = 120}) {
  if (content == null) return '';
  try {
    List ops;
    if (content is List) {
      ops = content;
    } else if (content is String && content.isNotEmpty) {
      // Unescape HTML entities before JSON decode
      final clean = _unescapeHtml(content);
      final decoded = jsonDecode(clean);
      if (decoded is List) {
        ops = decoded;
      } else {
        return clean.length > maxLength
            ? '${clean.substring(0, maxLength)}...'
            : clean;
      }
    } else {
      return '';
    }
    return ops
        .map((op) => op is Map ? (op['insert'] ?? '') : '')
        .join('')
        .replaceAll('\n', ' ')
        .trim();
  } catch (_) {
    final s = content.toString();
    return s.length > maxLength ? '${s.substring(0, maxLength)}...' : s;
  }
}

/// Parse Delta JSON content into a List suitable for Document.fromJson().
/// Returns null if content cannot be parsed.
List? parseDeltaContent(dynamic rawContent) {
  if (rawContent == null) return null;
  try {
    if (rawContent is List) return rawContent;
    if (rawContent is String && rawContent.isNotEmpty) {
      final clean = _unescapeHtml(rawContent);
      final decoded = jsonDecode(clean);
      if (decoded is List) return decoded;
      // Plain text fallback
      return [{'insert': '$clean\n'}];
    }
  } catch (_) {}
  // Last resort: treat as plain text
  final text = rawContent.toString();
  return [{'insert': '$text\n'}];
}
