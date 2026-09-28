/// Turns whatever the student typed into something the browser can open.
///
/// The bar in front of them does two jobs: it accepts a link
/// (`codeforces.com/blog/entry/1`, `https://atcoder.jp/...`) and it accepts a
/// plain name (`two sum problem set`), which becomes a web search. Keeping
/// this as a pure function makes the rule testable without a browser.
Uri buildBrowseUri(String rawInput) {
  final input = rawInput.trim();
  if (input.isEmpty) return Uri.parse(_searchBase);

  if (_looksLikeLink(input)) {
    final withScheme = input.contains('://') ? input : 'https://$input';
    try {
      return Uri.parse(withScheme);
    } on FormatException {
      // Not a link after all — fall through to a search.
    }
  }

  return Uri.parse(
    '$_searchBase/search?q=${Uri.encodeComponent(input)}',
  );
}

/// True when the text should be opened as an address instead of searched.
bool _looksLikeLink(String input) {
  if (input.contains(' ')) return false;

  final lower = input.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) return true;

  // A bare host has a dot (`codeforces.com`) or a path separator
  // (`atcoder.jp/contests/abc300`); a search phrase has neither.
  return input.contains('.') || input.contains('/');
}

const String _searchBase = 'https://www.google.com';
