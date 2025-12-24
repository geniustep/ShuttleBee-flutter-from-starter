import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/examples/responsive_screen_example.dart';

/// ملف اختبار مؤقت لرؤية التحسينات الجديدة
/// شغّل هذا الملف بدلاً من main.dart لرؤية المثال التوضيحي
void main() {
  runApp(const ProviderScope(child: MyTestApp()));
}

class MyTestApp extends StatelessWidget {
  const MyTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اختبار التحسينات المتجاوبة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
        useMaterial3: true,
      ),
      home: const ResponsiveScreenExample(),
    );
  }
}
