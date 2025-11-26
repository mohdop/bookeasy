import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // Add this import
import 'theme.dart';
import 'router.dart';

class BookEasyApp extends StatelessWidget {
  const BookEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(  // Add this wrapper
      child: MaterialApp.router(
        title: 'BookEasy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}