import 'package:flutter/material.dart';
import 'package:roommatematch/core/auth/login_screen.dart';
import 'package:roommatematch/app.dart';
import 'package:roommatematch/features/profile/profile_screen.dart';
import 'package:roommatematch/features/profile/compatibility_settings.dart';
import 'package:roommatematch/features/swipe/swipe_screen_simple.dart';
import 'package:roommatematch/features/chat/chat_screen.dart';
import 'package:roommatematch/features/chat/chat_list_screen.dart';
import 'package:roommatematch/features/filters/filters_screen.dart';
import 'package:roommatematch/features/premium/premium_screen.dart';
import 'package:roommatematch/features/verification/verification_screen.dart';
import 'package:roommatematch/features/group/group_creation_screen.dart';
import 'package:roommatematch/features/group/group_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String compatibilitySettings = '/compatibility-settings';
  static const String swipe = '/swipe';
  static const String chat = '/chat';
  static const String chatList = '/chat-list';
  static const String filters = '/filters';
  static const String premium = '/premium';
  static const String verification = '/verification';
  static const String createGroup = '/create-group';
  static const String group = '/group';
  static const String profileDetails = '/profile-details';
  static const String selectMembers = '/select-members';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      home: (context) => const MainScreen(),
      profile: (context) => const ProfileScreen(),
      compatibilitySettings: (context) => const CompatibilitySettingsScreen(),
      swipe: (context) => const SwipeScreen(),
      chat: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ChatScreen(
          matchId: args?['matchId'] ?? '',
          otherUserName: args?['otherUserName'] ?? 'Usuario',
          otherUserPhoto: args?['otherUserPhoto'] ?? '',
        );
      },
      chatList: (context) => const ChatListScreen(),
      filters: (context) => const FiltersScreen(),
      premium: (context) => const PremiumScreen(),
      verification: (context) => const VerificationScreen(),
      createGroup: (context) => const GroupCreationScreen(),
      group: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return GroupScreen(group: args ?? {});
      },
      profileDetails: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ProfileDetailsScreen(profile: args ?? {});
      },
    };
  }
}

class ProfileDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ProfileDetailsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profile['name'] ?? 'Perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile details
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: profile['photos'] != null && profile['photos'].isNotEmpty
                  ? NetworkImage(profile['photos'][0])
                  : null,
              child: profile['photos'] == null || profile['photos'].isEmpty
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${profile['name']}, ${profile['age']}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            profile['profession'] ?? '',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (profile['bio'] != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  profile['bio'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (profile['badges'] != null)
            Wrap(
              spacing: 8,
              children: (profile['badges'] as List).map((badge) {
                return Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 16),
                      const SizedBox(width: 4),
                      Text(badge),
                    ],
                  ),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: const Center(
        child: Text('Pantalla de registro'),
      ),
    );
  }
}
