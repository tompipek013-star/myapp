import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SpartakApp());
}

class SpartakApp extends StatelessWidget {
  const SpartakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spartak Smržovka',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spartak Smržovka'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => _showLoginDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vysledky')
            .orderBy('datum', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text("${doc['souper']} - ${doc['skore']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(doc['datum']),
                  leading: const Icon(Icons.sports_soccer, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin přihlášení'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Zadejte heslo",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'smrzovka2026') {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Špatné heslo!')),
                );
              }
            },
            child: const Text('Vstoupit'),
          ),
        ],
      ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _souperController = TextEditingController();
  final _skoreController = TextEditingController();

  void _pridatVysledek() {
    if (_souperController.text.isNotEmpty && _skoreController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('vysledky').add({
        'souper': _souperController.text,
        'skore': _skoreController.text,
        'datum': DateTime.now().toString().split(' ')[0],
      });
      _souperController.clear();
      _skoreController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Výsledek byl úspěšně přidán!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Spartak'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _souperController, 
              decoration: const InputDecoration(labelText: 'Soupeř (např. Tanvald)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _skoreController, 
              decoration: const InputDecoration(labelText: 'Skóre (např. 3:1)'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _pridatVysledek,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Přidat výsledek na web'),
            ),
          ],
        ),
      ),
    );
  }
}