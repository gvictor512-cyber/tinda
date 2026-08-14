import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'profile_card.dart';
import '../apartment/apartment_details_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final SwipableStackController _controller = SwipableStackController();
  
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  // ignore: unused_field
  int _currentIndex = 0;
  int _likesRemaining = 10;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _loadDailyLimits();
  }

  Future<void> _loadDailyLimits() async {
    // TODO: Load daily limits from Firestore
    setState(() {
      _likesRemaining = 10;
    });
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load profiles from API based on filters
      // For now, using mock data with minimal delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      setState(() {
        _profiles = _getMockProfiles();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      setState(() {
        _profiles = _getMockProfiles();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockProfiles() {
    return [
      {
        'id': '1',
        'name': 'María',
        'age': 24,
        'profession': 'Estudiante',
        'city': 'Madrid',
        'bio': 'Busco compañeros tranquilos y ordenados. Me encanta cocinar y viajar.',
        'photos': ['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400'],
        'compatibility': 85,
        'badges': ['Muy limpio', 'No fumador'],
        'apartment': {
          'title': 'Piso luminoso en Chamberí',
          'location': 'Madrid, Chamberí',
          'price': 650,
          'bedrooms': 2,
          'bathrooms': 1,
          'area': 65,
          'floor': 2,
          'description': 'Piso exterior con mucho sol, cerca de metro Iglesia y Canal. Cocina reformada, amueblado. Ideal para estudiantes.',
          'photos': [
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
            'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
            'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800',
          ],
          'conditions': {
            'Estudiantes': true,
            'Trabajadores': true,
            'Mascotas': false,
            'Fumadores': false,
            'Parejas': false,
            'Ruido nocturno': false,
            'Visitantes frecuentes': true,
          },
        },
      },
      {
        'id': '2',
        'name': 'Carlos',
        'age': 28,
        'profession': 'Ingeniero',
        'city': 'Madrid',
        'bio': 'Trabajo remoto, busco piso tranquilo. Me gustan el cine y la lectura.',
        'photos': ['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400'],
        'compatibility': 92,
        'badges': ['Teletrabajo', 'Tranquilo'],
        'apartment': {
          'title': 'Ático moderno en Salamanca',
          'location': 'Madrid, Salamanca',
          'price': 1200,
          'bedrooms': 3,
          'bathrooms': 2,
          'area': 110,
          'floor': 6,
          'description': 'Ático con terraza, vistas panorámicas. Aire acondicionado, calefacción, trastero. Zona muy tranquila.',
          'photos': [
            'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
            'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=800',
            'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
          ],
          'conditions': {
            'Estudiantes': false,
            'Trabajadores': true,
            'Mascotas': true,
            'Fumadores': false,
            'Parejas': true,
            'Ruido nocturno': false,
            'Visitantes frecuentes': false,
          },
        },
      },
      {
        'id': '3',
        'name': 'Lucía',
        'age': 26,
        'profession': 'Diseñadora',
        'city': 'Madrid',
        'bio': 'Creativa y sociable. Busco compañeros con buena vibra.',
        'photos': ['https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400'],
        'compatibility': 78,
        'badges': ['Sociable', 'Amante de animales'],
        'apartment': {
          'title': 'Loft industrial en Lavapiés',
          'location': 'Madrid, Lavapiés',
          'price': 800,
          'bedrooms': 1,
          'bathrooms': 1,
          'area': 55,
          'floor': 1,
          'description': 'Loft con alturas de techo, muy luminoso. Zona multicultural, cerca de museos y restaurantes. Ideal para personas creativas.',
          'photos': [
            'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800',
            'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
            'https://images.unsplash.com/photo-1560185007-c5ca9d2c014d?w=800',
          ],
          'conditions': {
            'Estudiantes': true,
            'Trabajadores': true,
            'Mascotas': true,
            'Fumadores': true,
            'Parejas': true,
            'Ruido nocturno': true,
            'Visitantes frecuentes': true,
          },
        },
      },
    ];
  }

  void _onSwipeLeft() {
    if (_profiles.isEmpty) return;
    
    // TODO: Send dislike to backend
    setState(() {
      _profiles.removeAt(0);
      _currentIndex = 0;
    });
  }

  void _onSwipeRight() async {
    if (_profiles.isEmpty || _likesRemaining <= 0) {
      _showPremiumDialog();
      return;
    }

    // TODO: Send like to backend
    setState(() {
      _profiles.removeAt(0);
      _currentIndex = 0;
      _likesRemaining--;
    });
  }

  void _onSuperLike() async {
    if (_profiles.isEmpty || _likesRemaining <= 0) {
      _showPremiumDialog();
      return;
    }

    // TODO: Send super like to backend
    setState(() {
      _profiles.removeAt(0);
      _currentIndex = 0;
      _likesRemaining--;
    });
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Límite diario alcanzado'),
        content: const Text('Hazte Premium para tener me gustas ilimitados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium no disponible en modo demostración')),
              );
            },
            child: const Text('Ver Premium'),
          ),
        ],
      ),
    );
  }

  void _showProfileDetails(Map<String, dynamic> profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApartmentDetailsScreen(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Descubrir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtros no disponibles en modo demostración')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfiles,
          ),
        ],
      ),
      body: Column(
        children: [
          // Likes counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_likesRemaining me gustas restantes hoy',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Swipe area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _profiles.isEmpty
                    ? _buildEmptyState()
                    : _buildSwipeStack(),
          ),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay más perfiles',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta tus filtros o vuelve más tarde',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProfiles,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeStack() {
    return SwipableStack(
      controller: _controller,
      onSwipeCompleted: (direction, details) {
        if (direction == SwipeDirection.left) {
          _onSwipeLeft();
        } else if (direction == SwipeDirection.right) {
          _onSwipeRight();
        }
      },
      builder: (context, properties) {
        if (_profiles.isEmpty) return const SizedBox();
        
        final profile = _profiles[0];
        return ProfileCard(
          profile: profile,
          onInfoPressed: () => _showProfileDetails(profile),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.close,
            color: Colors.red,
            onPressed: () {
              _controller.next(swipeDirection: SwipeDirection.left);
              _onSwipeLeft();
            },
          ),
          _ActionButton(
            icon: Icons.star,
            color: Colors.blue,
            size: 50,
            onPressed: _onSuperLike,
          ),
          _ActionButton(
            icon: Icons.favorite,
            color: Colors.green,
            onPressed: () {
              _controller.next(swipeDirection: SwipeDirection.right);
              _onSwipeRight();
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.size = 45,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 20,
      height: size + 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
      ),
    );
  }
}
