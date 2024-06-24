import 'package:cached_network_image/cached_network_image.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile Screen',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.lightBlue,
          iconTheme: IconThemeData(color: Colors.black),
        ),

        //floating button to add new user
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            onPressed: () async {
              Dialogs.showProcessBar(context);
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
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
          child: Column(
            children: [
              SizedBox(width: mq.width, height: mq.height * .03),
              //profile picture
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .1),
                    child: CachedNetworkImage(
                      width: mq.height * .2,
                      height: mq.height * .2,
                      fit: BoxFit.fill,
                      imageUrl: widget.user.image,
                      //placeholder: (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: MaterialButton(
                      elevation: 1,
                      onPressed: () {},
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
                decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.info_outline, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    hintText: 'eg. Feeling Happy',
                    label: const Text('About')),
              ),
              SizedBox(height: mq.height * .03),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.edit),
                label: const Text('UPDATE'),
                style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: Size(mq.width * .5, mq.height * .06),
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white),
              )
            ],
          ),
        ));
  }
}
