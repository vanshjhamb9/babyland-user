import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/notification_service.dart';

/// AI-powered notification intelligence.
///
/// Sends contextual health notifications based on AI insights.
class AiNotificationService {
  final NotificationService _notificationService;

  AiNotificationService({NotificationService? notificationService})
      : _notificationService = notificationService ?? sl.notificationService;

  /// Sends an AI health tip notification.
  Future<void> sendHealthTip({
    required String tip,
    String? title,
  }) async {
    await _notificationService.showNotification(
      title: title ?? '💡 ${AppConstants.aiAssistantDisplayName} Health Tip',
      body: tip,
      type: NotificationType.aiAssistant,
      data: {'type': 'ai_assistant', 'action': 'health_tip'},
    );
  }

  /// Sends a pregnancy milestone notification.
  Future<void> sendMilestoneUpdate({
    required String milestone,
    int? week,
  }) async {
    await _notificationService.showNotification(
      title: '🎉 Pregnancy Milestone',
      body: milestone,
      type: NotificationType.pregnancyMilestone,
      data: {
        'type': 'pregnancy_milestone',
        'week': week?.toString() ?? '',
      },
    );
  }

  /// Sends a medical checkup reminder.
  Future<void> sendCheckupReminder({
    required String message,
    String? appointmentDate,
  }) async {
    await _notificationService.showNotification(
      title: '🏥 Medical Checkup Reminder',
      body: message,
      type: NotificationType.appointmentReminder,
      data: {
        'type': 'appointment_reminder',
        'date': appointmentDate ?? '',
      },
    );
  }

  /// Sends a nutrition reminder based on AI insights.
  Future<void> sendNutritionReminder({required String message}) async {
    await _notificationService.showNotification(
      title: '🥗 Nutrition Reminder',
      body: message,
      type: NotificationType.aiAssistant,
      data: {'type': 'ai_assistant', 'action': 'nutrition_reminder'},
    );
  }

  /// Sends daily guidance notification.
  Future<void> sendDailyGuidance({required List<String> tips}) async {
    if (tips.isEmpty) return;
    await _notificationService.showNotification(
      title: '✨ Your daily ${AppConstants.aiAssistantDisplayName} guidance',
      body: tips.first,
      type: NotificationType.aiAssistant,
      data: {'type': 'ai_assistant', 'action': 'daily_guidance'},
    );
  }
}
