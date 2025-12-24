import 'package:flutter/material.dart';

class RoleSwitcher extends StatelessWidget {
  final bool isDispatcherMode;
  final ValueChanged<bool> onRoleChanged;

  const RoleSwitcher({
    super.key,
    required this.isDispatcherMode,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRoleButton(
            label: 'Dispatcher',
            icon: Icons.dashboard,
            isSelected: isDispatcherMode,
            onTap: () => onRoleChanged(true),
          ),
          const SizedBox(width: 4),
          _buildRoleButton(
            label: 'Monitor',
            icon: Icons.visibility,
            isSelected: !isDispatcherMode,
            onTap: () => onRoleChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
