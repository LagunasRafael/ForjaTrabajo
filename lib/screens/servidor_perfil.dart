import 'package:flutter/material.dart';

class ServidorPerfil extends StatefulWidget {
  const ServidorPerfil({super.key});

  @override
  State<ServidorPerfil> createState() => _ServidorPerfilState();
}

class _ServidorPerfilState extends State<ServidorPerfil> {
  int _selectedIndex = 3; // Índice del ícono seleccionado en la barra de navegación

  void _onItemTapped(int index) {
    // Si ya está seleccionado, no hacer nada
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    // Navegación basada en el índice seleccionado
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/trabajos');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/mensajes');
        break;
      case 3:
        // Ya estamos en el perfil, no necesitamos navegar
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 140, 
        title: Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 10.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, size: 40, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Armando Juarez Ruiz',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.onSurface,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              Icons.star,
                              color: index < 4 ? Colors.amber : Colors.grey[400],
                              size: 20,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trabajos en proceso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.onSurface,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          Navigator.pushNamed(context, '/');
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 0, 128, 255),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: theme.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 128, 255),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Trabajos completados:', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text('5 de 10', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total de trabajos aceptados:', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text('10', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Valoración de los trabajos:', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Icon(Icons.star, color: Colors.amber, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 180,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 128, 255),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total de trabajos realizados',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '20',
                              style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Icon(Icons.assignment, color: Colors.white, size: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 180,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 128, 255),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total de comentarios positivos',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '10',
                              style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Icon(Icons.star, color: Colors.amber, size: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 0, 128, 255),
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
      ),
    );
  }
}