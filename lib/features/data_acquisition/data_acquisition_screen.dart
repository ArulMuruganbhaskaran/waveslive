import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_router.dart';
import '../../providers/app_providers.dart';
import '../../services/image_validation_service.dart';

// State holders for current capture session
class CaptureState {
  final XFile? image;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime capturedAt;
  final String? description;
  final bool isLoadingLocation;
  // Validation result is carried along so preview screen can show the badge
  final ImageValidationSuccess? validationResult;

  const CaptureState({
    this.image,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.capturedAt,
    this.description,
    this.isLoadingLocation = false,
    this.validationResult,
  });

  CaptureState copyWith({
    XFile? image,
    double? latitude,
    double? longitude,
    String? locationName,
    String? description,
    bool? isLoadingLocation,
    ImageValidationSuccess? validationResult,
  }) {
    return CaptureState(
      image: image ?? this.image,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      capturedAt: capturedAt,
      description: description ?? this.description,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      validationResult: validationResult ?? this.validationResult,
    );
  }
}

final captureStateProvider = StateProvider<CaptureState>(
  (ref) => CaptureState(capturedAt: DateTime.now()),
);

class DataAcquisitionScreen extends ConsumerStatefulWidget {
  const DataAcquisitionScreen({super.key});

  @override
  ConsumerState<DataAcquisitionScreen> createState() =>
      _DataAcquisitionScreenState();
}

class _DataAcquisitionScreenState
    extends ConsumerState<DataAcquisitionScreen> {
  final _picker = ImagePicker();
  final _descController = TextEditingController();
  bool _isCapturing = false;
  bool _isValidating = false;
  String? _locationError;
  bool _isDragOver = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    setState(() {
      _isCapturing = true;
      _locationError = null;
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) {
        setState(() => _isCapturing = false);
        return;
      }

      await _validateAndProcess(photo);
    } catch (e) {
      setState(() => _locationError = 'Camera error: $e');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (photo == null) return;
    await _validateAndProcess(photo);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Validation gate — runs BEFORE navigation to preview screen
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _validateAndProcess(XFile photo) async {
    setState(() {
      _isValidating = true;
      _locationError = null;
    });

    try {
      final validator = ref.read(imageValidationServiceProvider);
      final result = await validator.validate(photo);

      if (!mounted) return;

      if (result is ImageValidationFailure) {
        // Show rejection bottom sheet and abort
        _showRejectionSheet(result);
        return;
      }

      // Validation passed — show brief snackbar and navigate
      final success = result as ImageValidationSuccess;
      _showValidationSuccessSnack(success);
      await _processPickedImage(photo, success);
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _processPickedImage(
      XFile photo, ImageValidationSuccess validation) async {
    ref.read(captureStateProvider.notifier).state = CaptureState(
      image: photo,
      capturedAt: DateTime.now(),
      isLoadingLocation: true,
      validationResult: validation,
    );

    if (mounted) context.push(AppRoutes.reportPreview);

    final position = await _getLocation();

    ref.read(captureStateProvider.notifier).state =
        ref.read(captureStateProvider).copyWith(
              latitude: position?.latitude,
              longitude: position?.longitude,
              locationName: position != null
                  ? 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}'
                  : 'Location unavailable',
              isLoadingLocation: false,
            );
  }

  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = 'Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationError = 'Location permission denied');
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // Return demo location if GPS fails
      return Position(
        latitude: 8.5241,
        longitude: 76.9366,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _showRejectionSheet(ImageValidationFailure failure) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ValidationRejectionSheet(failure: failure),
    );
  }

  void _showValidationSuccessSnack(ImageValidationSuccess success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✅ ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                'Sea image detected (${(success.confidence * 100).toStringAsFixed(0)}% confidence)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A7A4A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _isCapturing || _isValidating;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Acquisition'),
        backgroundColor: AppColors.agentColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Module header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.agentColor, AppColors.agentColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.camera_alt_outlined, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Sea Condition Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture or import a sea photograph to detect coastal hazards using AI analysis',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Validating indicator overlay
            if (_isValidating)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Validating image content…',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Camera button
            SizedBox(
              height: 60,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : _capturePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.agentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt, size: 24),
                label: Text(
                  isBusy ? 'Please wait…' : 'Open Camera',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Drag & Drop zone (shown on web) or Gallery button (all platforms)
            _buildImageDropZone(isBusy: isBusy),

            if (_locationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.severityHigh.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _locationError!,
                  style: const TextStyle(
                    color: AppColors.severityHigh,
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Instruction(
                      icon: Icons.camera_alt_outlined,
                      text: kIsWeb
                          ? 'Click "Open Camera" to use your device/webcam camera'
                          : 'Point the camera towards the sea/coastal area',
                    ),
                    _Instruction(
                      icon: Icons.drag_indicator,
                      text: kIsWeb
                          ? 'Drag & drop an image file into the zone below, or click to browse'
                          : 'Select from gallery to import an existing photo',
                    ),
                    const _Instruction(
                      icon: Icons.verified_outlined,
                      text: 'AI validates that the photo shows a sea/coastal scene',
                    ),
                    const _Instruction(
                      icon: Icons.block_outlined,
                      text: 'Human photos, selfies & non-sea images are rejected',
                    ),
                    const _Instruction(
                      icon: Icons.wb_sunny_outlined,
                      text: 'Ensure good lighting and a clear view of the sea',
                    ),
                    const _Instruction(
                      icon: Icons.gps_fixed,
                      text: 'GPS location will be captured automatically',
                    ),
                    const _Instruction(
                      icon: Icons.auto_awesome_outlined,
                      text: 'AI will analyse the validated image for hazards',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDropZone({required bool isBusy}) {
    if (kIsWeb) {
      return DragTarget<Object>(
        onWillAcceptWithDetails: (details) {
          setState(() => _isDragOver = true);
          return true;
        },
        onLeave: (_) => setState(() => _isDragOver = false),
        onAcceptWithDetails: (details) {
          setState(() => _isDragOver = false);
          if (!isBusy) _pickFromGallery();
        },
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTap: isBusy ? null : _pickFromGallery,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 140,
              decoration: BoxDecoration(
                color: _isDragOver
                    ? AppColors.agentColor.withValues(alpha: 0.12)
                    : AppColors.agentColor.withValues(alpha: 0.04),
                border: Border.all(
                  color: _isDragOver
                      ? AppColors.agentColor
                      : AppColors.agentColor.withValues(alpha: 0.35),
                  width: _isDragOver ? 2.5 : 1.5,
                  // ignore: deprecated_member_use
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isDragOver ? Icons.file_download : Icons.cloud_upload_outlined,
                    size: 40,
                    color: AppColors.agentColor.withValues(alpha: _isDragOver ? 1.0 : 0.6),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isDragOver ? 'Drop image here' : 'Drag & drop image here',
                    style: TextStyle(
                      color: AppColors.agentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'or tap to browse from gallery',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supports JPG, PNG, WEBP • Sea/coastal photos only',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return OutlinedButton.icon(
        onPressed: isBusy ? null : _pickFromGallery,
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('Select from Gallery'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.agentColor,
          side: const BorderSide(color: AppColors.agentColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rejection Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ValidationRejectionSheet extends StatelessWidget {
  final ImageValidationFailure failure;

  const _ValidationRejectionSheet({required this.failure});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF4444).withValues(alpha: 0.2), width: 2),
            ),
            child: Center(
              child: Text(
                failure.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Invalid Image',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            failure.userMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),

          // Hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF0EA5E9)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WavesLive accepts only sea or coastal environment photos for accurate hazard detection.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dismiss button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.agentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Instruction extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Instruction({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.agentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

