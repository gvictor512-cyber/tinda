import 'package:flutter/material.dart';

class GroupScreen extends StatelessWidget {
  final Map<String, dynamic> group;

  const GroupScreen({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final members = group['members'] as List<dynamic>? ?? [];
    final compatibilityScore = group['compatibilityScore'] ?? 0;
    final userRole = group['userRole'] ?? 'member';

    return Scaffold(
      appBar: AppBar(
        title: Text(group['name'] ?? 'Grupo'),
        actions: [
          if (userRole == 'creator' || userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettings(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGroupInfo(),
          const SizedBox(height: 24),
          _buildCompatibilityScore(compatibilityScore),
          const SizedBox(height: 24),
          _buildMembersList(context, members, userRole),
          const SizedBox(height: 24),
          if (userRole == 'creator' || userRole == 'admin')
            _buildAdminActions(context),
        ],
      ),
    );
  }

  Widget _buildGroupInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Color(0xFF4A90E2),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'] ?? 'Grupo',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (group['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          group['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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

  Widget _buildCompatibilityScore(int score) {
    Color scoreColor;
    String scoreText;

    if (score >= 85) {
      scoreColor = Colors.green;
      scoreText = 'Excelente';
    } else if (score >= 70) {
      scoreColor = const Color(0xFF4A90E2);
      scoreText = 'Buena';
    } else if (score >= 50) {
      scoreColor = Colors.orange;
      scoreText = 'Moderada';
    } else {
      scoreColor = Colors.red;
      scoreText = 'Baja';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Compatibilidad Grupal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$score%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Nivel de compatibilidad: $scoreText',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(BuildContext context, List<dynamic> members, String userRole) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Miembros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${members.length} miembros',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...members.map((member) => _buildMemberTile(context, member, userRole)),
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, dynamic member, String userRole) {
    final profile = member['profile'];
    final role = member['role'];
    final userName = profile?['firstName'] ?? 'Usuario';
    final userPhoto = profile?['profilePhotoUrl'];

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
          child: userPhoto == null ? const Icon(Icons.person) : null,
        ),
        title: Row(
          children: [
            Text(userName),
            const SizedBox(width: 8),
            if (role == 'creator')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Creador',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (role == 'admin')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(profile?['profession'] ?? ''),
        trailing: (userRole == 'creator' || userRole == 'admin') && role != 'creator'
            ? IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showMemberOptions(context, member),
              )
            : null,
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones de Admin',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Añadir miembro'),
                onTap: () => _addMember(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar grupo'),
                onTap: () => _editGroup(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar grupo', style: TextStyle(color: Colors.red)),
                onTap: () => _deleteGroup(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSettings(BuildContext context) {
    // TODO: Show group settings
  }

  void _showMemberOptions(BuildContext context, dynamic member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Hacer admin'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Make admin
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Eliminar del grupo', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Remove member
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addMember(BuildContext context) {
    // TODO: Navigate to add member screen
  }

  void _editGroup(BuildContext context) {
    // TODO: Navigate to edit group screen
  }

  void _deleteGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: const Text('¿Estás seguro de que quieres eliminar este grupo? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete group
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
