part of '../utils.dart';

Future<String> loadAssets() async {
  List<String> assetKeys = [];
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    assetKeys = manifest.listAssets();
  } catch (e) {
    // Logs('Warning: Could not load AssetManifest: $e');
    // Return default path - assets will be loaded on demand
    return '${(await getApplicationDocumentsDirectory()).path}/assets';
  }
  Directory documentsDirectory = await getApplicationDocumentsDirectory();

  for (String key in assetKeys) {
    String assetPath = key;

    if (assetPath.contains("packages/face_sdk_3divi_models/")) {
      assetPath = assetPath.replaceFirst("packages/face_sdk_3divi_models/", "");
    }

    String dbPath = "${documentsDirectory.path}/$assetPath";

    if (FileSystemEntity.typeSync(dbPath) == FileSystemEntityType.notFound ||
        dbPath.contains('conf/facerec') ||
        dbPath.contains('license')) {
      ByteData data = await rootBundle.load(key);
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      File file = File(dbPath);
      file.createSync(recursive: true);

      await file.writeAsBytes(bytes);
    }
  }

  return "${documentsDirectory.path}/assets";
}

Future<String> getLibraryDirectory() async {
  const platform = MethodChannel('samples.flutter.dev/facesdk');
  String libraryDirectory = "None";
  libraryDirectory = await platform.invokeMethod('getNativeLibDir');

  return libraryDirectory;
}
