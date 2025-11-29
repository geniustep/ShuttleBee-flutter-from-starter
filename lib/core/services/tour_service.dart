import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:bridgecore_flutter_starter/core/storage/prefs_storage_service.dart';

/// Tour guide service
class TourService {
  static final TourService _instance = TourService._internal();
  factory TourService() => _instance;
  TourService._internal();

  TutorialCoachMark? _tutorialCoachMark;

  /// Show home tour
  Future<void> showHomeTour({
    required BuildContext context,
    required List<GlobalKey> keys,
  }) async {
    // Check if tour was already shown
    final tourShown = await PrefsStorageService.instance.read<bool>(
      key: 'tour_home_shown',
    );

    if (tourShown == true) return;

    final targets = [
      TargetFocus(
        identify: 'drawer',
        keyTarget: keys[0],
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTourContent(
                title: 'Navigation Menu',
                description: 'Tap here to access all features and settings',
                onNext: () => controller.next(),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: 'dashboard',
        keyTarget: keys[1],
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                title: 'Dashboard',
                description: 'View your key metrics and performance indicators',
                onNext: () => controller.next(),
                onPrevious: () => controller.previous(),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: 'sync',
        keyTarget: keys[2],
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                title: 'Sync Status',
                description: 'Check your sync status and pending operations',
                onNext: () => controller.next(),
                onPrevious: () => controller.previous(),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: 'notifications',
        keyTarget: keys[3],
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTourContent(
                title: 'Notifications',
                description: 'Stay updated with important notifications',
                onNext: () {
                  controller.next();
                  PrefsStorageService.instance.write(
                    key: 'tour_home_shown',
                    value: true,
                  );
                },
                onPrevious: () => controller.previous(),
              );
            },
          ),
        ],
      ),
    ];

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        PrefsStorageService.instance.write(
          key: 'tour_home_shown',
          value: true,
        );
      },
      onSkip: () {
        PrefsStorageService.instance.write(
          key: 'tour_home_shown',
          value: true,
        );
        return true;
      },
    );

    if (!context.mounted) return;
    _tutorialCoachMark!.show(context: context);
  }

  Widget _buildTourContent({
    required String title,
    required String description,
    VoidCallback? onNext,
    VoidCallback? onPrevious,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onPrevious != null)
                TextButton(
                  onPressed: onPrevious,
                  child: const Text('Previous'),
                ),
              if (onNext != null) const SizedBox(width: 8),
              if (onNext != null)
                ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Next'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Reset all tours
  Future<void> resetTours() async {
    await PrefsStorageService.instance.delete(key: 'tour_home_shown');
    // Add more tour keys as needed
  }

  /// Stop current tour
  void stop() {
    _tutorialCoachMark?.finish();
  }
}
