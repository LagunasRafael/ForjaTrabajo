import 'package:flutter/material.dart';

class Mensajes extends StatelessWidget {
  final List<Map<String, dynamic>> trabajos = [
    {
      "nombre": "Jose Armando Juarez Ruiz",
      "valoracion": "4.5 de 5",
      "calificacion": "4.5",
      "icono": "🔥",
      "descripcion": "Tengo una fuga en la tubería de la cocina y el grifo gotea todo el tiempo. Necesito que alguien revise, repare y asegure que no haya más problemas",
      "progreso": 0,
      "costo": "\$3000"
    },
    {
      "nombre": "Juan Luis Romero Martinez",
      "valoracion": "5 de 5",
      "calificacion": "5.0",
      "icono": "🔥",
      "descripcion": "Quiero construir un muro nuevo en mi jardín y necesito que también reparen algunas partes dañadas de la pared que ya tengo",
      "progreso": 1,
      "costo": "\$5000"
    },
    {
      "nombre": "Rafael Lagunas Perez",
      "valoracion": "3.8 de 5",
      "calificacion": "3.8",
      "icono": "🔥",
      "descripcion": "Mi auto hace un ruido extraño cuando freno y siento que no está funcionando como antes. Necesito un diagnóstico y reparación urgente",
      "progreso": 2,
      "costo": "\$1500"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0099FF),
      body: SafeArea(
        child: Column(
          children: [
            // Flecha y título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, size: 28, color: Colors.black),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Mensajes',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Barra de búsqueda
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Buscar trabajador',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 60),
            // Contenedor blanco inferior
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título "Trabajo aceptados"
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    // Lista de trabajos
                    ...trabajos.map((trabajo) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(trabajo: trabajo),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF0099FF),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: AssetImage('assets/avatar.png'),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trabajo['nombre'],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Valoracion ${trabajo['valoracion']} ',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          trabajo['icono'],
                                          style: TextStyle(fontSize: 16),
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
                    }).toList()
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2, // Índice 2 para Mensajes
        onTap: (index) {
          // Si ya estamos en la pantalla seleccionada, no hacer nada
          if (index == 2) return;
          
          // Navegar a la nueva pantalla
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/homescreen');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/trabajos');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/cleinte_perf');
              break;
          }
        },
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final Map<String, dynamic> trabajo;

  const ChatScreen({super.key, required this.trabajo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(trabajo['nombre']),
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Mensajes simulados
                _buildMessage(
                  text: "Hola, ¿cómo estás? Necesito ayuda con ${trabajo['descripcion']}",
                  isMe: false,
                  time: "10:00 AM",
                ),
                _buildMessage(
                  text: "Hola, estoy bien. Claro que puedo ayudarte con eso. ¿Cuándo te vendría bien que pasara?",
                  isMe: true,
                  time: "10:05 AM",
                ),
                _buildMessage(
                  text: "¿Podrías venir mañana por la mañana?",
                  isMe: false,
                  time: "10:10 AM",
                ),
                _buildMessage(
                  text: "Sí, perfecto. ¿A qué hora exactamente?",
                  isMe: true,
                  time: "10:12 AM",
                ),
                _buildMessage(
                  text: "¿A las 9:00 AM te parece bien?",
                  isMe: false,
                  time: "10:15 AM",
                ),
                _buildMessage(
                  text: "Perfecto, ahí estaré. ¿Necesitas que lleve algún material especial?",
                  isMe: true,
                  time: "10:16 AM",
                ),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessage({required String text, required bool isMe, required String time}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Color(0xFF0099FF) : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Color(0xFF0099FF)),
            onPressed: () {},
          ),
        ],
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