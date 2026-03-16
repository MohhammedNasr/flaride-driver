import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _flutterTts = FlutterTts();
      
      await _flutterTts!.setLanguage('en-US');
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);
      
      _isInitialized = true;
      debugPrint('VoiceService: Initialized');
    } catch (e) {
      debugPrint('VoiceService: Error initializing: $e');
    }
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  Future<void> speak(String text) async {
    if (!_isEnabled || !_isInitialized || _flutterTts == null) return;
    
    try {
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('VoiceService: Error speaking: $e');
    }
  }

  Future<void> stop() async {
    if (_flutterTts == null) return;
    await _flutterTts!.stop();
  }

  /// Announce new order available
  Future<void> announceNewOrder({
    required String restaurantName,
    required String earnings,
    double? distance,
  }) async {
    String text = 'New order available from $restaurantName.';
    text += ' Earn $earnings.';
    if (distance != null) {
      text += ' ${distance.toStringAsFixed(1)} kilometers away.';
    }
    await speak(text);
  }

  /// Announce order assigned
  Future<void> announceOrderAssigned({
    required String restaurantName,
  }) async {
    await speak('Order assigned. Head to $restaurantName for pickup.');
  }

  /// Announce pickup complete
  Future<void> announcePickupComplete({
    required String customerName,
  }) async {
    await speak('Pickup complete. Deliver to $customerName.');
  }

  /// Announce delivery complete
  Future<void> announceDeliveryComplete() async {
    await speak('Delivery completed. Great job!');
  }

  /// Announce navigation instruction
  Future<void> announceNavigation(String instruction) async {
    await speak(instruction);
  }

  void dispose() {
    _flutterTts?.stop();
    _flutterTts = null;
    _isInitialized = false;
  }
}
