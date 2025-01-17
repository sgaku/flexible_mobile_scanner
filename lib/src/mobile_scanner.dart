import 'dart:async';

import 'package:flexible_mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:flexible_mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:flexible_mobile_scanner/src/objects/barcode_capture.dart';
import 'package:flexible_mobile_scanner/src/objects/mobile_scanner_arguments.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The function signature for the error builder.
typedef MobileScannerErrorBuilder = Widget Function(
  BuildContext,
  MobileScannerException,
  Widget?,
);

/// The [MobileScanner] widget displays a live camera preview.
class MobileScanner extends StatefulWidget {
  /// The controller that manages the barcode scanner.
  ///
  /// If this is null, the scanner will manage its own controller.
  final MobileScannerController? controller;

  /// The function that builds an error widget when the scanner
  /// could not be started.
  ///
  /// If this is null, defaults to a black [ColoredBox]
  /// with a centered white [Icons.error] icon.
  final MobileScannerErrorBuilder? errorBuilder;

  /// The function that signals when new codes were detected by the [controller].
  final void Function(BarcodeCapture barcodes) onDetect;

  /// The function that signals when the barcode scanner is started.
  @Deprecated('Use onScannerStarted() instead.')
  final void Function(MobileScannerArguments? arguments)? onStart;

  /// The function that signals when the barcode scanner is started.
  final void Function(MobileScannerArguments? arguments)? onScannerStarted;

  /// The function that builds a placeholder widget when the scanner
  /// is not yet displaying its camera preview.
  ///
  /// If this is null, a black [ColoredBox] is used as placeholder.
  final Widget Function(BuildContext, Widget?)? placeholderBuilder;

  /// ⚡️ Added function from the original package
  ///
  /// A function that builds and customizes the camera preview display within the scanner.
  /// The [cameraPreviewBuilder] takes the following parameters:
  /// - [context]: The build context for the widget tree.
  /// - [texture]: The widget that displays the camera preview (typically a [Texture] or [HtmlElementView]).
  /// - [arguments]: The [MobileScannerArguments] that contain metadata about the scanner.
  ///
  /// This builder allows developers to modify the appearance and layout of the camera preview
  /// as per the application's requirements.
  final Widget Function(
    BuildContext context,
    Widget texture,
    MobileScannerArguments arguments,
  ) cameraPreviewBuilder;

  /// ⚡️ Added function from the original package
  ///
  /// A function that builds the scan window which is an area where the scanner actively looks for barcodes.
  /// The [scanWindowBuilder] takes the following parameter:
  /// - [arguments]: The [MobileScannerArguments] that contain metadata about the scanner.
  ///
  /// This builder allows developers to adjust the scan window, defining where the scanner should
  /// specifically look for barcodes within the camera preview.
  final Rect? Function(MobileScannerArguments)? scanWindowBuilder;

  /// Only set this to true if you are starting another instance of mobile_scanner
  /// right after disposing the first one, like in a PageView.
  ///
  /// Default: false
  final bool startDelay;

  final Color borderColor;

  final double borderWidth;

  /// Create a new [MobileScanner] using the provided [controller]
  /// and [onBarcodeDetected] callback.
  const MobileScanner({
    this.controller,
    this.errorBuilder,
    required this.onDetect,
    required this.cameraPreviewBuilder,
    this.scanWindowBuilder,
    @Deprecated('Use onScannerStarted() instead.') this.onStart,
    this.onScannerStarted,
    this.placeholderBuilder,
    this.startDelay = false,
    this.borderColor = const Color(0xFF00BA88),
    this.borderWidth = 10,
    super.key,
  });

  @override
  State<MobileScanner> createState() => _MobileScannerState();
}

class _MobileScannerState extends State<MobileScanner>
    with WidgetsBindingObserver {
  /// The subscription that listens to barcode detection.
  StreamSubscription<BarcodeCapture>? _barcodesSubscription;

  /// The internally managed controller.
  late MobileScannerController _controller;

  /// Whether the controller should resume
  /// when the application comes back to the foreground.
  bool _resumeFromBackground = false;

  MobileScannerException? _startException;

  Widget _buildPlaceholderOrError(BuildContext context, Widget? child) {
    final error = _startException;

    if (error != null) {
      return widget.errorBuilder?.call(context, error, child) ??
          const ColoredBox(
            color: Colors.black,
            child: Center(child: Icon(Icons.error, color: Colors.white)),
          );
    }

    return widget.placeholderBuilder?.call(context, child) ??
        const ColoredBox(color: Colors.black);
  }

  /// Start the given [scanner].
  Future<void> _startScanner() async {
    if (widget.startDelay) {
      await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    }

    _barcodesSubscription ??= _controller.barcodes.listen(
      widget.onDetect,
    );

    if (!_controller.autoStart) {
      debugPrint(
        'mobile_scanner: not starting automatically because autoStart is set to false in the controller.',
      );
      return;
    }
    if (_controller.isStarting) {
      debugPrint(
        'mobile_scanner: the controller is already starting.',
      );
      return;
    }
    _controller.start().then((arguments) {
      // ignore: deprecated_member_use_from_same_package
      widget.onStart?.call(arguments);
      widget.onScannerStarted?.call(arguments);
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _startException = error as MobileScannerException;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? MobileScannerController();
    _startScanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before the controller was initialized.
    if (_controller.isStarting) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        if (_resumeFromBackground) {
          _startScanner();
        }
        break;
      case AppLifecycleState.inactive:
        _resumeFromBackground = true;
        _controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerArguments?>(
      valueListenable: _controller.startArguments,
      builder: (context, value, child) {
        if (value == null) {
          return _buildPlaceholderOrError(context, child);
        }

        if (widget.scanWindowBuilder != null) {
          final scanWindow = widget.scanWindowBuilder!(value);
          _controller.updateScanWindow(scanWindow);
        }

        return widget.cameraPreviewBuilder(
          context,
          kIsWeb
              ? HtmlElementView(viewType: value.webId!)
              : Texture(textureId: value.textureId!),
          value,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.updateScanWindow(null);
    WidgetsBinding.instance.removeObserver(this);
    _barcodesSubscription?.cancel();
    _barcodesSubscription = null;
    _controller.dispose();
    super.dispose();
  }
}
