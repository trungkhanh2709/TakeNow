import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<CameraDescription> cameras;
  late CameraController _controller;
  bool _isCameraInitialized = false;
<<<<<<< Updated upstream
  int _currentCameraIndex = 0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;
  double _currentZoom = 1.0;
  double _zoomSpeedMutiplier = 0.008;
=======
  int _currentCameraIndex = 0; // Index to track current camera
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras[_currentCameraIndex], ResolutionPreset.high);

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    try {
      await _controller.initialize();
<<<<<<< Updated upstream
      double zoom = await _controller.getMaxZoomLevel();

      setState(() {
        _isCameraInitialized = true;
        _maxZoom= zoom;
        _minZoom = 1.0;
        _currentZoom = 1.0;
=======
      setState(() {
        _isCameraInitialized = true;
>>>>>>> Stashed changes
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || !_controller.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    double screenWidth = MediaQuery.of(context).size.width;
<<<<<<< Updated upstream
    double cameraPreviewSize = screenWidth * 0.95;
=======

    // Calculate the size for the CameraPreview to maintain 1:1 aspect ratio
    double cameraPreviewSize = screenWidth * 0.9;
>>>>>>> Stashed changes

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          IconButton(
            onPressed: () {
              _onSwitchCamera();
            },
<<<<<<< Updated upstream
            icon: Icon(Icons.person),
=======
            icon: Icon(Icons.switch_camera),
>>>>>>> Stashed changes
          ),
          IconButton(
            onPressed: () {
              _onToggleFlash();
            },
<<<<<<< Updated upstream
            icon: Icon(Icons.chat_bubble_outline_outlined),
          ),
        ],
      ),
      backgroundColor: Color(0xFF2F2E2E),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.only(top:100.0),
              width: cameraPreviewSize,
              height: cameraPreviewSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0), // Điều chỉnh độ cong của góc tại đây
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.previewSize!.height,
                      height: _controller.value.previewSize!.width,
                      child: GestureDetector(
                        onScaleUpdate: (details){
                          double newZoom = _currentZoom * details.scale;
                          if(details.scale < 1.0){
                            newZoom= _currentZoom - (_currentZoom - _minZoom) * (1.0 - details.scale) * (_zoomSpeedMutiplier + 0.065);
                          }
                          else{
                            newZoom = _currentZoom + (_maxZoom - _currentZoom) * (details.scale - 1.0) * _zoomSpeedMutiplier;
                          }

                          newZoom = newZoom.clamp(_minZoom, _maxZoom);
                          _controller.setZoomLevel(newZoom);
                          setState(() {
                            _currentZoom = newZoom;
                          });
                        },
                      onTapDown: _onTapFocus,
                      child: CameraPreview(_controller),
                    ),
                  ),
=======
            icon: Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: cameraPreviewSize,
          height: cameraPreviewSize,
          child: ClipRect(

            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.previewSize!.height,
                  height: _controller.value.previewSize!.width,
                  child: CameraPreview(_controller),
>>>>>>> Stashed changes
                ),
              ),
            ),
          ),
<<<<<<< Updated upstream
          ),
        ],

        ),

=======
        ),
      ),
>>>>>>> Stashed changes
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: _onCapturePressed,
            child: Icon(Icons.camera_alt),
          ),
          FloatingActionButton(
            onPressed: _onToggleFlash,
            child: Icon(Icons.flash_on),
          ),
          FloatingActionButton(
            onPressed: _onSwitchCamera,
            child: Icon(Icons.switch_camera),
          ),
        ],
      ),
    );
  }


<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
  void _onSwitchCamera() {
    _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
    _controller = CameraController(
      cameras[_currentCameraIndex],
      ResolutionPreset.high,
    );

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
<<<<<<< Updated upstream

    _controller.initialize().then((_) {
      setState(() {});
    });
  }

  void _onToggleFlash() {
    if (_controller.value.isInitialized) {
      bool currentFlashMode = _controller.value.flashMode == FlashMode.torch;
      _controller.setFlashMode(currentFlashMode ? FlashMode.off : FlashMode.torch);
    }
  }

  void _onCapturePressed() async {
    try {
      XFile file = await _controller.takePicture();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Image.file(File(file.path)),

              )
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  void _onTapFocus(TapDownDetails details){
    double x = details.localPosition.dx / MediaQuery.of(context).size.width;
    double y = details.localPosition.dx / MediaQuery.of(context).size.height;
    Offset focusPoint = Offset(x, y); // Create Offset object
    _controller.setFocusPoint(focusPoint);
=======
>>>>>>> Stashed changes

    _controller.initialize().then((_) {
      setState(() {});
    });
  }

  void _onToggleFlash() {
    if (_controller.value.isInitialized) {
      bool currentFlashMode = _controller.value.flashMode == FlashMode.torch;
      _controller.setFlashMode(currentFlashMode ? FlashMode.off : FlashMode.torch);
    }
  }

  void _onCapturePressed() async {
    try {
      XFile file = await _controller.takePicture();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Image.file(File(file.path)),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error taking picture: $e');
    }
  }
}
