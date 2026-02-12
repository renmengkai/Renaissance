// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'letter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GoldenLetter _$GoldenLetterFromJson(Map<String, dynamic> json) {
  return _GoldenLetter.fromJson(json);
}

/// @nodoc
mixin _$GoldenLetter {
  String get id => throw _privateConstructorUsedError;
  String get songId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  String get authorName => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  int? get listenCount => throw _privateConstructorUsedError;
  String? get mood => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GoldenLetterCopyWith<GoldenLetter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoldenLetterCopyWith<$Res> {
  factory $GoldenLetterCopyWith(
          GoldenLetter value, $Res Function(GoldenLetter) then) =
      _$GoldenLetterCopyWithImpl<$Res, GoldenLetter>;
  @useResult
  $Res call(
      {String id,
      String songId,
      String content,
      String authorName,
      DateTime createdAt,
      String? location,
      int? listenCount,
      String? mood});
}

/// @nodoc
class _$GoldenLetterCopyWithImpl<$Res, $Val extends GoldenLetter>
    implements $GoldenLetterCopyWith<$Res> {
  _$GoldenLetterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? songId = null,
    Object? content = null,
    Object? authorName = null,
    Object? createdAt = null,
    Object? location = freezed,
    Object? listenCount = freezed,
    Object? mood = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      songId: null == songId
          ? _value.songId
          : songId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      authorName: null == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      listenCount: freezed == listenCount
          ? _value.listenCount
          : listenCount // ignore: cast_nullable_to_non_nullable
              as int?,
      mood: freezed == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoldenLetterImplCopyWith<$Res>
    implements $GoldenLetterCopyWith<$Res> {
  factory _$$GoldenLetterImplCopyWith(
          _$GoldenLetterImpl value, $Res Function(_$GoldenLetterImpl) then) =
      __$$GoldenLetterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String songId,
      String content,
      String authorName,
      DateTime createdAt,
      String? location,
      int? listenCount,
      String? mood});
}

/// @nodoc
class __$$GoldenLetterImplCopyWithImpl<$Res>
    extends _$GoldenLetterCopyWithImpl<$Res, _$GoldenLetterImpl>
    implements _$$GoldenLetterImplCopyWith<$Res> {
  __$$GoldenLetterImplCopyWithImpl(
      _$GoldenLetterImpl _value, $Res Function(_$GoldenLetterImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? songId = null,
    Object? content = null,
    Object? authorName = null,
    Object? createdAt = null,
    Object? location = freezed,
    Object? listenCount = freezed,
    Object? mood = freezed,
  }) {
    return _then(_$GoldenLetterImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      songId: null == songId
          ? _value.songId
          : songId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      authorName: null == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      listenCount: freezed == listenCount
          ? _value.listenCount
          : listenCount // ignore: cast_nullable_to_non_nullable
              as int?,
      mood: freezed == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GoldenLetterImpl implements _GoldenLetter {
  const _$GoldenLetterImpl(
      {required this.id,
      required this.songId,
      required this.content,
      required this.authorName,
      required this.createdAt,
      this.location,
      this.listenCount,
      this.mood});

  factory _$GoldenLetterImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoldenLetterImplFromJson(json);

  @override
  final String id;
  @override
  final String songId;
  @override
  final String content;
  @override
  final String authorName;
  @override
  final DateTime createdAt;
  @override
  final String? location;
  @override
  final int? listenCount;
  @override
  final String? mood;

  @override
  String toString() {
    return 'GoldenLetter(id: $id, songId: $songId, content: $content, authorName: $authorName, createdAt: $createdAt, location: $location, listenCount: $listenCount, mood: $mood)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoldenLetterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.songId, songId) || other.songId == songId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.listenCount, listenCount) ||
                other.listenCount == listenCount) &&
            (identical(other.mood, mood) || other.mood == mood));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, songId, content, authorName,
      createdAt, location, listenCount, mood);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoldenLetterImplCopyWith<_$GoldenLetterImpl> get copyWith =>
      __$$GoldenLetterImplCopyWithImpl<_$GoldenLetterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoldenLetterImplToJson(
      this,
    );
  }
}

abstract class _GoldenLetter implements GoldenLetter {
  const factory _GoldenLetter(
      {required final String id,
      required final String songId,
      required final String content,
      required final String authorName,
      required final DateTime createdAt,
      final String? location,
      final int? listenCount,
      final String? mood}) = _$GoldenLetterImpl;

  factory _GoldenLetter.fromJson(Map<String, dynamic> json) =
      _$GoldenLetterImpl.fromJson;

  @override
  String get id;
  @override
  String get songId;
  @override
  String get content;
  @override
  String get authorName;
  @override
  DateTime get createdAt;
  @override
  String? get location;
  @override
  int? get listenCount;
  @override
  String? get mood;
  @override
  @JsonKey(ignore: true)
  _$$GoldenLetterImplCopyWith<_$GoldenLetterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
