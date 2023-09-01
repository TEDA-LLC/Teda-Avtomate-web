import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _LoginPage();
}

class _LoginPage extends State<HomePage> {
  late final cameras;

  initCamera() async {
    cameras = await availableCameras();
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakePictureScreen(camera: cameras.first),
                    ),
                  );
                },
                child: const Text('register'),
              )
            ],
          )
        ),
    );
  }
}