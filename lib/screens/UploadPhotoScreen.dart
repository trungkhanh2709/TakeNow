import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:takenow/Class/Globals.dart';

import '../api/apis.dart';

class UploadPhotoScreen extends StatefulWidget {
  final String imagePath;
  const UploadPhotoScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  _UploadPhotoScreenState createState() => _UploadPhotoScreenState();
}

class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _image = File(widget.imagePath);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Photo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!,
                    height:
                        300.0), // Use !_image to access File since it's nullable
            ElevatedButton(
              onPressed: getImage,
              child: Text('Take Picture'),
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  labelText: 'Caption',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: uploadImageToFirebase,
              child: Text('Upload Image'),
            ),
          ],
        ),
      ),
    );
  }
}
