import 'package:flutter/material.dart';
import 'theme.dart';
import 'router.dart';

class BookEasyApp extends StatelessWidget {
  const BookEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BookEasy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}