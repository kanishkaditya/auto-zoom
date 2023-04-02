import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:yuvtransform/service/image_result_processor_service.dart';
import 'package:yuvtransform/tflite/classifier.dart';
import 'package:yuvtransform/tflite/recognition.dart';
import 'package:yuvtransform/util/isolate_utils.dart';

// Future<String> _getModel(String assetPath) async {
//   if (Platform.isAndroid) {
//     return 'flutter_assets/$assetPath';
//   }
//   final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
//   await Directory(dirname(path)).create(recursive: true);
//   final file = File(path);
//   if (!await file.exists()) {
//     final byteData = await rootBundle.load(assetPath);
//     await file.writeAsBytes(byteData.buffer
//         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
//   }
//   return file.path;
// }

class ImageViewer extends StatefulWidget {
  final CameraImage image;

  const ImageViewer({Key key, this.image}) : super(key: key);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> with WidgetsBindingObserver {
  ObjectDetector objectDetector;
  Uint8List rgbimage;
  List<StreamSubscription> _subscription =[];
  ImageResultProcessorService _imageResultProcessorService;
  IsolateUtils isolateUtils;
  Classifier classifier;
  List<Recognition>recognition;
  int DELAY_TIME=3000;


  void initStateAsync() async {
    _imageResultProcessorService = ImageResultProcessorService();
    WidgetsBinding.instance.addObserver(this);
    _subscription.add(_imageResultProcessorService.queue.listen((event) async{
      rgbimage=event;
      if(rgbimage!=null){
        await detectImage(widget.image);
      }
      setState(() {});
      // _isProcessing = false;
    }));

    isolateUtils = IsolateUtils();
    await isolateUtils.start();
    classifier = Classifier();
    _processCameraImage(widget.image);
  }


  void _processCameraImage(CameraImage image) async {
    // if (_isProcessing)
    //   return; //Do not detect another image until you finish the previous.
    // _isProcessing = true;
    // print("Sent a new image and sleeping for: $DELAY_TIME");
   _imageResultProcessorService.addRawImage(image);
  }

  detectImage(CameraImage cameraImage) async {
    // print(classifier!.interpreter);
    // print(classifier!.labels);
    if (classifier.interpreter != null && classifier.labels != null) {
      // If previous inference has not completed then return
      // print('bi');
      // var uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;

      // Data to be passed to inference isolate\
      // print(widget.image.height);
      // print(widget.image.width);
      // print('_______________________________________________');
      var isolateData = IsolateData(
          cameraImage, classifier.interpreter.address, classifier.labels);
      Map<String, dynamic> inferenceResults = await inference(isolateData);

      // var uiThreadInferenceElapsedTime =
      //     DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

      // pass results to HomeView
      recognition=inferenceResults["recognitions"];
      if(recognition.isNotEmpty)
       print(recognition[0].label);
      final rect = recognition[0].renderLocation;
      print(rect);
      // rgbimage=await getCroppedImage(rgbimage, rect);


      // if(recognition!=null){
      //   // print(recognition[0].location);
      //   // rgbimage =  convertCameraImage(widget.image, MediaQuery.of(context).size,recognition![0].location );
      //
      // }
      // setState(() {});
      // // pass stats to HomeView
      // widget.statsCallback((inferenceResults["stats"] as Stats)
      //   ..totalElapsedTime = uiThreadInferenceElapsedTime);

    }
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose all streams!
    _subscription.forEach((element) {
      element.cancel();
    });
    super.dispose();
  }

  Future<Map<String, dynamic>> inference(IsolateData isolateData) async {
    ReceivePort responsePort = ReceivePort();
    isolateUtils.sendPort
        .send(isolateData..responsePort = responsePort.sendPort);
    var results = await responsePort.first;
    return results;
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    // double factorX = screen.width;
    // double factorY = screen.height;
    // print(objects.length);

    Color colorPick = Colors.pink;
    if(recognition.isEmpty) {
      return [];
    } else if (recognition[0].label.isEmpty) {
      // for(DetectedObject result in objects){
      //   for(Label label in result.labels)
      //
      //     print(label.text);
      // }
      return [];
    }


    final rect = recognition[0].renderLocation;
    // rgbimage.
    // print(rect);
    // if(objects[0].labels[0].text!='computer keyboard') return [];

    return [
      Positioned(
        left: rect.left,
        top: rect.top+270,
        width: rect.width-50,
        height: rect.height,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${recognition[0].label} ${(recognition[0].score * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.black,
              fontSize: 18.0,
            ),
          ),
        ),
      )
    ];
    // }).toList();
  }
  // Future<Uint8List> getCroppedImage(Uint8List image, Rect rectangle) async {
  //
  //   var face = img.copyCrop(
  //     img.decodeImage(image),
  //     rectangle.left.toInt(),
  //     rectangle.top.toInt()+270,
  //     rectangle.width.toInt(),
  //     rectangle.height.toInt()+100,
  //   );
  //   return Uint8List.fromList(img.encodePng(face));
  // }

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];
    if (rgbimage != null) {
      list.add(Image.memory(rgbimage,fit: BoxFit.fitHeight, ));
    }
    if(recognition!=null && recognition.isNotEmpty){
      list.addAll(displayBoxesAroundRecognizedObjects(MediaQuery.of(context).size));
    }
    // if(list.isEmpty)
    //   return Scaffold(
    //   body:Container(height: 12,width: 12,)
    //   );
    // else
    return Scaffold(
    //   body: Stack(
    //     children: [
    //
    //       // Zoom(
    //       //   // maxZoomWidth: 1800,
    //       //   // maxZoomHeight: 1800,
    //       //   canvasColor: Colors.grey,
    //       //   backgroundColor: Colors.orange,
    //       //   colorScrollBars: Colors.purple,
    //       //   opacityScrollBars: 0.9,
    //       //   scrollWeight: 10.0,
    //       //   initPosition: recognition.isNotEmpty?Offset(recognition[0].renderLocation.left, recognition[0].renderLocation.top):null,
    //       //   centerOnScale: false,
    //       //   enableScroll: false,
    //       //   doubleTapZoom: false,
    //       //   zoomSensibility: 0.05,
    //       //   // initPosition: Offset(280,280),
    //       //   onTap: () {
    //       //     // print("Widget clicked");
    //       //   },
    //       //   // onPositionUpdate: (position) {
    //       //   //   setState(() {
    //       //   //     x = position.dx;
    //       //   //     y = position.dy;
    //       //   //   });
    //       //   // },
    //       //   // onScaleUpdate: (scale, zoom) {
    //       //   //   setState(() {
    //       //   //     // _zoom = zoom;
    //       //   //   });
    //       //   // },
    //       //   child: Container(
    //       //     height: MediaQuery.of(context).size.height,
    //       //       width: MediaQuery.of(context).size.width,
    //       //       child: list[0]
    //       //   )
    //       // ),
    //       ...list.sublist(1)
    //     ],
    //   ),
      // body: InteractiveViewer(
      //   o
      //   child: list[0],
      // ),
      // body: Transform(
      //   transform:  Matrix4.diagonal3(vector.Vector3(2,2,1)),
      //   // alignment: FractionalOffset.center,
      //   origin: objects.isNotEmpty?Offset(objects[0].boundingBox.left, objects[0].boundingBox.top):Offset(0,0),
      //   child: list.isNotEmpty?list[0]:Container(height: 280,width: 280,)
      // ),

      body:Stack(
        children:list
      )
    );
  }

  @override
  void initState() {
    super.initState();
    initStateAsync();
    // detectImage(widget.image);
  }

}

