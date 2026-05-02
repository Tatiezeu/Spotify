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
    // 1. Determine Title/Name
    final String title = json['name']?.toString() ?? 'Unknown';

    // 2. Handle Artists (could be a list for tracks, or the object itself for artists)
    final artists = json['artists'] as List?;
    String artistName = 'Unknown Artist';
    String artistId = '';
    
    if (artists != null && artists.isNotEmpty) {
      artistName = artists[0]['name']?.toString() ?? 'Unknown Artist';
      artistId = artists[0]['id']?.toString() ?? '';
    } else if (json['type'] == 'artist') {
      artistName = json['name']?.toString() ?? 'Unknown Artist';
      artistId = json['id']?.toString() ?? '';
    }

    // 3. Handle Images (in 'album' for tracks, or at root for artists/albums)
    final album = json['album'] as Map<String, dynamic>?;
    final images = (album != null) ? album['images'] as List? : json['images'] as List?;
    
    String coverUrl = 'https://via.placeholder.com/150';
    if (images != null && images.isNotEmpty) {
      coverUrl = images[0]['url'] ?? coverUrl;
    }

    return Song(
      id: json['id']?.toString() ?? '',
      title: title,
      artist: artistName,
      artistId: artistId,
      albumId: album?['id']?.toString() ?? '',
      albumName: album?['name']?.toString() ?? (json['type'] == 'album' ? title : 'Single'),
      coverUrl: coverUrl,
      previewUrl: json['preview_url']?.toString() ?? '',
      duration: Duration(milliseconds: json['duration_ms'] is int ? json['duration_ms'] : 0),
      isExplicit: json['explicit'] == true,
      playCount: json['popularity'] is int ? json['popularity'] : 0,
      isLiked: false,
    );
  }
}
