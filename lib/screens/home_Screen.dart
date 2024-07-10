import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:takenow/screens/listChat_Screen.dart';
import 'package:takenow/screens/profile_screen.dart';
import 'package:takenow/screens/viewPhotoScreen.dart';
import 'package:image/image.dart' as img;
import '../models/chat_user.dart';
import 'UploadPhotoScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

//khanh
class _HomeScreenState extends State<HomeScreen> {
  late List<CameraDescription> cameras;
  late CameraController _controller;
  late Future<void> initiallizeControllerFutter;
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
    double previewSize = screenWidth;  // Keeping width and height same for 1:1 aspect ratio

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {
              GoogleSignInAccount? googleUser =
              await GoogleSignIn().signInSilently();
              if (googleUser != null) {
                // Convert GoogleSignInAccount to ChatUser
                ChatUser user = ChatUser(
                  image: googleUser.photoUrl ?? '',
                  name: googleUser.displayName ?? '',
                  about: '', // Add default value or fetch from backend if available
                  createdAt: '', // Add default value or fetch from backend if available
                  id: googleUser.id,
                  isOnline: false, // Add default value or fetch from backend if available
                  lastActive: '', // Add default value or fetch from backend if available
                  email: googleUser.email,
                  pushToken: '', // Add default value or fetch from backend if available
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
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
              width: previewSize,
              height: previewSize,  // Keeping width and height same for 1:1 aspect ratio
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40.0),
                child: AspectRatio(
                  aspectRatio: 1.0,  // Ensuring 1:1 aspect ratio
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
            icon: SvgPicture.asset('assets/icons/lightning_duotone_line.svg',width: 50, height: 55),
            onPressed: _onToggleFlash,

          ),
          FloatingActionButton(
            onPressed: _onCapturePressed,
            child: Icon(Icons.camera_alt),
          ),
          IconButton(
              onPressed: _onSwitchCamera,
              icon: SvgPicture.asset('assets/icons/Camera_light.svg',width: 50, height: 55,)
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
      await _controller.takePicture().then((XFile file) async {
        File imageFile = File(file.path);

        img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
        if (image != null) {

          int minLength = image.width < image.height ? image.width : image.height;
          int offsetX = (image.width - minLength) ~/ 2;
          int offsetY = (image.height - minLength) ~/ 2;
          img.Image croppedImage = img.copyCrop(image, x:offsetX, y:offsetY, width: minLength, height: minLength);

          // Ghi ảnh đã crop vào file tạm
          File croppedFile = await imageFile.writeAsBytes(img.encodeJpg(croppedImage));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadPhotoScreen(imagePath: croppedFile.path),
            ),
          );
        } else {
          print('Error decoding image');
        }
      });
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
