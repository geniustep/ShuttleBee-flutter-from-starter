import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../widgets/unified_action_button.dart';
import '../../shared/widgets/responsive/responsive_scaffold.dart';

/// مثال على استخدام النظام المتجاوب الجديد
/// يوضح كيفية إنشاء شاشة تتكيف مع جميع أحجام الأجهزة
class ResponsiveScreenExample extends StatefulWidget {
  const ResponsiveScreenExample({super.key});

  @override
  State<ResponsiveScreenExample> createState() =>
      _ResponsiveScreenExampleState();
}

class _ResponsiveScreenExampleState extends State<ResponsiveScreenExample> {
  int _selectedRailIndex = 0;

  @override
  Widget build(BuildContext context) {
    // الحصول على نوع الجهاز
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    // استخدام ResponsiveScaffold من shared/widgets (المتقدم)
    return ResponsiveScaffold(
      currentIndex: _selectedRailIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedRailIndex = index);
      },
      destinations: const [
        ResponsiveNavItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'الرئيسية',
        ),
        ResponsiveNavItem(
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: 'لوحة التحكم',
        ),
        ResponsiveNavItem(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: 'المستخدمين',
        ),
      ],
      pages: [
        // صفحة واحدة فقط - نفس المحتوى لكل الصفحات
        SingleChildScrollView(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان يتكيف مع حجم الشاشة
              Text(
                'مرحباً بك!',
                style: TextStyle(
                  fontSize: context.responsive(
                    mobile: 24.0,
                    tablet: 28.0,
                    desktop: 32.0,
                  ),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),

              const SizedBox(height: 24),

              // بطاقات معلومات
              _buildInfoCards(context),

              const SizedBox(height: 24),

              // أمثلة على الأزرار الموحدة
              _buildButtonExamples(context),

              const SizedBox(height: 24),

              // جدول يتكيف مع حجم الشاشة
              _buildResponsiveTable(context),
            ],
          ),
        ),
        // نفس المحتوى لجميع الصفحات (مثال)
        SingleChildScrollView(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontSize: context.responsive(
                    mobile: 24.0,
                    tablet: 28.0,
                    desktop: 32.0,
                  ),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المستخدمين',
                style: TextStyle(
                  fontSize: context.responsive(
                    mobile: 24.0,
                    tablet: 28.0,
                    desktop: 32.0,
                  ),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ],
      appBar: AppBar(
        title: const Text('مثال على الشاشة المتجاوبة'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              avatar: Icon(
                isMobile
                    ? Icons.phone_android
                    : isTablet
                    ? Icons.tablet
                    : Icons.computer,
              ),
              label: Text(
                isMobile
                    ? 'Mobile'
                    : isTablet
                    ? 'Tablet'
                    : 'Desktop',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    // تحديد عدد الأعمدة بناءً على حجم الشاشة
    final crossAxisCount = context.responsive(mobile: 1, tablet: 2, desktop: 3);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'إجمالي المستخدمين',
          '1,234',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'النشط اليوم',
          '456',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'في الانتظار',
          '78',
          Icons.pending,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonExamples(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أمثلة على الأزرار الموحدة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 16),

            // أزرار أساسية
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                UnifiedActionButton.primary(
                  label: 'حفظ',
                  icon: Icons.save,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم الحفظ بنجاح!')),
                    );
                  },
                ),
                UnifiedActionButton.secondary(
                  label: 'إلغاء',
                  icon: Icons.cancel,
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('تم الإلغاء')));
                  },
                ),
                UnifiedActionButton.primary(
                  label: 'مدمج',
                  isCompact: true,
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 16),

            // أزرار أيقونات
            Row(
              children: [
                UnifiedIconButton(
                  icon: Icons.add,
                  tooltip: 'إضافة',
                  backgroundColor: Colors.blue,
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                UnifiedIconButton(
                  icon: Icons.edit,
                  tooltip: 'تعديل',
                  backgroundColor: Colors.orange,
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                UnifiedIconButton(
                  icon: Icons.delete,
                  tooltip: 'حذف',
                  backgroundColor: Colors.red,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveTable(BuildContext context) {
    // على الجوال: قائمة عمودية
    // على التابلت/سطح المكتب: جدول أفقي
    final isMobile = context.isMobile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'البيانات المتكيفة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 16),
            if (isMobile)
              // عرض عمودي للجوال
              Column(
                children: List.generate(
                  3,
                  (index) => ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text('مستخدم ${index + 1}'),
                    subtitle: Text('user${index + 1}@example.com'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),
              )
            else
              // عرض جدولي للتابلت/سطح المكتب
              Table(
                border: TableBorder.all(color: Colors.grey[300]!),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Colors.blue),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'الاسم',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'البريد الإلكتروني',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...List.generate(
                    3,
                    (index) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${index + 1}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('مستخدم ${index + 1}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('user${index + 1}@example.com'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
