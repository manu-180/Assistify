import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/utils/internet.dart'; // Importa la clase para verificar conexión

class SubscriptionManager {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final List<PurchaseDetails> _purchases = [];

  SubscriptionManager() {
    _startPeriodicValidation();
  }

  void _startPeriodicValidation() {
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      await verificarEstadoSuscripcion();
    });
  }

  Future<void> verificarEstadoSuscripcion() async {
    // Verifica la conexión a Internet antes de proceder
    if (!await Internet().hayConexionInternet()) {
      throw Exception('No hay conexión a Internet.');
    }

    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    if (usuarioActivo == null) return;

    await _inAppPurchase.restorePurchases();
    final List<PurchaseDetails> restoredPurchases = _purchases
        .where((purchase) => purchase.status == PurchaseStatus.restored)
        .toList();

    bool isSubscribed = restoredPurchases.any((purchase) {
      return (purchase.productID == 'monthlysubscription' ||
              purchase.productID == 'annualsubscription' ||
              purchase.productID == 'cero' ||
              purchase.productID == 'prueba') &&
          purchase.status == PurchaseStatus.purchased;
    });

    await Supabase.instance.client
        .from('subscriptions')
        .update({'is_active': isSubscribed}).eq('user_id', usuarioActivo.id);
  }

  Future<void> checkAndUpdateSubscription() async {
    // Verifica la conexión a Internet antes de proceder
    if (!await Internet().hayConexionInternet()) {
      throw Exception('No hay conexión a Internet.');
    }

    await _inAppPurchase.restorePurchases();
    final List<PurchaseDetails> restoredPurchases = _purchases
        .where((purchase) => purchase.status == PurchaseStatus.restored)
        .toList();

    bool isSubscribed = false;
    for (var purchase in restoredPurchases) {
      if (purchase.productID == 'monthlysubscription' ||
          purchase.productID == 'annualsubscription' ||
          purchase.productID == 'cero' ||
          purchase.productID == 'prueba') {
        if (purchase.status == PurchaseStatus.purchased) {
          isSubscribed = true;
          break;
        }
      }
    }
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser != null) {
      await supabase
      .from('subscriptions')
      .update({'is_active': isSubscribed}).eq('user_id', currentUser.id);  
      
    }
  }

  /// Escucha las actualizaciones de compras
  void listenToPurchaseUpdates() {
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
      },
    );
  }

  /// Verifica manualmente si el usuario está suscripto
  bool isUserSubscribed() {
    for (var purchase in _purchases) {
      if ((purchase.productID == "monthlysubscription" ||
              purchase.productID == "annualsubscription") &&
          purchase.status == PurchaseStatus.purchased) {
        return true;
      }
    }
    return false;
  }

  /// Consulta los detalles de productos configurados
  Future<void> fetchProductDetails() async {
    const Set<String> productIds = {
      "monthlysubscription",
      "annualsubscription"
    };

    // Verifica la conexión a Internet antes de proceder
    if (!await Internet().hayConexionInternet()) {
      throw Exception('No hay conexión a Internet.');
    }

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

  Future<void> restorePurchases() async {
    if (!await Internet().hayConexionInternet()) {
      throw Exception('No hay conexión a Internet.');
    }

    await _inAppPurchase.restorePurchases();
  }
}
