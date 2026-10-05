import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'analytics_service.dart';
import 'payment_api_service.dart';
import 'payment_service.dart';

/// Servicio de compras dentro de la app (IAP) usando Google Play Billing y StoreKit.
/// Requiere configurar los productos con los mismos IDs en:
///   - Google Play Console > Monetización > Productos
///   - App Store Connect > App > In-App Purchases
class IapService {
  static final IapService _instance = IapService._internal();
  factory IapService() => _instance;
  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final PaymentService _paymentService = PaymentService();
  final PaymentApiService _paymentApi = PaymentApiService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final List<ProductDetails> _products = [];
  static const Map<String, String> _planProductIds = {
    'premium_monthly': 'premium_monthly',
    'premium_annual': 'premium_annual',
    'boost': 'boost',
    'super_like': 'super_like',
    'premium_verification': 'premium_verification',
    'highlight_listing': 'highlight_listing',
  };

  // Mapeo de productos por región (ISO 3166-1 alpha-2).
  // Configura aquí los IDs que tienes en cada tienda.
  static const Map<String, Map<String, String>> _regionalProductIds = {
    'US': {
      'premium_monthly': 'premium_monthly_us',
      'premium_annual': 'premium_annual_us',
    },
    'GB': {
      'premium_monthly': 'premium_monthly_gb',
      'premium_annual': 'premium_annual_gb',
    },
    'MX': {
      'premium_monthly': 'premium_monthly_mx',
      'premium_annual': 'premium_annual_mx',
    },
  };

  String _getRegion() {
    try {
      final locale = Platform.localeName;
      return locale.split('_').last.toUpperCase();
    } catch (_) {
      return '';
    }
  }

  /// Todos los IDs de producto candidatos para un plan en la región actual:
  /// el ID regional (si está definido) y el ID base. Ambos se consultan en la
  /// tienda y se usa el regional solo si existe en App Store Connect /
  /// Play Console; en caso contrario se usa el base.
  Set<String> _candidateProductIds(String planId) {
    final region = _getRegion();
    return {
      _planProductIds[planId]!,
      if (_regionalProductIds[region]?[planId] != null)
        _regionalProductIds[region]![planId]!,
    };
  }

  ProductDetails? _resolveProduct(String planId) {
    final region = _getRegion();
    final regionalId = _regionalProductIds[region]?[planId];
    return (regionalId != null ? _findProduct(regionalId) : null) ??
        _findProduct(_planProductIds[planId]!);
  }

  final _purchaseCompleters = <String, Completer<PurchaseDetails?>>{};

  /// Inicializar el listener de compras. Llamar en main() tras inicializar Firebase.
  Future<void> initialize() async {
    if (!await _iap.isAvailable()) {
      throw Exception('IAP no está disponible en este dispositivo.');
    }

    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription = null,
      onError: (error) => debugPrint('IAP stream error: $error'),
    );
  }

  /// Cargar los detalles de producto de las tiendas (por región).
  Future<List<ProductDetails>> loadProducts() async {
    final ids = _planProductIds.keys.expand(_candidateProductIds).toSet();
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      throw Exception('Error consultando productos: ${response.error!}');
    }
    _products
      ..clear()
      ..addAll(response.productDetails);
    return _products;
  }

  /// Inicia la compra de un producto y espera su finalización.
  /// Devuelve el PurchaseDetails si se completó, o null si fue cancelado.
  Future<PurchaseDetails?> purchase(String planId) async {
    try {
    if (!_planProductIds.containsKey(planId)) throw Exception('Plan desconocido: $planId');

    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      if (kDebugMode) {
        final simulated = PurchaseDetails(
          productID: _planProductIds[planId]!,
          status: PurchaseStatus.purchased,
          transactionDate: DateTime.now().toIso8601String(),
          purchaseID: 'debug_${DateTime.now().millisecondsSinceEpoch}',
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'debug',
          ),
        );
        await _deliverProduct(simulated);
        return simulated;
      }
      throw Exception('La tienda de la aplicación no está disponible en este dispositivo/emulador.');
    }

    if (_products.isEmpty) await loadProducts();

    final product = _resolveProduct(planId);
    if (product == null) {
      throw Exception('Producto para plan $planId no encontrado en la tienda.');
    }
    final productId = product.id;

    final completer = Completer<PurchaseDetails?>();
    _purchaseCompleters[productId] = completer;

    if (_isConsumable(planId)) {
      await _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } else {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    }

    return await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _purchaseCompleters.remove(productId);
        throw Exception('La compra no respondió a tiempo. Si ya te cobraron, reinicia la app.');
      },
    );
    } catch (e) {
      unawaited(AnalyticsService().logPurchaseError(
        planId: planId,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// Restaurar compras (útil al reinstalar o en iOS).
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final completer = _purchaseCompleters[purchase.productID];

    switch (purchase.status) {
      case PurchaseStatus.pending:
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _deliverProduct(purchase);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        completer?.complete(purchase);
        _purchaseCompleters.remove(purchase.productID);
        break;
      case PurchaseStatus.error:
        unawaited(AnalyticsService().logPurchaseError(
          planId: purchase.productID,
          error: purchase.error?.toString() ?? 'Error de compra',
        ));
        completer?.completeError(purchase.error ?? Exception('Error de compra'));
        _purchaseCompleters.remove(purchase.productID);
        break;
      case PurchaseStatus.canceled:
        completer?.complete(null);
        _purchaseCompleters.remove(purchase.productID);
        break;
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    try {
      final planId = _planProductIdToPlanId(purchase.productID);
      final isSubscription = planId == 'premium_monthly' || planId == 'premium_annual';

      if (purchase.purchaseID == null || purchase.purchaseID!.isEmpty) {
        throw Exception('Compra sin purchaseID, no se puede entregar el producto');
      }
      final transactionId = purchase.purchaseID!;

      final platform = Platform.isIOS ? 'ios' : 'android';
      final verificationData = purchase.verificationData.serverVerificationData;

      if (isSubscription) {
        await _paymentService.purchaseSubscription(
          planId,
          transactionId: transactionId,
          verificationData: verificationData,
          platform: platform,
        );
      } else {
        await _paymentService.purchaseIndividualItem(
          planId,
          transactionId: transactionId,
          verificationData: verificationData,
          platform: platform,
        );
      }

      // Log analytics
      unawaited(AnalyticsService().logPurchase(
        planId: planId,
        transactionId: transactionId,
      ));

      // Solicitar factura por email (no bloqueante, omite compras de debug)
      if (!kDebugMode && purchase.verificationData.source != 'debug') {
        final product = _findProduct(purchase.productID);
        unawaited(_paymentApi.sendPurchaseReceipt(
          productId: purchase.productID,
          transactionId: transactionId,
          productName: product?.title,
          amountCents: product != null ? (product.rawPrice * 100).round() : null,
          currency: product?.currencyCode,
          platform: Platform.isIOS ? 'ios' : 'android',
        ));
      }
    } catch (e) {
      debugPrint('Error entregando producto: $e');
      rethrow;
    }
  }

  ProductDetails? _findProduct(String productId) {
    for (final p in _products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  String _planProductIdToPlanId(String productId) {
    final allEntries = <MapEntry<String, String>>[
      ..._planProductIds.entries,
      ..._regionalProductIds.values.expand((m) => m.entries),
    ];
    return allEntries
        .firstWhere(
          (e) => e.value == productId,
          orElse: () => const MapEntry('', ''),
        )
        .key;
  }

  static const Set<String> _consumablePlanIds = {
    'boost',
    'super_like',
    'highlight_listing',
  };

  bool _isConsumable(String planId) => _consumablePlanIds.contains(planId);

  void dispose() {
    _subscription?.cancel();
  }
}

