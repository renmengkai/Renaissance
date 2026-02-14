// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MusicSource _$MusicSourceFromJson(Map<String, dynamic> json) {
  return _MusicSource.fromJson(json);
}

/// @nodoc
mixin _$MusicSource {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  MusicSourceType get type => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;
  CloudProvider? get cloudProvider => throw _privateConstructorUsedError;
  WebDAVProvider? get webdavProvider => throw _privateConstructorUsedError;
  String? get baseUrl => throw _privateConstructorUsedError;
  String? get customDomain => throw _privateConstructorUsedError;
  String? get bucketName => throw _privateConstructorUsedError;
  String? get accessKey => throw _privateConstructorUsedError;
  String? get secretKey => throw _privateConstructorUsedError;
  String? get region => throw _privateConstructorUsedError;
  String? get customHeaders => throw _privateConstructorUsedError;
  String? get webdavPath => throw _privateConstructorUsedError;
  DateTime? get lastSyncTime => throw _privateConstructorUsedError;
  int get songCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MusicSourceCopyWith<MusicSource> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MusicSourceCopyWith<$Res> {
  factory $MusicSourceCopyWith(
          MusicSource value, $Res Function(MusicSource) then) =
      _$MusicSourceCopyWithImpl<$Res, MusicSource>;
  @useResult
  $Res call(
      {String id,
      String name,
      MusicSourceType type,
      bool isEnabled,
      CloudProvider? cloudProvider,
      WebDAVProvider? webdavProvider,
      String? baseUrl,
      String? customDomain,
      String? bucketName,
      String? accessKey,
      String? secretKey,
      String? region,
      String? customHeaders,
      String? webdavPath,
      DateTime? lastSyncTime,
      int songCount});
}

/// @nodoc
class _$MusicSourceCopyWithImpl<$Res, $Val extends MusicSource>
    implements $MusicSourceCopyWith<$Res> {
  _$MusicSourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? isEnabled = null,
    Object? cloudProvider = freezed,
    Object? webdavProvider = freezed,
    Object? baseUrl = freezed,
    Object? customDomain = freezed,
    Object? bucketName = freezed,
    Object? accessKey = freezed,
    Object? secretKey = freezed,
    Object? region = freezed,
    Object? customHeaders = freezed,
    Object? webdavPath = freezed,
    Object? lastSyncTime = freezed,
    Object? songCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MusicSourceType,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      cloudProvider: freezed == cloudProvider
          ? _value.cloudProvider
          : cloudProvider // ignore: cast_nullable_to_non_nullable
              as CloudProvider?,
      webdavProvider: freezed == webdavProvider
          ? _value.webdavProvider
          : webdavProvider // ignore: cast_nullable_to_non_nullable
              as WebDAVProvider?,
      baseUrl: freezed == baseUrl
          ? _value.baseUrl
          : baseUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      customDomain: freezed == customDomain
          ? _value.customDomain
          : customDomain // ignore: cast_nullable_to_non_nullable
              as String?,
      bucketName: freezed == bucketName
          ? _value.bucketName
          : bucketName // ignore: cast_nullable_to_non_nullable
              as String?,
      accessKey: freezed == accessKey
          ? _value.accessKey
          : accessKey // ignore: cast_nullable_to_non_nullable
              as String?,
      secretKey: freezed == secretKey
          ? _value.secretKey
          : secretKey // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      customHeaders: freezed == customHeaders
          ? _value.customHeaders
          : customHeaders // ignore: cast_nullable_to_non_nullable
              as String?,
      webdavPath: freezed == webdavPath
          ? _value.webdavPath
          : webdavPath // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSyncTime: freezed == lastSyncTime
          ? _value.lastSyncTime
          : lastSyncTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      songCount: null == songCount
          ? _value.songCount
          : songCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MusicSourceImplCopyWith<$Res>
    implements $MusicSourceCopyWith<$Res> {
  factory _$$MusicSourceImplCopyWith(
          _$MusicSourceImpl value, $Res Function(_$MusicSourceImpl) then) =
      __$$MusicSourceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      MusicSourceType type,
      bool isEnabled,
      CloudProvider? cloudProvider,
      WebDAVProvider? webdavProvider,
      String? baseUrl,
      String? customDomain,
      String? bucketName,
      String? accessKey,
      String? secretKey,
      String? region,
      String? customHeaders,
      String? webdavPath,
      DateTime? lastSyncTime,
      int songCount});
}

/// @nodoc
class __$$MusicSourceImplCopyWithImpl<$Res>
    extends _$MusicSourceCopyWithImpl<$Res, _$MusicSourceImpl>
    implements _$$MusicSourceImplCopyWith<$Res> {
  __$$MusicSourceImplCopyWithImpl(
      _$MusicSourceImpl _value, $Res Function(_$MusicSourceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? isEnabled = null,
    Object? cloudProvider = freezed,
    Object? webdavProvider = freezed,
    Object? baseUrl = freezed,
    Object? customDomain = freezed,
    Object? bucketName = freezed,
    Object? accessKey = freezed,
    Object? secretKey = freezed,
    Object? region = freezed,
    Object? customHeaders = freezed,
    Object? webdavPath = freezed,
    Object? lastSyncTime = freezed,
    Object? songCount = null,
  }) {
    return _then(_$MusicSourceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MusicSourceType,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      cloudProvider: freezed == cloudProvider
          ? _value.cloudProvider
          : cloudProvider // ignore: cast_nullable_to_non_nullable
              as CloudProvider?,
      webdavProvider: freezed == webdavProvider
          ? _value.webdavProvider
          : webdavProvider // ignore: cast_nullable_to_non_nullable
              as WebDAVProvider?,
      baseUrl: freezed == baseUrl
          ? _value.baseUrl
          : baseUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      customDomain: freezed == customDomain
          ? _value.customDomain
          : customDomain // ignore: cast_nullable_to_non_nullable
              as String?,
      bucketName: freezed == bucketName
          ? _value.bucketName
          : bucketName // ignore: cast_nullable_to_non_nullable
              as String?,
      accessKey: freezed == accessKey
          ? _value.accessKey
          : accessKey // ignore: cast_nullable_to_non_nullable
              as String?,
      secretKey: freezed == secretKey
          ? _value.secretKey
          : secretKey // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      customHeaders: freezed == customHeaders
          ? _value.customHeaders
          : customHeaders // ignore: cast_nullable_to_non_nullable
              as String?,
      webdavPath: freezed == webdavPath
          ? _value.webdavPath
          : webdavPath // ignore: cast_nullable_to_non_nullable
              as String?,
      lastSyncTime: freezed == lastSyncTime
          ? _value.lastSyncTime
          : lastSyncTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      songCount: null == songCount
          ? _value.songCount
          : songCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MusicSourceImpl implements _MusicSource {
  const _$MusicSourceImpl(
      {required this.id,
      required this.name,
      required this.type,
      required this.isEnabled,
      this.cloudProvider,
      this.webdavProvider,
      this.baseUrl,
      this.customDomain,
      this.bucketName,
      this.accessKey,
      this.secretKey,
      this.region,
      this.customHeaders,
      this.webdavPath,
      this.lastSyncTime,
      this.songCount = 0});

  factory _$MusicSourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$MusicSourceImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final MusicSourceType type;
  @override
  final bool isEnabled;
  @override
  final CloudProvider? cloudProvider;
  @override
  final WebDAVProvider? webdavProvider;
  @override
  final String? baseUrl;
  @override
  final String? customDomain;
  @override
  final String? bucketName;
  @override
  final String? accessKey;
  @override
  final String? secretKey;
  @override
  final String? region;
  @override
  final String? customHeaders;
  @override
  final String? webdavPath;
  @override
  final DateTime? lastSyncTime;
  @override
  @JsonKey()
  final int songCount;

  @override
  String toString() {
    return 'MusicSource(id: $id, name: $name, type: $type, isEnabled: $isEnabled, cloudProvider: $cloudProvider, webdavProvider: $webdavProvider, baseUrl: $baseUrl, customDomain: $customDomain, bucketName: $bucketName, accessKey: $accessKey, secretKey: $secretKey, region: $region, customHeaders: $customHeaders, webdavPath: $webdavPath, lastSyncTime: $lastSyncTime, songCount: $songCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MusicSourceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.cloudProvider, cloudProvider) ||
                other.cloudProvider == cloudProvider) &&
            (identical(other.webdavProvider, webdavProvider) ||
                other.webdavProvider == webdavProvider) &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl) &&
            (identical(other.customDomain, customDomain) ||
                other.customDomain == customDomain) &&
            (identical(other.bucketName, bucketName) ||
                other.bucketName == bucketName) &&
            (identical(other.accessKey, accessKey) ||
                other.accessKey == accessKey) &&
            (identical(other.secretKey, secretKey) ||
                other.secretKey == secretKey) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.customHeaders, customHeaders) ||
                other.customHeaders == customHeaders) &&
            (identical(other.webdavPath, webdavPath) ||
                other.webdavPath == webdavPath) &&
            (identical(other.lastSyncTime, lastSyncTime) ||
                other.lastSyncTime == lastSyncTime) &&
            (identical(other.songCount, songCount) ||
                other.songCount == songCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      isEnabled,
      cloudProvider,
      webdavProvider,
      baseUrl,
      customDomain,
      bucketName,
      accessKey,
      secretKey,
      region,
      customHeaders,
      webdavPath,
      lastSyncTime,
      songCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MusicSourceImplCopyWith<_$MusicSourceImpl> get copyWith =>
      __$$MusicSourceImplCopyWithImpl<_$MusicSourceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MusicSourceImplToJson(
      this,
    );
  }
}

abstract class _MusicSource implements MusicSource {
  const factory _MusicSource(
      {required final String id,
      required final String name,
      required final MusicSourceType type,
      required final bool isEnabled,
      final CloudProvider? cloudProvider,
      final WebDAVProvider? webdavProvider,
      final String? baseUrl,
      final String? customDomain,
      final String? bucketName,
      final String? accessKey,
      final String? secretKey,
      final String? region,
      final String? customHeaders,
      final String? webdavPath,
      final DateTime? lastSyncTime,
      final int songCount}) = _$MusicSourceImpl;

  factory _MusicSource.fromJson(Map<String, dynamic> json) =
      _$MusicSourceImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  MusicSourceType get type;
  @override
  bool get isEnabled;
  @override
  CloudProvider? get cloudProvider;
  @override
  WebDAVProvider? get webdavProvider;
  @override
  String? get baseUrl;
  @override
  String? get customDomain;
  @override
  String? get bucketName;
  @override
  String? get accessKey;
  @override
  String? get secretKey;
  @override
  String? get region;
  @override
  String? get customHeaders;
  @override
  String? get webdavPath;
  @override
  DateTime? get lastSyncTime;
  @override
  int get songCount;
  @override
  @JsonKey(ignore: true)
  _$$MusicSourceImplCopyWith<_$MusicSourceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CloudMusicConfig _$CloudMusicConfigFromJson(Map<String, dynamic> json) {
  return _CloudMusicConfig.fromJson(json);
}

/// @nodoc
mixin _$CloudMusicConfig {
  CloudProvider get provider => throw _privateConstructorUsedError;
  String get baseUrl => throw _privateConstructorUsedError;
  String? get customDomain => throw _privateConstructorUsedError;
  String? get bucketName => throw _privateConstructorUsedError;
  String? get accessKey => throw _privateConstructorUsedError;
  String? get secretKey => throw _privateConstructorUsedError;
  String? get region => throw _privateConstructorUsedError;
  Map<String, String>? get customHeaders => throw _privateConstructorUsedError;
  bool get useHttps => throw _privateConstructorUsedError;
  bool get enableCache => throw _privateConstructorUsedError;
  int get cacheExpireDays => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CloudMusicConfigCopyWith<CloudMusicConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CloudMusicConfigCopyWith<$Res> {
  factory $CloudMusicConfigCopyWith(
          CloudMusicConfig value, $Res Function(CloudMusicConfig) then) =
      _$CloudMusicConfigCopyWithImpl<$Res, CloudMusicConfig>;
  @useResult
  $Res call(
      {CloudProvider provider,
      String baseUrl,
      String? customDomain,
      String? bucketName,
      String? accessKey,
      String? secretKey,
      String? region,
      Map<String, String>? customHeaders,
      bool useHttps,
      bool enableCache,
      int cacheExpireDays});
}

/// @nodoc
class _$CloudMusicConfigCopyWithImpl<$Res, $Val extends CloudMusicConfig>
    implements $CloudMusicConfigCopyWith<$Res> {
  _$CloudMusicConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? provider = null,
    Object? baseUrl = null,
    Object? customDomain = freezed,
    Object? bucketName = freezed,
    Object? accessKey = freezed,
    Object? secretKey = freezed,
    Object? region = freezed,
    Object? customHeaders = freezed,
    Object? useHttps = null,
    Object? enableCache = null,
    Object? cacheExpireDays = null,
  }) {
    return _then(_value.copyWith(
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as CloudProvider,
      baseUrl: null == baseUrl
          ? _value.baseUrl
          : baseUrl // ignore: cast_nullable_to_non_nullable
              as String,
      customDomain: freezed == customDomain
          ? _value.customDomain
          : customDomain // ignore: cast_nullable_to_non_nullable
              as String?,
      bucketName: freezed == bucketName
          ? _value.bucketName
          : bucketName // ignore: cast_nullable_to_non_nullable
              as String?,
      accessKey: freezed == accessKey
          ? _value.accessKey
          : accessKey // ignore: cast_nullable_to_non_nullable
              as String?,
      secretKey: freezed == secretKey
          ? _value.secretKey
          : secretKey // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      customHeaders: freezed == customHeaders
          ? _value.customHeaders
          : customHeaders // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      useHttps: null == useHttps
          ? _value.useHttps
          : useHttps // ignore: cast_nullable_to_non_nullable
              as bool,
      enableCache: null == enableCache
          ? _value.enableCache
          : enableCache // ignore: cast_nullable_to_non_nullable
              as bool,
      cacheExpireDays: null == cacheExpireDays
          ? _value.cacheExpireDays
          : cacheExpireDays // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CloudMusicConfigImplCopyWith<$Res>
    implements $CloudMusicConfigCopyWith<$Res> {
  factory _$$CloudMusicConfigImplCopyWith(_$CloudMusicConfigImpl value,
          $Res Function(_$CloudMusicConfigImpl) then) =
      __$$CloudMusicConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CloudProvider provider,
      String baseUrl,
      String? customDomain,
      String? bucketName,
      String? accessKey,
      String? secretKey,
      String? region,
      Map<String, String>? customHeaders,
      bool useHttps,
      bool enableCache,
      int cacheExpireDays});
}

/// @nodoc
class __$$CloudMusicConfigImplCopyWithImpl<$Res>
    extends _$CloudMusicConfigCopyWithImpl<$Res, _$CloudMusicConfigImpl>
    implements _$$CloudMusicConfigImplCopyWith<$Res> {
  __$$CloudMusicConfigImplCopyWithImpl(_$CloudMusicConfigImpl _value,
      $Res Function(_$CloudMusicConfigImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? provider = null,
    Object? baseUrl = null,
    Object? customDomain = freezed,
    Object? bucketName = freezed,
    Object? accessKey = freezed,
    Object? secretKey = freezed,
    Object? region = freezed,
    Object? customHeaders = freezed,
    Object? useHttps = null,
    Object? enableCache = null,
    Object? cacheExpireDays = null,
  }) {
    return _then(_$CloudMusicConfigImpl(
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as CloudProvider,
      baseUrl: null == baseUrl
          ? _value.baseUrl
          : baseUrl // ignore: cast_nullable_to_non_nullable
              as String,
      customDomain: freezed == customDomain
          ? _value.customDomain
          : customDomain // ignore: cast_nullable_to_non_nullable
              as String?,
      bucketName: freezed == bucketName
          ? _value.bucketName
          : bucketName // ignore: cast_nullable_to_non_nullable
              as String?,
      accessKey: freezed == accessKey
          ? _value.accessKey
          : accessKey // ignore: cast_nullable_to_non_nullable
              as String?,
      secretKey: freezed == secretKey
          ? _value.secretKey
          : secretKey // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      customHeaders: freezed == customHeaders
          ? _value._customHeaders
          : customHeaders // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      useHttps: null == useHttps
          ? _value.useHttps
          : useHttps // ignore: cast_nullable_to_non_nullable
              as bool,
      enableCache: null == enableCache
          ? _value.enableCache
          : enableCache // ignore: cast_nullable_to_non_nullable
              as bool,
      cacheExpireDays: null == cacheExpireDays
          ? _value.cacheExpireDays
          : cacheExpireDays // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CloudMusicConfigImpl implements _CloudMusicConfig {
  const _$CloudMusicConfigImpl(
      {required this.provider,
      required this.baseUrl,
      this.customDomain,
      this.bucketName,
      this.accessKey,
      this.secretKey,
      this.region,
      final Map<String, String>? customHeaders,
      this.useHttps = true,
      this.enableCache = false,
      this.cacheExpireDays = 30})
      : _customHeaders = customHeaders;

  factory _$CloudMusicConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$CloudMusicConfigImplFromJson(json);

  @override
  final CloudProvider provider;
  @override
  final String baseUrl;
  @override
  final String? customDomain;
  @override
  final String? bucketName;
  @override
  final String? accessKey;
  @override
  final String? secretKey;
  @override
  final String? region;
  final Map<String, String>? _customHeaders;
  @override
  Map<String, String>? get customHeaders {
    final value = _customHeaders;
    if (value == null) return null;
    if (_customHeaders is EqualUnmodifiableMapView) return _customHeaders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final bool useHttps;
  @override
  @JsonKey()
  final bool enableCache;
  @override
  @JsonKey()
  final int cacheExpireDays;

  @override
  String toString() {
    return 'CloudMusicConfig(provider: $provider, baseUrl: $baseUrl, customDomain: $customDomain, bucketName: $bucketName, accessKey: $accessKey, secretKey: $secretKey, region: $region, customHeaders: $customHeaders, useHttps: $useHttps, enableCache: $enableCache, cacheExpireDays: $cacheExpireDays)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CloudMusicConfigImpl &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl) &&
            (identical(other.customDomain, customDomain) ||
                other.customDomain == customDomain) &&
            (identical(other.bucketName, bucketName) ||
                other.bucketName == bucketName) &&
            (identical(other.accessKey, accessKey) ||
                other.accessKey == accessKey) &&
            (identical(other.secretKey, secretKey) ||
                other.secretKey == secretKey) &&
            (identical(other.region, region) || other.region == region) &&
            const DeepCollectionEquality()
                .equals(other._customHeaders, _customHeaders) &&
            (identical(other.useHttps, useHttps) ||
                other.useHttps == useHttps) &&
            (identical(other.enableCache, enableCache) ||
                other.enableCache == enableCache) &&
            (identical(other.cacheExpireDays, cacheExpireDays) ||
                other.cacheExpireDays == cacheExpireDays));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      provider,
      baseUrl,
      customDomain,
      bucketName,
      accessKey,
      secretKey,
      region,
      const DeepCollectionEquality().hash(_customHeaders),
      useHttps,
      enableCache,
      cacheExpireDays);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CloudMusicConfigImplCopyWith<_$CloudMusicConfigImpl> get copyWith =>
      __$$CloudMusicConfigImplCopyWithImpl<_$CloudMusicConfigImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CloudMusicConfigImplToJson(
      this,
    );
  }
}

abstract class _CloudMusicConfig implements CloudMusicConfig {
  const factory _CloudMusicConfig(
      {required final CloudProvider provider,
      required final String baseUrl,
      final String? customDomain,
      final String? bucketName,
      final String? accessKey,
      final String? secretKey,
      final String? region,
      final Map<String, String>? customHeaders,
      final bool useHttps,
      final bool enableCache,
      final int cacheExpireDays}) = _$CloudMusicConfigImpl;

  factory _CloudMusicConfig.fromJson(Map<String, dynamic> json) =
      _$CloudMusicConfigImpl.fromJson;

  @override
  CloudProvider get provider;
  @override
  String get baseUrl;
  @override
  String? get customDomain;
  @override
  String? get bucketName;
  @override
  String? get accessKey;
  @override
  String? get secretKey;
  @override
  String? get region;
  @override
  Map<String, String>? get customHeaders;
  @override
  bool get useHttps;
  @override
  bool get enableCache;
  @override
  int get cacheExpireDays;
  @override
  @JsonKey(ignore: true)
  _$$CloudMusicConfigImplCopyWith<_$CloudMusicConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CloudSongInfo _$CloudSongInfoFromJson(Map<String, dynamic> json) {
  return _CloudSongInfo.fromJson(json);
}

/// @nodoc
mixin _$CloudSongInfo {
  String get key => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  int? get size => throw _privateConstructorUsedError;
  DateTime? get lastModified => throw _privateConstructorUsedError;
  String? get contentType => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CloudSongInfoCopyWith<CloudSongInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CloudSongInfoCopyWith<$Res> {
  factory $CloudSongInfoCopyWith(
          CloudSongInfo value, $Res Function(CloudSongInfo) then) =
      _$CloudSongInfoCopyWithImpl<$Res, CloudSongInfo>;
  @useResult
  $Res call(
      {String key,
      String url,
      String fileName,
      int? size,
      DateTime? lastModified,
      String? contentType});
}

/// @nodoc
class _$CloudSongInfoCopyWithImpl<$Res, $Val extends CloudSongInfo>
    implements $CloudSongInfoCopyWith<$Res> {
  _$CloudSongInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? url = null,
    Object? fileName = null,
    Object? size = freezed,
    Object? lastModified = freezed,
    Object? contentType = freezed,
  }) {
    return _then(_value.copyWith(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      size: freezed == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
      lastModified: freezed == lastModified
          ? _value.lastModified
          : lastModified // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      contentType: freezed == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CloudSongInfoImplCopyWith<$Res>
    implements $CloudSongInfoCopyWith<$Res> {
  factory _$$CloudSongInfoImplCopyWith(
          _$CloudSongInfoImpl value, $Res Function(_$CloudSongInfoImpl) then) =
      __$$CloudSongInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String key,
      String url,
      String fileName,
      int? size,
      DateTime? lastModified,
      String? contentType});
}

/// @nodoc
class __$$CloudSongInfoImplCopyWithImpl<$Res>
    extends _$CloudSongInfoCopyWithImpl<$Res, _$CloudSongInfoImpl>
    implements _$$CloudSongInfoImplCopyWith<$Res> {
  __$$CloudSongInfoImplCopyWithImpl(
      _$CloudSongInfoImpl _value, $Res Function(_$CloudSongInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? url = null,
    Object? fileName = null,
    Object? size = freezed,
    Object? lastModified = freezed,
    Object? contentType = freezed,
  }) {
    return _then(_$CloudSongInfoImpl(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      size: freezed == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int?,
      lastModified: freezed == lastModified
          ? _value.lastModified
          : lastModified // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      contentType: freezed == contentType
          ? _value.contentType
          : contentType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CloudSongInfoImpl implements _CloudSongInfo {
  const _$CloudSongInfoImpl(
      {required this.key,
      required this.url,
      required this.fileName,
      this.size,
      this.lastModified,
      this.contentType});

  factory _$CloudSongInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CloudSongInfoImplFromJson(json);

  @override
  final String key;
  @override
  final String url;
  @override
  final String fileName;
  @override
  final int? size;
  @override
  final DateTime? lastModified;
  @override
  final String? contentType;

  @override
  String toString() {
    return 'CloudSongInfo(key: $key, url: $url, fileName: $fileName, size: $size, lastModified: $lastModified, contentType: $contentType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CloudSongInfoImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.lastModified, lastModified) ||
                other.lastModified == lastModified) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, key, url, fileName, size, lastModified, contentType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CloudSongInfoImplCopyWith<_$CloudSongInfoImpl> get copyWith =>
      __$$CloudSongInfoImplCopyWithImpl<_$CloudSongInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CloudSongInfoImplToJson(
      this,
    );
  }
}

abstract class _CloudSongInfo implements CloudSongInfo {
  const factory _CloudSongInfo(
      {required final String key,
      required final String url,
      required final String fileName,
      final int? size,
      final DateTime? lastModified,
      final String? contentType}) = _$CloudSongInfoImpl;

  factory _CloudSongInfo.fromJson(Map<String, dynamic> json) =
      _$CloudSongInfoImpl.fromJson;

  @override
  String get key;
  @override
  String get url;
  @override
  String get fileName;
  @override
  int? get size;
  @override
  DateTime? get lastModified;
  @override
  String? get contentType;
  @override
  @JsonKey(ignore: true)
  _$$CloudSongInfoImplCopyWith<_$CloudSongInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
