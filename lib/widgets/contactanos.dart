import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:http/http.dart' as http;

class Contactanos extends StatefulWidget {
  const Contactanos({super.key});

  @override
  State<Contactanos> createState() => _ContactanosState();
}

class _ContactanosState extends State<Contactanos>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  void _launchWhatsApp() async {
    final link = WhatsAppUnilink(
      phoneNumber: '+5491125303794',
      text: '¡Hola! Me gustaría más información.',
    );

    if (await canLaunchUrl(Uri.parse('$link'))) {
      await launchUrl(Uri.parse('$link'), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir WhatsApp. Verifica que está instalado.');
    }
  }

  Future<void> enviarConfirmacionPorSendGrid({
    required BuildContext context,
    required String destinatario,
    required String nombreUsuario,
    required String message,
  }) async {
    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${dotenv.env['SENDGRID_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "personalizations": [
            {
              "to": [
                {"email": destinatario}
              ],
              "subject": "Confirmación de contacto"
            }
          ],
          "from": {
            "email": "soporte@assistify.lat",
            "name": "Soporte Assistify"
          },
          "content": [
            {
              "type": "text/plain",
              "value":
                  'Hola $nombreUsuario,\n\nEste es un mensaje automático para confirmarte que hemos recibido tu consulta: \n\n"$message" \n\nEn breve nos estaremos comunicando para ayudarte con todas tus dudas.\n\nSaludos,\nEquipo de Assistify.'
            }
          ]
        }),
      );

      if (response.statusCode == 202) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ ¡Recibimos exitosamente tu consulta!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "❌ Error al enviar el correo. Contactá a soporte por WhatsApp."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Error inesperado. Contactá a soporte por WhatsApp."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _launchEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    final fullname = user?.userMetadata?['fullname'] ?? 'usuario';
    final email = user?.email ?? 'sin_email';
    final isWide = MediaQuery.of(context).size.width > 600;

    final TextEditingController mensajeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email_outlined,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              "Soporte",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Envia un mail a soporte y te responderemos a $email"),
            const SizedBox(height: 16),
            TextField(
              controller: mensajeController,
              maxLines: isWide ? 2 : 5,
              decoration: const InputDecoration(
                hintText: "Escribí tu mensaje acá...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await enviarConfirmacionPorSendGrid(
                context: context,
                destinatario: email,
                nombreUsuario: fullname,
                message: mensajeController.text,
              );
            },
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 10),
                if (_isExpanded)
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 350),
                    tween: Tween<double>(begin: 12, end: 0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, value),
                      child: FloatingActionButton(
                        onPressed: _launchWhatsApp,
                        backgroundColor: Colors.green,
                        heroTag: 'whatsapp',
                        child: const Icon(
                          FontAwesomeIcons.whatsapp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (_isExpanded)
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 350),
                    tween: Tween<double>(begin: 12, end: 0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, value),
                      child: FloatingActionButton(
                        onPressed: _launchEmail,
                        backgroundColor: Colors.red,
                        heroTag: 'email',
                        child: const Icon(
                          FontAwesomeIcons.envelope,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                // if (_isExpanded)
                //   TweenAnimationBuilder(
                //     duration: const Duration(milliseconds: 350),
                //     tween: Tween<double>(begin: 12, end: 0),
                //     curve: Curves.easeOut,
                //     builder: (context, value, child) => Transform.translate(
                //       offset: Offset(0, value),
                //       child: GestureDetector(
                //         onTap: () {
                //           setState(() {
                //             context.push("/chatscreen");
                //           });
                //         },
                //         child: Container(
                //           width: isWide ?  size.width * 0.065 : size.width * 0.143,
                //           height: isWide ?  size.height * 0.135 : size.height * 0.068,
                //           decoration: BoxDecoration(
                //             color: Colors.blueAccent,
                //             borderRadius: BorderRadius.circular(18),
                //             boxShadow: [
                //               BoxShadow(
                //                 color: Colors.black.withAlpha(10),
                //                 blurRadius: 8,
                //                 spreadRadius: 2,
                //               ),
                //             ],
                //           ),
                //           child: const Icon(
                //             Icons.android,
                //             color: Colors.white,
                //             size: 33,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                const SizedBox(height: 10),
                Visibility(
                  visible: !isKeyboardOpen, // Oculta si el teclado está abierto
                  child: IntrinsicWidth(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExpanded
                                ? Icons.close
                                : Icons.contact_page_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 5),
                          const Text("Contáctanos"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
