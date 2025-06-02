import 'package:flutter/material.dart';
// import 'quest_Screen.dart'; // Asegúrate de importar correctamente el archivo del formulario si es necesario para alguna ruta

class HomeScreen extends StatefulWidget {
  final double altura;
  final double curvaIzquierda;
  final double curvaDerecha;
  final bool modoOvalo;

  // Parámetros para posicionamiento de botones (ahora relativos al óvalo)
  final double albanilLeft;
  final double albanilTop;
  final double electricistaRight;
  final double electricistaTop;
  final double plomeroLeft;
  final double plomeroBottom;
  final double plomeroTop; // Este parece duplicado con plomeroBottom, revisar uso
  final double mecanicoRight;
  final double mecanicoBottom;

  const HomeScreen({
    super.key,
    this.altura = 0.35,
    this.curvaIzquierda = 0.9,
    this.curvaDerecha = 1.7,
    this.modoOvalo = true,
    // Valores por defecto para posicionamiento dentro del óvalo
    this.albanilLeft = 30,
    this.albanilTop = 120,
    this.electricistaRight = 40,
    this.electricistaTop = 110,
    this.plomeroLeft = 100,
    this.plomeroBottom = 30,
    this.plomeroTop = 110, // Considerar si este es necesario o si es un error
    this.mecanicoRight = 30,
    this.mecanicoBottom = 40,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Índice del ícono seleccionado en la barra de navegación.
  // Establecido en 0 para el ícono de casa (Home).
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Lógica de navegación basada en el índice seleccionado.
    // Asegúrate de que tus rutas estén definidas en tu MaterialApp.
    switch (index) {
      case 0:
    
        break;
      case 1:
        Navigator.pushNamed(context, '/trabajos'); // Ruta para la pantalla de trabajos
        break;
      case 2:
        Navigator.pushNamed(context, '/mensajes'); // Ruta para la pantalla de mensajes
        break;
      case 3:
        Navigator.pushNamed(context, '/cleinte_perf'); // Ruta para la pantalla de perfil
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context).colorScheme; // Obtener el tema para el BottomNavigationBar

    final List<String> sampleItems =
        List.generate(20, (index) => 'Elemento ${index + 1}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: screenHeight * widget.altura + 100,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Fondo azul con forma de óvalo
                  Container(
                    height: screenHeight * widget.altura,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: widget.modoOvalo
                          ? BorderRadius.vertical(
                              bottom: Radius.elliptical(
                                screenWidth *
                                    (widget.curvaIzquierda + widget.curvaDerecha) /
                                    2,
                                screenWidth * 0.5,
                              ),
                            )
                          : BorderRadius.only(
                              bottomLeft: Radius.elliptical(
                                screenWidth * widget.curvaIzquierda,
                                screenWidth * 0.5,
                              ),
                              bottomRight: Radius.elliptical(
                                screenWidth * widget.curvaDerecha,
                                screenWidth * 0.5,
                              ),
                            ),
                    ),
                  ),

                  // Ubicación
                  Positioned( // Removed const here
                    top: 50,
                    left: 16,
                    child: Container( // Removed const here
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Ciudad Hidalgo Mich.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Barra de búsqueda
                  Positioned(
                    bottom: 200,
                    left: 35,
                    right: 70,
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar oficio...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.blue),
                          suffixIcon: Icon(Icons.tune, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

 // Reemplaza todo el Stack de botones por este Widget:
                  Positioned(
                    top: 120, // Ajusta esta posición según necesites
                    left: 16,
                    right: 16,
                    child: Container(
                      height:
                          290, // Altura suficiente para los botones y sus etiquetas
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCircularButton(
                            icon: Icons.construction,
                            label: 'Albañilería',
                            color: Colors.orange,
                          ),
                          _buildCircularButton(
                            icon: Icons.electrical_services,
                            label: 'Electricista',
                            color: Colors.yellow[700]!,
                          ),
                          _buildCircularButton(
                            icon: Icons.plumbing,
                            label: 'Plomería',
                            color: Colors.blue[400]!,
                          ),
                          _buildCircularButton(
                            icon: Icons.car_repair,
                            label: 'Mecánico',
                            color: Colors.red[400]!,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resto del contenido...
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lo más',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Destacado de',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Hoy',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: PageView(
                      controller: PageController(viewportFraction: 0.8),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCarouselItem('assets/electricista_trabajando.jpg'),
                        _buildCarouselItem('assets/funciones_del_plomero.jpg'),
                        _buildCarouselItem('assets/oficio_albañil.jpg'),
                        _buildCarouselItem('assets/oficio_mecanico.jpg'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          const SliverPadding(
            padding: EdgeInsets.only(left: 16.0, top: 20, bottom: 10),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Profesionales disponibles',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= sampleItems.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _buildListItem(sampleItems[index]);
              },
              childCount: sampleItems.length + 1,
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar integrado
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        backgroundColor: theme.surface,
        type: BottomNavigationBarType.fixed, // Asegura que los ítems tengan ancho fijo
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '', // Etiquetas vacías para solo mostrar íconos
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description), // Ícono de documento
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat), // Ícono de chat
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Ícono de persona
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700], // Texto en gris oscuro
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(String imagePath) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: 8.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12.0),
      image: DecorationImage(
        image: AssetImage(imagePath),
        fit: BoxFit.cover,
      ),
    ),
  );
}

  Widget _buildListItem(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(Icons.person, color: Colors.blue, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Especialista en su área con 5 años de experiencia',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}