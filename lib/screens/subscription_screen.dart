// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'dart:async';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/subscription/subscription_manager.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/supabase/suscribir/suscribir_usuario.dart';
import 'package:taller_ceramica/utils/verificar_suscripcion_con_backend.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  SubscriptionScreenState createState() => SubscriptionScreenState();
}

class SubscriptionScreenState extends State<SubscriptionScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  Map<String, bool> hovering = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isProcessingPurchase = false;
  Timer? _purchaseTimeoutTimer;

  final Map<String, Map<String, String>> planesCustom = {
  'assistify_monthly': {
    'titulo': 'Plan Mensual',
    'beneficio': '1 MES GRATIS',
    'descripcion':
        'Suscripción mensual con acceso completo a todas las funcionalidades.',
  },
  'assistify_annual': {
    'titulo': 'Plan Anual',
    'beneficio': '2 MESES GRATIS',
    'descripcion':
        'Suscripción anual con acceso completo y ahorro especial.',
  },
};


  String? extraerBeneficio(String description) {
    final exp = RegExp(r'(\d+)\s+mes(?:es)?\s+gratis', caseSensitive: false);
    final match = exp.firstMatch(description);
    return match != null ? match.group(0) : null;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SubscriptionManager().checkAndUpdateSubscription();
    });

    _initializeStore();

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchases) {
      _handlePurchaseUpdates(purchases);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      debugPrint('Error en las compras: $error');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // Función para limpiar el título
  String cleanTitle(String title) {
    return title.replaceAll(
        RegExp(r' *\(.*?\)'), ''); // Elimina texto entre paréntesis
  }

  Future<void> _initializeStore() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (isAvailable) {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(
        {
          "assistify_monthly",
          "assistify_annual",
        }.toSet(),
      );

      setState(() {
        _isAvailable = isAvailable;
        _products = response.productDetails;
        _products.sort((a, b) => a.price.compareTo(b.price));

        for (var product in _products) {
          hovering[product.id] = false;
        }
      });
    }
  }

 void _subscribe(ProductDetails productDetails) async {
  if (_isProcessingPurchase) {
    debugPrint('⚠️ Ya hay una compra en proceso.');
    return;
  }

  _isProcessingPurchase = true;

  try {
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    debugPrint('Attempting to purchase: ${productDetails.id}');
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

    // 🕒 Liberar el flag si no pasa nada después de 15 segundos
    _purchaseTimeoutTimer?.cancel(); // por si hay otro pendiente

_purchaseTimeoutTimer = Timer(const Duration(seconds: 15), () {
  if (_isProcessingPurchase) {
    debugPrint('🕒 Timeout: No se completó la compra, liberando bloqueo.');
    _isProcessingPurchase = false;
  }
});

  } catch (e) {
    debugPrint('❌ Error initiating purchase: $e');
    _isProcessingPurchase = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate(
          'purchaseError',
          params: {'error': e.toString()},
        )),
      ),
    );
  }
}


  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        try {
          // ✅ Enviar acknowledgment si es necesario
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
            debugPrint('🟢 Purchase completada y acknowledge enviada');
          }

          await Future.delayed(const Duration(seconds: 2));

          final purchaseToken =
              purchase.verificationData.serverVerificationData;
          final productId = purchase.productID;
          final DateTime startDate = DateTime.now();

          debugPrint("🧾 Purchase info:");
          debugPrint("👉 Usuario ID: ${usuarioActivo.id}");
          debugPrint("👉 Producto ID: $productId");
          debugPrint("👉 Token: $purchaseToken");

          final bool isActive = await verificarSuscripcionConBackend(
            purchaseToken: purchaseToken,
            subscriptionId: productId,
          );

          await SuscribirUsuario(supabaseClient: supabase).insertSubscription(
            userId: usuarioActivo.id,
            productId: productId,
            purchaseToken: purchaseToken,
            startDate: startDate,
            isActive: isActive,
            taller: taller,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('purchaseSuccess'),
              ),
            ),
          );
        } catch (e) {
          debugPrint('❌ Error en acknowledgment o backend: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate(
                'purchaseError',
                params: {'error': e.toString()},
              )),
            ),
          );
        }
      } else if (purchase.status == PurchaseStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate(
              'purchaseError',
              params: {
                'error': purchase.error?.message ?? 'Unknown error',
              },
            )),
          ),
        );
      }
    }
    _isProcessingPurchase = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final color = theme.colorScheme;
    final double fontSizeTitle = size.width * 0.065;
    final double fontSizeDescription = size.width * 0.04;
    final double fontSizePrice = size.width * 0.07;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        toolbarHeight: kToolbarHeight * 1.1,
        title: GestureDetector(
          onTap: () {
            context.push("/subscription");
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Image.asset(
              'assets/icon/assistifyLogo.png',
              height: size.width * 0.42,
              fit: BoxFit.contain,
            ),
          ),
        ),
        backgroundColor: color.primary,
      ),
      body: _isAvailable
          ? _products.isEmpty
              ? Center(
                  child: Text(AppLocalizations.of(context)
                      .translate('noProductsAvailable')),
                )
              : SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: size.height * 0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                       children: _products.map((product) {
  final custom = planesCustom[product.id];

  return GestureDetector(
    onTap: () => _subscribe(product),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: size.width * 0.8,
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📦 Título
            Text(
              custom?['titulo'] ?? product.title,
              style: TextStyle(
                fontSize: size.width * 0.055,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 🔥 Beneficio
            if (custom?['beneficio'] != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: color.primary.withAlpha(130),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  custom!['beneficio']!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // 📝 Descripción
            Text(
              custom?['descripcion'] ?? product.description,
              style: TextStyle(
                fontSize: size.width * 0.04,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            // 💰 Precio
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                product.price,
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}).toList(),
                      )
                    ),
                  ),
                )
          : Center(
            
              child: Text(
                  AppLocalizations.of(context).translate('storeNotAvailable')),
            ),
    );
  }
}
