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
        primaryColor: Colors.blue[900],
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[900]!),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 2; // Začínáme na Výsledcích

  final List<Widget> _pages = [
    const ContentPage(collection: 'zapasy', title: 'Plán zápasů', icon: Icons.event),
    const ContentPage(collection: 'novinky', title: 'Aktuality', icon: Icons.newspaper),
    const ResultsPage(),
    const ContentPage(collection: 'stadion', title: 'O stadionu', icon: Icons.stadium),
    const ContentPage(collection: 'kategorie', title: 'Týmy a kategorie', icon: Icons.category),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spartak Smržovka', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () => _showLoginDialog(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Zápasy'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Novinky'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Výsledky'),
          BottomNavigationBarItem(icon: Icon(Icons.stadium), label: 'Stadion'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Kategorie'),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin vstup'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Zadejte heslo"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'smrzovka2026') {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminMenuPage()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Špatné heslo!')));
              }
            },
            child: const Text('Vstoupit'),
          ),
        ],
      ),
    );
  }
}

class ContentPage extends StatelessWidget {
  final String collection;
  final String title;
  final IconData icon;
  const ContentPage({super.key, required this.collection, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return Center(child: Text('Zatím žádné $title'));
        return ListView(
          children: snapshot.data!.docs.map((doc) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(icon, color: Colors.blue[900]),
              title: Text(doc['obsah'] ?? "", style: const TextStyle(fontSize: 16)),
              subtitle: Text(doc['datum'] ?? "", style: const TextStyle(fontSize: 12)),
            ),
          )).toList(),
        );
      },
    );
  }
}

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vysledky').orderBy('datum', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          children: snapshot.data!.docs.map((doc) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.sports_soccer, color: Colors.blue),
              title: Text("${doc['souper']}   ${doc['skore']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              subtitle: Text("Datum zápasu: ${doc['datum']}"),
            ),
          )).toList(),
        );
      },
    );
  }
}

class AdminMenuPage extends StatelessWidget {
  const AdminMenuPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Menu - Ovládání')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _adminTile(context, 'Přidat Výsledek', 'vysledky', true),
          _adminTile(context, 'Přidat Zápas', 'zapasy', false),
          _adminTile(context, 'Přidat Novinku', 'novinky', false),
          _adminTile(context, 'Změnit Info o Stadionu', 'stadion', false),
          _adminTile(context, 'Přidat Kategorii', 'kategorie', false),
        ],
      ),
    );
  }

  Widget _adminTile(BuildContext context, String title, String coll, bool isResult) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.add_circle, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAddPage(collection: coll, isResult: isResult))),
      ),
    );
  }
}

class AdminAddPage extends StatefulWidget {
  final String collection;
  final bool isResult;
  const AdminAddPage({super.key, required this.collection, required this.isResult});
  @override
  State<AdminAddPage> createState() => _AdminAddPageState();
}

class _AdminAddPageState extends State<AdminAddPage> {
  final _c1 = TextEditingController();
  final _c2 = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Přidat nový obsah')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _c1, 
              maxLines: widget.isResult ? 1 : 3,
              decoration: InputDecoration(
                labelText: widget.isResult ? 'Soupeř' : 'Zde napište text (zpráva/info)',
                border: const OutlineInputBorder()
              )
            ),
            if (widget.isResult) const SizedBox(height: 15),
            if (widget.isResult) TextField(
              controller: _c2, 
              decoration: const InputDecoration(labelText: 'Skóre (např. 2:0)', border: OutlineInputBorder())
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
              onPressed: () {
                Map<String, dynamic> data = {'datum': DateTime.now().toString().split(' ')[0]};
                if (widget.isResult) {
                  data['souper'] = _c1.text;
                  data['skore'] = _c2.text;
                } else {
                  data['obsah'] = _c1.text;
                }
                FirebaseFirestore.instance.collection(widget.collection).add(data);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uloženo do aplikace!')));
              },
              child: const Text('ULOŽIT DO APLIKACE'),
            ),
          ],
        ),
      ),
    );
  }
}