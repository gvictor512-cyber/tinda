import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';

class VideoCallScreen extends StatefulWidget {
  final String callWith;
  const VideoCallScreen({super.key, this.callWith = 'Compañero'});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isReady = false;
  String? _error;
  bool _isMuted = false;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      setState(() {
        _error = 'Se necesitan permisos de cámara y micrófono para la videollamada.';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No se encontró cámara disponible.');
        return;
      }

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error al iniciar la cámara: $e');
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2 || _controller == null || !_isReady) return;
    _isFront = !_isFront;
    final newDirection = _isFront ? CameraLensDirection.front : CameraLensDirection.back;
    final camera = _cameras.firstWhere((c) => c.lensDirection == newDirection);
    await _controller!.setDescription(camera);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    // En una integración real se silenciaría el audio del canal WebRTC.
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDarkMode),
            Expanded(child: _buildCameraPreview()),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.callWith,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    if (!_isReady || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            SizedBox(height: 16),
            Text(
              'Conectando cámara y micrófono...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? Colors.red : Colors.white,
            onTap: _toggleMute,
          ),
          _controlButton(
            icon: Icons.call_end,
            color: Colors.red,
            size: 64,
            onTap: () => Navigator.of(context).pop(),
          ),
          _controlButton(
            icon: Icons.flip_camera_ios,
            color: Colors.white,
            onTap: _toggleCamera,
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color == Colors.white ? Colors.white.withValues(alpha: 0.2) : color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color == Colors.white ? Colors.white : Colors.white,
          size: size == 64 ? 32 : 24,
        ),
      ),
    );
  }
}
