import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import '../models/exif_data.dart';

class FileManagerService {
  static Future<String> copyToInternalStorage(String sourcePath) async {
    if (kIsWeb) return sourcePath; // Web doesn't have internal app directory
    
    final dir = await getApplicationDocumentsDirectory();
    final importedDir = Directory(p.join(dir.path, 'imported_images'));
    if (!await importedDir.exists()) {
      await importedDir.create(recursive: true);
    }
    
    final fileName = 'imported_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final destinationPath = p.join(importedDir.path, fileName);
    
    final file = File(sourcePath);
    await file.copy(destinationPath);
    
    return destinationPath;
  }

  static String generateFileName(ExifData exif, String extension) {
    final now = DateTime.now();
    
    // 1. Camera Name processing
    String cameraPart = 'UNKNOWN';
    if (exif.cameraName != null && exif.cameraName!.trim().isNotEmpty) {
      cameraPart = exif.cameraName!
          .trim()
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9가-힣ㄱ-ㅎㅏ-ㅣ_]'), '')
          .toUpperCase();
    } else if (exif.cameraMake != null && exif.cameraMake!.trim().isNotEmpty) {
      cameraPart = exif.cameraMake!
          .trim()
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9가-힣ㄱ-ㅎㅏ-ㅣ_]'), '')
          .toUpperCase();
    }
    
    // 2. Date/Time processing
    String datePart;
    if (exif.shotDate != null) {
      datePart = DateFormat("yyyyMMdd_HHmmss").format(exif.shotDate!);
    } else {
      final dateStr = DateFormat("yyyyMMdd_HHmmss").format(now);
      datePart = "D_$dateStr";
    }
    
    final ext = extension.startsWith('.') ? extension : '.$extension';
    return "Room_${cameraPart}_$datePart$ext";
  }

  static Future<void> shareOrSaveImage(
    String imagePath, 
    bool isWindows, {
    bool saveToDevice = false, 
    Uint8List? webBytes,
    String? customFileName,
  }) async {
    if (kIsWeb) {
      Uint8List? bytes = webBytes;
      if (bytes == null) {
        try {
          final xfile = XFile(imagePath);
          bytes = await xfile.readAsBytes();
        } catch (e) {
          debugPrint('Failed to read image bytes on Web: $e');
        }
      }
      if (bytes != null) {
        final ext = p.extension(imagePath).toLowerCase().replaceAll('.', '');
        final finalExt = ext.isEmpty ? 'png' : ext;
        final name = customFileName ?? p.basename(imagePath);
        final fileName = name.endsWith('.$finalExt') ? name : '$name.$finalExt';
        
        final xfile = XFile.fromData(bytes, name: fileName, mimeType: finalExt == 'png' ? 'image/png' : 'image/jpeg');
        await xfile.saveTo(fileName);
      }
      return; // Always return early on Web to prevent native platform channel calls
    }

    if (isWindows) {
      final ext = p.extension(imagePath).toLowerCase().replaceAll('.', '');
      final finalExt = ext.isEmpty ? 'png' : ext;
      final name = customFileName ?? p.basename(imagePath);
      final fileName = name.endsWith('.$finalExt') ? name : '$name.$finalExt';
      final typeGroup = XTypeGroup(
        label: 'Images',
        extensions: <String>[finalExt],
      );
      final saveLocation = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: [typeGroup],
      );
      if (saveLocation != null) {
        final file = File(imagePath);
        await file.copy(saveLocation.path);
      }
    } else if (saveToDevice) {
      final ext = p.extension(imagePath).toLowerCase().replaceAll('.', '');
      final finalExt = ext.isEmpty ? 'png' : ext;
      final name = customFileName ?? p.basename(imagePath);
      final fileName = name.endsWith('.$finalExt') ? name : '$name.$finalExt';
      final params = SaveFileDialogParams(
        sourceFilePath: imagePath,
        fileName: fileName,
      );
      await FlutterFileDialog.saveFile(params: params);
    } else {
      await Share.shareXFiles([XFile(imagePath)], text: 'Check out my poster!');
    }
  }
}
