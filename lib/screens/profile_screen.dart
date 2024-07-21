import 'dart:io';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:takenow/api/apis.dart';
import 'package:takenow/helper/dialogs.dart';
import 'package:takenow/main.dart';
import 'package:takenow/models/chat_user.dart';
import 'package:takenow/screens/FriendRequestsScreen.dart';
import 'package:takenow/screens/FriendSearchScreen.dart';
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
        backgroundColor: Color(0xFF2F2E2E),
        appBar: AppBar(
          title: const Text(
            'Profile Screen',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF2F2E2E), // Màu nền cho AppBar
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/Refund_back_light.svg',
              width: 30,
              height: 30,
            ),
            onPressed: () {
              Navigator.pop(context); // Quay về màn hình trước đó (homescreen)
            },
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            onPressed: () async {
              Dialogs.showProcessBar(context);
              await APIs.updateActiveStatus(false);
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
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
                  _buildProfilePicture(),
                  SizedBox(height: mq.height * .03),
                  Text(widget.user.email,
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(height: mq.height * .05),
                  _buildTextInputFields(),
                  SizedBox(height: mq.height * .05),
                  _buildUpdateButton(),
                  SizedBox(height: mq.height * 0.05),
                  _buildFriendButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        _image != null
            ? ClipRRect(
            borderRadius: BorderRadius.circular(mq.height * .1),
            child: Image.file(File(_image!),
                width: mq.height * .2,
                height: mq.height * .2,
                fit: BoxFit.cover))
            : ClipRRect(
          borderRadius: BorderRadius.circular(mq.height * .1),
          child: CachedNetworkImage(
            width: mq.height * .2,
            height: mq.height * .2,
            fit: BoxFit.cover,
            imageUrl: widget.user.image,
            errorWidget: (context, url, error) =>
            const CircleAvatar(child: Icon(CupertinoIcons.person)),
          ),
        ),
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
        ),
      ],
    );
  }

  Widget _buildTextInputFields() {
    return Column(
      children: [
        TextFormField(
          initialValue: widget.user.name,
          onSaved: (val) => APIs.me.name = val ?? '',
          validator: (val) =>
            val != null && val.isNotEmpty ? null : 'Required Field',
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: 'Your Name',
            hintStyle: const TextStyle(color: Colors.white),
            label: const Text('Name', style: TextStyle(color: Colors.white)),
          ),
        ),
        SizedBox(height: mq.height * .02),
        TextFormField(
          initialValue: widget.user.about,
          onSaved: (val) => APIs.me.about = val ?? '',
          validator: (val) =>
            val != null && val.isNotEmpty ? null : 'Required Field',
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.info_outline, color: Colors.blue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: 'eg. Feeling Happy',
            hintStyle: const TextStyle(color: Colors.white),
            label: const Text('About', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: Size(mq.width * .4, mq.height * .06),
      ),
      onPressed: () {
        if (_formkey.currentState!.validate()) {
          _formkey.currentState!.save();
          APIs.updateUserInfo().then((value) {
            Dialogs.showSnackbar(context, 'Profile Updated Successfully!');
          });
        }
      },
      icon: const Icon(Icons.edit, size: 24),
      label: const Text('Update', style: TextStyle(fontSize: 15)),
    );
  }

  Widget _buildFriendButtons() {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: Size(mq.width * .4, mq.height * .06),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendSearchScreen(),
              ),
            );
          },
          child: const Text('Search For Friends', style: TextStyle(fontSize: 15)),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: Size(mq.width * .4, mq.height * .06),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendRequestsScreen(),
              ),
            );
          },
          child: const Text('Friend Request', style: TextStyle(fontSize: 15)),
        ),
      ],
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
          children: [
            const Text(
              'Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: mq.height * .02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .3, mq.height * .15),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      log('Image Path: ${image.path} -- MimeType" ${image.mimeType}');
                      setState(() {
                        _image = image.path;
                      });
                      APIs.updateProfilePicture(File(_image!));
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/add_image.png'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .3, mq.height * .15),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      log('Image Path: ${image.path}');
                      setState(() {
                        _image = image.path;
                      });
                      APIs.updateProfilePicture(File(_image!));
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/camera.png'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }


}