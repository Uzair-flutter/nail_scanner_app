// List<CameraDescription> cameras = [];
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   try {
//     cameras = await availableCameras();
//   } catch (e) {
//     print('Error: $e');
//   }
//   runApp(const NailScannerApp());
// }
//
// class NailScannerApp extends StatelessWidget {
//   const NailScannerApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Hand Nail Scanner',
//       theme: ThemeData.dark(),
//       debugShowCheckedModeBanner: false,
//       home: const CameraScannerScreen(),
//     );
//   }
// }
//
// class CameraScannerScreen extends StatefulWidget {
//   const CameraScannerScreen({Key? key}) : super(key: key);
//
//   @override
//   State<CameraScannerScreen> createState() => _CameraScannerScreenState();
// }
//
// class _CameraScannerScreenState extends State<CameraScannerScreen>
//     with SingleTickerProviderStateMixin {
//   CameraController? _cameraController;
//   bool _isCameraInitialized = false;
//   late AnimationController _pulseController;
//   String? selectedFinger;
//   bool isScanning = false;
//
//   final List<FingerData> fingers = [
//     FingerData('thumb', 'Thumb', Colors.cyan),
//     FingerData('index', 'Index', Colors.blue),
//     FingerData('middle', 'Middle', Colors.purple),
//     FingerData('ring', 'Ring', Colors.orange),
//     FingerData('pinky', 'Pinky', Colors.teal),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat(reverse: true);
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     if (cameras.isEmpty) {
//       print('No cameras available');
//       return;
//     }
//
//     _cameraController = CameraController(
//       cameras[0],
//       ResolutionPreset.high,
//       enableAudio: false,
//     );
//
//     try {
//       await _cameraController!.initialize();
//       if (mounted) {
//         setState(() {
//           _isCameraInitialized = true;
//         });
//       }
//     } catch (e) {
//       print('Error initializing camera: $e');
//     }
//   }
//
//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     _pulseController.dispose();
//     super.dispose();
//   }
//
//   void _selectFinger(String fingerId) {
//     setState(() {
//       selectedFinger = fingerId;
//       isScanning = true;
//     });
//
//     Future.delayed(const Duration(milliseconds: 2000), () {
//       if (mounted) {
//         setState(() {
//           isScanning = false;
//         });
//       }
//     });
//   }
//
//   Future<void> _takePicture() async {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return;
//     }
//
//     try {
//       final image = await _cameraController!.takePicture();
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Image captured: ${image.path}'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error taking picture: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Camera Preview
//           if (_isCameraInitialized && _cameraController != null)
//             Positioned.fill(child: CameraPreview(_cameraController!))
//           else
//             const Center(
//               child: CircularProgressIndicator(color: Color(0xFF00ff88)),
//             ),
//
//           // Hand Stroke Overlay
//           Positioned.fill(
//             child: AnimatedBuilder(
//               animation: _pulseController,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: HandStrokePainter(
//                     selectedFinger: selectedFinger,
//                     pulseAnimation: _pulseController.value,
//                     isScanning: isScanning,
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           // Top Instruction
//           Positioned(
//             top: 50,
//             left: 20,
//             right: 20,
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: const Color(0xFF00ff88).withOpacity(0.5),
//                   width: 2,
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.pan_tool, color: Color(0xFF00ff88), size: 24),
//                       SizedBox(width: 10),
//                       Text(
//                         'Position your hand in the frame',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                   if (selectedFinger != null) ...[
//                     const SizedBox(height: 8),
//                     Text(
//                       'Scanning: ${fingers.firstWhere((f) => f.id == selectedFinger).name}',
//                       style: const TextStyle(
//                         color: Color(0xFF00ff88),
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//
//           // Bottom Controls
//           Positioned(
//             bottom: 30,
//             left: 20,
//             right: 20,
//             child: Column(
//               children: [
//                 // Finger Selector
//                 SizedBox(
//                   height: 80,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: fingers.length,
//                     itemBuilder: (context, index) {
//                       final finger = fingers[index];
//                       final isSelected = selectedFinger == finger.id;
//                       return GestureDetector(
//                         onTap: () => _selectFinger(finger.id),
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(horizontal: 6),
//                           padding: const EdgeInsets.all(10),
//                           width: 80,
//                           decoration: BoxDecoration(
//                             color: isSelected
//                                 ? finger.color.withOpacity(0.4)
//                                 : Colors.black.withOpacity(0.7),
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                               color: isSelected
//                                   ? finger.color
//                                   : Colors.white.withOpacity(0.3),
//                               width: 2,
//                             ),
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.fingerprint,
//                                 color: finger.color,
//                                 size: 30,
//                               ),
//                               const SizedBox(height: 6),
//                               Text(
//                                 finger.name,
//                                 style: TextStyle(
//                                   color: isSelected
//                                       ? Colors.white
//                                       : Colors.white70,
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Capture Button
//                 GestureDetector(
//                   onTap: _takePicture,
//                   child: Container(
//                     width: 70,
//                     height: 70,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF00ff88),
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: const Color(0xFF00ff88).withOpacity(0.5),
//                           blurRadius: 20,
//                           spreadRadius: 3,
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.camera_alt,
//                       size: 35,
//                       color: Colors.black,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class HandStrokePainter extends CustomPainter {
//   final String? selectedFinger;
//   final double pulseAnimation;
//   final bool isScanning;
//
//   HandStrokePainter({
//     required this.selectedFinger,
//     required this.pulseAnimation,
//     required this.isScanning,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
//
//     // Define nail positions based on the reference image
//     final nailPositions = [
//       NailPosition('pinky', centerX - 110, centerY - 120, 26, 40, -0.15),
//       NailPosition('ring', centerX - 55, centerY - 140, 28, 44, -0.05),
//       NailPosition('middle', centerX, centerY - 150, 30, 48, 0),
//       NailPosition('index', centerX + 60, centerY - 135, 28, 44, 0.08),
//       NailPosition('thumb', centerX + 130, centerY - 30, 34, 42, 1.2),
//     ];
//
//     // Draw hand outline stroke
//     _drawHandStroke(canvas, centerX, centerY);
//
//     // Draw nail frames
//     for (var nail in nailPositions) {
//       _drawNailFrame(canvas, nail);
//     }
//   }
//
//   void _drawHandStroke(Canvas canvas, double centerX, double centerY) {
//     final strokePaint = Paint()
//       ..color = Colors.white.withOpacity(0.4)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3
//       ..strokeCap = StrokeCap.round
//       ..strokeJoin = StrokeJoin.round;
//
//     final handPath = Path();
//
//     // Start from bottom left of pinky
//     handPath.moveTo(centerX - 130, centerY - 50);
//
//     // Pinky finger outline
//     handPath.lineTo(centerX - 130, centerY - 100);
//     handPath.quadraticBezierTo(
//       centerX - 130,
//       centerY - 140,
//       centerX - 110,
//       centerY - 160,
//     );
//     handPath.lineTo(centerX - 110, centerY - 180);
//     handPath.lineTo(centerX - 90, centerY - 180);
//     handPath.lineTo(centerX - 90, centerY - 160);
//     handPath.quadraticBezierTo(
//       centerX - 80,
//       centerY - 140,
//       centerX - 80,
//       centerY - 100,
//     );
//
//     // Ring finger
//     handPath.lineTo(centerX - 80, centerY - 80);
//     handPath.lineTo(centerX - 75, centerY - 100);
//     handPath.quadraticBezierTo(
//       centerX - 70,
//       centerY - 160,
//       centerX - 55,
//       centerY - 180,
//     );
//     handPath.lineTo(centerX - 55, centerY - 200);
//     handPath.lineTo(centerX - 35, centerY - 200);
//     handPath.lineTo(centerX - 35, centerY - 180);
//     handPath.quadraticBezierTo(
//       centerX - 25,
//       centerY - 160,
//       centerX - 20,
//       centerY - 100,
//     );
//
//     // Middle finger
//     handPath.lineTo(centerX - 20, centerY - 80);
//     handPath.lineTo(centerX - 15, centerY - 110);
//     handPath.lineTo(centerX - 15, centerY - 210);
//     handPath.lineTo(centerX + 15, centerY - 210);
//     handPath.lineTo(centerX + 15, centerY - 110);
//     handPath.lineTo(centerX + 20, centerY - 80);
//
//     // Index finger
//     handPath.lineTo(centerX + 20, centerY - 100);
//     handPath.quadraticBezierTo(
//       centerX + 25,
//       centerY - 155,
//       centerX + 40,
//       centerY - 180,
//     );
//     handPath.lineTo(centerX + 40, centerY - 195);
//     handPath.lineTo(centerX + 60, centerY - 195);
//     handPath.lineTo(centerX + 60, centerY - 180);
//     handPath.quadraticBezierTo(
//       centerX + 70,
//       centerY - 155,
//       centerX + 75,
//       centerY - 100,
//     );
//
//     // Connect to palm
//     handPath.lineTo(centerX + 75, centerY - 50);
//     handPath.lineTo(centerX + 90, centerY - 30);
//
//     // Thumb
//     handPath.lineTo(centerX + 110, centerY - 20);
//     handPath.quadraticBezierTo(
//       centerX + 150,
//       centerY - 10,
//       centerX + 165,
//       centerY + 10,
//     );
//     handPath.lineTo(centerX + 165, centerY + 30);
//     handPath.lineTo(centerX + 145, centerY + 30);
//     handPath.lineTo(centerX + 145, centerY + 10);
//     handPath.quadraticBezierTo(
//       centerX + 135,
//       centerY - 5,
//       centerX + 110,
//       centerY + 5,
//     );
//
//     // Palm bottom
//     handPath.lineTo(centerX + 85, centerY + 30);
//     handPath.quadraticBezierTo(
//       centerX + 40,
//       centerY + 100,
//       centerX - 40,
//       centerY + 100,
//     );
//     handPath.quadraticBezierTo(
//       centerX - 85,
//       centerY + 100,
//       centerX - 110,
//       centerY + 30,
//     );
//     handPath.lineTo(centerX - 130, centerY - 50);
//
//     canvas.drawPath(handPath, strokePaint);
//
//     // Draw palm lines
//     final palmLinePaint = Paint()
//       ..color = Colors.white.withOpacity(0.25)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2
//       ..strokeCap = StrokeCap.round;
//
//     // Life line
//     final lifeLine = Path();
//     lifeLine.moveTo(centerX - 60, centerY);
//     lifeLine.quadraticBezierTo(
//       centerX - 40,
//       centerY + 50,
//       centerX - 10,
//       centerY + 70,
//     );
//     canvas.drawPath(lifeLine, palmLinePaint);
//
//     // Heart line
//     final heartLine = Path();
//     heartLine.moveTo(centerX - 70, centerY + 10);
//     heartLine.quadraticBezierTo(centerX, centerY, centerX + 60, centerY + 10);
//     canvas.drawPath(heartLine, palmLinePaint);
//   }
//
//   void _drawNailFrame(Canvas canvas, NailPosition nail) {
//     final isActive = selectedFinger == nail.id;
//     final frameColor = isActive
//         ? const Color(0xFF00ff88)
//         : const Color(0xFF4a90e2);
//     final opacity = isActive ? (0.6 + pulseAnimation * 0.4) : 0.5;
//
//     canvas.save();
//     canvas.translate(nail.x, nail.y);
//     canvas.rotate(nail.rotation);
//
//     // Glow effect for active nail
//     if (isActive) {
//       final glowPaint = Paint()
//         ..color = frameColor.withOpacity(0.3)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 12
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
//
//       canvas.drawRRect(
//         RRect.fromRectAndRadius(
//           Rect.fromCenter(
//             center: Offset.zero,
//             width: nail.width + 20,
//             height: nail.height + 20,
//           ),
//           const Radius.circular(15),
//         ),
//         glowPaint,
//       );
//     }
//
//     // Main frame
//     final framePaint = Paint()
//       ..color = frameColor.withOpacity(opacity)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = isActive ? 3 : 2;
//
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(
//         Rect.fromCenter(
//           center: Offset.zero,
//           width: nail.width + 16,
//           height: nail.height + 16,
//         ),
//         const Radius.circular(14),
//       ),
//       framePaint,
//     );
//
//     // Corner brackets
//     final bracketPaint = Paint()
//       ..color = frameColor
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3
//       ..strokeCap = StrokeCap.round;
//
//     final hw = (nail.width + 16) / 2;
//     final hh = (nail.height + 16) / 2;
//     final len = 12.0;
//
//     // Draw 4 corner brackets
//     final corners = [
//       [Offset(-hw, -hh), Offset(-hw + len, -hh), Offset(-hw, -hh + len)],
//       [Offset(hw, -hh), Offset(hw - len, -hh), Offset(hw, -hh + len)],
//       [Offset(-hw, hh), Offset(-hw + len, hh), Offset(-hw, hh - len)],
//       [Offset(hw, hh), Offset(hw - len, hh), Offset(hw, hh - len)],
//     ];
//
//     for (var corner in corners) {
//       canvas.drawLine(corner[0], corner[1], bracketPaint);
//       canvas.drawLine(corner[0], corner[2], bracketPaint);
//     }
//
//     // Center crosshair
//     if (isActive) {
//       final crossPaint = Paint()
//         ..color = frameColor.withOpacity(0.6)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1.5;
//
//       canvas.drawLine(Offset(-6, 0), Offset(6, 0), crossPaint);
//       canvas.drawLine(Offset(0, -6), Offset(0, 6), crossPaint);
//       canvas.drawCircle(Offset.zero, 4, crossPaint);
//     }
//
//     // Scanning animation
//     if (isActive && isScanning) {
//       final scanPaint = Paint()
//         ..shader =
//             LinearGradient(
//               colors: [
//                 frameColor.withOpacity(0),
//                 frameColor,
//                 frameColor.withOpacity(0),
//               ],
//             ).createShader(
//               Rect.fromLTWH(-hw, -hh, nail.width + 16, nail.height + 16),
//             )
//         ..strokeWidth = 2;
//
//       final scanY = -hh + (nail.height + 16) * pulseAnimation;
//       canvas.drawLine(Offset(-hw, scanY), Offset(hw, scanY), scanPaint);
//     }
//
//     canvas.restore();
//   }
//
//   @override
//   bool shouldRepaint(HandStrokePainter oldDelegate) => true;
// }
//
// class FingerData {
//   final String id;
//   final String name;
//   final Color color;
//
//   FingerData(this.id, this.name, this.color);
// }
//
// class NailPosition {
//   final String id;
//   final double x;
//   final double y;
//   final double width;
//   final double height;
//   final double rotation;
//
//   NailPosition(this.id, this.x, this.y, this.width, this.height, this.rotation);
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Camera with Custom Stroke',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: CameraPreviewPage(),
//     );
//   }
// }
//
// class CameraPreviewPage extends StatefulWidget {
//   @override
//   _CameraPreviewPageState createState() => _CameraPreviewPageState();
// }
//
// class _CameraPreviewPageState extends State<CameraPreviewPage> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//
//   // Initialize the camera controller
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     try {
//       final cameras = await availableCameras();
//       final firstCamera = cameras.first;
//
//       _controller = CameraController(firstCamera, ResolutionPreset.high);
//       _initializeControllerFuture = _controller.initialize();
//       setState(() {});
//     } catch (e) {
//       // Handle camera initialization error
//       print('Error initializing camera: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Camera with Hand Stroke')),
//       body: FutureBuilder<void>(
//         future: _initializeControllerFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             return Stack(
//               children: [
//                 CameraPreview(_controller), // Camera preview
//                 Positioned.fill(
//                   child: CustomPaint(
//                     size: Size(320, 360),
//                     painter: HandFramePainter(
//                       strokeColor: Colors.pink,
//                       strokeWidth: 3.0,
//                     ), // Overlay custom hand stroke
//                   ),
//                 ),
//               ],
//             );
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else {
//             return Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _controller.dispose();
//   }
// }
//
// class HandStrokePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..color = Colors
//           .pink // Color of the stroke
//       ..strokeWidth = 5
//       ..style = PaintingStyle.stroke;
//
//     Path path = Path();
//
//     // Start by tracing the hand outline based on the image dimensions (You should adjust these values)
//     // Example Path to represent hand shape (to be adjusted based on actual hand image)
//
//     // Drawing a simple outline for illustration; adjust to match your image
//     path.moveTo(size.width * 0.3, size.height * 0.3); // Palm base
//     path.lineTo(size.width * 0.35, size.height * 0.15); // Thumb
//     path.lineTo(size.width * 0.4, size.height * 0.1);
//     path.lineTo(size.width * 0.5, size.height * 0.05); // Thumb tip
//
//     path.moveTo(size.width * 0.55, size.height * 0.3); // Index finger base
//     path.lineTo(size.width * 0.58, size.height * 0.1);
//     path.lineTo(size.width * 0.6, size.height * 0.05); // Index tip
//
//     path.moveTo(size.width * 0.6, size.height * 0.3); // Middle finger base
//     path.lineTo(size.width * 0.65, size.height * 0.1);
//     path.lineTo(size.width * 0.7, size.height * 0.05); // Middle tip
//
//     path.moveTo(size.width * 0.7, size.height * 0.3); // Ring finger base
//     path.lineTo(size.width * 0.75, size.height * 0.1);
//     path.lineTo(size.width * 0.8, size.height * 0.05); // Ring tip
//
//     path.moveTo(size.width * 0.8, size.height * 0.3); // Little finger base
//     path.lineTo(size.width * 0.85, size.height * 0.1);
//     path.lineTo(size.width * 0.9, size.height * 0.05); // Little tip
//
//     path.moveTo(size.width * 0.35, size.height * 0.3); // Palm curve
//     path.lineTo(size.width * 0.45, size.height * 0.5);
//     path.lineTo(size.width * 0.55, size.height * 0.45);
//
//     // Connect the palm curve to the base of the wrist (use your image to adjust the exact path)
//     path.lineTo(size.width * 0.3, size.height * 0.65);
//
//     // Draw the path to represent the hand stroke
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }
