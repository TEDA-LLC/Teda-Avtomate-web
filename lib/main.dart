import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'modeels/region_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  String errorMessage = '';

  final TextEditingController _fioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  var region = [];
  var country = [];
  var dropdownCountryList = ['Uzbekistan', 'Russia', 'USA'];
  var countryId = [1, 2, 3];
  int countryIndex = 0;
  var dropdownRegionList = ['Tashkent', 'Moscow', 'New York'];
  var regionId = [1, 2, 3];
  int regionIndex = 0;

  String selectedOption = 'rezident';
  var selectedCountry = 'USA';
  var selectedRegion = 'Tashkent';

  static const String _url = 'https://api.teda.uz:72';
  var _result;

  var _cropImage;

  uploadImage(XFile image) async {
    var formData = FormData();
    var dio = Dio();
    dio.options.headers["X-Api-Key"] = "o347TWgq7GeP4f2cTpp4WG5x";
    try {
      if (kIsWeb) {
        var bytes = await image.readAsBytes();
        formData.files.add(MapEntry("image_file",
            MultipartFile.fromBytes(bytes, filename: "pic-name.jpg")));
      } else {
        formData.files.add(MapEntry(
          "image_file",
          await MultipartFile.fromFile(image.path, filename: "pic-name.jpg"),
        ));
      }
      Response<List<int>> response = await dio.post(
          "https://api.remove.bg/v1.0/removebg",
          data: formData,
          options: Options(responseType: ResponseType.bytes));
      _cropImage = response.data;
      return response.data;
    } catch (e) {
      _cropImage = null;
      showToast('Error', 'Limit is over', Colors.red);
      return "";
    }
  }

  var files;

  showCamera() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CameraPreview(_controller),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.height * 0.05,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.deepPurple[800],
                    ),
                    child: TextButton(
                      onPressed: () {
                        _controller.dispose();
                        Navigator.pop(context);
                        initState();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.02,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.height * 0.05,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.deepPurple[800],
                    ),
                    child: TextButton(
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          final image = await _controller.takePicture();
                          final uploadedImageResp = await uploadImage(image);
                          if (uploadedImageResp.runtimeType == String) {
                            errorMessage = "Failed to upload image";
                            showToast('Error', errorMessage, Colors.red);
                            return;
                          }
                          removeBg(uploadedImageResp, image.path);
                          files = image.path;
                          setState(() {
                            _result = uploadedImageResp;
                          });

                        } catch (e) {
                          pop();
                          showToast('Error', 'Limit is over', Colors.red);
                        }
                      },
                      child: Text(
                        'Take',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.02,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  removeBg(List<int> uploadedImage, String imagePath) {
    Image image;
    if (kIsWeb) {
      image = Image.network(imagePath);
    } else {
      image = Image.file(File(imagePath));
    }
    Widget otherImage;
    try {
      otherImage = Image.memory(Uint8List.fromList(uploadedImage));
    } catch (e) {
      otherImage = const SizedBox.shrink();
    }
    setState(() {
      _result = uploadedImage;
    });
    pop();
  }

  Future<void> addUser() async {
    var request = http.MultipartRequest('POST', Uri.parse('$_url/api/user'));
    request.fields.addAll({
      'fio': _fioController.text,
      'email': _emailController.text,
      'tel': _phoneNumberController.text,
      'lavozim': _positionController.text,
      'tashkilot': _companyNameController.text,
      'img': base64Encode(_result!),
      'countryId': countryId[countryIndex].toString(),
      'regionId': regionId[regionIndex].toString(),
      'resident': selectedOption == 'rezident' ? 'true' : 'false',
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        _result!,
        filename: 'pic-name.png',
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200||response.statusCode == 201) {
      var data = json.decode(await response.stream.bytesToString());
      if (data['success']) {
        showToast('Success', 'User added successfully', Colors.green);
        pushReplacement();
      } else {
        showToast('Error', 'User not added', Colors.red);
      }
    } else {
      showToast('Error', 'User not added', Colors.red);
    }
  }

  Future<void> getRegion() async {
    var response = await http.get(
      Uri.parse(
        '$_url/api/region',
      ),
    );
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      List<RegionModel> regions = [];
      selectedRegion = data['data'][0]['name'];
      dropdownRegionList.clear();
      regionId.clear();
      for (var item in data['data']) {
        regions.add(RegionModel.fromJson(item));
        dropdownRegionList.add(item['name']);
        regionId.add(item['id']);
      }
      setState(() {
        region = regions;
      });
    } else {
      showToast(
          'Error',
          'Region not found ${response.statusCode} : ${response.body}',
          Colors.red);
      setState(() {
        region = [];
      });
    }
  }

  Future<void> getCountry() async {
    var response = await http.get(Uri.parse('$_url/api/country'));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      List<RegionModel> regions = [];
      dropdownCountryList.clear();
      countryId.clear();
      selectedCountry = data['data'][0]['name'];
      for (var item in data['data']) {
        regions.add(RegionModel.fromJson(item));
        dropdownCountryList.add(item['name']);
        countryId.add(item['id']);
      }
      setState(() {
        country = regions;
      });
    } else {
      showToast(
          'Error',
          'Country not found ${response.statusCode} : ${response.body}',
          Colors.red);
      setState(() {
        country = [];
      });
    }
  }


  pushReplacement() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }
  pop() {
    Navigator.pop(context);
  }
  showToast(String title, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        closeIconColor: Colors.white,
        backgroundColor: color,
        showCloseIcon: true,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getRegion();
    getCountry();
    _controller = CameraController(widget.camera, ResolutionPreset.ultraHigh);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fioController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
    _positionController.dispose();
    super.dispose();
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
              Row(
                children: [
                  SizedBox(width: w * 0.03),
                  Container(
                    width: w * 0.04,
                    height: w * 0.04,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Text(
                    'Teda',
                    style: TextStyle(
                      fontSize: w * 0.025,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Expanded(child: SizedBox()),
              IconButton(
                iconSize: w * 0.04,
                onPressed: () {
                },
                icon: const Icon(Icons.language, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SingleChildScrollView(
                child: Column(
              children: [
                SizedBox(height: h * 0.05),
                Text(
                  'Register',
                  style: TextStyle(
                    fontSize: w * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: h * 0.03),
                SizedBox(
                  height: h * 0.22,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: w * 0.4,
                        height: h * 0.3,
                        child: Column(
                          children: [
                            Container(
                              width: w * 0.9,
                              height: h * 0.06,
                              padding: EdgeInsets.only(left: w * 0.005),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[200],
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _fioController,
                                  style: TextStyle(
                                    fontSize: w * 0.02,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'FIO',
                                    hintStyle: TextStyle(
                                      fontSize: w * 0.02,
                                      color: Colors.grey,
                                    ),
                                    prefixIcon: Icon(
                                      size: w * 0.03,
                                      Icons.person,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: h * 0.02),
                            Container(
                              width: w * 0.9,
                              height: h * 0.06,
                              padding: EdgeInsets.only(left: w * 0.005),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[200],
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _emailController,
                                  style: TextStyle(
                                    fontSize: w * 0.02,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Email',
                                    hintStyle: TextStyle(
                                      fontSize: w * 0.02,
                                      color: Colors.grey,
                                    ),
                                    prefixIcon: Icon(
                                      size: w * 0.03,
                                      Icons.email,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: h * 0.02),
                            Container(
                              width: w * 0.9,
                              height: h * 0.06,
                              padding: EdgeInsets.only(left: w * 0.005),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[200],
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _phoneNumberController,
                                  style: TextStyle(
                                    fontSize: w * 0.02,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Phone number',
                                    hintStyle: TextStyle(
                                      fontSize: w * 0.02,
                                      color: Colors.grey,
                                    ),
                                    prefixIcon: Icon(
                                      size: w * 0.03,
                                      Icons.phone,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      SizedBox(
                        width: w * 0.15,
                        height: h * 0.32,
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                showCamera();
                              },
                              child: Container(
                                width: w * 0.15,
                                height: h * 0.22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[200],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_result != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.memory(
                                            Uint8List.fromList(_result),
                                            width: w * 0.15,
                                            height: h * 0.22,
                                            fit: BoxFit.cover),
                                      ),
                                    if (_result == null)
                                      Icon(Icons.camera_alt,
                                          size: w * 0.05, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.02),
                Row(
                  children: [
                    SizedBox(width: w * 0.2),
                    Radio(
                      value: 'rezident',
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                        });
                      },
                    ),
                    Text('Rezident',
                        style: TextStyle(fontSize: w * 0.02, color: Colors.white)),
                    SizedBox(width: w * 0.03),
                    Radio(
                      value: 'nonrezident',
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                        });
                      },
                    ),
                    Text('Nonrezident',
                        style: TextStyle(fontSize: w * 0.02, color: Colors.white)),
                  ],
                ),
                SizedBox(height: h * 0.02),
                if (selectedOption == 'rezident')
                  if (region.isNotEmpty)
                    Container(
                      width: w * 0.585,
                      height: h * 0.06,
                      padding: EdgeInsets.only(left: w * 0.02, right: w * 0.02),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: DropdownButton(
                          underline: const SizedBox(),
                          isExpanded: true,
                          dropdownColor: Colors.grey[200],
                          iconEnabledColor: Colors.black,
                          iconDisabledColor: Colors.black,
                          value: selectedRegion,
                          onChanged: (value) {
                            setState(() {
                              selectedRegion = value.toString();
                              regionIndex = dropdownRegionList.indexOf(value!);
                            });
                          },
                          items: dropdownRegionList.map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: TextStyle(
                                      fontSize: w * 0.02, color: Colors.black)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                if (selectedOption != 'rezident')
                  if (region.isNotEmpty)
                    Container(
                      width: w * 0.585,
                      height: h * 0.06,
                      padding: EdgeInsets.only(left: w * 0.02, right: w * 0.02),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: Center(
                        child: DropdownButton(
                          underline: const SizedBox(),
                          isExpanded: true,
                          dropdownColor: Colors.grey[200],
                          iconEnabledColor: Colors.black,
                          iconDisabledColor: Colors.black,
                          value: selectedCountry,
                          onChanged: (value) {
                            setState(() {
                              selectedCountry = value.toString();
                              countryIndex =
                                  dropdownCountryList.indexOf(value!);
                            });
                          },
                          items: dropdownCountryList.map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: TextStyle(
                                      fontSize: w * 0.02, color: Colors.black)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                if (region.isNotEmpty || country.isNotEmpty)
                  SizedBox(height: h * 0.02),
                Container(
                  width: w * 0.585,
                  height: h * 0.06,
                  padding: EdgeInsets.only(left: w * 0.005, right: w * 0.02),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                  ),
                  child: Center(
                    child: TextField(
                      controller: _companyNameController,
                      style: TextStyle(
                        fontSize: w * 0.02,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Company name',
                        hintStyle: TextStyle(
                          fontSize: w * 0.02,
                          color: Colors.grey,
                        ),
                        prefixIcon: Icon(
                          size: w * 0.03,
                          Icons.business,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h * 0.02),
                Container(
                  width: w * 0.585,
                  height: h * 0.06,
                  padding: EdgeInsets.only(left: w * 0.005, right: w * 0.02),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                  ),
                  child: Center(
                    child: TextField(
                      controller: _positionController,
                      style: TextStyle(
                        fontSize: w * 0.02,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Position',
                        hintStyle: TextStyle(
                          fontSize: w * 0.02,
                          color: Colors.grey,
                        ),
                        prefixIcon: Icon(
                          size: w * 0.03,
                          Icons.work,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h * 0.02),
                Container(
                  width: w * 0.585,
                  height: h * 0.06,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.deepPurple[800],
                  ),
                  child: TextButton(
                    onPressed: () {
                      addUser();
                    },
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontSize: w * 0.02,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: h * 0.02),
              ],
            ));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
