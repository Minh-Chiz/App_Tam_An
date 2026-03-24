import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart'; // Thêm import HomeScreen
import 'screens/emotion_flow_screen.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/emotion_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/ai_companion_provider.dart';
import 'providers/reminder_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null);
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProxyProvider<AuthProvider, ThemeProvider>(
          create: (_) => ThemeProvider(apiService),
          update: (_, auth, theme) {
            if (auth.isAuthenticated && auth.userSettings != null) {
              theme!.setInitialTheme(auth.userSettings!['theme_mode']);
            }
            return theme!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, EmotionProvider>(
          create: (_) => EmotionProvider(apiService),
          update: (_, auth, emotion) {
            if (auth.isAuthenticated && auth.userSettings != null) {
              final customEmotions = (auth.userSettings!['custom_emotions'] as List?)?.cast<String>();
              if (customEmotions != null) {
                emotion!.setInitialCustomEmotions(customEmotions);
              }
            } else if (!auth.isAuthenticated) {
              Future.microtask(() => emotion!.clear());
            }
            return emotion!;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReminderProvider>(
          create: (_) => ReminderProvider(apiService),
          update: (_, auth, reminder) {
            if (auth.isAuthenticated && auth.userSettings != null) {
              final settings = auth.userSettings!['reminder_settings'] as Map<String, dynamic>?;
              if (settings != null) {
                reminder!.setInitialSettings(settings);
              }
            }
            return reminder!;
          },
        ),
        ChangeNotifierProvider(create: (_) => AICompanionProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TÂM AN',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                // Show loading while checking auth
                if (authProvider.isLoading) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Navigate based on auth state
                // After login, go to EmotionFlowScreen first
                return authProvider.isAuthenticated
                    ? (authProvider.isFreshLogin ? const EmotionFlowScreen() : const HomeScreen())
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
