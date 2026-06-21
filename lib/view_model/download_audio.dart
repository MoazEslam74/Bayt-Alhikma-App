import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Download audio file from [url] and save as [fileName] (preserve extension
/// from URL when possible) inside application documents/audio/ folder.
/// Optionally report progress.
Future<String> downloadAudio(
  String url,
  String fileName, {
  void Function(int received, int total)? onProgress,
}) async {
  final dir = await getApplicationDocumentsDirectory();

  final audioFolder = Directory("${dir.path}/audio");
  if (!audioFolder.existsSync()) {
    audioFolder.createSync(recursive: true);
  }

  // Detect extension from URL path (if any)
  String urlFileName = '';
  try {
    final uri = Uri.parse(url);
    if (uri.pathSegments.isNotEmpty) {
      urlFileName = uri.pathSegments.last;
    }
  } catch (_) {
    urlFileName = '';
  }

  final extMatch = RegExp(r'\.[A-Za-z0-9]+$').firstMatch(urlFileName);
  final urlExt = extMatch?.group(0) ?? '';

  // If user provided fileName already includes an extension, keep it.
  final hasExt = RegExp(r'\.[A-Za-z0-9]+$').hasMatch(fileName);

  final finalFileName = hasExt
      ? fileName
      : (urlExt.isNotEmpty ? '$fileName$urlExt' : '$fileName.mp3');

  final filePath = "${audioFolder.path}/$finalFileName";

  final dio = Dio();

  try {
    await dio.download(
      url,
      filePath,
      onReceiveProgress: onProgress,
      options: Options(
        followRedirects: true,
        validateStatus: (status) {
          return status != null && status < 400;
        },
      ),
    );
    return filePath;
  } on DioError catch (dioErr) {
    final status = dioErr.response?.statusCode ?? 0;
    final message = dioErr.message ?? 'DioError';
    throw Exception('Download failed: $message (HTTP $status)');
  } catch (e) {
    throw Exception('Download failed: ${e.toString()}');
  }
}
