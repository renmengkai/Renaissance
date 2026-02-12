import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/letter.dart';

// 信件仓库
class LetterRepository {
  final Random _random = Random();

  // 根据歌曲ID获取信件
  Future<GoldenLetter?> getLetterForSong(String songId) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    final letters = sampleLetters[songId];
    if (letters == null || letters.isEmpty) {
      return null;
    }

    // 随机选择一封信件
    return letters[_random.nextInt(letters.length)];
  }

  // 检查歌曲是否有信件
  Future<bool> hasLetter(String songId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final letters = sampleLetters[songId];
    return letters != null && letters.isNotEmpty;
  }

  // 保存新信件
  Future<void> saveLetter(GoldenLetter letter) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 在实际应用中，这里会将信件保存到数据库
    // 现在只是模拟
    final letters = sampleLetters[letter.songId] ?? [];
    letters.add(letter);
    sampleLetters[letter.songId] = letters;
  }
}

// Provider
final letterRepositoryProvider = Provider<LetterRepository>((ref) {
  return LetterRepository();
});

// 当前信件状态
class LetterState {
  final GoldenLetter? letter;
  final bool isLoading;
  final bool isRevealed;
  final bool hasError;

  const LetterState({
    this.letter,
    this.isLoading = false,
    this.isRevealed = false,
    this.hasError = false,
  });

  LetterState copyWith({
    GoldenLetter? letter,
    bool? isLoading,
    bool? isRevealed,
    bool? hasError,
  }) {
    return LetterState(
      letter: letter ?? this.letter,
      isLoading: isLoading ?? this.isLoading,
      isRevealed: isRevealed ?? this.isRevealed,
      hasError: hasError ?? this.hasError,
    );
  }
}

// 信件控制器
class LetterController extends StateNotifier<LetterState> {
  final LetterRepository _repository;

  LetterController(this._repository) : super(const LetterState());

  Future<void> checkForLetter(String songId) async {
    state = state.copyWith(isLoading: true, hasError: false);

    try {
      final letter = await _repository.getLetterForSong(songId);
      state = state.copyWith(
        letter: letter,
        isLoading: false,
        isRevealed: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  void revealLetter() {
    if (state.letter != null) {
      state = state.copyWith(isRevealed: true);
    }
  }

  void closeLetter() {
    state = state.copyWith(isRevealed: false);
  }

  void reset() {
    state = const LetterState();
  }

  Future<void> writeLetter(String songId, String content, String authorName) async {
    final newLetter = GoldenLetter(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      songId: songId,
      content: content,
      authorName: authorName,
      createdAt: DateTime.now(),
    );

    await _repository.saveLetter(newLetter);
  }
}

// Provider
final letterControllerProvider = StateNotifierProvider<LetterController, LetterState>((ref) {
  final repository = ref.watch(letterRepositoryProvider);
  return LetterController(repository);
});
