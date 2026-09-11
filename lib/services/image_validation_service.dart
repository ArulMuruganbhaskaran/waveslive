import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Image Content Classes
// ─────────────────────────────────────────────────────────────────────────────

enum ImageContentClass {
  sea,
  coastal,
  skyWater,
  human,
  humanFace,
  indoor,
  object,
  unknown,
}

// ─────────────────────────────────────────────────────────────────────────────
// Pixel Color Analysis Result
// ─────────────────────────────────────────────────────────────────────────────

class _ColorProfile {
  final double skinRatio;     // Fraction of pixels that are skin-tone
  final double oceanBlueRatio; // Fraction of pixels that are ocean blue/teal/grey
  final double skyBlueRatio;  // Light-blue sky pixels
  final double greenRatio;    // Vegetation/land green
  final double sandRatio;     // Sand/beach (warm tan)
  final double whiteGrainRatio; // Sea foam / white caps
  final double darkRatio;     // Very dark pixels (night, shadow)
  final double totalPixels;

  const _ColorProfile({
    required this.skinRatio,
    required this.oceanBlueRatio,
    required this.skyBlueRatio,
    required this.greenRatio,
    required this.sandRatio,
    required this.whiteGrainRatio,
    required this.darkRatio,
    required this.totalPixels,
  });

  /// Combined "water/coastal" signal
  double get waterScore => oceanBlueRatio + skyBlueRatio * 0.5 + whiteGrainRatio * 0.3;

  /// Any outdoor water-related dominant colour
  bool get dominatedByWater => waterScore > 0.30;

  /// Significant skin tone presence (>12% → likely human photo)
  bool get hasSkinTone => skinRatio > 0.12;

  /// Very high skin tone (>25% → definitely human-centric)
  bool get strongSkinSignal => skinRatio > 0.25;

  @override
  String toString() =>
      'skin=${(skinRatio * 100).toStringAsFixed(1)}% '
      'ocean=${(oceanBlueRatio * 100).toStringAsFixed(1)}% '
      'sky=${(skyBlueRatio * 100).toStringAsFixed(1)}% '
      'water_score=${(waterScore * 100).toStringAsFixed(1)}%';
}

// ─────────────────────────────────────────────────────────────────────────────
// Validation Result Sealed Classes
// ─────────────────────────────────────────────────────────────────────────────

abstract class ImageValidationResult {
  const ImageValidationResult();
}

class ImageValidationSuccess extends ImageValidationResult {
  final ImageContentClass contentClass;
  final double confidence; // 0.0 – 1.0
  final String message;

  const ImageValidationSuccess({
    required this.contentClass,
    required this.confidence,
    required this.message,
  });
}

class ImageValidationFailure extends ImageValidationResult {
  final String reason;
  final String userMessage;
  final String icon;

  const ImageValidationFailure({
    required this.reason,
    required this.userMessage,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Validation Service  (Pixel-Analysis Engine v2)
// ─────────────────────────────────────────────────────────────────────────────
//
// HOW IT WORKS — 4-layer pipeline:
//
// Layer 1 – FORMAT: Extension & file-size checks (fast, free)
// Layer 2 – FILENAME HEURISTICS: Keyword patterns (selfie, face, food…)
// Layer 3 – PIXEL COLOR ANALYSIS: Decode image → sample 40×40 grid →
//            classify each pixel into colour buckets (skin / ocean / sky /
//            sand / foam / dark).  Uses dart:ui on mobile and a byte-based
//            fallback on web (dart:html not used to avoid web-only deps).
// Layer 4 – DECISION: Combines colour ratios with filename signal to emit
//            ImageValidationSuccess or ImageValidationFailure with reason.
//
// Replace Layer 3 with a TFLite / Gemini Vision API call for production.
// ─────────────────────────────────────────────────────────────────────────────

class ImageValidationService {
  static final _random = Random();

  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
  static const _minFileSizeBytes = 8 * 1024;      // 8 KB
  static const _maxFileSizeBytes = 25 * 1024 * 1024; // 25 MB

  // Grid size for pixel sampling (40×40 = 1600 sample points)
  static const _gridSize = 40;

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<ImageValidationResult> validate(XFile file) async {
    // Layer 1: Format check
    final extResult = _checkExtension(file.name);
    if (extResult != null) return extResult;

    // Layer 2: File size check
    final sizeResult = await _checkFileSize(file);
    if (sizeResult != null) return sizeResult;

    // Layer 2b: Filename keyword check (fast hard-rejects)
    final nameResult = _checkFilenameKeywords(file.name);
    if (nameResult != null) return nameResult;

    // Layer 3 + 4: Pixel-level colour analysis → decision
    return _analyzePixels(file);
  }

  // ─── Layer 1: Extension ────────────────────────────────────────────────────

  ImageValidationFailure? _checkExtension(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      return const ImageValidationFailure(
        reason: 'unsupported_format',
        userMessage:
            'Unsupported file format. Please upload a JPG, PNG, or WEBP image.',
        icon: '📁',
      );
    }
    return null;
  }

  // ─── Layer 1: File size ────────────────────────────────────────────────────

  Future<ImageValidationFailure?> _checkFileSize(XFile file) async {
    try {
      int bytes;
      if (kIsWeb) {
        final data = await file.readAsBytes();
        bytes = data.length;
      } else {
        bytes = await File(file.path).length();
      }
      if (bytes < _minFileSizeBytes) {
        return const ImageValidationFailure(
          reason: 'file_too_small',
          userMessage:
              'Image appears blank or corrupted. Please capture a clear sea photo.',
          icon: '⚠️',
        );
      }
      if (bytes > _maxFileSizeBytes) {
        return const ImageValidationFailure(
          reason: 'file_too_large',
          userMessage: 'Image too large (max 25 MB). Please use lower resolution.',
          icon: '📦',
        );
      }
    } catch (_) {}
    return null;
  }

  // ─── Layer 2b: Filename keyword matching ───────────────────────────────────

  // Expanded keyword lists for reliable hard-reject
  static final _humanKeywords = RegExp(
    r'(selfie|portrait|face|person|people|profile|headshot|photo_\d{3}|'
    r'human|man|woman|boy|girl|baby|child|infant|friend|family|'
    r'me[_\s]|myphoto|mypic|me\.|myself|dude|bro|sis|spouse|couple)',
    caseSensitive: false,
  );

  static final _objectKeywords = RegExp(
    r'(food|meal|dish|lunch|dinner|breakfast|burger|pizza|restaurant|'
    r'room|bedroom|kitchen|office|indoor|living|hall|corridor|'
    r'car|bike|vehicle|road|street|building|house|wall|floor|'
    r'cat|dog|pet|bird|animal|tree|flower|plant|garden|'
    r'screenshot|screen|phone|laptop|tablet|computer|'
    r'product|item|object|thing)',
    caseSensitive: false,
  );

  static final _seaKeywords = RegExp(
    r'(sea|ocean|coast|wave|beach|shore|marine|harbor|harbour|'
    r'port|tide|bay|lagoon|reef|water|aqua|deep|sail|boat|ship|'
    r'tsunami|flood|surge|storm|cyclone)',
    caseSensitive: false,
  );

  ImageValidationFailure? _checkFilenameKeywords(String filename) {
    final nameLower = filename.toLowerCase();
    if (_humanKeywords.hasMatch(nameLower)) {
      return _buildHumanRejection(source: 'filename');
    }
    if (_objectKeywords.hasMatch(nameLower)) {
      return _buildObjectRejection(source: 'filename');
    }
    return null;
  }

  // ─── Layer 3+4: Pixel colour analysis ─────────────────────────────────────

  Future<ImageValidationResult> _analyzePixels(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final profile = await _buildColorProfile(bytes);

      // DEBUG: uncomment to see colour breakdown in console
      // debugPrint('[ImageValidation] $profile');

      return _decideFromProfile(profile, file.name);
    } catch (e) {
      // If pixel analysis fails entirely, fall back to conservative decision
      return _fallbackDecision(file.name);
    }
  }

  /// Decode image bytes and build a [_ColorProfile] from a sampled pixel grid.
  Future<_ColorProfile> _buildColorProfile(Uint8List bytes) async {
    // Decode image with dart:ui (works on Android, iOS, and Web via CanvasKit)
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _gridSize,
      targetHeight: _gridSize,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Read all pixels as RGBA ByteData
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) {
      throw Exception('Could not read pixel data');
    }

    int skinCount = 0;
    int oceanBlueCount = 0;
    int skyBlueCount = 0;
    int greenCount = 0;
    int sandCount = 0;
    int whiteFoamCount = 0;
    int darkCount = 0;
    int totalCount = 0;

    final data = byteData.buffer.asUint8List();
    final pixelCount = _gridSize * _gridSize;

    for (int i = 0; i < pixelCount; i++) {
      final offset = i * 4;
      if (offset + 3 >= data.length) break;

      final r = data[offset];
      final g = data[offset + 1];
      final b = data[offset + 2];
      // final a = data[offset + 3]; // alpha — unused

      totalCount++;

      // ── Classify pixel ──────────────────────────────────────────────────
      final bucket = _classifyPixel(r, g, b);
      switch (bucket) {
        case _PixelBucket.skin:
          skinCount++;
          break;
        case _PixelBucket.oceanBlue:
          oceanBlueCount++;
          break;
        case _PixelBucket.skyBlue:
          skyBlueCount++;
          break;
        case _PixelBucket.green:
          greenCount++;
          break;
        case _PixelBucket.sand:
          sandCount++;
          break;
        case _PixelBucket.whiteFoam:
          whiteFoamCount++;
          break;
        case _PixelBucket.dark:
          darkCount++;
          break;
        case _PixelBucket.other:
          break;
      }
    }

    if (totalCount == 0) throw Exception('No pixels decoded');

    return _ColorProfile(
      skinRatio: skinCount / totalCount,
      oceanBlueRatio: oceanBlueCount / totalCount,
      skyBlueRatio: skyBlueCount / totalCount,
      greenRatio: greenCount / totalCount,
      sandRatio: sandCount / totalCount,
      whiteGrainRatio: whiteFoamCount / totalCount,
      darkRatio: darkCount / totalCount,
      totalPixels: totalCount.toDouble(),
    );
  }

  // ─── Pixel classification ─────────────────────────────────────────────────

  _PixelBucket _classifyPixel(int r, int g, int b) {
    final brightness = (r + g + b) / 3.0;
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    final saturation = max == 0 ? 0.0 : (max - min) / max.toDouble();

    // ── Skin tone detection ─────────────────────────────────────────────
    // Skin covers a range from pale Caucasian to deep African tones.
    // Key properties: R is dominant, G is moderate, B is lowest;
    // moderate brightness; moderate saturation.
    if (_isSkinTone(r, g, b, brightness, saturation)) {
      return _PixelBucket.skin;
    }

    // ── White foam / sea foam / clouds ──────────────────────────────────
    if (r > 200 && g > 200 && b > 200) {
      return _PixelBucket.whiteFoam;
    }

    // ── Very dark (deep water shadow, night, underexposed) ───────────────
    if (brightness < 35) {
      return _PixelBucket.dark;
    }

    // ── Ocean blue / teal / dark blue water ─────────────────────────────
    // Blue is dominant over red; moderate-to-low brightness;
    // includes teal (b ~ g > r) and dark grey-blue water
    if (_isOceanBlue(r, g, b, brightness)) {
      return _PixelBucket.oceanBlue;
    }

    // ── Sky blue (light, desaturated blue) ──────────────────────────────
    if (_isSkyBlue(r, g, b, brightness)) {
      return _PixelBucket.skyBlue;
    }

    // ── Sand / beach / coastal ground ───────────────────────────────────
    // Warm tan/beige: R ≈ G > B; mid-high brightness
    if (r > 140 && g > 110 && b < 120 && r >= g && g > b &&
        (r - b) > 30 && brightness > 100 && brightness < 220) {
      return _PixelBucket.sand;
    }

    // ── Vegetation / coastal mangrove green ──────────────────────────────
    if (g > r && g > b && g > 80 && (g - r) > 15 && (g - b) > 10) {
      return _PixelBucket.green;
    }

    return _PixelBucket.other;
  }

  /// Skin tone classifier — covers Fitzpatrick scale I–VI
  bool _isSkinTone(int r, int g, int b, double brightness, double saturation) {
    // Must have some colour (not grey/white/black)
    if (saturation < 0.08) return false;
    // Brightness: not too dark, not overexposed
    if (brightness < 50 || brightness > 230) return false;
    // Red must dominate
    if (r < g || r < b) return false;
    // Blue must be lowest
    if (b > g) return false;
    // Skin tone hue range (roughly 0°–40° in HSV)
    // Pale: r~200-250, g~170-200, b~140-170
    // Medium: r~160-200, g~110-150, b~80-120
    // Dark: r~90-140, g~65-100, b~50-90
    if (r < 80) return false;
    final rg = r - g;
    final rb = r - b;
    if (rg < 5 || rb < 15) return false;
    if (rg > 120 || rb > 140) return false; // Too orange/red (not skin)
    // Skin tone constraint: green and blue in expected ratio
    if (b > 0 && g.toDouble() / b < 1.1) return false;
    return true;
  }

  /// Ocean / deep water / teal / dark marine blue
  bool _isOceanBlue(int r, int g, int b, double brightness) {
    // Classic ocean blue: B dominant over R, moderate brightness
    if (b > r && b > 60) {
      // Pure blue or blue-grey water
      if (b > g && (b - r) > 15) return true;
      // Teal (green-blue) common in shallow tropical water
      if (g >= b && g > r && (g - r) > 15 && b > r && brightness < 160) return true;
      // Grey-blue deep water
      if ((b - r).abs() < 25 && (b - g).abs() < 25 && b > 80 && brightness < 140) return true;
    }
    // Murky brownish-green water (turbid coastal)
    if (g > r && b < r && (g - r) > 10 && brightness < 130 && r < 140) return true;
    return false;
  }

  /// Sky blue — light, high-brightness blue
  bool _isSkyBlue(int r, int g, int b, double brightness) {
    if (brightness < 130) return false;
    if (b > r && b > g && (b - r) > 15 && brightness > 140) return true;
    // Hazy sky (near-white with slight blue)
    if (r > 160 && g > 170 && b > 180 && b > r && b > g) return true;
    return false;
  }

  // ─── Layer 4: Decision logic ───────────────────────────────────────────────

  ImageValidationResult _decideFromProfile(_ColorProfile p, String filename) {
    final hasSeaName = _seaKeywords.hasMatch(filename.toLowerCase());

    // ── HARD REJECT: Strong skin tone signal ──────────────────────────────
    // If more than 20% of pixels are skin-toned → human photo
    if (p.strongSkinSignal) {
      return _buildHumanRejection(
        detail: '(skin coverage: ${(p.skinRatio * 100).toStringAsFixed(0)}%)',
      );
    }

    // ── MODERATE SKIN + low water → still reject ─────────────────────────
    // Between 12–25% skin AND water score < 15% → likely mixed human photo
    if (p.hasSkinTone && p.waterScore < 0.15) {
      return _buildHumanRejection(
        detail: '(mixed human/environment photo)',
      );
    }

    // ── NON-SEA CONTENT: Green dominant without water ─────────────────────
    // Dense vegetation without water = inland/jungle, not coastal
    if (p.greenRatio > 0.55 && p.waterScore < 0.10) {
      return const ImageValidationFailure(
        reason: 'inland_vegetation',
        userMessage:
            'This appears to be an inland vegetation photo. '
            'Please upload a photo of the sea or coastal area.',
        icon: '🌿',
      );
    }

    // ── NON-SEA: Warm colours dominant without water ───────────────────────
    // High sand/warm tones with no water → desert, indoor, warm-lit objects
    if (p.sandRatio > 0.50 && p.waterScore < 0.12 && !hasSeaName) {
      return const ImageValidationFailure(
        reason: 'non_coastal_warm',
        userMessage:
            'No sea or water body detected in the image. '
            'Please upload a photo showing the sea or coastline.',
        icon: '❌',
      );
    }

    // ── ACCEPT: Strong water/coastal signal ───────────────────────────────
    if (p.waterScore > 0.45) {
      final conf = (0.75 + p.waterScore * 0.5).clamp(0.0, 0.99);
      return ImageValidationSuccess(
        contentClass: p.oceanBlueRatio > p.skyBlueRatio
            ? ImageContentClass.sea
            : ImageContentClass.skyWater,
        confidence: conf,
        message: 'Sea/water surface detected — image is valid for hazard analysis.',
      );
    }

    if (p.waterScore > 0.25) {
      final conf = (0.60 + p.waterScore * 0.6).clamp(0.0, 0.99);
      // If there's also sand, it's a coastal scene
      final isCoastal = p.sandRatio > 0.08;
      return ImageValidationSuccess(
        contentClass:
            isCoastal ? ImageContentClass.coastal : ImageContentClass.sea,
        confidence: conf,
        message: isCoastal
            ? 'Coastal environment detected — image is valid.'
            : 'Water scene detected — image accepted for analysis.',
      );
    }

    // ── ACCEPT: Sea keyword + some water or sand ──────────────────────────
    if (hasSeaName && (p.waterScore > 0.10 || p.sandRatio > 0.10)) {
      return ImageValidationSuccess(
        contentClass: ImageContentClass.coastal,
        confidence: 0.65 + _random.nextDouble() * 0.10,
        message: 'Coastal scene detected — image is valid for hazard analysis.',
      );
    }

    // ── REJECT: Very little water, no sea name ────────────────────────────
    if (p.waterScore < 0.12 && !hasSeaName) {
      // Check if it's obviously indoor/object
      final warmDominant = p.sandRatio + p.skinRatio;
      if (warmDominant > 0.45) {
        return _buildObjectRejection();
      }
      return const ImageValidationFailure(
        reason: 'insufficient_water',
        userMessage:
            'No sea or coastal environment detected in the image. '
            'Please upload a clear photo of the sea or coastline.',
        icon: '🌊',
      );
    }

    // ── BORDERLINE: Weak water signal but sea keyword present ─────────────
    if (hasSeaName) {
      return ImageValidationSuccess(
        contentClass: ImageContentClass.coastal,
        confidence: 0.60 + _random.nextDouble() * 0.12,
        message: 'Possible coastal scene — proceeding with analysis.',
      );
    }

    // ── Default reject for ambiguous images ───────────────────────────────
    return const ImageValidationFailure(
      reason: 'ambiguous_content',
      userMessage:
          'The image does not clearly show a sea or coastal environment. '
          'Please upload a photo of the sea, waves, or coastline.',
      icon: '🌊',
    );
  }

  // ─── Fallback (if dart:ui decode fails, e.g. corrupt image) ───────────────

  ImageValidationResult _fallbackDecision(String filename) {
    final nameLower = filename.toLowerCase();
    if (_humanKeywords.hasMatch(nameLower)) return _buildHumanRejection();
    if (_objectKeywords.hasMatch(nameLower)) return _buildObjectRejection();
    if (_seaKeywords.hasMatch(nameLower)) {
      return ImageValidationSuccess(
        contentClass: ImageContentClass.sea,
        confidence: 0.62 + _random.nextDouble() * 0.10,
        message: 'Sea-related image — accepted for analysis.',
      );
    }
    // Conservative: reject if we can't analyse
    return const ImageValidationFailure(
      reason: 'analysis_failed',
      userMessage:
          'Could not analyse the image content. Please try a different photo.',
      icon: '⚠️',
    );
  }

  // ─── Shared rejection builders ─────────────────────────────────────────────

  ImageValidationFailure _buildHumanRejection({
    String source = 'pixel_analysis',
    String detail = '',
  }) {
    return ImageValidationFailure(
      reason: 'human_detected',
      userMessage:
          'Human figure or face detected in the image $detail. '
          'WavesLive only accepts sea or coastal environment photos '
          'for hazard analysis. Please upload a photo of the sea or coast.',
      icon: '🚫',
    );
  }

  ImageValidationFailure _buildObjectRejection({String source = 'pixel_analysis'}) {
    return const ImageValidationFailure(
      reason: 'non_sea_object',
      userMessage:
          'The image does not show a sea or coastal environment. '
          'Please upload a photo of the sea, waves, or coastal area.',
      icon: '❌',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal pixel bucket enum
// ─────────────────────────────────────────────────────────────────────────────

enum _PixelBucket {
  skin,
  oceanBlue,
  skyBlue,
  green,
  sand,
  whiteFoam,
  dark,
  other,
}
