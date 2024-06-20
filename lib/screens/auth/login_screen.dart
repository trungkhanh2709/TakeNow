import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:takenow/main.dart';
import 'package:takenow/screens/home_Screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});


  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool _isAnimate = false;
  @override
  void initState() {
    super.initState();
      Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }

  _handleGoogleBtnClick(){
    _signInWithGoogle().then((user){
      log('\nUser: ${user.user}');
      log('\nUserAdditionalInfor: ${user.additionalUserInfo}');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));

    });
  }
  Future<UserCredential> _signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Login'),
      ),
      body: Stack(children: [
        AnimatedPositioned(
            top: mq.height * .15,
            right: _isAnimate ? mq.width *.25: -mq.width * .5,
            width: mq.width * .5,
            duration: const Duration(seconds: 1),
            child: Image.asset("images/LogoRemoveBackground.png")),
        Positioned(
            bottom: mq.height * .15,
            left: mq.width * .05,
            width: mq.width * .9,
            height: mq.height * .07,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const StadiumBorder(),
                elevation: 1),
              onPressed: () {
                _handleGoogleBtnClick();
              },
              icon: Image.asset('images/google-logo.png', height: mq.height * .05 ,),
              label: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.white),
                  children:[
                    TextSpan(text: 'Sign In with '),
                    TextSpan(
                        text: 'Google ',
                        style: TextStyle(
                            fontWeight: FontWeight.w500)
                    ),
                  ]

                ),
              ),
            ))
      ],
      ),
    );
  }
}