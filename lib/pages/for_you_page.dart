import 'package:flutter/material.dart';
import 'dart:ui';
import '../models.dart';
import '../services/music_api_service.dart';
import '../services/music_player_service.dart';
import '../widgets/glassmorphism.dart';
import '../theme/glass_theme.dart';

class ForYouPage extends StatefulWidget {
  const ForYouPage({super.key});

  @override
  State<ForYouPage> createState() => _ForYouPageState();
}

class _ForYouPageState extends State<ForYouPage> {
  List<MusicItem> recentlyPlayed = [];
  List<MusicItem> youMightLike = [];
  bool isLoadingRecent = true;
  bool isLoadingRecommended = true;

  final List<Artist> favoriteArtists = [
    Artist('HOYO-MIX', Colors.blue),
    Artist('桜マグネタイト', Colors.pink),
    Artist('TOGENASHI TOGEARI', Colors.green),
    Artist('Laur', Colors.yellow),
  ];

  @override
  void initState() {
    super.initState();
    _loadMusicData();
  }

  Future<void> _loadMusicData() async {
    // Load both APIs in parallel for faster loading
    if (mounted) {
      setState(() {
        isLoadingRecent = true;
        isLoadingRecommended = true;
      });
    }

    try {
      // Fetch both simultaneously
      final results = await Future.wait([
        MusicApiService.fetchRecentlyPlayed(),
        MusicApiService.fetchRecommendations(),
      ]);

      if (mounted) {
        setState(() {
          recentlyPlayed = results[0];
          youMightLike = results[1];
          isLoadingRecent = false;
          isLoadingRecommended = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading music data: $e');
      // If both fail, try loading individually with error handling
      _loadRecentlyPlayedSafely();
      _loadRecommendationsSafely();
    }
  }

  Future<void> _loadRecentlyPlayedSafely() async {
    try {
      final recent = await MusicApiService.fetchRecentlyPlayed();
      if (mounted) {
        setState(() {
          recentlyPlayed = recent;
          isLoadingRecent = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recently played: $e');
      if (mounted) {
        setState(() {
          recentlyPlayed = [];
          isLoadingRecent = false;
        });
      }
    }
  }

  Future<void> _loadRecommendationsSafely() async {
    try {
      final recommended = await MusicApiService.fetchRecommendations();
      if (mounted) {
        setState(() {
          youMightLike = recommended;
          isLoadingRecommended = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      if (mounted) {
        setState(() {
          youMightLike = [];
          isLoadingRecommended = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('For You Page',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            floating: true,
            snap: true,
            pinned: false,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0D0118).withValues(alpha: 0.7),
                        Color(0xFF0D0118).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 140,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassWithGlow(
                  borderRadius: BorderRadius.circular(20),
                  padding: EdgeInsets.fromLTRB(12, 6, 12, 6),
                  glowBlur: Glow.buttonBlur,
                  glowSpread: GlassTheme.buttonGlowSpread,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/heart.png',
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.favorite, color: Colors.pink, size: 20);
                        },
                      ),
                      SizedBox(width: 4),
                      Text('Liked Songs'),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                GlassWithGlow(
                  borderRadius: BorderRadius.circular(20),
                  padding: EdgeInsets.fromLTRB(12, 6, 12, 6),
                  glowBlur: Glow.buttonBlur,
                  glowSpread: Glow.buttonSpread,
                  glowAlpha: Glow.buttonAlpha,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icons/radio icon 2.png',
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.radio, color: Colors.purple, size: 20);
                        },
                      ),
                      SizedBox(width: 4),
                      Text('Radio Mode'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Recently Played
            Text('Recently Played',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            isLoadingRecent
                ? Center(child: CircularProgressIndicator())
                : recentlyPlayed.isEmpty
                    ? SizedBox(
                        height: 140,
                        child: Center(
                          child: Text(
                            'No songs available. Pull to refresh.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : SizedBox(
              height: 185, // 增加高度以容納發光效果
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                clipBehavior: Clip.none, // 不裁剪發光效果
                itemCount: recentlyPlayed.length,
                itemBuilder: (context, index) {
                  final item = recentlyPlayed[index];
                  return GestureDetector(
                    onTap: () {
                      MusicPlayerService().playSong(
                        item,
                        playlist: recentlyPlayed,
                        index: index,
                      );
                    },
                    child: Container(
                      width: 120,
                      margin: EdgeInsets.only(right: 12, top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassWithGlow(
                            borderRadius: BorderRadius.circular(8),
                            glowColor: item.color,
                            glowBlur: Glow.albumBlur,
                            glowSpread: GlassTheme.albumGlowSpread,
                            glowAlpha: Glow.albumAlpha,
                            child: Container(
                            width: 120,
                            height: 100,
                            decoration: BoxDecoration(
                            gradient: item.albumCoverUrl == null
                                ? LinearGradient(
                                    colors: [item.color, item.color.withValues(alpha: 0.6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item.albumCoverUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.albumCoverUrl!,
                                    width: 120,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(Icons.music_note,
                                            size: 40, color: Colors.white.withValues(alpha: 0.8)),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Icon(Icons.music_note,
                                      size: 40, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                item.artist,
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ));
                },
              ),
            ),
            SizedBox(height: 20),

            // You Might Also Like
            Text('You Might Also Like',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            isLoadingRecommended
                ? Center(child: CircularProgressIndicator())
                : youMightLike.isEmpty
                    ? SizedBox(
                        height: 140,
                        child: Center(
                          child: Text(
                            'No recommendations available. Pull to refresh.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : SizedBox(
              height: 185, // 增加高度以容納發光效果
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                clipBehavior: Clip.none, // 不裁剪發光效果
                itemCount: youMightLike.length,
                itemBuilder: (context, index) {
                  final item = youMightLike[index];
                  return GestureDetector(
                    onTap: () {
                      MusicPlayerService().playSong(
                        item,
                        playlist: youMightLike,
                        index: index,
                      );
                    },
                    child: Container(
                      width: 120,
                      margin: EdgeInsets.only(right: 12, top: 10, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassWithGlow(
                            borderRadius: BorderRadius.circular(8),
                            glowColor: item.color,
                            glowBlur: Glow.albumBlur,
                            glowSpread: Glow.albumSpread,
                            glowAlpha: Glow.albumAlpha,
                            child: Container(
                            width: 120,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: item.albumCoverUrl == null
                                  ? LinearGradient(
                                      colors: [item.color, item.color.withValues(alpha: 0.6)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: item.albumCoverUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.albumCoverUrl!,
                                    width: 120,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(Icons.album,
                                            size: 40, color: Colors.white.withValues(alpha: 0.8)),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Icon(Icons.album,
                                      size: 40, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                item.artist,
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ));
                },
              ),
            ),
            SizedBox(height: 20),

            // Favorite Artists
            Text('Favorite Artists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SizedBox(
              height: 140, // 增加高度
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                clipBehavior: Clip.none, // 不裁剪發光效果
                itemCount: favoriteArtists.length,
                itemBuilder: (context, index) {
                  final artist = favoriteArtists[index];
                  return Container(
                    width: 90,
                    margin: EdgeInsets.only(right: 15, top: 10, bottom: 10),
                    child: Column(
                      children: [
                        GlassWithGlow(
                          borderRadius: BorderRadius.circular(35),
                          glowColor: artist.color,
                          glowBlur: Glow.cardBlur,
                          glowSpread: Glow.cardSpread,
                          glowAlpha: Glow.cardAlpha,
                          child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [artist.color, artist.color.withValues(alpha: 0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              artist.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          artist.name,
                          style: TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
