import 'package:flutter/material.dart';
import 'detalle_serv_trabajo.dart'; // Asegúrate de que este archivo exista

// Definimos un enum para los diferentes estados de filtro
enum JobFilter { all, accepted, solicited }

class Trabajos extends StatefulWidget {
  const Trabajos({super.key});

  @override
  State<Trabajos> createState() => _TrabajosState();
}

class _TrabajosState extends State<Trabajos> {
  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();
  // Cadena de consulta de búsqueda
  String _searchQuery = '';
  // Lista de trabajos aceptados (tarjetas azules)
  final List<Map<String, dynamic>> trabajosAceptados = [
    {
      "nombre": "Jose Armando Juarez Ruiz",
      "valoracion": "4.5 de 5",
      "calificacion": "4.5",
      "descripcion":
          "Tengo una fuga en la tubería de la cocina y el grifo gotea todo el tiempo. Necesito que alguien revise, repare y asegure que no haya más problemas",
      "progreso": 0,
      "costo": "\$3000",
      "imagen": "https://picsum.photos/id/1013/100/100" // Asegúrate de tener estas imágenes en tu carpeta assets
    },
    {
      "nombre": "Juan Luis Romero Martinez",
      "valoracion": "5 de 5",
      "calificacion": "5.0",
      "descripcion":
          "Quiero construir un muro nuevo en mi jardín y necesito que también reparen algunas partes dañadas de la pared que ya tengo",
      "progreso": 1,
      "costo": "\$5000",
      "imagen": "https://picsum.photos/id/1043/100/100"
    },
    {
      "nombre": "Rafael Lagunas Perez",
      "valoracion": "3.8 de 5",
      "calificacion": "3.8",
      "descripcion":
          "Mi auto hace un ruido extraño cuando freno y siento que no está funcionando como antes. Necesito un diagnóstico y reparación urgente",
      "progreso": 2,
      "costo": "\$1500",
      "imagen": "https://picsum.photos/id/1020/100/100"
    },
    {
      "nombre": "Sofia Garcia",
      "valoracion": "4.9 de 5",
      "calificacion": "4.9",
      "descripcion":
          "Necesito instalar un nuevo calentador de agua en mi baño y revisar la presión del agua en toda la casa.",
      "progreso": 1,
      "costo": "\$2500",
      "imagen": "https://picsum.photos/id/1024/100/100" // Nueva imagen
    },
    {
      "nombre": "Pedro Ramirez",
      "valoracion": "4.2 de 5",
      "calificacion": "4.2",
      "descripcion":
          "Tengo problemas con el sistema eléctrico de mi casa. Las luces parpadean y algunos enchufes no funcionan.",
      "progreso": 0,
      "costo": "\$1800",
      "imagen": "https://picsum.photos/id/1023/100/100" // Nueva imagen
    },
  ];

  // Nueva lista para solicitudes de trabajo (tarjetas grises) con imágenes de personas de internet
  final List<Map<String, dynamic>> solicitudesTrabajo = [
    {
      "nombre": "Maria Fernanda Lopez",
      "valoracion": "Nuevo",
      "calificacion": "N/A",
      "icono": "✨",
      "descripcion":
          "Necesito ayuda para montar unos muebles nuevos en mi sala. Son tres estanterías y una mesa de centro.",
      "progreso": -1, // Un valor para indicar que es una nueva solicitud
      "costo": "\$800",
      "imagen": "https://picsum.photos/id/1027/100/100" // Imagen de mujer
    },
    {
      "nombre": "Carlos Sanchez",
      "valoracion": "Nuevo",
      "calificacion": "N/A",
      "icono": "✨",
      "descripcion":
          "Mi laptop no enciende y creo que es un problema de la batería o el cargador. Necesito un técnico que la revise.",
      "progreso": -1,
      "costo": "\$1200",
      "imagen": "https://picsum.photos/id/1025/100/100" // Imagen de hombre
    },
    {
      "nombre": "Ana Gomez",
      "valoracion": "Nuevo",
      "calificacion": "N/A",
      "icono": "✨",
      "descripcion":
          "Quiero pintar una habitación de mi casa. Es una habitación de 3x4 metros y necesito ayuda con la preparación y la pintura.",
      "progreso": -1,
      "costo": "\$2000",
      "imagen": "https://picsum.photos/id/1011/100/100" // Imagen de mujer
    },
    {
      "nombre": "Laura Torres",
      "valoracion": "Nuevo",
      "calificacion": "N/A",
      "icono": "✨",
      "descripcion":
          "Busco a alguien que pueda reparar mi lavadora. Hace un ruido extraño al centrifugar y no drena bien el agua.",
      "progreso": -1,
      "costo": "\$950",
      "imagen": "https://picsum.photos/id/1005/100/100" // Imagen de hombre
    },
    {
      "nombre": "Roberto Castro",
      "valoracion": "Nuevo",
      "calificacion": "N/A",
      "icono": "✨",
      "descripcion":
          "Necesito un jardinero para podar los árboles de mi patio trasero y mantener el césped. Es un trabajo recurrente.",
      "progreso": -1,
      "costo": "\$1100",
      "imagen": "https://picsum.photos/id/1012/100/100" // Imagen de hombre
    },
    {
      "nombre": "Elena Ramirez",
      "valoracion": "Nuevo",
      "calificacion": "N/A",
      "icono": "✨",
      "descripcion":
          "Tengo una gotera en el techo de la sala, necesito que alguien venga a revisarla y la repare lo antes posible.",
      "progreso": -1,
      "costo": "\$1500",
      "imagen": "https://picsum.photos/id/1015/100/100" // Imagen de mujer
    },
    {
      "nombre": "Miguel Perez",
      "valoracion": "Nuevo",
      "calificacion": "N/A",
      "icono": "✨",
      "descripcion":
          "Mi bicicleta eléctrica no enciende, creo que es un problema con la batería o el motor. Necesito un técnico especializado.",
      "progreso": -1,
      "costo": "\$1000",
      "imagen": "https://picsum.photos/id/1021/100/100" // Imagen de hombre
    },
  ];

  // Listas filtradas que se mostrarán en la UI
  List<Map<String, dynamic>> _filteredTrabajosAceptados = [];
  List<Map<String, dynamic>> _filteredSolicitudesTrabajo = [];

  // Estado actual del filtro (todos, aceptados, solicitados)
  JobFilter _currentFilter = JobFilter.all;

  @override
  void initState() {
    super.initState();
    // Inicializar las listas filtradas con todos los trabajos al inicio
    _filterJobs();
    // Escuchar cambios en el campo de búsqueda
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Método para manejar cambios en la barra de búsqueda
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterJobs(); // Volver a filtrar cada vez que cambia la búsqueda
    });
  }

  // Método para filtrar los trabajos y solicitudes
  void _filterJobs() {
    final query = _searchQuery.toLowerCase();

    // Filtrar trabajos aceptados
    _filteredTrabajosAceptados = trabajosAceptados.where((job) {
      final nameLower = job['nombre'].toLowerCase();
      final descriptionLower = job['descripcion'].toLowerCase();
      return nameLower.contains(query) || descriptionLower.contains(query);
    }).toList();

    // Filtrar solicitudes de trabajo
    _filteredSolicitudesTrabajo = solicitudesTrabajo.where((job) {
      final nameLower = job['nombre'].toLowerCase();
      final descriptionLower = job['descripcion'].toLowerCase();
      return nameLower.contains(query) || descriptionLower.contains(query);
    }).toList();
  }

  // Método para obtener el icono basado en la calificación
  String _getRatingIcon(String calificacion) {
    double? calificacionValue = double.tryParse(calificacion);
    if (calificacionValue != null) {
      // Si la calificación es mayor a 4.5 (incluyendo 5.0), es llama.
      // De lo contrario, es estrella.
      if (calificacionValue > 4.5) {
        return "🔥";
      } else {
        return "⭐";
      }
    }
    return "⭐"; // Icono por defecto si la calificación no es un número válido
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0099FF),
      body: SafeArea(
        child: Column(
          children: [
            // Flecha y título de la pantalla
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Trabajos',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TextField(
                    controller: _searchController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Buscar trabajador',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    child: Icon(Icons.search, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Espacio antes del filtro
            // Botón de filtro
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SegmentedButton<JobFilter>(
                segments: const <ButtonSegment<JobFilter>>[
                  ButtonSegment<JobFilter>(
                    value: JobFilter.all,
                    label: Text('Todos'),
                    icon: Icon(Icons.list_alt),
                  ),
                  ButtonSegment<JobFilter>(
                    value: JobFilter.accepted,
                    label: Text('Aceptados'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment<JobFilter>(
                    value: JobFilter.solicited,
                    label: Text('Solicitudes'),
                    icon: Icon(Icons.pending_actions),
                  ),
                ],
                selected: <JobFilter>{_currentFilter},
                onSelectionChanged: (Set<JobFilter> newSelection) {
                  setState(() {
                    _currentFilter = newSelection.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  selectedBackgroundColor: const Color(0xFF0099FF),
                  selectedForegroundColor: Colors.white,
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Espacio después del filtro
            // Contenedor principal con fondo blanco y listas de trabajos
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(60)),
                ),
                child: SingleChildScrollView( // Permite el scroll si el contenido excede la pantalla
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección de Trabajos aceptados
                      if (_currentFilter == JobFilter.all || _currentFilter == JobFilter.accepted)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'Trabajos aceptados (${_filteredTrabajosAceptados.length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      if (_currentFilter == JobFilter.all || _currentFilter == JobFilter.accepted)
                        ..._filteredTrabajosAceptados.map((trabajo) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetalleTrabajo(detalle_trabajo: trabajo),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0099FF), // Color azul para trabajos aceptados
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      // Lógica para cargar imagen desde URL o asset
                                      backgroundImage: (trabajo['imagen'] != null && trabajo['imagen'].toString().startsWith('http'))
                                          ? NetworkImage(trabajo['imagen']) as ImageProvider<Object>
                                          : AssetImage(trabajo['imagen']) as ImageProvider<Object>,
                                      backgroundColor: Colors.grey[200],
                                      onBackgroundImageError: (exception, stackTrace) {
                                        // Puedes añadir un print para depurar errores de carga de assets
                                        // print('Error al cargar la imagen de asset para ${trabajo['nombre']}: $exception');
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trabajo['nombre'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Valoracion ${trabajo['valoracion']} ',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            // Aquí se usa el método para obtener el icono dinámicamente
                                            Text(
                                              _getRatingIcon(trabajo['calificacion']),
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                      // Espacio entre secciones
                      if (_currentFilter == JobFilter.all && (_filteredTrabajosAceptados.isNotEmpty || _filteredSolicitudesTrabajo.isNotEmpty))
                        const SizedBox(height: 30),

                      // Sección de Solicitudes de trabajo
                      if (_currentFilter == JobFilter.all || _currentFilter == JobFilter.solicited)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'Solicitudes de trabajo (${_filteredSolicitudesTrabajo.length})',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      if (_currentFilter == JobFilter.all || _currentFilter == JobFilter.solicited)
                        ..._filteredSolicitudesTrabajo.map((solicitud) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetalleTrabajo(detalle_trabajo: solicitud),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200], // Color gris para solicitudes
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.grey[300], // Fondo del avatar si la imagen no carga
                                      child: ClipOval( // Asegura que la imagen o el fallback se recorten en círculo
                                        child: Image.network(
                                          solicitud['imagen'],
                                          width: 50, // Doble del radio
                                          height: 50, // Doble del radio
                                          fit: BoxFit.cover, // Cubre el área del avatar
                                          errorBuilder: (context, error, stackTrace) {
                                            // Fallback si la imagen de red falla al cargar
                                            String initial = solicitud['nombre'].isNotEmpty ? solicitud['nombre'][0].toUpperCase() : '';
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              alignment: Alignment.center,
                                              color: Colors.grey[400], // Un gris ligeramente más oscuro para el fondo del fallback
                                              child: Text(
                                                initial,
                                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          solicitud['nombre'],
                                          style: const TextStyle(
                                            color: Colors.black87, // Texto oscuro para contraste
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Valoracion ${solicitud['valoracion']} ',
                                              style: const TextStyle(color: Colors.black54), // Texto oscuro
                                            ),
                                            Text(
                                              solicitud['icono'], // Aquí se mantiene el icono original de solicitud
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 20), // Espacio al final del scroll
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1, // Índice 1 para la pantalla de trabajos
        onTap: (index) {
          if (index == 1) return;
          // Navigator.pop(context); // Esto podría causar problemas si no hay rutas previas
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/homescreen');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/mensajes');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/cleinte_perf');
              break;
            default:
              // Manejar otros casos o no hacer nada
              break;
          }
        },
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.blue.shade700,
      unselectedItemColor: Colors.grey,
      backgroundColor: theme.surface,
      type: BottomNavigationBarType.fixed,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '',
        ),
      ],
    );
  }
}
