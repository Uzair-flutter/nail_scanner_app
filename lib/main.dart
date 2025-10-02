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
  @override
  _HandScannerScreenState createState() => _HandScannerScreenState();
}

class _HandScannerScreenState extends State<HandScannerScreen>
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
      print('Error taking picture: $e');
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
          // Animated Hand Outline Overlay
          // AnimatedBuilder(
          //   animation: _pulseAnimation,
          //   builder: (context, child) {
          //     return CustomPaint(
          //       // size: Size.infinite,
          //       size: Size(322, 363),
          //       painter: RPSCustomPainter(
          //         // pulseValue: _pulseAnimation.value,
          //       ),
          //     );
          //   },
          // ),

          // Top Instructions Panel
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.3),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                            color: Colors.cyan.withOpacity(0.5),
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

class EnhancedHandOutlinePainter extends CustomPainter {
  final double pulseValue;

  EnhancedHandOutlinePainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Main outline paint with gradient effect
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.8 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Glow effect paint
    final glowPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    // Inner glow
    final innerGlowPaint = Paint()
      ..color = Colors.white.withOpacity(0.5 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dark overlay for focus area
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Create the hand path
    final handPath = _createDetailedHandPath(size);

    // Draw dark overlay with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path.combine(
      PathOperation.difference,
      overlayPath,
      handPath,
    );

    canvas.drawPath(cutoutPath, overlayPaint);

    // Draw multiple glow layers for depth
    for (int i = 3; i > 0; i--) {
      final layerPaint = Paint()
        ..color = Colors.cyan.withOpacity(0.1 * i * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0 - (i * 3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 - i.toDouble());
      canvas.drawPath(handPath, layerPaint);
    }

    // Draw main glow
    canvas.drawPath(handPath, glowPaint);

    // Draw main outline
    canvas.drawPath(handPath, paint);

    // Draw inner glow
    canvas.drawPath(handPath, innerGlowPaint);

    // Add scanning grid effect
    _drawScanningGrid(canvas, size, handPath);

    // Draw alignment guides
    _drawAlignmentGuides(canvas, size);
  }

  Path _createDetailedHandPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width * 0.4; // Slightly larger for better visibility

    // Start from wrist - more realistic proportions
    path.moveTo(centerX - scale * 0.25, centerY + scale * 0.8);

    // Left wrist curve - more natural
    path.cubicTo(
      centerX - scale * 0.28,
      centerY + scale * 0.65,
      centerX - scale * 0.32,
      centerY + scale * 0.45,
      centerX - scale * 0.35,
      centerY + scale * 0.25,
    );

    // Palm left side - more realistic curve
    path.cubicTo(
      centerX - scale * 0.38,
      centerY + scale * 0.05,
      centerX - scale * 0.42,
      centerY - scale * 0.1,
      centerX - scale * 0.45,
      centerY - scale * 0.2,
    );

    // Thumb - anatomically correct positioning
    // Thumb base (web between thumb and index)
    path.cubicTo(
      centerX - scale * 0.48,
      centerY - scale * 0.25,
      centerX - scale * 0.52,
      centerY - scale * 0.3,
      centerX - scale * 0.55,
      centerY - scale * 0.35,
    );

    // Thumb metacarpal
    path.cubicTo(
      centerX - scale * 0.58,
      centerY - scale * 0.4,
      centerX - scale * 0.6,
      centerY - scale * 0.45,
      centerX - scale * 0.62,
      centerY - scale * 0.5,
    );

    // Thumb tip - more rounded and realistic
    path.cubicTo(
      centerX - scale * 0.64,
      centerY - scale * 0.55,
      centerX - scale * 0.65,
      centerY - scale * 0.58,
      centerX - scale * 0.64,
      centerY - scale * 0.6,
    );

    // Thumb tip curve
    path.cubicTo(
      centerX - scale * 0.63,
      centerY - scale * 0.62,
      centerX - scale * 0.6,
      centerY - scale * 0.63,
      centerX - scale * 0.57,
      centerY - scale * 0.62,
    );

    // Thumb inner curve back to hand
    path.cubicTo(
      centerX - scale * 0.54,
      centerY - scale * 0.61,
      centerX - scale * 0.5,
      centerY - scale * 0.58,
      centerX - scale * 0.46,
      centerY - scale * 0.52,
    );

    // Valley between thumb and index finger - deeper and more natural
    path.cubicTo(
      centerX - scale * 0.42,
      centerY - scale * 0.48,
      centerX - scale * 0.38,
      centerY - scale * 0.45,
      centerX - scale * 0.35,
      centerY - scale * 0.42,
    );

    // Index finger - more realistic proportions
    // Index finger base
    path.cubicTo(
      centerX - scale * 0.32,
      centerY - scale * 0.48,
      centerX - scale * 0.3,
      centerY - scale * 0.6,
      centerX - scale * 0.28,
      centerY - scale * 0.72,
    );

    // Index finger middle joint (knuckle)
    path.cubicTo(
      centerX - scale * 0.26,
      centerY - scale * 0.78,
      centerX - scale * 0.24,
      centerY - scale * 0.84,
      centerX - scale * 0.22,
      centerY - scale * 0.88,
    );

    // Index finger tip - more realistic shape
    path.cubicTo(
      centerX - scale * 0.2,
      centerY - scale * 0.92,
      centerX - scale * 0.17,
      centerY - scale * 0.94,
      centerX - scale * 0.14,
      centerY - scale * 0.95,
    );

    // Index finger tip curve
    path.cubicTo(
      centerX - scale * 0.11,
      centerY - scale * 0.96,
      centerX - scale * 0.08,
      centerY - scale * 0.95,
      centerX - scale * 0.06,
      centerY - scale * 0.92,
    );

    // Index finger right side
    path.cubicTo(
      centerX - scale * 0.04,
      centerY - scale * 0.88,
      centerX - scale * 0.03,
      centerY - scale * 0.82,
      centerX - scale * 0.02,
      centerY - scale * 0.72,
    );

    // Valley between index and middle finger
    path.cubicTo(
      centerX - scale * 0.01,
      centerY - scale * 0.62,
      centerX,
      centerY - scale * 0.58,
      centerX + scale * 0.01,
      centerY - scale * 0.55,
    );

    // Middle finger - longest finger, more realistic
    path.cubicTo(
      centerX + scale * 0.02,
      centerY - scale * 0.65,
      centerX + scale * 0.03,
      centerY - scale * 0.8,
      centerX + scale * 0.04,
      centerY - scale * 0.92,
    );

    // Middle finger tip (highest point)
    path.cubicTo(
      centerX + scale * 0.05,
      centerY - scale * 0.98,
      centerX + scale * 0.07,
      centerY - scale * 1.0,
      centerX + scale * 0.1,
      centerY - scale * 1.01,
    );

    // Middle finger tip curve
    path.cubicTo(
      centerX + scale * 0.13,
      centerY - scale * 1.02,
      centerX + scale * 0.16,
      centerY - scale * 1.01,
      centerX + scale * 0.18,
      centerY - scale * 0.98,
    );

    // Middle finger right side
    path.cubicTo(
      centerX + scale * 0.2,
      centerY - scale * 0.92,
      centerX + scale * 0.21,
      centerY - scale * 0.8,
      centerX + scale * 0.22,
      centerY - scale * 0.65,
    );

    // Valley between middle and ring finger
    path.cubicTo(
      centerX + scale * 0.23,
      centerY - scale * 0.58,
      centerX + scale * 0.24,
      centerY - scale * 0.55,
      centerX + scale * 0.25,
      centerY - scale * 0.52,
    );

    // Ring finger - more realistic proportions
    path.cubicTo(
      centerX + scale * 0.27,
      centerY - scale * 0.62,
      centerX + scale * 0.29,
      centerY - scale * 0.75,
      centerX + scale * 0.31,
      centerY - scale * 0.85,
    );

    // Ring finger tip
    path.cubicTo(
      centerX + scale * 0.33,
      centerY - scale * 0.9,
      centerX + scale * 0.35,
      centerY - scale * 0.92,
      centerX + scale * 0.38,
      centerY - scale * 0.93,
    );

    // Ring finger tip curve
    path.cubicTo(
      centerX + scale * 0.41,
      centerY - scale * 0.94,
      centerX + scale * 0.44,
      centerY - scale * 0.93,
      centerX + scale * 0.46,
      centerY - scale * 0.9,
    );

    // Ring finger right side
    path.cubicTo(
      centerX + scale * 0.48,
      centerY - scale * 0.85,
      centerX + scale * 0.49,
      centerY - scale * 0.75,
      centerX + scale * 0.5,
      centerY - scale * 0.62,
    );

    // Valley between ring and pinky finger
    path.cubicTo(
      centerX + scale * 0.51,
      centerY - scale * 0.58,
      centerX + scale * 0.52,
      centerY - scale * 0.55,
      centerX + scale * 0.53,
      centerY - scale * 0.52,
    );

    // Pinky finger - shortest finger, more realistic
    path.cubicTo(
      centerX + scale * 0.55,
      centerY - scale * 0.6,
      centerX + scale * 0.57,
      centerY - scale * 0.7,
      centerX + scale * 0.59,
      centerY - scale * 0.78,
    );

    // Pinky finger tip
    path.cubicTo(
      centerX + scale * 0.61,
      centerY - scale * 0.82,
      centerX + scale * 0.63,
      centerY - scale * 0.84,
      centerX + scale * 0.66,
      centerY - scale * 0.85,
    );

    // Pinky finger tip curve
    path.cubicTo(
      centerX + scale * 0.69,
      centerY - scale * 0.86,
      centerX + scale * 0.72,
      centerY - scale * 0.85,
      centerX + scale * 0.74,
      centerY - scale * 0.82,
    );

    // Pinky finger outer edge
    path.cubicTo(
      centerX + scale * 0.76,
      centerY - scale * 0.78,
      centerX + scale * 0.77,
      centerY - scale * 0.7,
      centerX + scale * 0.78,
      centerY - scale * 0.6,
    );

    // Right side of palm - more natural curve
    path.cubicTo(
      centerX + scale * 0.79,
      centerY - scale * 0.5,
      centerX + scale * 0.78,
      centerY - scale * 0.35,
      centerX + scale * 0.76,
      centerY - scale * 0.2,
    );

    // Right side down to wrist
    path.cubicTo(
      centerX + scale * 0.74,
      centerY - scale * 0.05,
      centerX + scale * 0.7,
      centerY + scale * 0.1,
      centerX + scale * 0.65,
      centerY + scale * 0.25,
    );

    // Right wrist curve
    path.cubicTo(
      centerX + scale * 0.6,
      centerY + scale * 0.4,
      centerX + scale * 0.55,
      centerY + scale * 0.55,
      centerX + scale * 0.5,
      centerY + scale * 0.7,
    );

    // Bottom wrist connection - more natural
    path.cubicTo(
      centerX + scale * 0.4,
      centerY + scale * 0.75,
      centerX + scale * 0.25,
      centerY + scale * 0.78,
      centerX + scale * 0.1,
      centerY + scale * 0.8,
    );

    path.cubicTo(
      centerX - scale * 0.05,
      centerY + scale * 0.82,
      centerX - scale * 0.15,
      centerY + scale * 0.81,
      centerX - scale * 0.25,
      centerY + scale * 0.8,
    );

    path.close();

    return path;
  }

  void _drawScanningGrid(Canvas canvas, Size size, Path handPath) {
    final gridPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.1 * pulseValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Create clipping region for grid
    canvas.save();
    canvas.clipPath(handPath);

    // Draw grid lines
    final gridSpacing = 20.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.restore();
  }

  void _drawAlignmentGuides(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dotPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final guideSize = 30.0;
    final spacing = size.width * 0.4;

    // Corner brackets with dots
    final corners = [
      Offset(centerX - spacing, centerY - spacing * 0.8),
      Offset(centerX + spacing, centerY - spacing * 0.8),
      Offset(centerX - spacing, centerY + spacing * 0.8),
      Offset(centerX + spacing, centerY + spacing * 0.8),
    ];

    for (final corner in corners) {
      // Draw corner brackets
      final isLeft = corner.dx < centerX;
      final isTop = corner.dy < centerY;

      // Horizontal line
      canvas.drawLine(
        corner,
        Offset(corner.dx + (isLeft ? guideSize : -guideSize), corner.dy),
        guidePaint,
      );

      // Vertical line
      canvas.drawLine(
        corner,
        Offset(corner.dx, corner.dy + (isTop ? guideSize : -guideSize)),
        guidePaint,
      );

      // Center dot
      canvas.drawCircle(corner, 3, dotPaint);
    }

    // Draw center crosshair
    final crosshairPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal crosshair line
    canvas.drawLine(
      Offset(centerX - 20, centerY),
      Offset(centerX + 20, centerY),
      crosshairPaint,
    );

    // Vertical crosshair line
    canvas.drawLine(
      Offset(centerX, centerY - 20),
      Offset(centerX, centerY + 20),
      crosshairPaint,
    );

    // Center dot
    canvas.drawCircle(Offset(centerX, centerY), 2, dotPaint);
  }

  @override
  bool shouldRepaint(EnhancedHandOutlinePainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
