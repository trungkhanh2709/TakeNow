import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:takenow/Class/Globals.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/screens/MyFriendScreen.dart';
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

//khanh demo 2
class _HomeScreenState extends State<HomeScreen> {
  late List<CameraDescription> cameras;
  late CameraController _controller;
  late Future<void> initiallizeControllerFutter;
  bool _isCameraInitialized = false;
  double _maxZoom = 1.0;
  double _minZoom = 0.7;
  double _currentZoom = 1.0;
  double _zoomSpeedMultiplier = 0.008;
  int _currentCameraIndex = 0;
  List<String> friendsIds = [];
  String userLogin = '';


  //click profile

  @override
  void initState() {
    super.initState();
    initializeUser();
    initializeCamera();



  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> initializeUser() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      // Store the user's ID in the global variable
      if (user != null) {
        Globals.setGoogleUserId(user.uid);

        setState(() {
          userLogin = user.uid; // Update userLogin here
        });
      }

      await APIs.getSelfInfo();
      if (mounted) {
        setState(() {});
      }
      fetchFriendsIds();

    } catch (e) {
      print('Error initializing user: $e');
      // Handle error initializing user
    }
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
      double maxZoom = await _controller.getMaxZoomLevel();
      double defaultZoom = 2.0; // Set your desired default zoom level here

      setState(() {
        _isCameraInitialized = true;
        _maxZoom = maxZoom;
        _minZoom = 0.7;
        _currentZoom = defaultZoom;
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
          backgroundColor: Color(0xFF2F2E2E),
        ),
        body: Center(
          child:  CircularProgressIndicator(),
        ),
        backgroundColor: Color(0xFF2F2E2E),
      );
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double cameraPreviewSize = screenWidth;

    if (_controller == null || !_controller.value.isInitialized) {
      return const Center(child: Text('No Camera to Preview'));
    }

    var tmp = MediaQuery.of(context).size;
    final screenH = math.max(tmp.height, tmp.width);
    final screenW = math.min(tmp.height, tmp.width);
    tmp = _controller.value.previewSize!;
    final previewH = math.max(tmp.height, tmp.width);
    final previewW = math.min(tmp.height, tmp.width);
    final screenRatio = screenH / screenW;
    final previewRatio = previewH / previewW;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2F2E2E),
        actions: [
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  top: 10,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0x5C968E8E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/User_cicrle_light.svg',
                        color: Colors.white, // Adjust color as needed
                      ),
                      onPressed: () async {
                        if (APIs.me != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProfileScreen(user: APIs.me)),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Google Account Not Found'),
                              content: Text(
                                  'Please sign in with your Google account.'),
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
                  ),
                ),
                Positioned(
                  top: 10,
                  bottom: 0,
                  left: MediaQuery.of(context).size.width / 2 - 25,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0x5C968E8E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/Group_light.svg',
                        color: Colors.white, // Adjust color as needed
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MyFriendScreen()));
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 20, // Căn lề phải
                  top: 10,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0x5C968E8E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/Chat_light.svg',
                        color: Colors.white, // Adjust color as needed
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ListChatScreen()));
                      },
                    ),
                  ),
                ),
              ],
            ),
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
              height:
                  cameraPreviewSize, // Keeping width and height same for 1:1 aspect ratio
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40.0),
                child: OverflowBox(
                  maxHeight: screenRatio > previewRatio
                      ? screenH
                      : screenW / previewW * previewH,
                  maxWidth: screenRatio > previewRatio
                      ? screenH / previewH * previewW
                      : screenW,
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
            icon: SvgPicture.asset('assets/icons/lightning_duotone_line.svg',
                width: 50, height: 55),
            onPressed: _onToggleFlash,
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ElevatedButton(
              onPressed: _onCapturePressed,
              child: null,
            ),
          ),
          IconButton(
            onPressed: _onSwitchCamera,
            icon: SvgPicture.asset('assets/icons/Camera_light.svg',
                width: 50, height: 55),
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
                  // Dùng Spacer để căn giữa
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Future<void> fetchFriendsIds() async {
    String idUser =userLogin; // Add null check operator `!` here

    try {
      // Truy vấn Firestore để lấy dữ liệu
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(idUser) // Use null check operator `!` to assert idUser is not null
          .get();

      // Lấy danh sách các bạn bè từ dữ liệu trả về
      List<dynamic> friends = documentSnapshot.data()?['friends'] ?? [];

      setState(() {
        friendsIds = List<String>.from(friends);
        friendsIds.add(idUser);
      });
    } catch (e) {
      print('Error fetching friends IDs: $e');
    }
    print('friendsIds: $friendsIds');
    print('Iuser: $idUser');
    fetchLatestImageUrls(friendsIds);

  }


  Future<void> fetchLatestImageUrls(List<String> friendsIds) async {
    String? latestImageUrl;
    Timestamp? latestTimestamp;

    for (String userId in friendsIds) {
      try {
        print('Fetching latest image for user $userId');
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collectionGroup('post_image')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot latestDoc = querySnapshot.docs.first;

          // Fetch the timestamp and ensure it is of type Timestamp
          Timestamp timestamp;
          var timestampValue = latestDoc.get('timestamp');

          print('Timestamp value for user $userId: $timestampValue (${timestampValue.runtimeType})');

          if (timestampValue is String) {
            try {
              int millisecondsSinceEpoch = int.parse(timestampValue);
              DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
              timestamp = Timestamp.fromDate(dateTime);
            } catch (e) {
              print('Error parsing string timestamp for user $userId: $e');
              continue;
            }
          } else if (timestampValue is int || timestampValue is double) {
            try {
              int millisecondsSinceEpoch = timestampValue is int
                  ? timestampValue
                  : (timestampValue as double).toInt();
              DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
              timestamp = Timestamp.fromDate(dateTime);
            } catch (e) {
              print('Error converting numeric timestamp for user $userId: $e');
              continue;
            }
          } else if (timestampValue is Timestamp) {
            timestamp = timestampValue;
          } else {
            print('Unsupported timestamp format for user $userId: $timestampValue (${timestampValue.runtimeType})');
            continue;
          }

          if (latestTimestamp == null || timestamp.compareTo(latestTimestamp) > 0) {
            latestTimestamp = timestamp;
            latestImageUrl = latestDoc.get('imageUrl');
          }
        } else {
          print('No images found for user $userId');
        }
      } catch (e) {
        print('Error fetching latest image for user $userId: $e');
      }
    }

    if (latestImageUrl != null) {
      print('Latest image URL: $latestImageUrl');
    } else {
      print('No latest image URL found.');
    }
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
      double maxZoom = await _controller.getMaxZoomLevel();
      double defaultZoom = 0.8; // Set your desired default zoom level here

      setState(() {
        _maxZoom = maxZoom;
        _minZoom = 0.8;
        _currentZoom = defaultZoom;
      });

      // Set the camera to use the default zoom level
      await _controller.setZoomLevel(defaultZoom);
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

        // Ensure the image has a 1:1 aspect ratio
        img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
        if (image != null) {
          int minLength =
              image.width < image.height ? image.width : image.height;
          int offsetX = (image.width - minLength) ~/ 2;
          int offsetY = (image.height - minLength) ~/ 2;
          img.Image croppedImage = img.copyCrop(image,
              x: offsetX, y: offsetY, width: minLength, height: minLength);

          // Save the cropped image to a temporary file
          File croppedFile =
              await imageFile.writeAsBytes(img.encodeJpg(croppedImage));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  UploadPhotoScreen(imagePath: croppedFile.path),
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
