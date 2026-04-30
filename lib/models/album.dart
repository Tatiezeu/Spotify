import 'song.dart';

class Album {
  final String id;
  final String title;
  final String artistName;
  final String artistId;
  final String coverUrl;
  final int year;
  final List<Song> tracks;
  final bool isSaved;

  Album({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artistId,
    required this.coverUrl,
    required this.year,
    required this.tracks,
    this.isSaved = false,
  });

  Album copyWith({
    String? id,
    String? title,
    String? artistName,
    String? artistId,
    String? coverUrl,
    int? year,
    List<Song>? tracks,
    bool? isSaved,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      artistId: artistId ?? this.artistId,
      coverUrl: coverUrl ?? this.coverUrl,
      year: year ?? this.year,
      tracks: tracks ?? this.tracks,
      isSaved: isSaved ?? this.isSaved,
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
}
