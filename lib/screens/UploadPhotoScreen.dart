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

  int MaxLimitCharacter = 35;

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

    // Bắt đầu animation
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
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

  Future<void> uploadImageToFirebase() async {
    String userId = Globals.getGoogleUserId().toString();
    String caption = captionController.text.trim();

    if (_image == null) {
      log('No image selected');
      return;
    } else {
      await APIs.upLoadPhoto(caption, userId, _image!);
    }
  }

  void DownloadImage() async {
    if (_image != null) {
      final bool? result = await GallerySaver.saveImage(_image!.path, albumName: 'Takenow');
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to album Takenow')),

        ); log('save');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image')),
        );log('fail');
      }

    } else {
      log('No image to save');
    }
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
          Align(
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
                                    )),
                              ),
                            ),
                          )
                        ],
                      ),
                SizedBox(
                    height:
                        30.0), // Adjust this value to move the buttons lower
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed:(){
                    Navigator
                        .push(context,MaterialPageRoute(builder: (_) => HomeScreen()));
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
                        onPressed: uploadImageToFirebase,
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
                    )
                  ],
                ),
                SizedBox(width: 50.0),
              ],
            ),
          )
        ],
      ),
    );
  }
}
