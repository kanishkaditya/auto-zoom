import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as imageLib;
import 'package:path_provider/path_provider.dart';

/// ImageUtils
class ImageUtils {
  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static imageLib.Image convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return convertBGRA8888ToImage(cameraImage);
    } else {
      return null;
    }
  }

  /// Converts a [CameraImage] in BGRA888 format to [imageLib.Image] in RGB format
  static imageLib.Image convertBGRA8888ToImage(CameraImage cameraImage) {
    imageLib.Image img = imageLib.Image.fromBytes(cameraImage.planes[0].width,
        cameraImage.planes[0].height, cameraImage.planes[0].bytes,
        format: imageLib.Format.bgra);
    return img;
  }

  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static imageLib.Image convertYUV420ToImage(CameraImage image) {
    int width = image.width;
    int height = image.height;
// imglib -> Image package from https://pub.dartlang.org/packages/image
    var img = imageLib.Image(width, height); // Create Image buffer
    const int hexFF = 0xFF << 24;
    final int uvyButtonStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
// Calculate pixel color
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
// color: 0x FF  FF  FF  FF
//           A   B   G   R
        img.setPixelRgba(x, y, r, g << 8, b << 16, hexFF);
      }
    }
    var img1 = imageLib.copyRotate(img, 90);
    return img1;
  }

  /// Convert a single YUV pixel to RGB
  // static int yuv2rgb(int y, int u, int v) {
  //   // Convert yuv pixel to rgb
  //
  // }

  static void saveImage(imageLib.Image image, [int i = 0]) async {
    List<int> jpeg = imageLib.JpegEncoder().encodeImage(image);
    final appDir = await getTemporaryDirectory();
    final appPath = appDir.path;
    final fileOnDevice = File('$appPath/out$i.jpg');
    await fileOnDevice.writeAsBytes(jpeg, flush: true);
    print('Saved $appPath/out$i.jpg');
  }
}
