import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/iap_service.dart';
import '../../services/payment_service.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoomMate Premium'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFeatures(),
            _buildIndividualPurchases(context),
            _buildPricing(context),
            _buildFAQ(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryGreen],
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'RoomMate Premium',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Encuentra a tu compañero ideal más rápido',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = <Map<String, dynamic>>[
      {
        'icon': Icons.all_inclusive,
        'title': 'Likes ilimitados',
        'description': 'Desliza sin límites todos los días',
      },
      {
        'icon': Icons.visibility,
        'title': 'Ver quién te dio like',
        'description': 'Descubre quién te gusta antes de deslizar',
      },
      {
        'icon': Icons.tune,
        'title': 'Filtros avanzados',
        'description': 'Filtra por más criterios para encontrar matches perfectos',
      },
      {
        'icon': Icons.rocket_launch,
        'title': 'Boost del perfil',
        'description': 'Sé el primero en ver durante 30 minutos',
      },
      {
        'icon': Icons.star,
        'title': 'Super Likes ilimitados',
        'description': 'Destácate con super likes ilimitados',
      },
      {
        'icon': Icons.visibility_off,
        'title': 'Modo Invisible',
        'description': 'Desliza sin que nadie te vea',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Características Premium',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => _buildFeatureItem(feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature['icon'],
              color: AppTheme.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature['description'],
                  style: const TextStyle(
                    color: AppTheme.textLightSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualPurchases(BuildContext context) {
    final items = PaymentService().getAllIndividualPurchases().entries.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comprar extras',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((entry) => _buildIndividualCard(context, entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildIndividualCard(
    BuildContext context,
    String id,
    Map<String, dynamic> item,
  ) {
    final icon = _getIconForIndividual(id);
    final name = item['name'] as String;
    final description = item['description'] as String;
    final price = item['price'] as double;
    final currency = item['currency'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.textLightSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _buyIndividual(context, id, price, currency),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '${price.toStringAsFixed(2)}$currency',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndividual(String id) {
    switch (id) {
      case 'boost':
        return Icons.rocket_launch;
      case 'super_like':
        return Icons.star;
      case 'premium_verification':
        return Icons.verified;
      case 'highlight_listing':
        return Icons.push_pin;
      default:
        return Icons.shopping_bag;
    }
  }

  void _buyIndividual(BuildContext context, String itemId, double price, String currency) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    try {
      await IapService().purchase(itemId);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra realizada con éxito'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final message = e.toString().replaceAll('Exception: ', '');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No se pudo completar la compra'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPricing(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppTheme.darkBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Elige tu plan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPlanCard(
                  context,
                  'Mensual',
                  '9.99€',
                  '/mes',
                  false,
                  () => _subscribe(context, 'monthly'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlanCard(
                  context,
                  'Anual',
                  '79.99€',
                  '/año',
                  true,
                  () => _subscribe(context, 'yearly'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    String title,
    String price,
    String period,
    bool isPopular,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPopular ? AppTheme.primaryBlue : AppTheme.textLightSecondary.withValues(alpha: 0.3),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Más popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLightSecondary,
                  ),
                ),
              ],
            ),
            if (isPopular) ...[
              const SizedBox(height: 8),
              const Text(
                'Ahorras 33%',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text(
                'Suscribirse',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ(BuildContext context) {
    final faqs = [
      {
        'question': '¿Puedo cancelar mi suscripción?',
        'answer': 'Sí, puedes cancelar en cualquier momento desde la configuración de tu cuenta.',
      },
      {
        'question': '¿Qué pasa si cancelo?',
        'answer': 'Mantendrás los beneficios Premium hasta el final del periodo de facturación.',
      },
      {
        'question': '¿Puedo cambiar de plan más adelante?',
        'answer': 'Sí, puedes cambiar entre el plan mensual y anual en cualquier momento desde la configuración de tu cuenta.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preguntas Frecuentes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _buildFAQItem(faq)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return ExpansionTile(
      title: Text(
        faq['question'],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            faq['answer'],
            style: const TextStyle(color: AppTheme.textLightSecondary),
          ),
        ),
      ],
    );
  }

  void _subscribe(BuildContext context, String plan) async {
    final planId = plan == 'yearly' ? 'premium_annual' : 'premium_monthly';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    try {
      await IapService().purchase(planId);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suscripción activada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final message = e.toString().replaceAll('Exception: ', '');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No se pudo completar la compra'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }
}
