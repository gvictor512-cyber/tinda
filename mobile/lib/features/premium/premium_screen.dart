import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/iap_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/purchase_success_dialog.dart';
import '../settings/legal_document_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final IapService _iap = IapService();
  bool _productsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// Refreshes store product details so prices shown are the localized
  /// store prices (falls back to the static catalog price otherwise).
  Future<void> _loadProducts() async {
    try {
      await _iap.loadProducts();
    } catch (e) {
      debugPrint('PremiumScreen: no se pudieron cargar los productos: $e');
    }
    if (mounted) setState(() => _productsLoaded = true);
  }

  /// Localized store price for [planId], or the static fallback when the
  /// store hasn't returned the product yet.
  String _priceFor(String planId, String fallback) {
    final product = _iap.productFor(planId);
    return product?.price ?? fallback;
  }

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
            _buildSubscriptionDisclosure(),
            _buildFAQ(context),
            _buildLegalLinks(context),
            _buildRestorePurchases(context),
            if (kDebugMode || kProfileMode) _buildDebugSection(),
          ],
        ),
      ),
    );
  }

  /// Diagnóstico visible solo en builds de debug: lista los productos
  /// que la tienda no reconoció para facilitar la configuración en
  /// App Store Connect / Play Console.
  Widget _buildDebugSection() {
    final missing = _productsLoaded ? _iap.missingProductIds : <String>[];
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text(
                'Modo prueba (solo debug)',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            missing.isEmpty
                ? 'Todos los productos están configurados en la tienda.'
                : 'Productos no encontrados en la tienda:\n${missing.join(', ')}\n\nEn debug se simulará la compra igualmente.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Recargar productos'),
          ),
        ],
      ),
    );
  }

  /// Cabecera con la identidad premium de la app: gradiente
  /// morado→rosa, logo de RoomMate Match en blanco y chip PREMIUM.
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryPurple,
            AppTheme.accentPink,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'RoomMate Match',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: 10),
              // Chip PREMIUM — misma cápsula que en perfil y likes
              _PremiumBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Encuentra a tu compañero ideal más rápido',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
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
    // El nombre legible se reutiliza en el diálogo de éxito.
    final displayName = name;

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
                onPressed: () =>
                    _buyIndividual(context, id, displayName, price, currency),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(80, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _priceFor(id, '${price.toStringAsFixed(2)}$currency'),
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

  void _buyIndividual(BuildContext context, String itemId, String itemName, double price, String currency) async {
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ));
    try {
      final result = await IapService().purchase(itemId);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (result == null) {
        // User cancelled in the store sheet — not an error, not a success.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compra cancelada')),
        );
        return;
      }
      unawaited(PurchaseSuccessDialog.show(
        context,
        productName: itemName,
        message: 'Tu compra se ha activado correctamente en tu cuenta.',
      ));
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final message = e.toString().replaceAll('Exception: ', '');
      unawaited(showDialog(
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
      ));
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
                  _priceFor('premium_monthly', '9.99€'),
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
                  _priceFor('premium_annual', '79.99€'),
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

  /// Guideline 3.1.2(c): the purchase flow must state that the plans are
  /// auto-renewable subscriptions, their length and price, and include
  /// functional links to the Terms of Use and Privacy Policy.
  Widget _buildSubscriptionDisclosure() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Text(
        'RoomMate Premium es una suscripción auto-renovable: el plan Mensual '
        'se renueva cada mes y el Anual cada año al precio indicado. El cargo '
        'se realiza en tu cuenta de Apple ID al confirmar la compra y se '
        'renueva automáticamente salvo que la canceles al menos 24 horas antes '
        'del fin del periodo en curso. Puedes gestionar o cancelar la '
        'suscripción en los Ajustes de tu cuenta de App Store.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textLightSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildLegalLinks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => _openLegal(
              context,
              'Términos de Uso',
              'assets/legal/terms_of_service.md',
            ),
            child: const Text(
              'Términos de Uso',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const Text('·',
              style: TextStyle(color: AppTheme.textLightSecondary)),
          TextButton(
            onPressed: () => _openLegal(
              context,
              'Política de Privacidad',
              'assets/legal/privacy_policy.md',
            ),
            child: const Text(
              'Política de Privacidad',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _openLegal(BuildContext context, String title, String assetPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(title: title, assetPath: assetPath),
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

  /// App Store guideline 3.1.1: users must be able to restore prior
  /// purchases — also the recovery path when a purchase completed in the
  /// store but delivery failed or the app was closed mid-flow.
  Widget _buildRestorePurchases(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: TextButton.icon(
        icon: const Icon(Icons.restore, size: 18),
        label: const Text('Restaurar compras'),
        onPressed: () => _restorePurchases(context),
      ),
    );
  }

  void _restorePurchases(BuildContext context) async {
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ));
    try {
      await IapService().restorePurchases();
      // The purchase stream re-delivers past purchases; delivery + store
      // completion run in IapService._handlePurchase automatically.
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compras restauradas')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No se pudieron restaurar las compras. Inténtalo de nuevo.')),
      );
    }
  }

  void _subscribe(BuildContext context, String plan) async {
    final planId = plan == 'yearly' ? 'premium_annual' : 'premium_monthly';
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ));
    try {
      final result = await IapService().purchase(planId);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suscripción cancelada')),
        );
        return;
      }
      unawaited(PurchaseSuccessDialog.show(
        context,
        productName: plan == 'yearly' ? 'Premium Anual' : 'Premium Mensual',
        message:
            'Tu suscripción Premium ya está activa. ¡Disfruta de todas las ventajas!',
      ));
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final message = e.toString().replaceAll('Exception: ', '');
      unawaited(showDialog(
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
      ));
    }
  }
}

/// Cápsula translúcida con el texto PREMIUM — mismo estilo que los
/// banners de perfil y likes para mantener la identidad de marca.
class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Text(
        'PREMIUM',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
