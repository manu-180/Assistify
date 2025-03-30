import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/supabase/utiles/actualizar_semanas.dart';
import 'package:taller_ceramica/supabase/utiles/reset_clases.dart';
import 'package:taller_ceramica/utils/actualizar_fechas_database.dart';
import 'package:taller_ceramica/utils/encontrar_semana.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart';

class Prueba extends StatelessWidget {
  const Prueba({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    

    
    return FutureBuilder(
      future: _loadData(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        } else {
          final data = snapshot.data as Map<String, dynamic>;
          final translatedText = data['translatedText'];
          final taller = data['taller'];

          return Scaffold(
            appBar: ResponsiveAppBar(isTablet: size.width > 600),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    translatedText,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _mostrarAdvertencia(context, taller),
              child: const Icon(Icons.warning),
            ),
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> _loadData(BuildContext context) async {
    final translatedText = AppLocalizations.of(context).translate('helloWorld');
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    return {'translatedText': translatedText, 'taller': taller};
  }

  Future<void> corregirDia() async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final clases = await ObtenerTotalInfo(supabase: supabase, clasesTable: taller, usuariosTable: "usuarios").obtenerClases();

    for( final clase in clases) {
      if(clase.dia == "miercoles"){

      await supabase.from(taller).update({'dia': "miércoles"}).eq('id', clase.id);}
    }
}

  void _mostrarAdvertencia(BuildContext context, dynamic taller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Advertencia"),
          content: const Text(
            "Viejita no te pases al siguiente mes porque no vas a poder volver para atrás. "
            "¿Estás apretando este botón por primera y única vez?",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el cuadro de diálogo
              },
            ),
            TextButton(
              child: const Text("Confirmar"),
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar el cuadro de diálogo
                corregirDia();

                ResetClases().reset();
                ActualizarFechasDatabase().actualizarClasesAlNuevoMes(taller, 2025);
                await Future.delayed(const Duration(seconds: 2));
                await ActualizarSemanas().actualizarSemana();
              },
            ),
          ],
        );
      },
    );
  }
}
