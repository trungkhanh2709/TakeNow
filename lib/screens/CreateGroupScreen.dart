import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:takenow/Class/Globals.dart';

class CreateGroupScreen extends StatefulWidget {
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  String userId = Globals.getGoogleUserId().toString();
  String groupName = '';
  Set<String> groupMembers = {};
  List<Map<String, dynamic>> friendsList = [];
  File? _groupImage;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchFriendsList();
  }

  Future<void> fetchFriendsList() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (userDoc.exists) {
      List<String> friendsIds = List<String>.from(userDoc['friends']);
      List<Map<String, dynamic>> tempFriendsList = [];
      for (String friendId in friendsIds) {
        DocumentSnapshot friendDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .get();
        if (friendDoc.exists) {
          tempFriendsList.add({
            'id': friendDoc.id,
            'name': friendDoc['name'],
            'image': friendDoc['image'],
          });
        }
      }
      setState(() {
        friendsList = tempFriendsList;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _groupImage = File(pickedFile.path);
      });
    }
  }

  Future<void> createGroup() async {
    if (_formKey.currentState!.validate()) {
      if (groupMembers.length < 2) {
        Fluttertoast.showToast(
          msg: 'Please add at least 2 members to the group.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      String imageUrl = '';
      if (_groupImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('group_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(_groupImage!);
        final snapshot = await uploadTask.whenComplete(() => {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('groups').add({
        'userId': userId,
        'nameOfGroup': groupName,
        'members': groupMembers.toList(),
        'image': imageUrl,
      });

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the screen after creating the group
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2F2E2E),
        title: Text('Create Group'),
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Refund_back_light.svg',
            width: 30,
            height: 30,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Color(0xFF2F2E2E),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    leading: Icon(Icons.camera),
                                    title: Text('Take a picture'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.photo_library),
                                    title: Text('Choose from gallery'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Stack(
                        children: [
                          Container(
                            height: 210,
                            width: 210,
                            padding: EdgeInsets.all(5), // Padding to create the border
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.purple, width: 5),
                            ),
                            child: ClipOval(
                              child: _groupImage != null
                                  ? Image.file(
                                _groupImage!,
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              )
                                  : Center(
                                child: Icon(Icons.add, size: 50, color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.edit, color: Colors.white),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            ListTile(
                                              leading: Icon(Icons.camera),
                                              title: Text('Take a picture'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImage(ImageSource.camera);
                                              },
                                            ),
                                            ListTile(
                                              leading: Icon(Icons.photo_library),
                                              title: Text('Choose from gallery'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _pickImage(ImageSource.gallery);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Group Name', labelStyle: TextStyle(color: Colors.white)),
                    style: TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        groupName = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        Fluttertoast.showToast(
                          msg: 'Please enter a group name',
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.CENTER,
                        );
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: friendsList.length,
                      itemBuilder: (context, index) {
                        final friend = friendsList[index];
                        final isSelected = groupMembers.contains(friend['id']);

                        return ListTile(
                          leading: friend['image'].isNotEmpty
                              ? ClipOval(
                            child: Image.network(
                              friend['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                              : ClipOval(
                            child: Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                          title: Text(friend['name'], style: TextStyle(color: Colors.white)),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  groupMembers.add(friend['id']);
                                } else {
                                  groupMembers.remove(friend['id']);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: TextButton(
                        onPressed: groupName.isNotEmpty && groupMembers.length >= 2
                            ? createGroup
                            : () {
                          Fluttertoast.showToast(
                            msg: 'Please enter a group name and add at least 2 members.',
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFF2F2E2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                          child: Text(
                            'Create Group',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Stack(
              children: [
                ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.5)),
                Center(child: CircularProgressIndicator()),
              ],
            ),
        ],
      ),
    );
  }
}
