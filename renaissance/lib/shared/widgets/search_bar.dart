import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../features/player/models/song.dart';

// 搜索状态
class SearchState {
  final String query;
  final List<Song> results;
  final bool isSearching;
  final List<String> searchHistory;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.searchHistory = const [],
  });

  SearchState copyWith({
    String? query,
    List<Song>? results,
    bool? isSearching,
    List<String>? searchHistory,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }
}

// 搜索控制器
class SearchController extends StateNotifier<SearchState> {
  SearchController() : super(const SearchState());

  void search(String query, List<Song> allSongs) {
    if (query.isEmpty) {
      state = state.copyWith(
        query: '',
        results: [],
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(
      query: query,
      isSearching: true,
    );

    // 模拟搜索延迟
    Future.delayed(const Duration(milliseconds: 300), () {
      final lowerQuery = query.toLowerCase();
      final results = allSongs.where((song) {
        return song.title.toLowerCase().contains(lowerQuery) ||
            song.artist.toLowerCase().contains(lowerQuery) ||
            song.album.toLowerCase().contains(lowerQuery) ||
            song.year.toString().contains(lowerQuery);
      }).toList();

      state = state.copyWith(
        results: results,
        isSearching: false,
      );

      // 添加到搜索历史
      if (query.isNotEmpty && !state.searchHistory.contains(query)) {
        addToHistory(query);
      }
    });
  }

  void addToHistory(String query) {
    final newHistory = [
      query,
      ...state.searchHistory.where((h) => h != query),
    ].take(10).toList();

    state = state.copyWith(searchHistory: newHistory);
  }

  void removeFromHistory(String query) {
    state = state.copyWith(
      searchHistory: state.searchHistory.where((h) => h != query).toList(),
    );
  }

  void clearHistory() {
    state = state.copyWith(searchHistory: []);
  }

  void clear() {
    state = state.copyWith(
      query: '',
      results: [],
      isSearching: false,
    );
  }
}

// Provider
final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController();
});

// 搜索栏组件
class AppSearchBar extends ConsumerStatefulWidget {
  final List<Song> allSongs;
  final Function(Song)? onSongSelected;
  final VoidCallback? onClose;

  const AppSearchBar({
    super.key,
    required this.allSongs,
    this.onSongSelected,
    this.onClose,
  });

  @override
  ConsumerState<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends ConsumerState<AppSearchBar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);

    return Container(
      width: 500,
      decoration: BoxDecoration(
        color: AppTheme.acrylicDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warmBrown.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 搜索输入框
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  FluentIcons.search,
                  color: AppTheme.vintageGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextBox(
                    controller: _textController,
                    focusNode: _focusNode,
                    placeholder: '搜索歌曲、艺术家、专辑...',
                    style: const TextStyle(
                      color: AppTheme.warmCream,
                      fontSize: 14,
                    ),
                    onChanged: (value) {
                      ref
                          .read(searchControllerProvider.notifier)
                          .search(value, widget.allSongs);
                    },
                  ),
                ),
                if (searchState.query.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      FluentIcons.chrome_close,
                      color: AppTheme.warmBeige.withOpacity(0.6),
                      size: 16,
                    ),
                    onPressed: () {
                      _textController.clear();
                      ref.read(searchControllerProvider.notifier).clear();
                    },
                  ),
                IconButton(
                  icon: Icon(
                    FluentIcons.cancel,
                    color: AppTheme.warmBeige.withOpacity(0.6),
                    size: 16,
                  ),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // 搜索结果
          if (searchState.isSearching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: ProgressRing(),
            )
          else if (searchState.results.isNotEmpty)
            _buildResultsList(searchState.results)
          else if (searchState.query.isNotEmpty)
            _buildNoResults()
          else if (searchState.searchHistory.isNotEmpty)
            _buildSearchHistory(searchState.searchHistory),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 200.ms,
        );
  }

  Widget _buildResultsList(List<Song> results) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (context, index) {
          final song = results[index];
          return _SearchResultItem(
            song: song,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onSongSelected?.call(song);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            FluentIcons.search,
            size: 48,
            color: AppTheme.warmBrown.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '未找到相关歌曲',
            style: TextStyle(
              color: AppTheme.warmBeige.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory(List<String> history) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '搜索历史',
                style: TextStyle(
                  color: AppTheme.warmBeige.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(searchControllerProvider.notifier).clearHistory();
                },
                child: Text(
                  '清除',
                  style: TextStyle(
                    color: AppTheme.vintageGold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history.map((query) {
              return _HistoryChip(
                query: query,
                onTap: () {
                  _textController.text = query;
                  ref
                      .read(searchControllerProvider.notifier)
                      .search(query, widget.allSongs);
                },
                onDelete: () {
                  ref
                      .read(searchControllerProvider.notifier)
                      .removeFromHistory(query);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.warmBrown.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppTheme.warmBrown.withOpacity(0.2),
              ),
              child: const Icon(
                FluentIcons.music_note,
                color: AppTheme.vintageGold,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: AppTheme.warmCream,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${song.artist} · ${song.album}',
                    style: TextStyle(
                      color: AppTheme.warmBeige.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '${song.year}',
              style: TextStyle(
                color: AppTheme.warmBrown.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryChip({
    required this.query,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.warmBrown.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.warmBrown.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.history,
              size: 12,
              color: AppTheme.warmBeige.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Text(
              query,
              style: TextStyle(
                color: AppTheme.warmBeige.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                FluentIcons.chrome_close,
                size: 12,
                color: AppTheme.warmBeige.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
