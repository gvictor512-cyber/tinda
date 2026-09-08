import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import 'video_call_screen.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _Visit {
  final String title;
  final DateTime date;
  final String type;

  _Visit({required this.title, required this.date, required this.type});
}

class _VisitsScreenState extends State<VisitsScreen> {
  final List<_Visit> _visits = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visits.addAll([
      _Visit(
        title: 'Videollamada con Ana',
        date: now.add(const Duration(minutes: 2)),
        type: 'Videollamada',
      ),
    ]);
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isReady(_Visit visit) {
    return visit.type == 'Videollamada' && DateTime.now().isAfter(visit.date);
  }

  Future<void> _addVisit() async {
    final now = DateTime.now();
    DateTime selectedDate = now.add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(now);
    String type = 'Presencial';
    final titleController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva cita'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(selectedTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'Presencial', child: Text('Presencial')),
                    DropdownMenuItem(value: 'Videollamada', child: Text('Videollamada')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => type = value);
                  },
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                if (type == 'Videollamada') ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Se desbloqueará el botón de videollamada cuando llegue la hora programada.',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final date = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      setState(() {
        _visits.add(_Visit(
          title: titleController.text.isNotEmpty ? titleController.text : 'Nueva cita',
          date: date,
          type: type,
        ));
        _visits.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  void _joinCall(_Visit visit) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => VideoCallScreen(callWith: visit.title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas y videollamadas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Próximas citas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Concierta visitas y videollamadas. El botón se desbloquea a la hora programada.',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ..._visits.map((v) => _buildVisitCard(v, isDarkMode)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVisit,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Nueva cita'),
      ),
    );
  }

  Widget _buildVisitCard(_Visit visit, bool isDarkMode) {
    final isVideo = visit.type == 'Videollamada';
    final ready = _isReady(visit);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVideo ? Icons.videocam : Icons.door_front_door,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(visit.date),
                  style: TextStyle(
                    color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isVideo)
            ready
                ? ElevatedButton.icon(
                    onPressed: () => _joinCall(visit),
                    icon: const Icon(Icons.videocam, size: 16),
                    label: const Text('Unirse'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  )
                : Chip(
                    label: const Text('Pronto'),
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    side: BorderSide.none,
                  ),
          if (!isVideo)
            Chip(
              label: Text(visit.type),
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final sameDay = date.year == today.year && date.month == today.month && date.day == today.day;
    final time = DateFormat('HH:mm').format(date);
    if (sameDay) return 'Hoy, $time';
    final tomorrow = today.add(const Duration(days: 1));
    final isTomorrow = date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
    if (isTomorrow) return 'Mañana, $time';
    return '${DateFormat('dd/MM').format(date)}, $time';
  }
}
