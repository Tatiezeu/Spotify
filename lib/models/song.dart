class Song {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String albumId;
  final String albumName;
  final String coverUrl;
  final String previewUrl;
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
    this.previewUrl = '',
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
    String? previewUrl,
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
      previewUrl: previewUrl ?? this.previewUrl,
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

  factory Song.fromJson(Map<String, dynamic> json) {
    // Safely extract artists
    final artists = json['artists'] as List?;
    final firstArtist = (artists != null && artists.isNotEmpty) ? artists[0] : null;
    
    // Safely extract album and images
    final album = json['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    final coverUrl = (images != null && images.isNotEmpty) 
        ? images[0]['url'] ?? 'https://via.placeholder.com/150'
        : 'https://via.placeholder.com/150';

    return Song(
      id: json['id']?.toString() ?? '',
      title: json['name']?.toString() ?? 'Unknown Title',
      artist: firstArtist?['name']?.toString() ?? 'Unknown Artist',
      artistId: firstArtist?['id']?.toString() ?? '',
      albumId: album?['id']?.toString() ?? '',
      albumName: album?['name']?.toString() ?? 'Unknown Album',
      coverUrl: coverUrl,
      previewUrl: json['preview_url']?.toString() ?? '',
      duration: Duration(milliseconds: json['duration_ms'] is int ? json['duration_ms'] : 0),
      isExplicit: json['explicit'] == true,
      playCount: json['popularity'] is int ? json['popularity'] : 0,
      isLiked: false,
    );
  }
}
