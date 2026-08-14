import 'package:flutter/material.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int _maxMembers = 4;
  final List<String> _selectedMembers = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Grupo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNameField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildMaxMembersSlider(),
            const SizedBox(height: 24),
            _buildMembersSection(),
            const SizedBox(height: 24),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nombre del grupo',
        hintText: 'Ej: Grupo piso Madrid',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El nombre es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Descripción',
        hintText: 'Describe el propósito del grupo',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMaxMembersSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Máximo de miembros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$_maxMembers',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: _maxMembers.toDouble(),
          min: 2,
          max: 10,
          divisions: 8,
          label: '$_maxMembers miembros',
          onChanged: (value) {
            setState(() => _maxMembers = value.toInt());
          },
        ),
        Text(
          'Mínimo 2, máximo 10 miembros',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Miembros iniciales',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_selectedMembers.length}/$_maxMembers',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.group_add, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Añade miembros desde tus matches',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedMembers.map((memberId) {
              return Chip(
                label: Text('Usuario $memberId'),
                onDeleted: () {
                  setState(() {
                    _selectedMembers.remove(memberId);
                  });
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _selectedMembers.length >= _maxMembers ? null : _addMember,
          icon: const Icon(Icons.add),
          label: const Text('Añadir miembro'),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _createGroup,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF4A90E2),
        ),
        child: const Text(
          'Crear Grupo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _addMember() {
    // TODO: Navigate to member selection screen (from matches)
    Navigator.pushNamed(context, '/select-members').then((selectedMembers) {
      if (selectedMembers != null && selectedMembers is List<String>) {
        setState(() {
          _selectedMembers.addAll(selectedMembers);
        });
      }
    });
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un miembro')),
      );
      return;
    }

    // TODO: Create group via API
    Navigator.pop(context, {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'maxMembers': _maxMembers,
      'members': _selectedMembers,
    });
  }
}
