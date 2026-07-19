# Quick Start Guide - Using the Integrated Services

This guide shows you how to quickly use all the integrated services in your Flutter app.

---

## 🚀 Getting Started

### 1. Initialize Services

```dart
// In main.dart or app initialization
await ServiceLocator().init();
```

### 2. Access Services

```dart
final sl = ServiceLocator();

// All services are now available:
// - sl.healthTrackerService
// - sl.dashboardService
// - sl.userService
// - sl.aiIntelligenceService
// - sl.aiService
```

---

## 💧 Health Trackers

### Create a Log

```dart
// Hydration
final hydration = HydrationLog(
  amountMl: 500,
  type: 'water',
  timestamp: DateTime.now(),
);
await sl.healthTrackerService.createHydrationLog(hydration);

// Sleep
final sleep = SleepLog(
  sleepStartTime: DateTime.now().subtract(Duration(hours: 8)),
  sleepEndTime: DateTime.now(),
  durationMinutes: 480,
  qualityScore: 4,
);
await sl.healthTrackerService.createSleepLog(sleep);

// Symptom
final symptom = SymptomLog(
  symptomName: 'Nausea',
  severity: 7,
  durationHours: 2.5,
  timestamp: DateTime.now(),
);
await sl.healthTrackerService.createSymptomLog(symptom);
```

### Get Logs

```dart
// Get paginated logs
final logs = await sl.healthTrackerService.getHydrationLogs(
  from: DateTime.now().subtract(Duration(days: 7)),
  to: DateTime.now(),
  page: 1,
  limit: 20,
);

// Access data
print('Total: ${logs.total}');
print('Items: ${logs.data.length}');
```

### Update/Delete

```dart
// Update
final updated = await sl.healthTrackerService.updateHydrationLog(
  logId,
  updatedLog,
);

// Delete
await sl.healthTrackerService.deleteHydrationLog(logId);
```

---

## 📊 Dashboard

### Get Dashboard Data

```dart
final data = await sl.dashboardService.getDashboardData();

// Access summaries
print('Hydration today: ${data.healthSummary.hydration.today}ml');
print('Sleep last night: ${data.healthSummary.sleep.lastNight}min');
print('Active symptoms: ${data.healthSummary.symptoms.activeCount}');
```

### Real-time Updates

```dart
// Start real-time updates
final stream = sl.dashboardService.startRealTimeUpdates(
  interval: Duration(seconds: 10),
);

// Listen to updates
stream.listen((dashboardData) {
  // Update your UI
  setState(() {
    hydrationToday = dashboardData.healthSummary.hydration.today;
  });
});

// Stop when done (e.g., in dispose)
sl.dashboardService.stopRealTimeUpdates();
```

---

## 👤 User Profile

### Get Current User

```dart
final user = await sl.userService.getCurrentUser();
print('Name: ${user.name}');
print('Stage: ${user.stage}');
```

### Update Profile

```dart
final updated = await sl.userService.updateProfile(
  name: 'New Name',
  phone: '+1234567890',
);
```

### Stage Shifting

```dart
// Shift to pregnancy
final updated = await sl.userService.shiftStage(
  stage: 'pregnancy',
  pregnancyWeek: 12,
);

// Shift to postpregnancy
final updated = await sl.userService.shiftStage(
  stage: 'postpregnancy',
  babyAge: 3, // months
);
```

### Upload Photo

```dart
final updated = await sl.userService.updateProfile(
  photo: File('/path/to/photo.jpg'),
);
```

---

## 🤖 AI Chat

### Standard Chat

```dart
final response = await sl.aiService.sendMessageNew(
  'What should I eat during pregnancy?',
);

print('Reply: ${response.reply}');
print('Trace ID: ${response.traceId}');
```

### Streaming Chat

```dart
final stream = sl.aiService.sendMessageStream(
  'Tell me about pregnancy nutrition',
);

String fullResponse = '';
await for (final token in stream) {
  fullResponse += token;
  // Update UI with each token
  setState(() {
    aiResponse = fullResponse;
  });
}
```

---

## 🧠 AI Intelligence

### Get Recommendations

```dart
final recommendations = await sl.aiIntelligenceService.getRecommendations(
  days: 30,
  category: 'nutrition', // optional
);

for (final rec in recommendations) {
  print('${rec.title}: ${rec.description}');
  print('Confidence: ${rec.confidence}');
}
```

### Get Predictive Alerts

```dart
final alerts = await sl.aiIntelligenceService.getPredictiveAlerts();

for (final alert in alerts) {
  if (alert.severity == 'high' || alert.severity == 'critical') {
    // Show important alert
    print('⚠️ ${alert.title}: ${alert.message}');
  }
}
```

### Get Health Trends

```dart
final trends = await sl.aiIntelligenceService.getTrends(
  from: DateTime.now().subtract(Duration(days: 30)),
  to: DateTime.now(),
  metric: 'hydration', // optional
);

print('Trend direction: ${trends.trends['hydration']?.direction}');
```

---

## ⚠️ Error Handling

### Handle Errors Gracefully

```dart
try {
  final log = await sl.healthTrackerService.createHydrationLog(hydration);
} on NetworkException catch (e) {
  // Show: "No internet connection"
  showError('No internet connection. Please check your network.');
} on AuthException catch (e) {
  // Redirect to login
  Navigator.pushNamed(context, '/login');
} on ValidationException catch (e) {
  // Show field-specific errors
  if (e.fieldErrors != null) {
    for (final error in e.fieldErrors!.entries) {
      print('${error.key}: ${error.value}');
    }
  }
} on AppException catch (e) {
  // Generic error
  showError(e.message);
}
```

---

## 🔄 Real-time Updates Pattern

### Recommended Pattern

```dart
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription<DashboardData>? _dashboardSubscription;
  DashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    _startRealTimeUpdates();
  }

  void _startRealTimeUpdates() {
    final stream = ServiceLocator().dashboardService.startRealTimeUpdates();
    _dashboardSubscription = stream.listen((data) {
      setState(() {
        _dashboardData = data;
      });
    });
  }

  @override
  void dispose() {
    _dashboardSubscription?.cancel();
    ServiceLocator().dashboardService.stopRealTimeUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dashboardData == null) {
      return CircularProgressIndicator();
    }
    
    return DashboardUI(data: _dashboardData!);
  }
}
```

---

## 📝 Best Practices

1. **Always handle errors** - Use try-catch blocks
2. **Dispose streams** - Cancel subscriptions in dispose()
3. **Check connectivity** - Use ConnectivityService before API calls
4. **Respect rate limits** - Don't spam API calls
5. **Use pagination** - For large data sets
6. **Cache when possible** - Use CacheService for offline support

---

## 🎯 Next Steps

1. Create UI screens for each feature
2. Implement state management (Provider/Riverpod/Bloc)
3. Add loading states
4. Add error UI
5. Test with real backend
6. Optimize performance

---

**Happy Coding! 🚀**
