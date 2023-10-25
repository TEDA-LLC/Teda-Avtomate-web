import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'package:image_picker/image_picker.dart';
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
  bool? sendData = false;

  static const String _url = 'https://api.teda.uz:72';
  var _result;

  var _cropImage;

  Uint8List? files;

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
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.04 < 20
                        ? 20
                        : MediaQuery.of(context).size.width * 0.03,
                    height: MediaQuery.of(context).size.height * 0.04 < 20
                        ? 20
                        : MediaQuery.of(context).size.height * 0.03,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Colors.deepPurple[800],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: InkWell(
                        onTap: () {
                          _controller.dispose();
                          pop();
                          initState();
                        },
                        child: Center(
                          child: Icon(
                            size: MediaQuery.of(context).size.width * 0.02,
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
                        showFileSelect();
                      },
                      child: Text(
                        'Select',
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
                          final XFile photo = await _controller.takePicture();
                          files = await photo.readAsBytes();
                          setState(() {
                            _result = files;
                          });
                          pop();
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

  showFileSelect() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    _result = await image!.readAsBytes();
    files = await image.readAsBytes();
    setState(() {
    });
    pop();
  }


  Future<void> addUser() async {
    setState(() {
      sendData = true;
    });
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
    /*request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        _result!,
        filename: 'pic-name.png',
      ),
    );*/
    //_result == blob files to Uint8List

    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        _result!,
        filename: 'pic-name.png',
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
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
    sendData = false;
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

  push() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => TakePictureScreen(camera: widget.camera)),
    );
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
    var cardHeight = h < 500
        ? h * 1.2
        : w * 0.7 < 600
            ? w * 0.7
            : w * 0.5 < 600
                ? w * 0.6
                : w * 0.3 < 600
                    ? w * 0.5
                    : w * 0.2;
    var cardWidth = w < 500
        ? w * 0.8
        : w * 0.5 < 600
            ? w * 0.5
            : w * 0.3 < 600
                ? w * 0.3
                : w * 0.2;
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
                      height: w * 0.03 < 30 ? 30 : w * 0.03,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.01),
                    SizedBox(
                      width: w * 0.06 < 60 ? 60 : w * 0.06,
                      height: h * 0.02 < 20 ? 20 : h * 0.02,
                      child: Center(
                        child: Text(
                          'Teda',
                          style: TextStyle(
                            fontSize: w * 0.02 < 20 ? 20 : w * 0.02,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
      body: Container(
        height: w * 1.5,
        width: w,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fon_0.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: h * 0.05),
            Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xff23568c),
                shape: BoxShape.rectangle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Column(
                        children: [
                          SizedBox(height: cardHeight * 0.03),
                          Text(
                            'Registration',
                            style: TextStyle(
                              fontSize: cardWidth * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          //CircleAvatar for image
                          SizedBox(height: cardHeight * 0.03),
                          InkWell(
                            onTap: () {
                              showCamera();
                            },
                            child: Container(
                              width: cardWidth * 0.25,
                              height: cardWidth * 0.25,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1000),
                                color: Colors.white,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_result != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(1000),
                                      child: Image.memory(
                                        _result!,
                                        width: cardWidth * 0.25,
                                        height: cardWidth * 0.25,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if (files == null)
                                    Icon(Icons.camera_alt,
                                        size: cardWidth * 0.05,
                                        color: Colors.grey),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: h * 0.03),
                          Container(
                            width: cardWidth * 0.9,
                            height: cardHeight * 0.06,
                            padding: EdgeInsets.only(left: cardWidth * 0.005),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: TextField(
                                controller: _fioController,
                                style: TextStyle(
                                  fontSize: cardWidth * 0.04,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Full name',
                                  hintStyle: TextStyle(
                                    fontSize: cardWidth * 0.04,
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: Icon(
                                    size: cardWidth * 0.05,
                                    Icons.person,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: cardHeight * 0.02),
                          Container(
                            width: cardWidth * 0.9,
                            height: cardHeight * 0.06,
                            padding: EdgeInsets.only(left: cardWidth * 0.005),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: TextField(
                                controller: _emailController,
                                style: TextStyle(
                                  fontSize: cardWidth * 0.04,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Email',
                                  hintStyle: TextStyle(
                                    fontSize: cardWidth * 0.04,
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: Icon(
                                    size: cardWidth * 0.05,
                                    Icons.email,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: cardHeight * 0.02),
                          Container(
                            width: cardWidth * 0.9,
                            height: cardHeight * 0.06,
                            padding: EdgeInsets.only(left: cardWidth * 0.005),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: TextField(
                                controller: _phoneNumberController,
                                style: TextStyle(
                                  fontSize: cardWidth * 0.04,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Phone number',
                                  hintStyle: TextStyle(
                                    fontSize: cardWidth * 0.04,
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: Icon(
                                    size: cardWidth * 0.05,
                                    Icons.phone,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: cardHeight * 0.02),
                          //rezident or non-rezident
                          SizedBox(
                            width: cardWidth * 0.9,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Radio(
                                  value: 'rezident',
                                  groupValue: selectedOption,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedOption = value!;
                                    });
                                  },
                                ),
                                Text('Resident',
                                    style: TextStyle(
                                        fontSize: cardWidth * 0.04,
                                        color: Colors.white)),
                                SizedBox(width: cardWidth * 0.03),
                                Radio(
                                  value: 'nonrezident',
                                  groupValue: selectedOption,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedOption = value!;
                                    });
                                  },
                                ),
                                Text('Non-resident',
                                    style: TextStyle(
                                        fontSize: cardWidth * 0.04,
                                        color: Colors.white)),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ),
                          SizedBox(height: cardHeight * 0.02),
                          if (selectedOption == 'rezident')
                            if (region.isNotEmpty)
                              Container(
                                width: cardWidth * 0.9,
                                height: cardHeight * 0.06,
                                padding: EdgeInsets.only(
                                    left: cardWidth * 0.02,
                                    right: cardWidth * 0.02),
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
                                        regionIndex =
                                            dropdownRegionList.indexOf(value!);
                                      });
                                    },
                                    items: dropdownRegionList.map((e) {
                                      return DropdownMenuItem(
                                        value: e,
                                        child: Text(e,
                                            style: TextStyle(
                                                fontSize: cardWidth * 0.04,
                                                color: Colors.black)),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                          if (selectedOption != 'rezident')
                            if (region.isNotEmpty)
                              Container(
                                width: cardWidth * 0.9,
                                height: cardHeight * 0.06,
                                padding: EdgeInsets.only(
                                    left: cardWidth * 0.02,
                                    right: cardWidth * 0.02),
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
                                                fontSize: cardWidth * 0.04,
                                                color: Colors.black)),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                          if (region.isNotEmpty || country.isNotEmpty)
                            SizedBox(height: cardHeight * 0.02),
                          Container(
                            width: cardWidth * 0.9,
                            height: cardHeight * 0.06,
                            padding: EdgeInsets.only(
                                left: cardWidth * 0.005,
                                right: cardWidth * 0.02),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: TextField(
                                controller: _companyNameController,
                                style: TextStyle(
                                  fontSize: cardWidth * 0.04,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Company name',
                                  hintStyle: TextStyle(
                                    fontSize: cardWidth * 0.04,
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: Icon(
                                    size: cardWidth * 0.05,
                                    Icons.business,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: cardHeight * 0.02),
                          Container(
                            width: cardWidth * 0.9,
                            height: cardHeight * 0.06,
                            padding: EdgeInsets.only(
                                left: cardWidth * 0.005,
                                right: cardWidth * 0.02),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: Center(
                              child: TextField(
                                controller: _positionController,
                                style: TextStyle(
                                  fontSize: cardWidth * 0.04,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Position',
                                  hintStyle: TextStyle(
                                    fontSize: cardWidth * 0.04,
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: Icon(
                                    size: cardWidth * 0.05,
                                    Icons.work,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: cardHeight * 0.02),
                          //sendData == false
                          if (!sendData!)
                            Container(
                              width: cardWidth * 0.9,
                              height: cardHeight * 0.06,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.blue),
                              child: TextButton(
                                onPressed: () {
                                  if (_fioController.text.isEmpty) {
                                    showToast(
                                        'Error', 'FIO is empty', Colors.red);
                                    return;
                                  }
                                  if (_emailController.text.isEmpty) {
                                    showToast(
                                        'Error', 'Email is empty', Colors.red);
                                    return;
                                  }
                                  if (_phoneNumberController.text.isEmpty) {
                                    showToast('Error', 'Phone number is empty',
                                        Colors.red);
                                    return;
                                  }
                                  if (_companyNameController.text.isEmpty) {
                                    showToast('Error', 'Company name is empty',
                                        Colors.red);
                                    return;
                                  }
                                  if (_positionController.text.isEmpty) {
                                    showToast('Error', 'Position is empty',
                                        Colors.red);
                                    return;
                                  }
                                  if (_result == null) {
                                    showToast(
                                        'Error', 'Image is empty', Colors.red);
                                    return;
                                  }
                                  addUser();
                                },
                                child: Text(
                                  'Send',
                                  style: TextStyle(
                                    fontSize: cardWidth * 0.04,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (sendData!)
                            Container(
                                width: cardWidth * 0.9,
                                height: cardHeight * 0.06,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.blue),
                                child: const SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: Center(
                                      child: CircularProgressIndicator(
                                    color: Colors.black,
                                    backgroundColor: Colors.white,
                                  )),
                                )),
                        ],
                      );
                    } else {
                      return Center(
                          child: Card(
                        shadowColor: Colors.black,
                        color: Colors.white,
                        shape: const RoundedRectangleBorder(
                          side: BorderSide(color: Colors.white70, width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        elevation: 10,
                        child: Container(
                          padding: EdgeInsets.all(cardWidth * 0.05),
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ));
                    }
                  }),
            ),
            SizedBox(height: cardHeight * 0.05),
          ],
        )),
      ),
    );
  }
}
