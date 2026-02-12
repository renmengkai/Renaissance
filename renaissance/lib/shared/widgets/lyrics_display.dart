import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

// 歌词行数据
class LyricLine {
  final Duration time;
  final String text;
  final String? translation;

  const LyricLine({
    required this.time,
    required this.text,
    this.translation,
  });
}

// 示例歌词数据
final List<LyricLine> sampleLyrics = [
  LyricLine(time: Duration(seconds: 0), text: ''), // 前奏
  LyricLine(time: Duration(seconds: 15), text: '在很久很久以前'),
  LyricLine(time: Duration(seconds: 20), text: '你拥有我'),
  LyricLine(time: Duration(seconds: 25), text: '我拥有你'),
  LyricLine(time: Duration(seconds: 30), text: '在很久很久以前'),
  LyricLine(time: Duration(seconds: 35), text: '你离开我'),
  LyricLine(time: Duration(seconds: 40), text: '去远空翱翔'),
  LyricLine(time: Duration(seconds: 45), text: '外面的世界很精彩'),
  LyricLine(time: Duration(seconds: 50), text: '外面的世界很无奈'),
  LyricLine(time: Duration(seconds: 55), text: '当你觉得外面的世界很精彩'),
  LyricLine(time: Duration(seconds: 60), text: '我会在这里衷心的祝福你'),
  LyricLine(time: Duration(seconds: 65), text: '每当夕阳西沉的时候'),
  LyricLine(time: Duration(seconds: 70), text: '我总是在这里盼望你'),
  LyricLine(time: Duration(seconds: 75), text: '天空中虽然飘着雨'),
  LyricLine(time: Duration(seconds: 80), text: '我依然等待你的归期'),
];

// 歌词显示组件
class LyricsDisplay extends ConsumerStatefulWidget {
  final List<LyricLine> lyrics;
  final Duration currentPosition;
  final bool isPlaying;
  final VoidCallback? onTap;

  const LyricsDisplay({
    super.key,
    required this.lyrics,
    required this.currentPosition,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  ConsumerState<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends ConsumerState<LyricsDisplay> {
  final ScrollController _scrollController = ScrollController();
  int _currentLineIndex = 0;

  @override
  void didUpdateWidget(LyricsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition) {
      _updateCurrentLine();
    }
  }

  void _updateCurrentLine() {
    final newIndex = _findCurrentLineIndex();
    if (newIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newIndex;
      });
      _scrollToCurrentLine();
    }
  }

  int _findCurrentLineIndex() {
    for (int i = widget.lyrics.length - 1; i >= 0; i--) {
      if (widget.currentPosition >= widget.lyrics[i].time) {
        return i;
      }
    }
    return 0;
  }

  void _scrollToCurrentLine() {
    if (_scrollController.hasClients) {
      final itemHeight = 56.0;
      final targetOffset = _currentLineIndex * itemHeight - 120;
      _scrollController.animateTo(
        targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppTheme.softBlack.withOpacity(0.8),
              AppTheme.softBlack.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.15, 0.85, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 120),
            itemCount: widget.lyrics.length,
            itemBuilder: (context, index) {
              final line = widget.lyrics[index];
              final isCurrent = index == _currentLineIndex;
              final isPast = index < _currentLineIndex;

              return _LyricLineItem(
                line: line,
                isCurrent: isCurrent,
                isPast: isPast,
                onTap: () {
                  // 可以添加点击跳转到对应时间的功能
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LyricLineItem extends StatelessWidget {
  final LyricLine line;
  final bool isCurrent;
  final bool isPast;
  final VoidCallback? onTap;

  const _LyricLineItem({
    required this.line,
    required this.isCurrent,
    required this.isPast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            Text(
              line.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isCurrent
                    ? AppTheme.vintageGold
                    : isPast
                        ? AppTheme.warmBeige.withOpacity(0.4)
                        : AppTheme.warmBeige.withOpacity(0.6),
                fontSize: isCurrent ? 20 : 16,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                height: 1.5,
                shadows: isCurrent
                    ? [
                        Shadow(
                          color: AppTheme.vintageGold.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
            if (line.translation != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  line.translation!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCurrent
                        ? AppTheme.warmBeige.withOpacity(0.7)
                        : AppTheme.warmBeige.withOpacity(0.4),
                    fontSize: isCurrent ? 14 : 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 迷你歌词显示（用于播放器底部）
class MiniLyricsDisplay extends StatelessWidget {
  final List<LyricLine> lyrics;
  final Duration currentPosition;

  const MiniLyricsDisplay({
    super.key,
    required this.lyrics,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    final currentLine = _getCurrentLine();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: currentLine != null
          ? Container(
              key: ValueKey(currentLine.text),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                currentLine.text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.warmBeige.withOpacity(0.8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  LyricLine? _getCurrentLine() {
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (currentPosition >= lyrics[i].time) {
        return lyrics[i];
      }
    }
    return null;
  }
}

// 歌词解析器
class LyricsParser {
  static List<LyricLine> parse(String lrcContent) {
    final lines = <LyricLine>[];
    final lineRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lrcContent.split('\n')) {
      final match = lineRegex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!);
        final text = match.group(4)!.trim();

        final time = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds < 100 ? milliseconds * 10 : milliseconds,
        );

        lines.add(LyricLine(time: time, text: text));
      }
    }

    return lines..sort((a, b) => a.time.compareTo(b.time));
  }
}
