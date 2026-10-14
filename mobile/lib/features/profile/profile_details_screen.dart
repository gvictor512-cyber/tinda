import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ProfileDetailsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final photos = profile['photos'] as List?;
    return Scaffold(
      appBar: AppBar(
        title: Text(profile['name'] ?? 'Perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile details
          Center(
            child: Hero(
              tag: 'profile-${profile['uid']}',
              child: CircleAvatar(
                radius: 60,
                backgroundImage: photos != null && photos.isNotEmpty
                    ? CachedNetworkImageProvider(photos[0] as String, maxWidth: 400)
                    : null,
                child: photos == null || photos.isEmpty
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
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
