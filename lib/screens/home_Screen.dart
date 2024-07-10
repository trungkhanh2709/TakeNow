import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/screens/listChat_Screen.dart';
import 'package:takenow/screens/profile_screen.dart';

import 'package:takenow/screens/viewPhotoScreen.dart';

import 'UploadPhotoScreen.dart';

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
  double _zoomSpeedMultiplier = 0.008;
  int _currentCameraIndex = 0;


  //click profile

  @override
  void initState() {
    super.initState();
    initializeCamera();
    initializeUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(
      cameras[_currentCameraIndex],
      ResolutionPreset.high,
    );

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
      // Handle camera initialization error
    }
  }

  Future<void> initializeUser() async {
    try {
      await APIs.getSelfInfo();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing user: $e');
      // Handle error initializing user
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || !_controller.value.isInitialized || APIs.me == null) {
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
    double cameraPreviewSize = screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {
              if (APIs.me != null){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen(user: APIs.me)),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Google Account Not Found'),
                    content: Text('Please sign in with your Google account.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ListChatScreen()));
            },
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
                borderRadius: BorderRadius.circular(40.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: GestureDetector(
                    onScaleUpdate: _onScaleUpdate,
                    onTapDown: _onTapFocus,
                    child: CameraPreview(_controller),
                  ),
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
          IconButton(
            icon: Icon(Icons.flip_camera_ios_outlined),
            onPressed: _onSwitchCamera,
          ),
          FloatingActionButton(
            onPressed: _onCapturePressed,
            child: Icon(Icons.camera_alt),
          ),
          IconButton(
            icon: Icon(Icons.flash_on),
            onPressed: _onToggleFlash,
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
          color: Color(0xFF2F2E2E),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ViewPhotoScreen()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //thm icon album
                    Text(
                      'Album',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 5),
                    SvgPicture.asset(
                      'assets/icons/expanddown.svg',
                      width: 24,
                      height: 24,
                      color: Colors.white,
                    ),
                    SizedBox(width: 40), // Space between icon and text
                  ],
                ),
              ),
            ],
          )),
    );
  }

  void _onSwitchCamera() async {
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

    try {
      await _controller.initialize();
      double zoom = await _controller.getMaxZoomLevel();

      setState(() {
        _maxZoom = zoom;
        _minZoom = 1.0;
        _currentZoom = 1.0;
      });
    } catch (e) {
      print('Error initializing camera: $e');
      // Handle camera initialization error
    }
  }

  void _onToggleFlash() {
    if (_controller.value.isInitialized) {
      bool currentFlashMode = _controller.value.flashMode == FlashMode.torch;
      _controller
          .setFlashMode(currentFlashMode ? FlashMode.off : FlashMode.torch);
    }
  }

  void _onCapturePressed() async {
    try {
      XFile file = await _controller.takePicture();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadPhotoScreen(imagePath: file.path),
        ),
      );
    } catch (e) {
      print('Error taking picture: $e');
      // Handle error taking picture
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
      newZoom = _currentZoom -
          (_currentZoom - _minZoom) *
              (1.0 - details.scale) *
              (_zoomSpeedMultiplier + 0.065);
    } else {
      newZoom = _currentZoom +
          (_maxZoom - _currentZoom) *
              (details.scale - 1.0) *
              _zoomSpeedMultiplier;
    }

    newZoom = newZoom.clamp(_minZoom, _maxZoom);
    _controller.setZoomLevel(newZoom);
    setState(() {
      _currentZoom = newZoom;
    });
  }
}
