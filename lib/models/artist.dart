class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final int monthlyListeners;
  final bool isFollowing;
  final String bio;
  final int globalRank;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.monthlyListeners,
    this.isFollowing = false,
    this.bio = '',
    this.globalRank = 0,
  });

  Artist copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? monthlyListeners,
    bool? isFollowing,
    String? bio,
    int? globalRank,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      monthlyListeners: monthlyListeners ?? this.monthlyListeners,
      isFollowing: isFollowing ?? this.isFollowing,
      bio: bio ?? this.bio,
      globalRank: globalRank ?? this.globalRank,
    );
  }

  String get monthlyListenersString {
    if (monthlyListeners >= 1000000) {
      return '${(monthlyListeners / 1000000).toStringAsFixed(1)}M';
    } else if (monthlyListeners >= 1000) {
      return '${(monthlyListeners / 1000).toStringAsFixed(1)}K';
    }
    return monthlyListeners.toString();
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Artist',
      imageUrl: (json['images'] != null && json['images'].isNotEmpty)
          ? json['images'][0]['url']
          : 'https://via.placeholder.com/150',
      monthlyListeners: json['followers']?['total'] ?? 0,
      globalRank: json['popularity'] ?? 0,
    );
  }
}
