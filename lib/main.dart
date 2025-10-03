// main.dart
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'hand_frame.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hand Scanner',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: HandScannerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HandScannerScreen extends StatefulWidget {
  const HandScannerScreen({super.key});

  @override
  HandScannerScreenState createState() => HandScannerScreenState();
}

class HandScannerScreenState extends State<HandScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCapturing = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for pulsing effect
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_cameras.isNotEmpty) {
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _initializeControllerFuture = _controller!.initialize();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;

      final XFile image = await _controller!.takePicture();

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = path.join(
        appDir.path,
        'hand_scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await File(image.path).copy(imagePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Hand scanned successfully!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_controller != null)
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return SizedBox.expand(child: CameraPreview(_controller!));
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.cyan),
                        SizedBox(height: 20),
                        Text(
                          'Initializing Camera...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }
              },
            )
          else
            Center(
              child: Text(
                'No camera available',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          Positioned(
            left: MediaQuery.sizeOf(context).width * 0.5,
            top: (MediaQuery.sizeOf(context).height / 2) - (363 / 2),
            child: CustomPaint(
              // size: Size.infinite,
              size: Size(322, 363),
              painter: RPSCustomPainter(
                // pulseValue: _pulseAnimation.value,
              ),
            ),
          ),
          //  Animated Hand Outline Overlay
          // Positioned(
          //   left: MediaQuery.sizeOf(context).width * 0.5,
          //   top: (MediaQuery.sizeOf(context).height / 2) - (363 / 2),
          //   child: AnimatedBuilder(
          //     animation: _pulseAnimation,
          //     builder: (context, child) {
          //       return CustomPaint(
          //         // size: Size.infinite,
          //         size: Size(322, 363),
          //         painter: RPSCustomPainter(
          //           // pulseValue: _pulseAnimation.value,
          //         ),
          //       );
          //     },
          //   ),
          // ),

          // Top Instructions Panel
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.cyan.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.pan_tool_outlined, color: Colors.cyan, size: 30),
                  SizedBox(height: 8),
                  Text(
                    'Place Your Hand',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Align your hand within the glowing outline',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(bottom: 30, top: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Capture Button
                  GestureDetector(
                    onTap: _isCapturing ? null : _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.cyan.shade400, Colors.cyan.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCapturing
                                  ? Colors.grey.shade800
                                  : Colors.white,
                            ),
                            child: _isCapturing
                                ? Padding(
                                    padding: EdgeInsets.all(15),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.cyan,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 30,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    _isCapturing ? 'Capturing...' : 'Tap to Scan',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
