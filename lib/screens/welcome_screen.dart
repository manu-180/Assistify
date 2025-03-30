import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/supabase/utiles/redirijir_usuario_al_taller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession(); // Llamar a la función al inicializar el widget
  }

  Future<void> _checkSession() async {
    // Recuperar la sesión desde Supabase
    final user = Supabase.instance.client.auth.currentUser;

    // Si la sesión es válida, redirigir al usuario
    if (user != null) {
      await RedirigirUsuarioAlTaller().redirigirUsuario(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // Tamaño de la pantalla

    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height, // Altura total de la pantalla
            width: size.width, // Ancho total de la pantalla
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Imagen (ocupa la mitad de la pantalla)
                Image.asset(
                  'assets/images/libreta.png',
                  height: size.height * 0.5, // 50% de la altura de la pantalla
                  width: size.width, // Ancho completo
                  fit: BoxFit.cover, // Ajuste para cubrir el ancho
                ),

                // Otra mitad de la pantalla para los textos y botones
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(size.height * 0.03, 0,
                        size.height * 0.03, size.height * 0.03),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Título para empresa
                        const Text(
                          '¿Sos empresa?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Texto blanco
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Botones para empresa
                        Column(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                context.push("/creartaller");
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(size.width * 0.8, 50),
                                side: BorderSide(color: Colors.white), // Borde blanco
                              ),
                              child: const Text(
                                  'Crea tu cuenta',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            SizedBox(height: size.width * 0.04),
                            OutlinedButton(
                              onPressed: () {
                                context.push("/login");
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(size.width * 0.8, 50),
                                side: BorderSide(color: Colors.white), // Borde blanco
                              ),
                              child: const Text(
                                'Inicia sesión',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),

                        // Título para alumno
                        const Text(
                          '¿Sos alumno?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Texto blanco
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Botón para alumno
                        OutlinedButton(
                          onPressed: () {
                            context.push("/login");
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size(size.width * 0.8, 50),
                            side: BorderSide(color: Colors.white), // Borde blanco
                          ),
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
