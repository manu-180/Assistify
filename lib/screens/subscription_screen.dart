// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';
import 'dart:async';

import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/subscription/subscription_manager.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/supabase/suscribir/suscribir_usuario.dart';
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

  @override
  void initState() {
    super.initState();

    SubscriptionManager().checkAndUpdateSubscription();

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
        {"monthlysubscription", "annualsubscription", "cero", "prueba"}.toSet(),
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

  void _subscribe(ProductDetails productDetails) {
    try {
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: productDetails);
      debugPrint('Attempting to purchase: ${productDetails.id}');
      _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam, autoConsume: false);
    } catch (e) {
      debugPrint('Error initiating purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('purchaseError', params: {'error': e.toString()}))),
      );
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        final usuarioActivo = Supabase.instance.client.auth.currentUser;
        final purchaseToken = purchase.verificationData.serverVerificationData;
        final productId = purchase.productID;

        final DateTime startDate = DateTime.now();

        final bool isActive = true;

        // Inserta la suscripción en Supabase
        await SuscribirUsuario(supabaseClient: supabase).insertSubscription(
          userId: usuarioActivo!.id,
          productId: productId,
          purchaseToken: purchaseToken,
          startDate: startDate,
          isActive: isActive,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context).translate('purchaseSuccess'))),
        );
      } else if (purchase.status == PurchaseStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('purchaseError', params: {
            'error': purchase.error?.message ?? 'Unknown error'
          }))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final double fontSizeTitle = size.width * 0.065;
    final double fontSizeDescription = size.width * 0.04;
    final double fontSizePrice = size.width * 0.07;

    return Scaffold(
      appBar: ResponsiveAppBar(isTablet: size.width > 600),
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
                          return GestureDetector(
                            onTap: () => _subscribe(product),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Container(
                                height: size.height * 0.28,
                                width: size.width * 0.8,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        cleanTitle(product.title),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: fontSizeTitle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        product.description,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          fontSize: fontSizeDescription,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      product.price,
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: fontSizePrice,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
