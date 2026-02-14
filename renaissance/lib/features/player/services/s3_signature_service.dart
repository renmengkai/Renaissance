import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class S3SignatureV4 {
  static const String _algorithm = 'AWS4-HMAC-SHA256';
  static const String _service = 's3';
  static const String _aws4Request = 'aws4_request';

  static Map<String, String> generateHeaders({
    required String accessKey,
    required String secretKey,
    required String region,
    required String method,
    required String host,
    required String path,
    Map<String, String>? queryParams,
  }) {
    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = _formatDateStamp(now);

    final canonicalUri = path.isEmpty ? '/' : path;
    final canonicalQueryString = _buildCanonicalQueryString(queryParams);
    final canonicalHeaders = 'host:$host\nx-amz-content-sha256:UNSIGNED-PAYLOAD\nx-amz-date:$amzDate\n';
    final signedHeaders = 'host;x-amz-content-sha256;x-amz-date';
    final payloadHash = 'UNSIGNED-PAYLOAD';

    final canonicalRequest = '$method\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    final credentialScope = '$dateStamp/$region/$_service/$_aws4Request';
    final canonicalRequestHash = sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign = '$_algorithm\n$amzDate\n$credentialScope\n$canonicalRequestHash';

    final signingKey = _getSignatureKey(secretKey, dateStamp, region, _service);
    final signature = _hmacSha256Hex(signingKey, stringToSign);

    final authorizationHeader = '$_algorithm Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    return {
      'Authorization': authorizationHeader,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
      'Host': host,
    };
  }

  static String _formatAmzDate(DateTime dt) {
    return '${dt.year}${_twoDigits(dt.month)}${_twoDigits(dt.day)}T${_twoDigits(dt.hour)}${_twoDigits(dt.minute)}${_twoDigits(dt.second)}Z';
  }

  static String _formatDateStamp(DateTime dt) {
    return '${dt.year}${_twoDigits(dt.month)}${_twoDigits(dt.day)}';
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  static String _buildCanonicalQueryString(Map<String, String>? params) {
    if (params == null || params.isEmpty) return '';
    
    final sortedKeys = params.keys.toList()..sort();
    final pairs = sortedKeys.map((key) {
      return '${_uriEncode(key)}=${_uriEncode(params[key]!)}';
    });
    return pairs.join('&');
  }

  static String _uriEncode(String value) {
    return Uri.encodeComponent(value)
        .replaceAll('+', '%20')
        .replaceAll('*', '%2A')
        .replaceAll('%7E', '~');
  }

  static List<int> _getSignatureKey(String key, String dateStamp, String region, String service) {
    final kDate = _hmacSha256(utf8.encode('AWS4$key'), dateStamp);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, service);
    final kSigning = _hmacSha256(kService, _aws4Request);
    return kSigning;
  }

  static List<int> _hmacSha256(List<int> key, String message) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(message)).bytes;
  }

  static String _hmacSha256Hex(List<int> key, String message) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(message)).toString();
  }

  static String _uriEncodePath(String value) {
    // AWS S3 规范：对路径进行 URI 编码，但保留斜杠
    // 使用 Uri.encodeComponent 会编码斜杠，所以需要特殊处理
    final segments = value.split('/');
    final encodedSegments = segments.map((segment) {
      if (segment.isEmpty) return '';
      return Uri.encodeComponent(segment)
          .replaceAll('+', '%20')
          .replaceAll('*', '%2A')
          .replaceAll('%7E', '~')
          .replaceAll('!', '%21')
          .replaceAll('\'', '%27')
          .replaceAll('(', '%28')
          .replaceAll(')', '%29');
    });
    return encodedSegments.join('/');
  }

  static String buildSignedUrl({
    required String baseUrl,
    required String accessKey,
    required String secretKey,
    required String region,
    required String bucketName,
    required String objectKey,
    int expiresIn = 3600,
  }) {
    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = _formatDateStamp(now);

    final host = '$bucketName.s3.$region.qiniucs.com';
    final path = objectKey.startsWith('/') ? objectKey : '/$objectKey';
    final encodedPath = _uriEncodePath(path);



    final credentialScope = '$dateStamp/$region/$_service/$_aws4Request';
    final credential = '$accessKey/$credentialScope';

    final signedHeaders = 'host';

    final canonicalRequest = 'GET\n$encodedPath\n\nhost:$host\n\n$signedHeaders\nUNSIGNED-PAYLOAD';

    final canonicalRequestHash = sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign = '$_algorithm\n$amzDate\n$credentialScope\n$canonicalRequestHash';

    final signingKey = _getSignatureKey(secretKey, dateStamp, region, _service);
    final signature = _hmacSha256Hex(signingKey, stringToSign);

    // 构建查询参数
    final queryParams = {
      'X-Amz-Algorithm': _algorithm,
      'X-Amz-Credential': credential,
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': expiresIn.toString(),
      'X-Amz-SignedHeaders': signedHeaders,
      'X-Amz-Signature': signature,
    };

    // 按字母顺序排序并编码查询参数
    final sortedKeys = queryParams.keys.toList()..sort();
    final queryString = sortedKeys.map((key) {
      return '${_uriEncode(key)}=${_uriEncode(queryParams[key]!)}';
    }).join('&');

    final signedUrl = 'https://$host$encodedPath?$queryString';


    return signedUrl;
  }
}

class QiniuS3Service {
  final String accessKey;
  final String secretKey;
  final String region;
  final String bucketName;
  final String endpoint;

  QiniuS3Service({
    required this.accessKey,
    required this.secretKey,
    required this.region,
    required this.bucketName,
    required this.endpoint,
  });

  String get host => '$bucketName.s3.$region.qiniucs.com';

  String get baseUrl => 'https://$host';

  Map<String, String> getAuthHeaders({
    String method = 'GET',
    String path = '/',
    Map<String, String>? queryParams,
  }) {
    return S3SignatureV4.generateHeaders(
      accessKey: accessKey,
      secretKey: secretKey,
      region: region,
      method: method,
      host: host,
      path: path,
      queryParams: queryParams,
    );
  }

  String getSignedUrl(String objectKey, {int expiresIn = 3600}) {

    
    final result = S3SignatureV4.buildSignedUrl(
      baseUrl: baseUrl,
      accessKey: accessKey,
      secretKey: secretKey,
      region: region,
      bucketName: bucketName,
      objectKey: objectKey,
      expiresIn: expiresIn,
    );
    

    return result;
  }

  static (String, String, String) parseEndpoint(String endpoint) {
    final uri = Uri.parse(endpoint.startsWith('http') ? endpoint : 'https://$endpoint');
    final host = uri.host;
    
    String region = 'auto';
    String bucketName = '';
    
    final s3Pattern = RegExp(r'^([^.]+)\.s3\.([^.]+)\.qiniucs\.com$');
    final match = s3Pattern.firstMatch(host);
    
    if (match != null) {
      bucketName = match.group(1)!;
      region = match.group(2)!;
    } else {
      final parts = host.split('.');
      if (parts.length >= 2) {
        bucketName = parts[0];
      }
    }
    
    return (bucketName, region, host);
  }
}
