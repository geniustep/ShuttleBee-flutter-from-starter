import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 🔌 Connection Status Indicator Widget - ويدجت مؤشر حالة الاتصال
///
/// يعرض شريط حالة الاتصال في الوقت الحقيقي
class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusIndicator({
    super.key,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    // إخفاء الشريط عند الاتصال
    if (isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondaryDark,
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // مؤشر التحميل
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          
          // النص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'جاري إعادة الاتصال...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                    color: Colors.white,
                  ),
                ),
                Text(
                  'التتبع الحي متوقف مؤقتاً',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Cairo',
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // أيقونة عدم الاتصال
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🟢 Connected Status Badge - شارة حالة الاتصال
/// يمكن استخدامها في أماكن أخرى
class ConnectionStatusBadge extends StatelessWidget {
  final bool isConnected;
  final bool showText;

  const ConnectionStatusBadge({
    super.key,
    required this.isConnected,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isConnected ? AppColors.success : AppColors.error)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isConnected ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // النقطة المضيئة
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.success : AppColors.error,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          if (showText) ...[
            const SizedBox(width: 8),
            Text(
              isConnected ? 'متصل' : 'غير متصل',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isConnected ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
