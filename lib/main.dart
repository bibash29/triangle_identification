import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TriangleIdentifier(),
    );
  }
}

class TriangleIdentifier extends StatefulWidget {
  const TriangleIdentifier({super.key});

  @override
  State<TriangleIdentifier> createState() => _TriangleIdentifierState();
}

class _TriangleIdentifierState extends State<TriangleIdentifier> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _side1Controller = TextEditingController();
  final TextEditingController _side2Controller = TextEditingController();
  final TextEditingController _side3Controller = TextEditingController();
  
  String _result = '';
  String _triangleType = '';
  bool _isValid = false;
  double _rotationX = 0;
  double _rotationY = 0;
  double _touchRotationX = 0;
  double _touchRotationY = 0;
  bool _isDragging = false;
  Offset? _lastDragPosition;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _startRotationAnimation();
  }

  void _startRotationAnimation() {
    Future.delayed(Duration.zero, () {
      setState(() {
        _rotationX = 0;
        _rotationY = 0;
      });
      
      _animationController = AnimationController(
        duration: const Duration(seconds: 8),
        vsync: this,
      )..repeat();

      _animationController.addListener(() {
        final double progress = _animationController.value;
        setState(() {
          _rotationX = sin(progress * pi * 2) * pi;
          _rotationY = cos(progress * pi * 2) * pi;
        });
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Triangle Identification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _side1Controller,
              decoration: InputDecoration(labelText: 'Side 1'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _side2Controller,
              decoration: InputDecoration(labelText: 'Side 2'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _side3Controller,
              decoration: InputDecoration(labelText: 'Side 3'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _analyzeTriangle,
              child: Text('Analyze Triangle'),
            ),
            SizedBox(height: 20),
            Text(_result),
            Text(_triangleType),
            SizedBox(height: 40),
            GestureDetector(
              onPanStart: _onDragStart,
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateX(_rotationX + _touchRotationX)
                  ..rotateY(_rotationY + _touchRotationY)
                  ..translate(0.0, 0.0, 50.0), // Move slightly forward for better 3D effect
                alignment: Alignment.center,
                child: Container(
                  width: 300,
                  height: 300,
                  color: Colors.transparent,
                  child: CustomPaint(
                    painter: TrianglePainter(
                      isValid: _isValid,
                      triangleType: _triangleType,
                      side1: _isValid ? double.tryParse(_side1Controller.text) : null,
                      side2: _isValid ? double.tryParse(_side2Controller.text) : null,
                      side3: _isValid ? double.tryParse(_side3Controller.text) : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _analyzeTriangle() {
    final double? side1 = double.tryParse(_side1Controller.text);
    final double? side2 = double.tryParse(_side2Controller.text);
    final double? side3 = double.tryParse(_side3Controller.text);

    if (side1 == null || side2 == null || side3 == null) {
      setState(() {
        _result = 'Please enter valid numbers';
        _triangleType = '';
        _isValid = false;
      });
      return;
    }

    if (_canFormTriangle(side1, side2, side3)) {
      final String type = _getTriangleType(side1, side2, side3);
      setState(() {
        _result = 'Valid triangle: YES';
        _triangleType = 'Triangle Type: $type';
        _isValid = true;
      });
    } else {
      setState(() {
        _result = 'Valid triangle: NO';
        _triangleType = '';
        _isValid = false;
      });
    }
  }

  bool _canFormTriangle(double a, double b, double c) {
    return (a + b > c) && (b + c > a) && (c + a > b);
  }

  String _getTriangleType(double a, double b, double c) {
    if (a == b && b == c) return 'Equilateral';
    if (pow(a, 2) + pow(b, 2) == pow(c, 2) ||
        pow(b, 2) + pow(c, 2) == pow(a, 2) ||
        pow(c, 2) + pow(a, 2) == pow(b, 2)) {
      return 'Right Angled';
    }
    if (a == b || b == c || c == a) return 'Isosceles';
    return 'Scalene';
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _lastDragPosition = details.globalPosition;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final Offset currentPos = details.globalPosition;
    final Offset delta = currentPos - _lastDragPosition!;
    
    setState(() {
      _touchRotationX += delta.dy * 0.02;
      _touchRotationY += delta.dx * 0.02;
      _lastDragPosition = currentPos;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    _lastDragPosition = null;
  }
}

class TrianglePainter extends CustomPainter {
  final bool isValid;
  final String triangleType;
  final double? side1;
  final double? side2;
  final double? side3;

  TrianglePainter({
    required this.isValid,
    required this.triangleType,
    this.side1,
    this.side2,
    this.side3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isValid || side1 == null || side2 == null || side3 == null) return;

    Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    List<Offset> points = _calculateTrianglePoints(size);
    
    Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    path.lineTo(points[1].dx, points[1].dy);
    path.lineTo(points[2].dx, points[2].dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  List<Offset> _calculateTrianglePoints(Size size) {
    // Calculate scale factor to fit triangle in view
    double maxSide = max(max(side1!, side2!), side3!);
    double scale = min(size.width, size.height) / (maxSide * 2.5); // Leave some padding

    // Determine which side to use as base (longest side)
    double baseSide;
    double otherSide1;
    double otherSide2;
    double angle1;
    double angle2;

    if (side1! >= side2! && side1! >= side3!) {
      // side1 is longest
      baseSide = side1!;
      otherSide1 = side2!;
      otherSide2 = side3!;
      angle1 = acos((pow(side2!, 2) + pow(side1!, 2) - pow(side3!, 2)) / (2 * side2! * side1!));
      angle2 = acos((pow(side3!, 2) + pow(side1!, 2) - pow(side2!, 2)) / (2 * side3! * side1!));
    } else if (side2! >= side1! && side2! >= side3!) {
      // side2 is longest
      baseSide = side2!;
      otherSide1 = side1!;
      otherSide2 = side3!;
      angle1 = acos((pow(side1!, 2) + pow(side2!, 2) - pow(side3!, 2)) / (2 * side1! * side2!));
      angle2 = acos((pow(side3!, 2) + pow(side2!, 2) - pow(side1!, 2)) / (2 * side3! * side2!));
    } else {
      // side3 is longest
      baseSide = side3!;
      otherSide1 = side1!;
      otherSide2 = side2!;
      angle1 = acos((pow(side1!, 2) + pow(side3!, 2) - pow(side2!, 2)) / (2 * side1! * side3!));
      angle2 = acos((pow(side2!, 2) + pow(side3!, 2) - pow(side1!, 2)) / (2 * side2! * side3!));
    }

    // Calculate points using scaled sides and angles
    double centerX = size.width / 2;
    double centerY = size.height / 2;

    Offset p1 = Offset(centerX, centerY);
    Offset p2 = Offset(
      centerX + baseSide * scale,
      centerY
    );
    Offset p3 = Offset(
      centerX + otherSide1 * scale * cos(angle1),
      centerY + otherSide1 * scale * sin(angle1)
    );

    // Special case for right-angled triangles
    if (triangleType.contains('Right Angled')) {
      // Find the longest side (hypotenuse)
      double hypotenuse = max(max(side1!, side2!), side3!);
      otherSide1 = side1! == hypotenuse ? side2! : side1!;
      otherSide2 = side2! == hypotenuse ? side3! : side2!;
      
      // Calculate points for right angle
      p1 = Offset(centerX, centerY);
      p2 = Offset(
        centerX + otherSide1 * scale,
        centerY
      );
      p3 = Offset(
        centerX,
        centerY + otherSide2 * scale
      );
    }

    return [p1, p2, p3];
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) {
    return oldDelegate.isValid != isValid ||
           oldDelegate.side1 != side1 ||
           oldDelegate.side2 != side2 ||
           oldDelegate.side3 != side3;
  }
}