import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import '../widgets/dispatcher_app_bar.dart';
import 'dispatcher_create_group_screen.dart';

class DispatcherEditGroupScreen extends ConsumerWidget {
  final int groupId;

  const DispatcherEditGroupScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            appBar: DispatcherAppBar(title: 'تعديل المجموعة'),
            body: Center(
              child: Text(
                'تعذر تحميل بيانات المجموعة.',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          );
        }

        return DispatcherCreateGroupScreen(
          key: ValueKey('dispatcher_edit_group_${group.id}'),
          initialGroup: group,
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        appBar: DispatcherAppBar(title: 'تعديل المجموعة'),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.dispatcherPrimary,
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: const DispatcherAppBar(title: 'تعديل المجموعة'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              e.toString(),
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
