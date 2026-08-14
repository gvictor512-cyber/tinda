import 'package:flutter/material.dart';

class ApartmentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ApartmentDetailsScreen({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final apartment = profile['apartment'] ?? _getMockApartment();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Piso'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos carousel
            _buildPhotoCarousel(apartment['photos']),
            const SizedBox(height: 24),
            
            // Basic info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apartment['title'] ?? 'Piso en ${profile['city']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        apartment['location'] ?? profile['city'] ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.euro, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${apartment['price'] ?? '---'}€/mes',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Features
                  _buildFeatures(apartment),
                  const SizedBox(height: 24),
                  
                  // Description
                  _buildSectionTitle('Descripción'),
                  const SizedBox(height: 8),
                  Text(
                    apartment['description'] ?? 'Sin descripción',
                    style: TextStyle(color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  // Conditions
                  _buildSectionTitle('Condiciones del arrendatario'),
                  const SizedBox(height: 8),
                  _buildConditions(apartment['conditions']),
                  const SizedBox(height: 24),
                  
                  // Contact button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF4A90E2),
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel(List<dynamic>? photos) {
    final photoList = photos ?? _getMockPhotos();
    
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: photoList.length,
        itemBuilder: (context, index) {
          return Image.network(
            photoList[index],
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.home, size: 80, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFeatures(Map<String, dynamic> apartment) {
    final features = [
      {'icon': Icons.bed, 'label': '${apartment['bedrooms'] ?? 0} hab', 'value': apartment['bedrooms']},
      {'icon': Icons.bathtub, 'label': '${apartment['bathrooms'] ?? 0} baños', 'value': apartment['bathrooms']},
      {'icon': Icons.square_foot, 'label': '${apartment['area'] ?? 0} m²', 'value': apartment['area']},
      {'icon': Icons.layers, 'label': 'Planta ${apartment['floor'] ?? 1}', 'value': apartment['floor']},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: features.map((feature) {
        return Column(
          children: [
            Icon(feature['icon'], color: const Color(0xFF4A90E2)),
            const SizedBox(height: 4),
            Text(
              feature['label'],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildConditions(Map<String, dynamic>? conditions) {
    final conditionList = conditions ?? _getMockConditions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: conditionList.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                entry.value ? Icons.check_circle : Icons.cancel,
                color: entry.value ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: Colors.grey[700],
                    decoration: entry.value ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _getMockApartment() {
    return {
      'title': 'Piso moderno en centro',
      'location': 'Madrid, Centro',
      'price': 850,
      'bedrooms': 3,
      'bathrooms': 2,
      'area': 90,
      'floor': 3,
      'description': 'Piso luminoso con balcones, recién reformado. Cocina equipada, aire acondicionado y calefacción central. Muy bien comunicado con metro y autobuses.',
      'photos': _getMockPhotos(),
      'conditions': _getMockConditions(),
    };
  }

  List<String> _getMockPhotos() {
    return [
      'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800',
    ];
  }

  Map<String, bool> _getMockConditions() {
    return {
      'Estudiantes': true,
      'Trabajadores': true,
      'Mascotas': false,
      'Fumadores': false,
      'Parejas': true,
      'Ruido nocturno': false,
      'Visitantes frecuentes': true,
    };
  }
}
