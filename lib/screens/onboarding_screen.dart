
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingItem> _slides = [
    _OnboardingItem(
      title: '¿Qué es Assistify?',
      description: 'Assistify te permite cancelar y recuperar clases de forma automática, sin necesidad de escribirle a tu profesor.',
      image: 'assets/onboarding/inscripcion.jpeg',
    ),
    _OnboardingItem(
      title: 'Paso 1: Crear las clases',
      description: 'Como administrador, lo primero que debes hacer es crear tus clases. '
          'Podés definir el día, la hora y cuántos alumnos puede tener cada una. '
          'Este paso es clave para organizar tu agenda.',
      image: 'assets/onboarding/crearclases.jpeg',
    ),
    _OnboardingItem(
      title: 'Paso 2: Dar de alta a tus alumnos',
      description: 'Desde la sección “Alumnos” podés crear las cuentas de tus alumnos. '
          'Es importante que lo hagas vos como administrador, así el sistema los vincula correctamente a tu entorno '
          'y no se mezclan con alumnos de otros grupos.',
      image: 'assets/onboarding/crearusuarios.jpeg',
    ),
    _OnboardingItem(
      title: 'Paso 3: Insertar alumnos en clases',
      description: 'Desde “Gestión de horarios” podés asignar alumnos a cada clase. '
          'Para ahorrar tiempo, también podés usar el botón x4, que inserta al alumno automáticamente en las próximas 4 clases del mismo día y horario.',
      image: 'assets/onboarding/gestiondehorarios.jpeg',
    ),
    _OnboardingItem(
      title: '¿Qué ven los alumnos?',
      description: 'Cada alumno puede ver sus clases asignadas, cancelar si no puede asistir '
          'y luego usar un crédito para recuperar en otra clase con lugar disponible. '
          'Todo se actualiza en tiempo real y el administrador recibe una notificación automática.',
      image: 'assets/onboarding/alumnoacciones.jpeg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (_, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              slide.image,
                              height: size.height * 0.5,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(slide.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(slide.description,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.start),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ),
              if (_currentIndex == _slides.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ElevatedButton(
                    onPressed: () => context.push('/creartaller'),
                    child: const Text("Comenzar"),
                  ),
                ),
            ],
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Visibility(
              visible: _currentIndex < _slides.length - 1,
              child: TextButton.icon(
  onPressed: () => context.push('/creartaller'),
  icon: const Icon(Icons.arrow_forward_ios, size: 16),
  label: const Text('Saltar'),
  style: TextButton.styleFrom(
    foregroundColor: color.primary,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ),
),

            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String description;
  final String image;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
  });
}
