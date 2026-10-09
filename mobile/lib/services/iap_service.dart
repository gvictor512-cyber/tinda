import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final baseId = _planProductIds[planId];
    if (baseId == null) return null;
    final region = _getRegion();
    final regionalId = _regionalProductIds[region]?[planId];
    return (regionalId != null ? _findProduct(regionalId) : null) ??
        _findProduct(baseId);
  }

  /// Producto de la tienda para [planId] (null si no está en la tienda).
  /// La UI lo usa para mostrar el precio localizado real.
  ProductDetails? productFor(String planId) => _resolveProduct(planId);

  final _purchaseCompleters = <String, Completer<PurchaseDetails?>>{};
  bool _purchaseInFlight = false;

  /// Entrega al backend en curso por productID. Permite a purchase()
  /// esperar el resultado real cuando su timeout dispara mientras la
  /// verificación sigue en vuelo (el pago ya ocurrió — un error sería
  /// falso y la entrega terminaría igualmente en segundo plano).
  final _inFlightDeliveries = <String, Future<PurchaseDetails>>{};

  /// Cola persistente de entregas pendientes: compras ya cobradas en la
  /// tienda cuya activación en el backend falló. Es la vía real de
  /// recuperación en iOS, donde restorePurchases NO re-emite consumibles ni
  /// transacciones ya finalizadas — sin ella el usuario quedaba en el
  /// bucle de "compra anterior procesándose".
  static const String _pendingDeliveriesKey = 'iap_pending_deliveries';

  /// Las compras simuladas solo existen en builds de desarrollo
  /// (debug y profile — ambas son builds de prueba instalables sin
  /// publicar; release nunca simula).
  static bool get _simulationAllowed => kDebugMode || kProfileMode;

  /// Inicializar el listener de compras. Llamar en main() tras inicializar Firebase.
  Future<void> initialize() async {
    if (!await _iap.isAvailable()) {
      throw Exception('IAP no está disponible en este dispositivo.');
    }

    _ensureListening();

    // Entregas pendientes de sesiones anteriores (compra cobrada pero la
    // activación falló): se reintentan en segundo plano sin bloquear el
    // arranque. El backend deduplica por transactionId.
    unawaited(_retryPendingDeliveries());

    // Prefetch product details so the paywall shows real store prices
    // and purchase() doesn't pay the query latency. Non-fatal.
    try {
      await loadProducts();
    } catch (e) {
      debugPrint('IAP product prefetch failed (retrying on demand): $e');
    }
  }

  /// Garantiza que el listener del purchaseStream está activo. Sin él,
  /// buyNonConsumable abre la hoja de la tienda pero nadie recibe el
  /// resultado: el usuario pagaría sin recibir el producto.
  void _ensureListening() {
    if (_subscription != null) return;
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
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
          'IAP productos no encontrados en la tienda: ${response.notFoundIDs}');
    }
    _products
      ..clear()
      ..addAll(response.productDetails);
    return _products;
  }

  /// IDs de producto que la tienda no reconoció en la última consulta.
  /// Útil para diagnosticar productos no configurados en App Store Connect.
  List<String> get missingProductIds {
    final wanted = _planProductIds.values.toSet();
    final found = _products.map((p) => p.id).toSet();
    return wanted.difference(found).toList();
  }

  /// Inicia la compra de un producto y espera su finalización.
  /// Devuelve el PurchaseDetails si se completó, o null si fue cancelado.
  Future<PurchaseDetails?> purchase(String planId) async {
    try {
    if (!_planProductIds.containsKey(planId)) throw Exception('Plan desconocido: $planId');
    if (_purchaseInFlight) {
      throw Exception('Ya hay una compra en curso. Espera a que termine.');
    }

    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      if (_simulationAllowed) {
        return await _debugPurchase(planId);
      }
      throw Exception('La tienda de la aplicación no está disponible en este dispositivo/emulador.');
    }

    // Si el init de arranque falló (tienda no lista todavía), el
    // listener puede no existir — sin él la compra se cobra pero
    // nunca se entrega.
    _ensureListening();

    if (_products.isEmpty) {
      try {
        await loadProducts();
      } catch (e) {
        // StoreKit no respondió (sandbox caído, productos aún no
        // configurados en App Store Connect, sin cuenta sandbox...):
        // en builds de prueba seguimos con la compra simulada.
        if (_simulationAllowed) {
          debugPrint('IAP: loadProducts falló ($e) — simulando la compra');
          return await _debugPurchase(planId);
        }
        rethrow;
      }
    }

    var product = _resolveProduct(planId);
    if (product == null) {
      // El prefetch puede haberse quedado parcial o anticuado (producto
      // activado en App Store Connect después del arranque): reconsulta
      // antes de rendirse.
      try {
        await loadProducts();
        product = _resolveProduct(planId);
      } catch (e) {
        debugPrint('IAP: reconsulta de productos falló: $e');
      }
    }
    if (product == null) {
      // Test builds fall back to a simulated purchase so the entitlement
      // flow can be tested before products exist in App Store Connect.
      if (_simulationAllowed) {
        debugPrint(
            'IAP: "$planId" no está en la tienda — simulando la compra');
        return await _debugPurchase(planId);
      }
      final missing = missingProductIds;
      throw Exception(
          'Producto "$planId" no encontrado en la tienda (faltan: ${missing.join(', ')}). '
          'Comprueba que el producto existe y está "Ready to Submit" en App Store Connect.');
    }
    final productId = product.id;

    final completer = Completer<PurchaseDetails?>();
    _purchaseCompleters[productId] = completer;
    _purchaseInFlight = true;

    try {
      if (_isConsumable(planId)) {
        await _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
      } else {
        await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final alreadyOwned = msg.contains('already') ||
          msg.contains('pending') ||
          msg.contains('owned') ||
          msg.contains('existe');
      if (alreadyOwned) {
        // La tienda dice que el producto ya está comprado (transacción de
        // una sesión anterior que nunca se entregó/consumió). La vía real
        // de recuperación es la cola persistente de entregas: en iOS,
        // restorePurchases NO re-emite consumibles ni transacciones ya
        // finalizadas, así que depender solo del stream dejaba al usuario
        // en el timeout de "compra anterior procesándose" en bucle.
        debugPrint('IAP: compra existente detectada, re-entregando: $e');
        final redeliveryError =
            await _retryPendingDeliveries(productId: productId);
        if (completer.isCompleted) {
          return await completer.future.whenComplete(() {
            _purchaseInFlight = false;
          });
        }
        // Pedimos a la tienda que re-emita las compras pendientes:
        // restorePurchases en Play también devuelve consumibles sin
        // consumir; en iOS solo restaura no-consumibles/suscripciones.
        try {
          await _iap.restorePurchases();
        } catch (restoreErr) {
          debugPrint('IAP: restorePurchases falló: $restoreErr');
        }
        try {
          return await completer.future.timeout(const Duration(seconds: 60));
        } on TimeoutException {
          _purchaseCompleters.remove(productId);
          final inFlight = _inFlightDeliveries[productId];
          if (inFlight != null) {
            try {
              return await inFlight;
            } catch (deliveryErr) {
              throw Exception(
                  'Compra realizada pero falló al activarla: $deliveryErr');
            }
          }
          final detail =
              redeliveryError != null ? ' Detalle: $redeliveryError' : '';
          throw Exception(
              'Tu compra anterior sigue procesándose en la tienda. '
              'Se activará automáticamente al completarse: cierra y vuelve '
              'a abrir la app en unos segundos.$detail');
        } finally {
          _purchaseInFlight = false;
        }
      } else {
        // Sin este reseteo _purchaseInFlight quedaría en true y
        // bloquearía toda compra futura.
        _purchaseCompleters.remove(productId);
        _purchaseInFlight = false;
        rethrow;
      }
    }

    try {
      return await completer.future.timeout(const Duration(seconds: 90));
    } on TimeoutException {
      _purchaseCompleters.remove(productId);
      final inFlight = _inFlightDeliveries[productId];
      if (inFlight != null) {
        // La tienda sí emitió la transacción pero la verificación con el
        // backend sigue en vuelo (cold start): el pago ya ocurrió, así que
        // esperamos el resultado real en vez de dar un error falso.
        try {
          return await inFlight;
        } catch (e) {
          throw Exception('Compra realizada pero falló al activarla: $e');
        }
      }
      throw Exception(
          'La tienda no respondió a tiempo. Si ya te cobraron, la compra '
          'se activará sola al reintentar o al reiniciar la app.');
    } finally {
      _purchaseInFlight = false;
    }
    } catch (e) {
      unawaited(AnalyticsService().logPurchaseError(
        planId: planId,
        error: e.toString(),
      ));
      // Mensaje accionable para el fallo más común de StoreKit.
      final errMsg = e.toString().toLowerCase();
      if (errMsg.contains('pending')) {
        throw Exception(
            'Tienes una compra pendiente en la tienda de una sesión anterior. '
            'Abre Play Store / App Store > tu perfil > historial de pedidos, '
            'completa o cancela esa transacción y vuelve a intentarlo. '
            'También puedes usar "Restaurar compras" en esta pantalla.');
      }
      if (e.toString().contains('storekit_no_response')) {
        throw Exception(
            'La App Store no respondió. Comprueba que los productos IAP '
            'existen en App Store Connect (IDs: premium_monthly, '
            'premium_annual, boost, super_like, premium_verification, '
            'highlight_listing) y que hay una cuenta sandbox iniciada '
            'en el dispositivo (Ajustes > App Store > Sandbox Account). '
            'Si el servicio de Apple está caído, reintenta en unos minutos.');
      }
      rethrow;
    }
  }

  /// Restaurar compras (útil al reinstalar o en iOS). Además drena la
  /// cola local de entregas pendientes: cubre consumibles iOS que
  /// restorePurchases nunca re-emite.
  Future<void> restorePurchases() async {
    unawaited(_retryPendingDeliveries());
    await _iap.restorePurchases();
  }

  /// Compra simulada para builds de debug: no pasa por la tienda pero
  /// sí por el backend, que concede el entitlement y registra la compra.
  /// El prefijo `debug_` en el transactionId hace que el backend omita
  /// la verificación de recibo con Apple/Google.
  Future<PurchaseDetails> _debugPurchase(String planId) async {
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

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      unawaited(_handlePurchase(purchase).catchError((Object e) {
        debugPrint('IAP: error procesando ${purchase.productID}: $e');
      }));
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final completer = _purchaseCompleters[purchase.productID];

    switch (purchase.status) {
      case PurchaseStatus.pending:
        // En builds de prueba las transacciones pending pueden quedarse
        // atascadas en la cola de StoreKit (sandbox) bloqueando compras
        // futuras del mismo producto. Las completamos para vaciar la cola;
        // en producción NUNCA se finaliza una pending porque la tienda
        // puede aprobarla después.
        if (purchase.pendingCompletePurchase && _simulationAllowed) {
          try {
            await _iap.completePurchase(purchase);
            debugPrint(
                'IAP: transacción pending atascada limpiada (${purchase.productID})');
          } catch (e) {
            debugPrint('IAP: no se pudo limpiar pending: $e');
          }
        }
        // La tienda retiene la transacción (p. ej. aprobación parental o un
        // pago aplazado sandbox). Resolvemos el completer con un mensaje
        // claro en vez de dejar la UI girando. Si la tienda la aprueba
        // después, llegará como purchased sin completer y se entregará por
        // el stream igualmente.
        completer?.completeError(Exception(
            'La compra quedó pendiente en la tienda (por ejemplo, esperando '
            'aprobación o confirmación del pago). Cuando Apple/Play la '
            'confirme se activará automáticamente — no hace falta volver a '
            'pagar.'));
        _purchaseCompleters.remove(purchase.productID);
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        try {
          await _deliverTracked(purchase);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          completer?.complete(purchase);
        } catch (e) {
          // La compra ya está cobrada: la persistimos en la cola de
          // entregas pendientes (se reintenta al arrancar, al reintentar
          // la compra o al restaurar) y finalizamos la transacción de la
          // tienda igualmente. Dejarla sin finalizar es lo que bloquea la
          // cola de StoreKit y provoca el bucle de "already owned".
          await _enqueuePendingDelivery(purchase);
          if (purchase.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(purchase);
            } catch (_) {}
          }
          // Surface the real delivery error to the caller instead of
          // letting purchase() hang until the timeout fires.
          completer?.completeError(
              Exception('Compra realizada pero falló al activarla: $e'));
        }
        _purchaseCompleters.remove(purchase.productID);
        break;
      case PurchaseStatus.error:
        unawaited(AnalyticsService().logPurchaseError(
          planId: purchase.productID,
          error: purchase.error?.toString() ?? 'Error de compra',
        ));
        if (purchase.pendingCompletePurchase) {
          // Finaliza transacciones fallidas para que no queden en la cola
          // de la tienda y reaparezcan como "compra pendiente".
          try {
            await _iap.completePurchase(purchase);
          } catch (_) {}
        }
        final errText =
            (purchase.error?.toString() ?? '').toLowerCase();
        final alreadyOwned = errText.contains('already') ||
            errText.contains('owned') ||
            errText.contains('pending') ||
            errText.contains('existe');
        if (alreadyOwned) {
          // La tienda dice que ya está comprado/pendiente: drenamos la
          // cola local de entregas y pedimos que re-emita la compra; un
          // evento restored/purchased posterior completará el completer.
          unawaited(_retryPendingDeliveries(productId: purchase.productID));
          try {
            await _iap.restorePurchases();
          } catch (_) {}
          break;
        }
        completer?.completeError(purchase.error ?? Exception('Error de compra'));
        _purchaseCompleters.remove(purchase.productID);
        break;
      case PurchaseStatus.canceled:
        if (purchase.pendingCompletePurchase) {
          try {
            await _iap.completePurchase(purchase);
          } catch (_) {}
        }
        completer?.complete(null);
        _purchaseCompleters.remove(purchase.productID);
        break;
    }
  }

  // ---------------------------------------------------------------
  // Cola persistente de entregas pendientes
  // ---------------------------------------------------------------

  Future<List<Map<String, dynamic>>> _readPendingDeliveries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingDeliveriesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writePendingDeliveries(
      List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingDeliveriesKey, jsonEncode(items));
  }

  /// Guarda una compra cobrada cuya entrega falló, para reintentarla en el
  /// próximo arranque o intento de compra. Deduplica por purchaseID.
  Future<void> _enqueuePendingDelivery(PurchaseDetails purchase) async {
    try {
      final items = await _readPendingDeliveries();
      items.removeWhere((e) => e['purchaseID'] == purchase.purchaseID);
      items.add(<String, dynamic>{
        'productID': purchase.productID,
        'purchaseID': purchase.purchaseID,
        'serverVerificationData':
            purchase.verificationData.serverVerificationData,
        'localVerificationData':
            purchase.verificationData.localVerificationData,
        'source': purchase.verificationData.source,
        'transactionDate': purchase.transactionDate,
      });
      await _writePendingDeliveries(items);
    } catch (e) {
      debugPrint('IAP: no se pudo persistir la entrega pendiente: $e');
    }
  }

  /// Reintenta las entregas pendientes persistidas. Con [productId] solo
  /// procesa las de ese producto. Las que tienen éxito salen de la cola y
  /// completan el completer de compra pendiente si existe. Devuelve el
  /// último error de entrega (null si todo se entregó o la cola está
  /// vacía).
  Future<Object?> _retryPendingDeliveries({String? productId}) async {
    List<Map<String, dynamic>> items;
    try {
      items = await _readPendingDeliveries();
    } catch (e) {
      debugPrint('IAP: no se pudo leer la cola de entregas: $e');
      return e;
    }
    if (items.isEmpty) return null;

    Object? lastError;
    var changed = false;
    for (final item in List.of(items)) {
      if (productId != null && item['productID'] != productId) continue;
      try {
        final purchase = PurchaseDetails(
          productID: item['productID'] as String,
          purchaseID: item['purchaseID'] as String?,
          transactionDate: item['transactionDate'] as String?,
          status: PurchaseStatus.purchased,
          verificationData: PurchaseVerificationData(
            localVerificationData:
                item['localVerificationData'] as String? ?? '',
            serverVerificationData:
                item['serverVerificationData'] as String? ?? '',
            source: item['source'] as String? ?? 'retry_queue',
          ),
        );
        await _deliverTracked(purchase);
        items.remove(item);
        changed = true;
        debugPrint(
            'IAP: entrega pendiente completada (${purchase.productID})');
        final completer = _purchaseCompleters[purchase.productID];
        if (completer != null && !completer.isCompleted) {
          completer.complete(purchase);
          _purchaseCompleters.remove(purchase.productID);
        }
      } catch (e) {
        lastError = e;
        debugPrint(
            'IAP: entrega pendiente sigue fallando (${item['productID']}): $e');
      }
    }
    if (changed) {
      try {
        await _writePendingDeliveries(items);
      } catch (e) {
        debugPrint('IAP: no se pudo guardar la cola de entregas: $e');
      }
    }
    return lastError;
  }

  /// Ejecuta la entrega registrando el Future en _inFlightDeliveries, de
  /// modo que purchase() pueda esperar el resultado real si el timeout de
  /// la tienda dispara mientras la verificación sigue en vuelo.
  Future<PurchaseDetails> _deliverTracked(PurchaseDetails purchase) {
    final future = _deliverProduct(purchase).then((_) => purchase);
    _inFlightDeliveries[purchase.productID] = future;
    unawaited(future.catchError((_) => purchase).whenComplete(() {
      if (identical(_inFlightDeliveries[purchase.productID], future)) {
        _inFlightDeliveries.remove(purchase.productID);
      }
    }));
    return future;
  }

  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    try {
      await _deliverProductOnce(purchase);
    } catch (e) {
      // Un solo reintento absorbe fallos transitorios (p. ej. cold start de
      // Render superando el timeout de 15s de Dio) que, si no, dejarían la
      // transacción cobrada sin entregar en la cola de la tienda.
      debugPrint('IAP: entrega falló ($e) — reintentando una vez');
      await Future.delayed(const Duration(seconds: 3));
      await _deliverProductOnce(purchase);
    }
  }

  Future<void> _deliverProductOnce(PurchaseDetails purchase) async {
    try {
      final planId = _planProductIdToPlanId(purchase.productID);
      if (planId.isEmpty) {
        throw Exception('Producto desconocido: ${purchase.productID}');
      }
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

      // Solicitar factura por email (no bloqueante). Se piden también en
      // debug: una compra real de sandbox merece factura igual; solo se
      // omiten las simuladas internas (source == 'debug').
      if (purchase.verificationData.source != 'debug') {
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

