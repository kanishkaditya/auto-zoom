
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yuvtransform/camera_handler.dart';
import 'package:yuvtransform/camera_view_singleton.dart';
import 'package:yuvtransform/imageViewer.dart';

import 'camera_screen.dart';

class YuvTransformScreen extends StatefulWidget {
  @override
  _YuvTransformScreenState createState() => _YuvTransformScreenState();
}

class _YuvTransformScreenState extends State<YuvTransformScreen>
    with CameraHandler {

  CameraImage img;

  @override
  void initState() {
    super.initState();

    // Registers the page to observer for life cycle managing.
    onNewCameraSelected(cameras[cameraType]);
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller?.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );


    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        print("Camera error: ${controller.value.errorDescription}");
      }
    });

    try {
      await controller.initialize();
      Size screenSize = MediaQuery.of(context).size;
      Size previewSize = controller.value.previewSize;
      CameraViewSingleton.screenSize = screenSize;
      CameraViewSingleton.ratio = screenSize.width / previewSize.height;
      await controller
          .startImageStream((CameraImage image){
            img=image;
      } );
    } on CameraException catch (e) {
      showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Stack(children: <Widget>[
      Column(
        children: <Widget>[
          Expanded(
            child: CameraScreenWidget(
              controller: controller,
            ),
          ),
        ],
      )
    ]
            ),
          floatingActionButton: FloatingActionButton(
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>ImageViewer(image: img)));
              // _processCameraImage(image);
            },
          ),
        )
    );
  }
}
