/// One entry of Codeforces' public `user.info` response.
///
/// Ratings are optional: Codeforces omits `rating`, `maxRating` and `rank`
/// for players who have never competed, so every field except [handle] is
/// nullable and a friend without them still renders as a plain handle card.
class FriendInfo {
  const FriendInfo({
    required this.handle,
    this.rating,
    this.maxRating,
    this.rank,
    this.titlePhoto,
  });

  /// Handle exactly as Codeforces spelled it back.
  final String handle;

  /// Current contest rating, `null` while unrated.
  final int? rating;

  /// Best rating ever reached, `null` while unrated.
  final int? maxRating;

  /// Codeforces rank slug, e.g. `pupil` or `candidate master`.
  final String? rank;

  /// Avatar image url (usually on codeforces.com).
  final String? titlePhoto;

  factory FriendInfo.fromJson(Map<String, dynamic> json) {
    return FriendInfo(
      handle: json['handle'] as String? ?? '',
      rating: _asInt(json['rating']),
      maxRating: _asInt(json['maxRating']),
      rank: json['rank'] as String?,
      titlePhoto: json['titlePhoto'] as String?,
    );
  }

  bool get isRated => rating != null;

  /// `pupil` -> `Pupil`, `candidate master` -> `Candidate Master`.
  ///
  /// Empty when Codeforces did not send a rank (unrated player).
  String get rankLabel {
    final raw = rank?.trim();
    if (raw == null || raw.isEmpty) return '';
    return raw
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
