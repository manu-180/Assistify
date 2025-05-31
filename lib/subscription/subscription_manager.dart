import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/utils/internet.dart';
import 'package:taller_ceramica/utils/verificar_suscripcion_con_backend.dart';

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final List<PurchaseDetails> _purchases = [];
  bool _isListening = false;

  SubscriptionManager._internal() {
    _startPeriodicValidation();
  }

  void _startPeriodicValidation() {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      await verificarEstadoSuscripcion();
    });
  }

  Future<void> verificarEstadoSuscripcion() async {
    if (!await Internet().hayConexionInternet()) return;

    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    if (usuarioActivo == null) return;

    final restoredPurchases = await restorePurchases();

    final bool isSubscribed = restoredPurchases.any((purchase) =>
        (purchase.productID == 'assistify_monthly' ||
            purchase.productID == 'assistify_annual') &&
        (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored));

    await Supabase.instance.client
        .from('subscriptions')
        .update({'is_active': isSubscribed}).eq('user_id', usuarioActivo.id);
  }

  Future<void> checkAndUpdateSubscription() async {
    if (!await Internet().hayConexionInternet()) return;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final restoredPurchases = await restorePurchases();

    bool isSubscribed = false;

    for (final purchase in restoredPurchases) {
      if ((purchase.productID == 'assistify_monthly' ||
              purchase.productID == 'assistify_annual' ||
              purchase.productID == 'cero' ||
              purchase.productID == 'prueba') &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        final purchaseToken = purchase.verificationData.serverVerificationData;

        final backendActiva = await verificarSuscripcionConBackend(
          purchaseToken: purchaseToken,
          subscriptionId: purchase.productID,
        );

        if (backendActiva) {
          isSubscribed = true;
          break;
        }
      }
    }

    await supabase
        .from('subscriptions')
        .update({'is_active': isSubscribed}).eq('user_id', currentUser.id);
  }

  void listenToPurchaseUpdates({Function(List<PurchaseDetails>)? onPurchase}) {
    if (_isListening) return;
    _isListening = true;

    _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        for (var purchase in purchaseDetailsList) {
          if (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored) {
            if (!_purchases.any((p) => p.productID == purchase.productID)) {
              _purchases.add(purchase);
            }
          }
        }

        if (onPurchase != null) {
          onPurchase(purchaseDetailsList);
        }
      },
      onError: (error) {
        print("Error en el stream de compras: $error");
      },
    );
  }

  bool isUserSubscribed() {
    for (var purchase in _purchases) {
      if ((purchase.productID == "assistify_monthly" ||
              purchase.productID == "assistify_annual") &&
          purchase.status == PurchaseStatus.purchased) {
        return true;
      }
    }
    return false;
  }

  Future<void> fetchProductDetails() async {
    const Set<String> productIds = {"assistify_monthly", "assistify_annual"};

    if (!await Internet().hayConexionInternet()) return;

    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        throw Exception("Error al consultar los productos: ${response.error}");
      }
    } catch (e) {
      throw Exception("Error al obtener detalles de productos: $e");
    }
  }

  Future<List<PurchaseDetails>> restorePurchases() async {
    if (!await Internet().hayConexionInternet()) return [];

    final Completer<List<PurchaseDetails>> completer = Completer();
    final List<PurchaseDetails> restored = [];

    final Stream<List<PurchaseDetails>> purchaseUpdates =
        _inAppPurchase.purchaseStream;

    final subscription = purchaseUpdates.listen((List<PurchaseDetails> purchases) {
      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.restored ||
            purchase.status == PurchaseStatus.purchased) {
          restored.add(purchase);
        }
      }

      if (!completer.isCompleted) {
        completer.complete(restored);
      }
    });

    await _inAppPurchase.restorePurchases();

    return completer.future.timeout(const Duration(seconds: 8), onTimeout: () {
      subscription.cancel();
      return restored;
    });
  }
}
