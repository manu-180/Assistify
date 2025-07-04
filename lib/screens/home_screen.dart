import 'package:flutter/material.dart';
import 'package:assistify/l10n/app_localizations.dart';
import 'package:assistify/supabase/obtener_datos/obtener_rubro.dart';
import 'package:assistify/supabase/supabase_barril.dart';
import 'package:assistify/widgets/responsive_appbar.dart';
import 'package:assistify/widgets/shimmer_loader.dart';
import 'package:assistify/widgets/titulo_seleccion.dart';

class HomeScreen extends StatelessWidget {
  final String? taller;

  const HomeScreen({super.key, this.taller});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final themeColor = Theme.of(context).primaryColor;
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['fullname'] ?? '';
    final firstName = fullName.split(' ').first;
    final size = MediaQuery.of(context).size;

    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: ResponsiveAppBar(isTablet: size.width > 600),
      body: FutureBuilder<String>(
        future: ObtenerRubro().rubro(fullName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox();
          } else if (snapshot.hasError) {
            return Center(
              child: Text(localizations.translate('errorLoadingData')),
            );
          } else {
            final rubro = snapshot.data ?? "Sin Rubro";

            // Determinar contenido según el rubro
            if (rubro == "Clases de cerámica") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymous",
                  'helloFemale',
                  'helloMale',
                  "assets/images/ceramicamujer.gif",
                  "assets/images/ceramicagif.gif",
                  'workshopDescription',
                  "workshopClasses");
            } else if (rubro == "Clases de natación") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "natacionHelloAnonymous",
                  'natacionHelloFemale',
                  'natacionHelloMale',
                  "assets/images/natacion.webp",
                  "assets/images/natacion.webp",
                  'natacionDescription',
                  "natacionClasses");
            } else if (rubro == "Clases de pintura") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousPainting",
                  'helloFemalePainting',
                  'helloMalePainting',
                  "assets/images/pintura.webp",
                  "assets/images/pintura.webp",
                  'workshopDescriptionPainting',
                  "workshopClassesPainting");
            } else if (rubro == "Clases de música") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousMusic",
                  'helloFemaleMusic',
                  'helloMaleMusic',
                  "assets/images/musica.webp",
                  "assets/images/musica.webp",
                  'workshopDescriptionMusic',
                  "workshopClassesMusic");
            } else if (rubro == "Clases de idiomas") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousLanguages",
                  'helloFemaleLanguages',
                  'helloMaleLanguages',
                  "assets/images/Languages.png",
                  "assets/images/Languages.png",
                  'workshopDescriptionLanguages',
                  "workshopClassesLanguages");
            } else if (rubro == "Clases de danza") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousDance",
                  'helloFemaleDance',
                  'helloMaleDance',
                  "assets/images/danza.png",
                  "assets/images/danza.png",
                  'workshopDescriptionDance',
                  "workshopClassesDance");
            } else if (rubro == "Clases de actuación") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousActing",
                  'helloFemaleActing',
                  'helloMaleActing',
                  "assets/images/Acting.png",
                  "assets/images/Acting.png",
                  'workshopDescriptionActing',
                  "workshopClassesActing");
            } else if (rubro == "Clases de cocina") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousCooking",
                  'helloFemaleCooking',
                  'helloMaleCooking',
                  "assets/images/Cooking.png",
                  "assets/images/Cooking.png",
                  'workshopDescriptionCooking',
                  "workshopClassesCooking");
            } else if (rubro == "Clases de tenis") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousTennis",
                  'helloFemaleTennis',
                  'helloMaleTennis',
                  "assets/images/Tennis.png",
                  "assets/images/Tennis.png",
                  'workshopDescriptionTennis',
                  "workshopClassesTennis");
            } else if (rubro == "Entrenamientos de CrossFit") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousCrossFit",
                  'helloFemaleCrossFit',
                  'helloMaleCrossFit',
                  "assets/images/CrossFit.png",
                  "assets/images/CrossFit.png",
                  'workshopDescriptionCrossFit',
                  "workshopClassesCrossFit");
            } else if (rubro == "Clases de artes marciales") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousMartialArts",
                  'helloFemaleMartialArts',
                  'helloMaleMartialArts',
                  "assets/images/artesmarciales.png",
                  "assets/images/artesmarciales.png",
                  'workshopDescriptionMartialArts',
                  "workshopClassesMartialArts");
            } else if (rubro == "Clases de pilates") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousPilates",
                  'helloFemalePilates',
                  'helloMalePilates',
                  "assets/images/Pilates.png",
                  "assets/images/Pilates.png",
                  'workshopDescriptionPilates',
                  "workshopClassesPilates");
            } else if (rubro == "Clases de gimnasia artística") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousGymnastics",
                  'helloFemaleGymnastics',
                  'helloMaleGymnastics',
                  "assets/images/Gymnastics.png",
                  "assets/images/Gymnastics.png",
                  'workshopDescriptionGymnastics',
                  "workshopClassesGymnastics");
            } else if (rubro == "Clases de marketing digital") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousGymnastics",
                  'helloFemaleGymnastics',
                  'helloMaleGymnastics',
                  "assets/images/Gymnastics.png",
                  "assets/images/Gymnastics.png",
                  'workshopDescriptionGymnastics',
                  "workshopClassesGymnastics");
            } else if (rubro == "Clases de boxeo") {
              return _homeGenerico(
                  size,
                  color,
                  localizations,
                  user,
                  firstName,
                  fullName,
                  themeColor,
                  context,
                  "helloAnonymousBoxing",
                  'helloFemaleBoxing',
                  'helloMaleBoxing',
                  "assets/images/Boxing.png",
                  "assets/images/Boxing.png",
                  'workshopDescriptionBoxing',
                  "workshopClassesBoxing");
            } else {
              return Center(
                child: Text("Contenido no disponible para este rubro."),
              );
            }
          }
        },
      ),
    );
  }

  Widget _homeGenerico(
    Size size,
    ColorScheme color,
    AppLocalizations localizations,
    User? user,
    String firstName,
    String fullName,
    Color themeColor,
    BuildContext context,
    String anonimo,
    String mujer,
    String hombre,
    String imagen1,
    String imagen2,
    String descripcion,
    String clases,
  ) {
    final sexo = user?.userMetadata?['sexo'];
    final isMujer = sexo == 'Mujer';
    final isHombre = sexo == 'Hombre';

    print("Sexo: $sexo");
    print("isMujer: $isMujer");
    print("isHombre: $isHombre");
    print("user: $user");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                isMujer
                    ? localizations
                        .translate('welcomeFemale')
                        .replaceAll('\$taller', taller ?? '')
                    : localizations
                        .translate('welcomeMale')
                        .replaceAll('\$taller', taller ?? ''),
                style: TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.w600,
                  color: color.primary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 25),
              TituloSeleccion(
                texto: user == null
                    ? localizations.translate(anonimo)
                    : isMujer
                        ? localizations
                            .translate(mujer)
                            .replaceAll('\$firstName', firstName)
                        : isHombre
                            ? localizations
                                .translate(hombre)
                                .replaceAll('\$firstName', firstName)
                            : localizations.translate(anonimo),
              ),
              const SizedBox(height: 20),
              _buildLoadingImage(
                imagePath: imagen1,
                height: 300,
                width: size.width * 0.9,
              ),
              const SizedBox(height: 20),
              Text(
                localizations.translate('whatWeDo'),
                style: TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.w400,
                  color: color.primary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              TituloSeleccion(texto: localizations.translate(descripcion)),
              const SizedBox(height: 20),
              _buildLoadingImage(
                imagePath: imagen2,
                height: 300,
                width: size.width * 0.9,
              ),
              const SizedBox(height: 20),
              TituloSeleccion(texto: localizations.translate(clases)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingImage({
    required String imagePath,
    required double height,
    required double width,
  }) {
    return FutureBuilder(
      future: _loadAssetImage(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: Center(
              child: ShimmerLoading(
                color: Color(0xFFE0E0E0),
                width: double.infinity,
                height: height,
                brillo: Color(0xFFF5F5F5),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: height,
            child: const Center(
              child: Text("Error al cargar la imagen"),
            ),
          );
        } else {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          );
        }
      },
    );
  }

  Future<void> _loadAssetImage(String assetPath) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
