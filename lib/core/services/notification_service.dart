import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('NotificationService: Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Notification channels for Android
  static const AndroidNotificationChannel _orderChannel = AndroidNotificationChannel(
    'order_notifications',
    'Order Notifications',
    description: 'Notifications for new orders and order updates',
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel _messageChannel = AndroidNotificationChannel(
    'message_notifications',
    'Messages',
    description: 'Notifications for customer messages',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _systemChannel = AndroidNotificationChannel(
    'system_notifications',
    'System Notifications',
    description: 'Important system announcements',
    importance: Importance.defaultImportance,
  );

  /// Initialize the notification service
  Future<void> initialize() async {
    // Set up background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    await _getFCMToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      print('NotificationService: Token refreshed: $token');
      // TODO: Send new token to backend
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: false,
      criticalAlert: false,
    );

    print('NotificationService: Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.createNotificationChannel(_orderChannel);
      await androidPlugin?.createNotificationChannel(_messageChannel);
      await androidPlugin?.createNotificationChannel(_systemChannel);
    }
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('NotificationService: FCM Token: $_fcmToken');
      // TODO: Send token to backend
    } catch (e) {
      print('NotificationService: Error getting FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('NotificationService: Foreground message: ${message.notification?.title}');
    
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'FlaRide Driver',
        body: notification.body ?? '',
        payload: message.data.toString(),
        channelId: _getChannelForMessageType(message.data['type']),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('NotificationService: Notification tapped: ${message.data}');
    // TODO: Navigate based on notification type
    final type = message.data['type'];
    final orderId = message.data['order_id'];
    
    switch (type) {
      case 'new_order':
      case 'order_assigned':
        // Navigate to order details
        print('NotificationService: Should navigate to order: $orderId');
        break;
      case 'customer_message':
        // Navigate to chat
        print('NotificationService: Should navigate to chat for order: $orderId');
        break;
      default:
        print('NotificationService: Unknown notification type: $type');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('NotificationService: Local notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  String _getChannelForMessageType(String? type) {
    switch (type) {
      case 'new_order':
      case 'order_assigned':
      case 'order_update':
        return _orderChannel.id;
      case 'customer_message':
        return _messageChannel.id;
      default:
        return _systemChannel.id;
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? channelId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? _systemChannel.id,
      channelId == _orderChannel.id ? 'Order Notifications' : 
        channelId == _messageChannel.id ? 'Messages' : 'System Notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show a notification for a new available order
  Future<void> showNewOrderNotification({
    required String restaurantName,
    required String earnings,
    String? orderId,
  }) async {
    await _showLocalNotification(
      title: '🔔 New Order Available!',
      body: '$restaurantName - Earn $earnings',
      payload: orderId,
      channelId: _orderChannel.id,
    );
  }

  /// Show a notification when an order is assigned
  Future<void> showOrderAssignedNotification({
    required String restaurantName,
    required String customerName,
    String? orderId,
  }) async {
    await _showLocalNotification(
      title: '✅ Order Assigned',
      body: 'Pick up from $restaurantName for $customerName',
      payload: orderId,
      channelId: _orderChannel.id,
    );
  }

  /// Show a notification for customer messages
  Future<void> showMessageNotification({
    required String customerName,
    required String message,
    String? orderId,
  }) async {
    await _showLocalNotification(
      title: '💬 Message from $customerName',
      body: message,
      payload: orderId,
      channelId: _messageChannel.id,
    );
  }

  /// Subscribe to driver-specific topics
  Future<void> subscribeToDriverTopics(String driverId) async {
    await _messaging.subscribeToTopic('drivers');
    await _messaging.subscribeToTopic('driver_$driverId');
    print('NotificationService: Subscribed to driver topics');
  }

  /// Unsubscribe from driver topics (on logout)
  Future<void> unsubscribeFromDriverTopics(String driverId) async {
    await _messaging.unsubscribeFromTopic('drivers');
    await _messaging.unsubscribeFromTopic('driver_$driverId');
    print('NotificationService: Unsubscribed from driver topics');
  }
}
