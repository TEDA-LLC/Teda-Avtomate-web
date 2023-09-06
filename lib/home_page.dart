import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _LoginPage();
}

class _LoginPage extends State<HomePage> {

  var cameras;
  var firstCamera;

  initCamera() async {
    cameras = await availableCameras();
    firstCamera = cameras.first;
  }

  push(){
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TakePictureScreen(camera: firstCamera)),
    );
  }

  @override
  initState() {
    initCamera();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(55),
        child: Center(
          child: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            actions: [
              InkWell(
                onTap: () async {
                  push();
                },
                child: Row(
                  children: [
                    SizedBox(width: w * 0.03),
                    Container(
                      width: w * 0.03 < 30 ? 30 : w * 0.03,
                      height: w * 0.03 < 30 ? 30: w * 0.03,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo1.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.01),
                    Container(
                      width: w * 0.06,
                      height: h * 0.02,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/text.png'),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100.0,),
              const Text('You have successfully completed your registration'),
              TextButton(
                onPressed: () {
                  push();
                },
                child: const Text('Successfully'),
              )
            ],
          )
        ),
    );
  }
}