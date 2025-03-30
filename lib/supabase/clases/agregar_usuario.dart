import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/main.dart';
import 'package:taller_ceramica/models/clase_models.dart';
import 'package:taller_ceramica/supabase/modificar_datos/modificar_lugar_disponible.dart';
import 'package:taller_ceramica/supabase/modificar_datos/modificar_credito.dart';
import 'package:taller_ceramica/supabase/obtener_datos/obtener_total_info.dart';
import 'package:taller_ceramica/utils/enviar_wpp.dart';
import 'dart:ui' as ui;

class AgregarUsuario {
  final SupabaseClient supabaseClient;

  AgregarUsuario(this.supabaseClient);

  Future<void> agregarUsuarioAClase(
      int idClase, String user, bool parametro, ClaseModels claseModels) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);
    final usuarios = await ObtenerTotalInfo(
            supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
        .obtenerUsuarios();

    final data =
        await supabaseClient.from(taller).select().eq('id', idClase).single();

    final clase = ClaseModels.fromMap(data);

    for (final usuario in usuarios) {
      if (usuario.fullname == user) {
        if (usuario.clasesDisponibles > 0 || parametro) {
          if (!clase.mails.contains(user)) {
            clase.mails.add(user);
            await supabaseClient
                .from(taller)
                .update(clase.toMap())
                .eq('id', idClase);
            ModificarLugarDisponible().removerLugarDisponible(idClase);
 
            if (!parametro) {
              ModificarCredito().removerCreditoUsuario(user);
              EnviarWpp().sendWhatsAppMessage(
  "HXb7f90c40c60e781a4c4be85825808e79",
  'whatsapp:+5491132820164',
  [user, clase.dia, clase.fecha, clase.hora, ""] 
);
EnviarWpp().sendWhatsAppMessage(
  "HXb7f90c40c60e781a4c4be85825808e79",
  'whatsapp:+5491134272488',
  [user, clase.dia, clase.fecha, clase.hora, ""] 
);
            
            }
          }
        }
      }
    }
  }

Future<void> agregarUsuarioEnCuatroClases(BuildContext context,ClaseModels clase, String user,
    void Function(ClaseModels claseActualizada) callback) async {
  final usuarioActivo = Supabase.instance.client.auth.currentUser;
  final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

  final data = await ObtenerTotalInfo(
          supabase: supabase, usuariosTable: 'usuarios', clasesTable: taller)
      .obtenerClases();

  int obtenerIndiceDia(String dia, String idioma) {
    final Map<String, List<String>> diasPorIdioma = {
      'es': [
        'lunes',
        'martes',
        'miércoles',
        'jueves',
        'viernes',
        'sábado',
        'domingo'
      ],
      'en': [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
      ],
      'fr': [
        'lundi',
        'mardi',
        'mercredi',
        'jeudi',
        'vendredi',
        'samedi',
        'dimanche'
      ],
      'de': [
        'montag',
        'dienstag',
        'mittwoch',
        'donnerstag',
        'freitag',
        'samstag',
        'sonntag'
      ],
      'it': [
        'lunedì',
        'martedì',
        'mercoledì',
        'giovedì',
        'venerdì',
        'sabato',
        'domenica'
      ],
      'pt': [
        'segunda-feira',
        'terça-feira',
        'quarta-feira',
        'quinta-feira',
        'sexta-feira',
        'sábado',
        'domingo'
      ],
      'zh': [
        '星期一',
        '星期二',
        '星期三',
        '星期四',
        '星期五',
        '星期六',
        '星期日'
      ],
      'ja': [
        '月曜日',
        '火曜日',
        '水曜日',
        '木曜日',
        '金曜日',
        '土曜日',
        '日曜日'
      ],
      'ko': [
        '월요일',
        '화요일',
        '수요일',
        '목요일',
        '금요일',
        '토요일',
        '일요일'
      ],
      'ar': [
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد'
      ],
      'hi': [
        'सोमवार',
        'मंगलवार',
        'बुधवार',
        'गुरुवार',
        'शुक्रवार',
        'शनिवार',
        'रविवार'
      ],
      'ru': [
        'понедельник',
        'вторник',
        'среда',
        'четверг',
        'пятница',
        'суббота',
        'воскресенье'
      ],
      'tr': [
        'pazartesi',
        'salı',
        'çarşamba',
        'perşembe',
        'cuma',
        'cumartesi',
        'pazar'
      ],
      'nl': [
        'maandag',
        'dinsdag',
        'woensdag',
        'donderdag',
        'vrijdag',
        'zaterdag',
        'zondag'
      ],
      'sv': [
        'måndag',
        'tisdag',
        'onsdag',
        'torsdag',
        'fredag',
        'lördag',
        'söndag'
      ],
      'pl': [
        'poniedziałek',
        'wtorek',
        'środa',
        'czwartek',
        'piątek',
        'sobota',
        'niedziela'
      ]
    };

    // Normaliza el día (minúsculas y sin tildes)
    dia = dia.toLowerCase();

    // Obtiene la lista de días según el idioma
    final dias = diasPorIdioma[idioma];
    if (dias == null) {
      throw Exception("Idioma no soportado: $idioma");
    }

    // Busca el índice del día
    final index = dias.indexOf(dia);
    if (index == -1) {
      throw Exception("Día no reconocido: $dia para el idioma $idioma");
    }

    return index + 1;
  }

  DateTime parseFecha(String fecha) {
    final partes = fecha.split('/');
    final dd = int.tryParse(partes[0]) ?? 0;
    final mm = int.tryParse(partes[1]) ?? 0;
    final yyyy = int.tryParse(partes[2]) ?? 0;
    return DateTime(yyyy, mm, dd);
  }

  final idioma = ui.window.locale.languageCode;
 // Detecta el idioma del sistema}

  data.sort((a, b) {
    final diaA = obtenerIndiceDia(a.dia, idioma);
    final diaB = obtenerIndiceDia(b.dia, idioma);

    final diaCompare = diaA.compareTo(diaB);
    if (diaCompare != 0) {
      return diaCompare;
    }

    final dateA = parseFecha(a.fecha);
    final dateB = parseFecha(b.fecha);
    return dateA.compareTo(dateB);
  });

  int count = 0;

  for (final item in data) {
    final partes = item.fecha.split('/');
    if (partes.length == 3) {
      if (item.dia == clase.dia && item.hora == clase.hora) {
        if (!item.mails.contains(user) && count < 4) {
          item.mails.add(user);

          await supabaseClient
              .from(taller)
              .update(item.toMap())
              .eq('id', item.id);

          ModificarLugarDisponible().removerLugarDisponible(item.id);

          callback(item);

          count++;
        
      }
    }
  }

  
   
  
  }
}


  Future<void> agregarUsuarioAListaDeEspera(int id, String user) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    final data =
        await supabaseClient.from(taller).select().eq('id', id).single();
    final clase = ClaseModels.fromMap(data);

    if (!clase.espera.contains(user)) {
      clase.espera.add(user);

      await supabaseClient
          .from(taller)
          .update({"espera": clase.espera}).eq('id', id);
    }
  }
}
