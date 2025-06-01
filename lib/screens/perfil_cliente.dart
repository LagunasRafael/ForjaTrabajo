import 'package:flutter/material.dart';

class PerfilCliente extends StatefulWidget {
  const PerfilCliente({super.key});

  @override
  State<PerfilCliente> createState() => _ServidorPerfilState();
}

class _ServidorPerfilState extends State<PerfilCliente> {
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/homescreen');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/trabajos');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/mensajes');
        break;
      case 3:
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
        toolbarHeight: 150,
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
                      radius: 35,
                      backgroundImage: AssetImage('assets/usuario.jpg'),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Armando Juárez Ruiz',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cliente desde 2025',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Ciudad Hidalgo Mich.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
                      'Trabajos solicitados',
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
                          Navigator.pushNamed(context, '/trabajos');
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0080FF),
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
                  'Mi actividad',
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
                        Text('Trabajos solicitados:', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text('15', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('En progreso:', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text('3', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Completados:', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text('12', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Mis estadísticas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 180,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 128, 255),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Servicios contratados',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '15',
                            style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Icon(Icons.shopping_cart, color: Colors.white, size: 40),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 180,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 128, 255),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Profesionales',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '8',
                            style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Icon(Icons.people_alt, color: Colors.white, size: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Sobre mí',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Soy un cliente frecuente de esta plataforma, donde busco profesionales confiables para diversos servicios. Valoro la puntualidad, la calidad del trabajo y la comunicación clara.',
                style: TextStyle(fontSize: 16, color: theme.onSurface.withOpacity(0.8)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Acción para editar perfil
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0080FF),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Editar perfil',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
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