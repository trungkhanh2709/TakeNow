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
  double _maxZoom = 1.0;
  double _minZoom = 1.0;
  double _currentZoom = 1.0;
  double _zoomSpeedMutiplier = 0.008;
  int _currentCameraIndex = 0;

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
      double zoom = await _controller.getMaxZoomLevel();

      setState(() {
        _isCameraInitialized = true;
        _maxZoom = zoom;
        _minZoom = 1.0;
        _currentZoom = 1.0;
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
    double cameraPreviewSize = screenWidth * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          IconButton(
            onPressed: _onSwitchCamera,
            icon: Icon(Icons.switch_camera),
          ),
          IconButton(
            onPressed: _onToggleFlash,
            icon: Icon(Icons.flash_on),
          ),
        ],
      ),
      backgroundColor: Color(0xFF2F2E2E),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: EdgeInsets.only(top: 100.0),
              width: cameraPreviewSize,
              height: cameraPreviewSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: GestureDetector(
                  onScaleUpdate: _onScaleUpdate,
                  onTapDown: _onTapFocus,
                  child: CameraPreview(_controller),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: _onCapturePressed,
            child: Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

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

  void _onTapFocus(TapDownDetails details) {
    double x = details.localPosition.dx / MediaQuery.of(context).size.width;
    double y = details.localPosition.dy / MediaQuery.of(context).size.height;
    Offset focusPoint = Offset(x, y);
    _controller.setFocusPoint(focusPoint);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    double newZoom = _currentZoom * details.scale;
    if (details.scale < 1.0) {
      newZoom = _currentZoom - (_currentZoom - _minZoom) * (1.0 - details.scale) * (_zoomSpeedMutiplier + 0.065);
    } else {
      newZoom = _currentZoom + (_maxZoom - _currentZoom) * (details.scale - 1.0) * _zoomSpeedMutiplier;
    }

    newZoom = newZoom.clamp(_minZoom, _maxZoom);
    _controller.setZoomLevel(newZoom);
    setState(() {
      _currentZoom = newZoom;
    });
  }
}
