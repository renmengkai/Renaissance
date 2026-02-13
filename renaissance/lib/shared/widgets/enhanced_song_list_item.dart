import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../features/player/models/song.dart';

class EnhancedSongListItem extends StatefulWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final String? coverPath;
  final int index;

  const EnhancedSongListItem({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    this.coverPath,
    this.index = 0,
  });

  @override
  State<EnhancedSongListItem> createState() => _EnhancedSongListItemState();
}

class _EnhancedSongListItemState extends State<EnhancedSongListItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isPlaying) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EnhancedSongListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.isPlaying
                ? AppTheme.vintageGold.withOpacity(0.12)
                : _isHovered
                    ? AppTheme.warmBrown.withOpacity(0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isPlaying
                  ? AppTheme.vintageGold.withOpacity(0.4)
                  : _isHovered
                      ? AppTheme.warmBrown.withOpacity(0.3)
                      : Colors.transparent,
              width: 1,
            ),
            boxShadow: widget.isPlaying
                ? [
                    BoxShadow(
                      color: AppTheme.vintageGold.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _buildCoverThumbnail(),
              const SizedBox(width: 12),
              Expanded(child: _buildSongInfo()),
              _buildTrailingIcons(),
            ],
          ),
        ),
      ),
    )
        .animate(target: _isPressed ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0.98, 0.98),
          duration: 100.ms,
        );
  }

  Widget _buildCoverThumbnail() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isHovered ? 52 : 48,
      height: _isHovered ? 52 : 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.warmBrown.withOpacity(0.3),
        boxShadow: widget.isPlaying
            ? [
                BoxShadow(
                  color: AppTheme.vintageGold.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildCoverImage(),
          ),
          if (widget.isPlaying)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: _buildPlayingIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    if (widget.coverPath != null && widget.coverPath!.isNotEmpty) {
      final path = widget.coverPath!;
      if (path.startsWith('http')) {
        return Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultCover(),
        );
      } else if (File(path).existsSync()) {
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultCover(),
        );
      }
    }
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warmBrown.withOpacity(0.5),
            AppTheme.deepBrown.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          FluentIcons.music_note,
          size: 20,
          color: AppTheme.warmBeige.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildPlayingIndicator() {
    return Semantics(
      container: false,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final value = ((_glowController.value + delay) % 1.0);
              final height = 8 + value * 12;

              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.vintageGold,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildSongInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.song.title,
          style: TextStyle(
            color: widget.isPlaying ? AppTheme.vintageGold : AppTheme.warmCream,
            fontSize: 14,
            fontWeight: widget.isPlaying ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.song.artist,
                style: TextStyle(
                  color: AppTheme.warmBeige.withOpacity(
                    widget.isPlaying ? 0.8 : 0.6,
                  ),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.warmBeige.withOpacity(0.4),
              ),
            ),
            Text(
              '${widget.song.year}',
              style: TextStyle(
                color: AppTheme.warmBrown.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrailingIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.song.hasGoldenLetter)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: '有黄金信件',
              child: Icon(
                FluentIcons.mail,
                color: AppTheme.vintageGold.withOpacity(
                  widget.isPlaying ? 0.9 : 0.5,
                ),
                size: 16,
              ),
            ),
          ),
        if (_isHovered && !widget.isPlaying)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              FluentIcons.play,
              color: AppTheme.warmBeige.withOpacity(0.6),
              size: 16,
            ),
          ).animate().fadeIn(duration: 150.ms),
      ],
    );
  }
}

class SongListHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;

  const SongListHeader({
    super.key,
    required this.title,
    required this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.vintageGold,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.warmCream,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.warmBrown.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: AppTheme.warmBeige,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SongListGroup extends StatelessWidget {
  final String groupName;
  final List<Song> songs;
  final String? Function(Song) currentSongId;
  final void Function(Song) onSongTap;
  final String? Function(Song)? getCoverPath;

  const SongListGroup({
    super.key,
    required this.groupName,
    required this.songs,
    required this.currentSongId,
    required this.onSongTap,
    this.getCoverPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.vintageGold,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                groupName,
                style: TextStyle(
                  color: AppTheme.warmBeige,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${songs.length}',
                style: TextStyle(
                  color: AppTheme.warmBrown,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        ...songs.asMap().entries.map((entry) {
          final song = entry.value;
          final isPlaying = currentSongId(song) == song.id;

          return EnhancedSongListItem(
            song: song,
            isPlaying: isPlaying,
            onTap: () => onSongTap(song),
            coverPath: getCoverPath?.call(song),
            index: entry.key,
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}
