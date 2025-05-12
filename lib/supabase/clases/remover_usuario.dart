import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/modificar_datos/modificar_alert_trigger.dart';
import 'package:taller_ceramica/supabase/modificar_datos/modificar_credito.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_clases_disponibles.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_numero_admin.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/models/clase_models.dart';
import 'package:taller_ceramica/supabase/modificar_datos/modificar_lugar_disponible.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_total_info.dart';
import 'package:taller_ceramica/utils/calcular_24hs.dart';
import 'package:taller_ceramica/utils/utils_barril.dart';

class RemoverUsuario {
  final SupabaseClient supabaseClient;

  RemoverUsuario(this.supabaseClient);

  Future<void> removerUsuarioDeClase(
      int idClase, String user, bool parametro) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final tellefonoAdmin = await ObtenerNumero().obtenerTelefonoAdmin();

    // Obtener la clase específica usando .single()
    final data =
        await supabaseClient.from(taller).select().eq('id', idClase).single();

    final clase = ClaseModels.fromMap(data);

    if (clase.mails.contains(user)) {
      clase.mails.remove(user);
      await supabaseClient
          .from(taller)
          .update({'mails': clase.mails}).eq('id', idClase);

      ModificarLugarDisponible().agregarLugarDisponible(idClase);

      // Manejo de la lista de espera
      if (clase.espera.isNotEmpty) {
        final copiaEspera = List<String>.from(clase.espera);

        for (final userEspera in copiaEspera) {
          if (await ObtenerClasesDisponibles().clasesDisponibles(userEspera) >
              0) {
            clase.mails.add(userEspera);
            clase.espera.remove(userEspera);

            await supabaseClient
                .from(taller)
                .update({'espera': clase.espera}).eq('id', idClase);
            await supabaseClient
                .from(taller)
                .update({'mails': clase.mails}).eq('id', idClase);

            ModificarCredito().removerCreditoUsuario(userEspera);
            ModificarLugarDisponible().removerLugarDisponible(idClase);

            return;
          }
        }
      }

      // Manejo de créditos o alertas
      if (!parametro) {
        if (Calcular24hs().esMayorA24Horas(clase.fecha, clase.hora)) {
          ModificarCredito().agregarCreditoUsuario(user);
        } else {
          ModificarAlertTrigger().agregarAlertTrigger(user);
        }

        EnviarWpp().sendWhatsAppMessage(
          "HXc3a9c584ef95fdb872121c9cb8a09fd1",
          'whatsapp:+549$tellefonoAdmin',
          Calcular24hs().esMayorA24Horas(clase.fecha, clase.hora)
              ? [
                  user,
                  clase.dia,
                  clase.fecha,
                  clase.hora,
                  "Se genero un credito para recuperar la clase"
                ]
              : [
                  user,
                  clase.dia,
                  clase.fecha,
                  clase.hora,
                  "Cancelo con menos de 24 horas de anticipacion, no podra recuperar la clase"
                ],
        );

      }
    }
  }

  Future<void> removerUsuarioDeMuchasClase(
    ClaseModels clase,
    String user,
    void Function(ClaseModels claseActualizada)? callback,
  ) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final data = await ObtenerTotalInfo(
      supabase: supabase,
      usuariosTable: 'usuarios',
      clasesTable: taller,
    ).obtenerClases();

    for (final item in data) {
      if (item.hora == clase.hora && item.dia == clase.dia) {
        if (item.mails.contains(user)) {
          item.mails.remove(user);

          await supabaseClient
              .from(taller)
              .update(item.toMap())
              .eq('id', item.id);

          ModificarLugarDisponible().agregarLugarDisponible(item.id);

          if (callback != null) {
            callback(item);
          }
        }
      }
    }
  }

  Future<void> removerUsuarioDeListaDeEspera(int idClase, String user) async {
  print("🟡 Iniciando función removerUsuarioDeListaDeEspera");

  final usuarioActivo = Supabase.instance.client.auth.currentUser;
  if (usuarioActivo == null) {
    print("❌ No hay usuario activo");
    return;
  }
  print("✅ Usuario activo: ${usuarioActivo.email}");

  final taller = await ObtenerTaller().retornarTaller(usuarioActivo.id);
  print("📍 Taller del usuario activo: $taller");

  final telefono = await ObtenerNumero().obtenerTelefonoPorNombre(user);
  print("📞 Teléfono del usuario '$user': $telefono");

  if (telefono == null) {
    print("❌ No se encontró el teléfono del usuario $user");
    return;
  }

  final data = await supabaseClient.from(taller).select().eq('id', idClase).single();
  print("📦 Datos de la clase obtenidos: $data");

  final clase = ClaseModels.fromMap(data);
  print("📚 Clase creada desde datos: ${clase.toString()}");

  if (clase.espera.contains(user)) {
    print("✅ El usuario '$user' está en la lista de espera. Se procede a eliminarlo.");
    clase.espera.remove(user);

    await supabaseClient
        .from(taller)
        .update({"espera": clase.espera}).eq('id', idClase);

    print("✏️ Lista de espera actualizada: ${clase.espera}");

    print("📤 Enviando mensaje a $user al número +549$telefono");
    EnviarWpp().sendWhatsAppMessage(
      "HX28a321ebed0fb2ed0b0c2c5ac524748a",
      'whatsapp:+549$telefono',
      [user, clase.dia, clase.fecha, clase.hora, ""],
    );
  } else {
    print("ℹ️ El usuario '$user' NO estaba en la lista de espera.");
  }

  print("✅ Función finalizada");
}



}
