import 'package:flutter/material.dart';
import '../services/music_player_service.dart';
import '../widgets/glassmorphism.dart';
import '../theme/glass_theme.dart';

class MusicPlayer extends StatefulWidget {
  const MusicPlayer({super.key});

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> with SingleTickerProviderStateMixin {
  final MusicPlayerService _playerService = MusicPlayerService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _playerService.addListener(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _playerService.removeListener(_onPlayerStateChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_playerService.hasSong) {
      return SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: _playerService.isMinimized ? Offset(0, 1) : Offset(0, -1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _playerService.isMinimized
          ? _buildMinimizedPlayer()
          : _buildMaximizedPlayer(),
    );
  }

  Widget _buildMinimizedPlayer() {
    final song = _playerService.currentSong!;
    
    return GestureDetector(
      onTap: () {
        debugPrint('Minimized player tapped - maximizing');
        _playerService.maximize();
      },
      child: Container(
        color: Colors.transparent,
        child: GlassWithGlow(
          borderRadius: BorderRadius.circular(0),
          padding: EdgeInsets.zero,
          glowColor: song.color,
          glowSpread: Glow.miniPlayerSpread,
          glowBlur: Glow.miniPlayerBlur,
          glowAlpha: Glow.miniPlayerAlpha,
          child: Container(
          height: 70,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
          children: [
            // Album cover
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: song.albumCoverUrl == null
                    ? LinearGradient(
                        colors: [song.color, song.color.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: song.albumCoverUrl != null
                  ? Image.network(
                      song.albumCoverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [song.color, song.color.withValues(alpha: 0.6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(Icons.music_note, color: Colors.white, size: 30),
                        );
                      },
                    )
                  : Icon(Icons.music_note, color: Colors.white, size: 30),
            ),
            SizedBox(width: 12),
            // Song info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Play/Pause button
            IconButton(
              icon: Icon(
                _playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                debugPrint('Play/Pause button pressed');
                _playerService.togglePlayPause();
              },
            ),
            SizedBox(width: 8),
          ],
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildMaximizedPlayer() {
    final song = _playerService.currentSong!;
    
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            song.color.withValues(alpha: 0.8),
            Color(0xFF1A1A2E),
            Color(0xFF0F0F1E),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with minimize button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                      onPressed: () => _playerService.minimize(),
                    ),
                    Text(
                      'Now Playing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            // Album cover
            GlassWithGlow(
              borderRadius: BorderRadius.circular(16),
              glowColor: song.color,
              glowBlur: Glow.albumBlur,
              glowSpread: Glow.albumSpread,
              opacity: 0.1,
              glowAlpha: Glow.albumAlpha,
              child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: song.albumCoverUrl != null
                    ? Image.network(
                        song.albumCoverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [song.color, song.color.withValues(alpha: 0.6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(Icons.music_note, color: Colors.white, size: 60),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [song.color, song.color.withValues(alpha: 0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(Icons.music_note, color: Colors.white, size: 60),
                        ),
                      ),
              ),
              ),
            ),
            SizedBox(height: 24),
            // Song info
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    song.artist,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Progress bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _playerService.currentPosition.inSeconds.toDouble(),
                      max: _playerService.totalDuration.inSeconds.toDouble(),
                      onChanged: (value) {
                        _playerService.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_playerService.currentPosition),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        Text(
                          _formatDuration(_playerService.totalDuration),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Control buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.shuffle, color: Colors.grey[400]),
                    iconSize: 28,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_previous, color: Colors.white),
                    iconSize: 40,
                    onPressed: () {
                      debugPrint('Previous button pressed');
                      _playerService.playPrevious();
                    },
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: song.color,
                      ),
                      iconSize: 40,
                      onPressed: () {
                        debugPrint('Maximized play/pause pressed');
                        _playerService.togglePlayPause();
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, color: Colors.white),
                    iconSize: 40,
                    onPressed: () {
                      debugPrint('Next button pressed');
                      _playerService.playNext();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.repeat, color: Colors.grey[400]),
                    iconSize: 28,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
