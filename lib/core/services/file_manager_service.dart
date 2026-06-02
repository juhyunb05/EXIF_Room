import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

class FileManagerService {
  static Future<String> copyToInternalStorage(String sourcePath) async {
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

  static Future<void> shareOrSaveImage(String imagePath, bool isWindows, {bool saveToDevice = false}) async {
    if (isWindows) {
      final name = p.basename(imagePath);
      final ext = p.extension(imagePath).toLowerCase().replaceAll('.', '');
      final typeGroup = XTypeGroup(
        label: 'Images',
        extensions: <String>[ext.isEmpty ? 'png' : ext],
      );
      final saveLocation = await getSaveLocation(
        suggestedName: name,
        acceptedTypeGroups: [typeGroup],
      );
      if (saveLocation != null) {
        final file = File(imagePath);
        await file.copy(saveLocation.path);
      }
    } else if (saveToDevice) {
      final params = SaveFileDialogParams(
        sourceFilePath: imagePath,
        fileName: p.basename(imagePath),
      );
      await FlutterFileDialog.saveFile(params: params);
    } else {
      await Share.shareXFiles([XFile(imagePath)], text: 'Check out my poster!');
    }
  }
}
