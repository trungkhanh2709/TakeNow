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
  int _currentCameraIndex = 0; // Index to track current camera

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
      setState(() {
        _isCameraInitialized = true;
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

    // Calculate the size for the CameraPreview to maintain 1:1 aspect ratio
    double cameraPreviewSize = screenWidth * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          IconButton(
            onPressed: () {
              _onSwitchCamera();
            },
            icon: Icon(Icons.switch_camera),
          ),
          IconButton(
            onPressed: () {
              _onToggleFlash();
            },
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
                ),
              ),
            ),
          ),
        ),
      ),
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
}
