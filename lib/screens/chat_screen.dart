import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:taller_ceramica/widgets/custom_appbar.dart';
import 'package:taller_ceramica/widgets/responsive_appbar.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = []; // Solo almacena los mensajes visibles en la UI
  bool _isLoading = false;

  final String? openAiApiKey = dotenv.env['OPEN_AI_KEY'];
  final String apiUrl = "https://api.openai.com/v1/chat/completions";

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida del bot
    _messages.add({
      "role": "assistant",
      "content": "¡Hola! Mi nombre es AssistifyBot. Puedo brindarte cualquier información de la aplicación de forma rápida y precisa. ¿En qué puedo ayudarte?"
    });
  }


  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": message});
      _isLoading = true;
    });

    try {
      // 📌 Construimos la lista de mensajes que enviamos a OpenAI (sin mostrar el mensaje de sistema)
      List<Map<String, String>> conversation = [
        {
          "role": "system",
          "content": """
         Eres Assistify Bot, un asistente de una agenda inteligente diseñada para ayudar a los usuarios a gestionar sus horarios de manera eficiente.
Tu función es responder preguntas sobre la aplicación Assistify y brindar asistencia en la gestión de tareas, eventos y recordatorios.

📅 **FUNCIONES PRINCIPALES DE ASSISTIFY**:
- Gestión de horarios con clases, reuniones y eventos.
- Sincronización con calendarios externos.
- Notificaciones automáticas para recordar eventos importantes.
- Posibilidad de añadir descripciones y notas a cada evento.
- Soporte para múltiples usuarios y colaboración en la organización de horarios.

---

### 📌 **FUNCIONALIDADES DETALLADAS**
Assistify tiene tres secciones principales: **Clases**, **Mis Clases** y **Configuración**.

### 📍 **1. Sección "Clases"**
- El usuario verá botones de **lunes a viernes**, cada uno con su fecha correspondiente.
- Al seleccionar un día, aparecerán los botones de las **clases disponibles para ese día**.
- **Si la clase está llena** → el botón estará **deshabilitado**.
- **Si la clase tiene lugares disponibles** → el botón estará **verde**.
- **Si el usuario presiona el botón de una clase disponible**, se abrirá un mensaje de confirmación.
  - Si el usuario confirma, **se gastará un crédito** y se agregará a la clase.
- **Si no hay clases disponibles**, se mostrará un mensaje informando los días que tienen disponibilidad.  
  Ejemplo: *"Hay clases disponibles el lunes, martes y miércoles".*

📌 **Lista de espera**
- Los usuarios pueden **mantener presionado** el botón de una clase (incluso si está llena).
- Aparecerá la opción de **agregarse a la lista de espera**.
- **Entrar a la lista de espera NO consume créditos**.
- Si un usuario cancela su lugar en la clase, **el sistema verifica si el usuario en lista de espera tiene un crédito**:
  - **Si tiene crédito** → se asigna automáticamente el lugar y se le notifica por WhatsApp.
  - **Si no tiene crédito** → no se asigna el lugar automáticamente.

---

### 📍 **2. Sección "Mis Clases"**
- Aquí los usuarios pueden ver todas sus **clases asignadas** y **su posición en la lista de espera**.
- **Cancelar una clase**:
  - Si un usuario cancela una clase **con más de 24 horas de anticipación**, **recupera un crédito**.
  - Si cancela **con menos de 24 horas de anticipación**, **no se le devuelve el crédito**.
- Si un usuario tiene un crédito disponible, puede volver a **usar ese crédito** para inscribirse en otra clase en la sección de "Clases".

---

### 📍 **3. Sección "Configuración"**
- Permite **personalizar la apariencia de la app**, incluyendo **modo nocturno** y cambios de colores.
- **Actualizar datos del usuario**.
- **Acceder a soporte** en caso de dudas o problemas.

---

📢 **IMPORTANTE**:
- **Si un usuario te hace preguntas fuera del contexto de Assistify**, redirígelo amablemente al funcionamiento de la aplicación.
- Responde siempre de manera **clara, concisa y amigable**.
- No inventes información. Si no conoces la respuesta, sugiere contactar con el soporte de Assistify.

          """
        },
        ..._messages // Agregamos los mensajes del usuario y asistente
      ];

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $openAiApiKey",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": conversation, // Enviamos la conversación con el contexto oculto
          "max_tokens": 200,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String botResponse = data["choices"][0]["message"]["content"];

        setState(() {
          _messages.add({"role": "assistant", "content": botResponse});
        });
      } else {
        debugPrint("Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error al conectar con OpenAI: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  String cleanResponse(String text) {
    try {
      String decoded = utf8.decode(text.runes.toList());
      return decoded.replaceAllMapped(
        RegExp(r'Ã©|Ã¡|Ã­|Ã³|Ãº|Ã±|â€™|â€œ|â€�'),
        (match) {
          switch (match[0]) {
            case 'Ã©':
              return 'é';
            case 'Ã¡':
              return 'á';
            case 'Ã­':
              return 'í';
            case 'Ã³':
              return 'ó';
            case 'Ãº':
              return 'ú';
            case 'Ã±':
              return 'ñ';
            case 'â€™':
              return '\'';
            case 'â€œ':
            case 'â€�':
              return '"';
            default:
              return match[0]!;
          }
        },
      );
    } catch (e) {
      print("Error al decodificar texto: $e");
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {

    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: ResponsiveAppBar(isTablet: MediaQuery.of(context).size.width > 600),
      body: Column(
        children: [
          SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["role"] == "user";
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? color.primary.withAlpha(180) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      cleanResponse(message["content"]!.trim()),
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                      textAlign: TextAlign.left,
                      softWrap: true,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) CircularProgressIndicator(),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_controller.text);
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
