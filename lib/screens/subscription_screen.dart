// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:assistify/l10n/app_localizations.dart';
import 'dart:async';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'package:assistify/main.dart';
import 'package:assistify/subscription/subscription_manager.dart';
import 'package:assistify/supabase/obtener_datos/obtener_taller.dart';
import 'package:assistify/supabase/supabase_barril.dart';
import 'package:assistify/supabase/suscribir/suscribir_usuario.dart';
import 'package:assistify/utils/verificar_suscripcion_con_backend.dart';
import 'package:assistify/widgets/responsive_appbar.dart';
import 'dart:io' show Platform;

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
      'descripcion': 'Suscripción anual con acceso completo y ahorro especial.',
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
    final manager = SubscriptionManager();
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      manager.listenToPurchaseUpdates(onPurchase: _handlePurchaseUpdates);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.checkAndUpdateSubscription();
    });

    _initializeStore();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _purchaseTimeoutTimer?.cancel(); // ← esto es clave
    super.dispose();
  }

  // Función para limpiar el título
  String cleanTitle(String title) {
    return title.replaceAll(
        RegExp(r' *\(.*?\)'), ''); // Elimina texto entre paréntesis
  }

  Future<void> _initializeStore() async {
    // ❌ Evita ejecutar en plataformas no soportadas
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      setState(() {
        _isAvailable = false;
      });
      return;
    }

    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (isAvailable) {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(
        {
          "assistify_monthly",
          "assistify_annual",
        }.toSet(),
      );

      if (!mounted) return;

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

    if (mounted) {
      setState(() {
        _isProcessingPurchase = true;
      });
    }

    try {
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);
      debugPrint('Attempting to purchase: ${productDetails.id}');
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      // 🕒 Timeout para liberar el flag si no hay respuesta
      _purchaseTimeoutTimer?.cancel();
      _purchaseTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (mounted && _isProcessingPurchase) {
          debugPrint(
              '🕒 Timeout: No se completó la compra, liberando bloqueo.');
          setState(() {
            _isProcessingPurchase = false;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Error initiating purchase: $e');
      if (mounted) {
        setState(() {
          _isProcessingPurchase = false;
        });
      }
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

// ✅ Redirigir al home del taller
          context.go("/home/$taller");
          return;
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
    if (mounted) {
      setState(() {
        _isProcessingPurchase = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final color = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        toolbarHeight: kToolbarHeight * 1.1,
        title: GestureDetector(
          onTap: () {
            context.push("/home/Lanalana");
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
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.08, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _products.map((product) {
                  final isAnnual = product.id == 'assistify_annual';

                  return GestureDetector(
                    onTap: () => _subscribe(product),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isAnnual ? Colors.red : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAnnual)
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Más popular',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            isAnnual ? 'Plan Anual' : 'Plan Mensual',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.price +
                                (isAnnual ? ' /año' : ' /mes'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isAnnual
                                ? '• Acceso total a todas las funcionalidades\n'
                                    '• Cancelación de clases con crédito recuperable\n'
                                    '• Inscripción a clases de forma autónoma\n'
                                    '• Notificaciones automáticas por WhatsApp\n'
                                    '• Gestión de clases, horarios y alumnos\n'
                                    '• Personalización de cuenta y soporte\n'
                                    '• Sistema de lista de espera\n'
                                    '• Ahorro frente al plan mensual\n'
                                    '• Renovación automática. Cancelable en cualquier momento'
                                : '• Acceso total a todas las funcionalidades\n'
                                    '• Cancelación de clases con crédito recuperable\n'
                                    '• Inscripción a clases de forma autónoma\n'
                                    '• Notificaciones automáticas por WhatsApp\n'
                                    '• Gestión de clases, horarios y alumnos\n'
                                    '• Personalización de cuenta y soporte\n'
                                    '• Sistema de lista de espera\n'
                                    '• Renovación automática. Cancelable en cualquier momento',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAnnual ? '2 MESES GRATIS' : '1 MES GRATIS',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          )
    : const Center(
        child: CircularProgressIndicator(),
      ),

    );
  }
}
