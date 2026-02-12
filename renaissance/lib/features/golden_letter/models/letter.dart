import 'package:freezed_annotation/freezed_annotation.dart';

part 'letter.freezed.dart';
part 'letter.g.dart';

@freezed
class GoldenLetter with _$GoldenLetter {
  const factory GoldenLetter({
    required String id,
    required String songId,
    required String content,
    required String authorName,
    required DateTime createdAt,
    String? location,
    int? listenCount,
    String? mood,
  }) = _GoldenLetter;

  factory GoldenLetter.fromJson(Map<String, dynamic> json) =>
      _$GoldenLetterFromJson(json);
}

// 示例信件数据
final Map<String, List<GoldenLetter>> sampleLetters = {
  '1': [
    GoldenLetter(
      id: 'l1',
      songId: '1',
      content: '那年夏天，我们在学校广播站听到了这首歌。'
          '你说，如果有一天我们分开了，就听这首歌来想念对方。'
          '没想到一语成谶。三年过去了，我 still 在听这首歌，'
          '只是身边再也没有你的身影。希望你过得好。',
      authorName: '匿名',
      createdAt: DateTime(2022, 6, 15),
      location: '上海',
      mood: '怀念',
    ),
    GoldenLetter(
      id: 'l2',
      songId: '1',
      content: '第一次听这首歌是在妈妈的旧磁带里。'
          '那时候不懂歌词的意思，只觉得旋律很好听。'
          '现在每次听到都会想起妈妈年轻时的样子。'
          '时光啊，请你慢些走。',
      authorName: '小雨',
      createdAt: DateTime(2023, 1, 20),
      location: '成都',
      mood: '温暖',
    ),
  ],
  '2': [
    GoldenLetter(
      id: 'l3',
      songId: '2',
      content: '红豆生南国，春来发几枝。'
          '愿君多采撷，此物最相思。'
          '每次听到这首歌，都会想起这首诗。'
          '思念是一种很玄的东西，如影随形。',
      authorName: '诗人',
      createdAt: DateTime(2021, 11, 11),
      location: '北京',
      mood: '诗意',
    ),
  ],
};
