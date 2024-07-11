import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takenow/Class/Globals.dart';
import 'package:takenow/screens/home_Screen.dart';
import 'package:vibration/vibration.dart';

import '../api/apis.dart';

class UploadPhotoScreen extends StatefulWidget {
  final String imagePath;
  const UploadPhotoScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  _UploadPhotoScreenState createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen>
    with TickerProviderStateMixin {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  double _captionWidth = 100;
  late AnimationController _controller;
  late Animation<double> _withAnimation;
  late Animation<double> _shakeAnimation;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _fadeController;

  String userId = Globals.getGoogleUserId().toString();
  bool _uploadSuccess = false;
  bool _isLoading = false;
  bool _isDowloaded = false;

  int MaxLimitCharacter = 35;
  Set<String> selectedFriends = {};
  List<String> friendsList = [];

  @override
  void initState() {
    super.initState();
    _image = File(widget.imagePath);
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );




    _withAnimation = Tween<double>(begin: 200, end: 200).animate(_controller);
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reverse();
      } else if (status == AnimationStatus.dismissed) {}
    });

    _shakeController.forward();

    captionController.addListener(() {
      if (captionController.text.length > MaxLimitCharacter) {
        captionController.text =
            captionController.text.substring(0, MaxLimitCharacter);
        captionController.selection = TextSelection.fromPosition(
          TextPosition(offset: captionController.text.length),
        );
        _shakeController.forward(from: 0);
        if (Vibration.hasVibrator() != null) {
          Vibration.vibrate();
        }
      }

      setState(() {
        _captionWidth = 50 + (captionController.text.length * 8).toDouble();
        if (_captionWidth > 350) {
          _captionWidth = 350;
        }
        _controller.value = _captionWidth / 350;
      });
    });
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    fetchFriendsList();

  }
  Future<void> fetchFriendsList() async {
    String userId = Globals.getGoogleUserId().toString();
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        friendsList = List<String>.from(userDoc['friends']);
      });
    }
  }



  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  TextEditingController captionController = TextEditingController();

  Future getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<bool> uploadImageToFirebase() async {

    String caption = captionController.text.trim();

    if (_image == null) {
      log('No image selected');
      return false;
    } else {
      await APIs.upLoadPhoto(caption, userId, _image!);
      setState(() {
        _uploadSuccess = true;
      });
      return true;
    }
  }

  void DownloadImage() async {
    setState(() {
      _isDowloaded = true;
    });
    if (_image != null) {
      final bool? result =
      await GallerySaver.saveImage(_image!.path, albumName: 'Takenow');
    } else {
      log('No image to save');
    }
    await Future.delayed(Duration(milliseconds: 1800));
    setState(() {
      _isDowloaded = false;
    });
  }

  void _uploadAndNavigate() async {
    setState(() {
      _isLoading = true;
    });

    bool success = await uploadImageToFirebase();
    if (success) {
      setState(() {
        _uploadSuccess = true;
        _isLoading = false; // Hiển thị icon Upload_sucessfull.svg
      });
      _fadeController.forward();
      await Future.delayed(Duration(milliseconds: 1500)); // Đợi 1 giây

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
      log('Upload and change ' + success.toString());
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildFriendsList() {
    if (userId == null) {
      log('User is not logged in');
      return Center(child: Text('User is not logged in',));
    }
    log('Current User ID: $userId');

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          log('No user document found.');
          return Center(child: Text('No user data found.'));
        }

        final userDocument = snapshot.data!;
        log('UserID test: ${userDocument.id}');
        log('UserFields test: ${userDocument.data()}');
        final List<dynamic> friendsList = userDocument['friends'] ?? [];

        if (friendsList.isEmpty) {
          log('Friends list is empty.');
          return Center(child: Text('No friends found.'));
        }

        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: friendsList)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> friendsSnapshot) {
            if (friendsSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (friendsSnapshot.hasError) {
              return Center(child: Text('Error: ${friendsSnapshot.error}'));
            }

            final friendsDocs = friendsSnapshot.data?.docs ?? [];
            log('Friends documents count: ${friendsDocs.length}');

            if (friendsDocs.isEmpty) {
              log('No friends documents found.');
              return Center(child: Text('No friends found.'));
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: friendsDocs.length,
              itemBuilder: (context, index) {
                final friendData = friendsDocs[index];


                final isSelected = selectedFriends.contains(friendData.id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedFriends.remove(friendData.id);
                      } else {
                        selectedFriends.add(friendData.id);
                      }
                    });
                  },
                  child: Container(

                    width: 50,

                    margin: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Color(0xB815CA00) : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(friendData['image']),
                          radius: 40,
                        ),
                        // SizedBox(height: 8.0),

                        Text(
                          friendData['name'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Photo'),
      ),
      backgroundColor: Color(0xFF2F2E2E),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isLoading,
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _image == null
                      ? Text('No image selected.')
                      : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40.0),
                        child: Image.file(
                          _image!,
                          height: 400.0,
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: child,
                            );
                          },
                          child: SizeTransition(
                            sizeFactor: _withAnimation,
                            axis: Axis.horizontal,
                            child: Container(
                              width: _captionWidth,
                              height: 65,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.all(10.0),
                              child: Center(
                                child: SingleChildScrollView(
                                  child: TextField(
                                    controller: captionController,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Caption',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF605F5F),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_uploadSuccess)
                        Positioned(
                          top: 100,
                          left: 0,
                          right: 0,
                          child: Center(
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SvgPicture.asset(
                                  'assets/icons/Upload_sucessfull.svg',
                                  width: 200,
                                  height: 200,
                                  color: Colors.white,
                                ),
                              )

                          ),
                        ),
                      if (_isDowloaded)
                        Positioned(
                          top: 150,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/Dowloaded.svg',
                              width: 200,
                              height: 200,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (_isLoading)
                        Positioned(
                          top: 150,
                          left: 0,
                          right: 0,
                          child: Center(
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )),
                        ),
                    ],
                  ),
                  SizedBox(height: 30.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => HomeScreen()));
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/Close_round.svg',
                          width: 55,
                          height: 55,
                        ),
                      ),
                      SizedBox(width: 50.0),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: IconButton(
                          onPressed: _uploadAndNavigate,
                          icon: SvgPicture.asset(
                            'assets/icons/Send_fill.svg',
                            width: 50,
                            height: 50,
                          ),
                        ),
                      ),
                      SizedBox(width: 50.0),
                      IconButton(
                        onPressed: DownloadImage,
                        icon: SvgPicture.asset(
                          'assets/icons/Import.svg',
                          width: 55,
                          height: 55,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    // bottom: 40,
                    // left: 30,
                    child:
                    Expanded(
                      child: buildFriendsList(),

                    ),)


                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}