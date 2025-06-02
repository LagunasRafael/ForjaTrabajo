import 'package:flutter/material.dart';

class DetalleTrabajo extends StatelessWidget {
  final Map detalle_trabajo;

  const DetalleTrabajo({Key? key, required this.detalle_trabajo}) : super(key: key);

  Color getColor(int step, int activeStep) {
    return step == activeStep ? const Color(0xFF005BBB) : const Color(0xFFB0C4DE); // azul fuerte y azul claro (gris)
  }

  @override
  Widget build(BuildContext context) {
    int progreso = detalle_trabajo['progreso'] ?? 0;

    // Determinar si la imagen es una URL de red o un asset local
    ImageProvider<Object> avatarImage;
    Widget avatarChild; // Para el caso de NetworkImage con errorBuilder

    if (detalle_trabajo['imagen'] != null && detalle_trabajo['imagen'].toString().startsWith('http')) {
      // Es una URL de red
      avatarChild = ClipOval(
        child: Image.network(
          detalle_trabajo['imagen'],
          width: 180, // Doble del radio del CircleAvatar (90 * 2)
          height: 180, // Doble del radio del CircleAvatar
          fit: BoxFit.cover, // Cubre el área del avatar
          errorBuilder: (context, error, stackTrace) {
            // Fallback si la imagen de red falla al cargar
            String initial = detalle_trabajo['nombre'].isNotEmpty ? detalle_trabajo['nombre'][0].toUpperCase() : '';
            return Container(
              width: 180,
              height: 180,
              alignment: Alignment.center,
              color: Colors.grey[400], // Un gris ligeramente más oscuro para el fondo del fallback
              child: Text(
                initial,
                style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      );
      avatarImage = const AssetImage('assets/avatar.png'); // Placeholder de asset, no se usará si Image.network funciona
    } else {
      // Es un asset local o nulo, usa AssetImage
      avatarImage = AssetImage(detalle_trabajo['imagen'] ?? 'assets/avatar.png');
      avatarChild = CircleAvatar(
        radius: 90,
        backgroundImage: avatarImage,
        backgroundColor: Colors.grey[200],
        onBackgroundImageError: (exception, stackTrace) {
          print('Error al cargar la imagen de asset en DetalleTrabajo: $exception');
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Contenedor azul con sombra y borderRadius
            Container(
              height: 290,
              decoration: BoxDecoration(
                color: const Color(0xFF0099FF),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(80)),
                boxShadow: [ // Corregido: de 'box boxShadow' a 'boxShadow'
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(9, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13.5),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, size: 28, color: Colors.grey[850]),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.1),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 90,
                        backgroundColor: Colors.grey[200],
                        // Aquí usamos el widget `avatarChild` que ya maneja la lógica de carga y fallback
                        child: avatarChild,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Calificación en container azul pequeño con estrella alineado a la izquierda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0099FF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detalle_trabajo['calificacion'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.star, color: Color.fromARGB(255, 238, 255, 2), size: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nombre alineado a la izquierda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                detalle_trabajo['nombre'] ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
            ),

            const SizedBox(height: 30),

            // Progreso de trabajo - 3 opciones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Iniciando
                  Column(
                    children: [
                      Icon(Icons.radio_button_checked,
                          color: getColor(0, progreso), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Iniciando',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getColor(0, progreso),
                        ),
                      )
                    ],
                  ),

                  // Por Terminar
                  Column(
                    children: [
                      Icon(Icons.radio_button_checked,
                          color: getColor(1, progreso), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Por Terminar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getColor(1, progreso),
                        ),
                      )
                    ],
                  ),

                  // Terminado
                  Column(
                    children: [
                      Icon(Icons.radio_button_checked,
                          color: getColor(2, progreso), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Terminado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: getColor(2, progreso),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Costo (título y valor alineados a la izquierda)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Costo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detalle_trabajo['costo'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Descripción / Detalle (título y texto alineados a la izquierda)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detalle_trabajo['descripcion'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(child: Container()), // Espacio flexible para que contenido quede arriba
          ],
        ),
      ),
    );
  }
}
