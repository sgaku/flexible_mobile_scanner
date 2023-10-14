import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('example'),
      ),
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanScreen(),
              ),
            );
          },
          child: const Text(
            'scan',
          ),
        ),
      ),
    );
  }
}

class ScanScreen extends StatelessWidget {
  const ScanScreen({Key? key}) : super(key: key);

  static const visibleAspectRatio = 0.25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('scan'),
      ),
      body: Column(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final values = capture.barcodes.map((e) => e.rawValue);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    values.toString(),
                  ),
                ),
              );
            },
            scanWindowBuilder: (arguments) {
              final aspectRatio = arguments.size.width / arguments.size.height;
              final screenWidth = MediaQuery.sizeOf(context).width;
              final previewHeight = screenWidth / aspectRatio;
              return Rect.fromLTWH(
                0,
                0,
                arguments.size.width,
                previewHeight,
              );
            },
            errorBuilder: (context, exception, child) {
              final errorMessage = 'error:${exception.errorDetails?.message}';
              return Center(child: Text(errorMessage));
            },
            cameraBuilder: (context, camera, arguments) {
              final aspectRatio = arguments.size.width / arguments.size.height;
              final screenWidth = MediaQuery.sizeOf(context).width;
              return ClipRect(
                child: Align(
                  heightFactor: visibleAspectRatio,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: screenWidth / aspectRatio,
                    width: screenWidth,
                    child: camera,
                  ),
                ),
              );
            },
          ),
          const Text("Let's scan!"),
        ],
      ),
    );
  }
}
