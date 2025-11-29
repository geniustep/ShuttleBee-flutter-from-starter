import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_dimensions.dart';

/// Loading Widgets for Driver Screens - ShuttleBee

/// Statistics Shimmer Loading
class StatisticsShimmer extends StatelessWidget {
  const StatisticsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        child: Row(
          children: List.generate(
            3,
            (index) => Expanded(
              child: Container(
                height: 100,
                margin: EdgeInsets.only(
                  left: index < 2 ? AppDimensions.sm : 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Trips List Shimmer Loading
class TripsListShimmer extends StatelessWidget {
  final int itemCount;

  const TripsListShimmer({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.md),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          );
        },
      ),
    );
  }
}

/// Trip Detail Shimmer Loading
class TripDetailShimmer extends StatelessWidget {
  const TripDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Info Card
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),

            const SizedBox(height: AppDimensions.md),

            // Vehicle Info Card
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),

            const SizedBox(height: AppDimensions.md),

            // Passengers Section Header
            Container(
              height: 24,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),

            const SizedBox(height: AppDimensions.sm),

            // Passenger Items
            ...List.generate(
              3,
              (index) => Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: AppDimensions.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Passenger List Shimmer Loading
class PassengerListShimmer extends StatelessWidget {
  final int itemCount;

  const PassengerListShimmer({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.md),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: AppDimensions.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          );
        },
      ),
    );
  }
}
