import 'dart:io';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/helper/dialogs.dart';
import 'package:takenow/main.dart';
import 'package:takenow/models/chat_user.dart';
import 'package:takenow/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formkey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Profile Screen',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.lightBlue,
            iconTheme: IconThemeData(color: Colors.black),
          ),
      
          //floating button to log out
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton.extended(
              onPressed: () async {
                Dialogs.showProcessBar(context);

                await APIs.updateActiveStatus(false);

                await APIs.auth.signOut().then((value) async {
                  await GoogleSignIn().signOut().then((value) {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => LoginScreen()));
                  });
                });
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ),
          
          body: Form(
            key: _formkey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(width: mq.width, height: mq.height * .03),
                    //profile picture
                    Stack(
                      children: [
                        //profile picture
                        _image != null ?

                        //local image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(mq.height * .1),
                          child: Image.file(
                            File(_image!),
                            width: mq.height * .2,
                            height: mq.height * .2,
                            fit: BoxFit.cover
                          )):

                        //image from server
                        ClipRRect(
                            borderRadius: BorderRadius.circular(mq.height * .1),
                            child: CachedNetworkImage(
                                width: mq.height * .2,
                                height: mq.height * .2,
                                fit: BoxFit.cover,
                                imageUrl: widget.user.image,
                                errorWidget:(context, url, error) =>
                                    const CircleAvatar(
                                      child: Icon(CupertinoIcons.person)),
                            ),
                        ),

                        //edit image button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: MaterialButton(
                            elevation: 1,
                            onPressed: () {
                              _showBottomSheet();
                            },
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: mq.height * .03),
                    Text(widget.user.email,
                        style: const TextStyle(color: Colors.black54, fontSize: 16)),
                      
                    SizedBox(height: mq.height * .05),
                      
                    // name input field
                    TextFormField(
                      initialValue: widget.user.name,
                      onSaved: (val) => APIs.me.name = val ?? '',
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : 'Required Field',
                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person, color: Colors.blue),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: 'Your Name',
                          label: const Text('Name')),
                    ),
                    SizedBox(height: mq.height * .02),
                      
                    // about input field
                    TextFormField(
                      initialValue: widget.user.about,
                      onSaved: (val) => APIs.me.about = val ?? '',
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : 'Required Field',
                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.info_outline,
                              color: Colors.blue),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          hintText: 'eg. Feeling Happy',
                          label: const Text('About')),
                    ),

                    //for adding some space
                    SizedBox(height: mq.height * .05),

                    //update profile button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        minimumSize: Size(mq.width * .5, mq.height * .06)),
                      onPressed: () {
                        if(_formkey.currentState!.validate()){
                          _formkey.currentState!.save();
                          APIs.updateUserInfo().then((value){
                            Dialogs.showSnackbar(
                              context, 'Profile Updated Successfully!');
                          });
                        }
                      },
                      icon: const Icon(Icons.edit, size: 28),
                      label:
                        const Text('UPDATE', style: TextStyle(fontSize: 16)),
                    )
                  ],
                ),
              ),
            ),
          )),
    );
  }

  void _showBottomSheet(){
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
      return ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
        children: [
          //pick profile picture label
          const Text('Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),

          //for adding some space
          SizedBox(height: mq.height * .02),

          //buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              //pick from gallery button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  fixedSize: Size(mq.width * .3, mq.height * .15)),
                onPressed: () async{
                  final ImagePicker picker = ImagePicker();

                  // Pick an image.
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if(image != null){
                    log('Image Path: ${image.path} -- MimeType" ${image.mimeType}');
                    setState((){
                      _image = image.path;
                    });
                    
                    APIs.updateProfilePicture(File(_image!));
                    //for hiding bottom sheet
                    Navigator.pop(context);
                  }
                },
                child: Image.asset('images/add_image.png')),

              //take picture from camera button
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                      fixedSize: Size(mq.width * .3, mq.height * .15)),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();

                    // Pick an image.
                    final XFile? image =
                        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                    if(image != null){
                      log('Image Path: ${image.path}');
                      setState((){
                        _image = image.path;
                      });

                      APIs.updateProfilePicture(File(_image!));
                      //for hiding bottom sheet
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/camera.png')),
            ],
          )
        ],
      );
    });
  }
}

