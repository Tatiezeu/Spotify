class Song {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String albumId;
  final String albumName;
  final String coverUrl;
  final Duration duration;
  final bool isExplicit;
  final bool isLiked;
  final int playCount;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.albumId,
    required this.albumName,
    required this.coverUrl,
    required this.duration,
    this.isExplicit = false,
    this.isLiked = false,
    this.playCount = 0,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    String? albumId,
    String? albumName,
    String? coverUrl,
    Duration? duration,
    bool? isExplicit,
    bool? isLiked,
    int? playCount,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      isExplicit: isExplicit ?? this.isExplicit,
      isLiked: isLiked ?? this.isLiked,
      playCount: playCount ?? this.playCount,
    );
  }

  String get durationString {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
