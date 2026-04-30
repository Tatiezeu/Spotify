import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final String description;
  final String coverUrl;
  final String creatorName;
  final List<Song> tracks;
  final bool isFollowing;
  final int followerCount;
  final bool isCollaborative;
  final bool isUserCreated;

  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.creatorName,
    required this.tracks,
    this.isFollowing = false,
    this.followerCount = 0,
    this.isCollaborative = false,
    this.isUserCreated = false,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    String? creatorName,
    List<Song>? tracks,
    bool? isFollowing,
    int? followerCount,
    bool? isCollaborative,
    bool? isUserCreated,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      creatorName: creatorName ?? this.creatorName,
      tracks: tracks ?? this.tracks,
      isFollowing: isFollowing ?? this.isFollowing,
      followerCount: followerCount ?? this.followerCount,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      isUserCreated: isUserCreated ?? this.isUserCreated,
    );
  }

  Duration get totalDuration {
    return tracks.fold(
      Duration.zero,
      (total, song) => total + song.duration,
    );
  }

  String get totalDurationString {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  int get trackCount => tracks.length;

  String get followerCountString {
    if (followerCount >= 1000000) {
      return '${(followerCount / 1000000).toStringAsFixed(1)}M followers';
    } else if (followerCount >= 1000) {
      return '${(followerCount / 1000).toStringAsFixed(1)}K followers';
    }
    return '$followerCount followers';
  }
}
