import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SmrzovkaApp());
}

class SmrzovkaApp extends StatelessWidget {
  const SmrzovkaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FK Smržovka',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _checkAdminPassword(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vstup pro Admina'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Heslo: smrzovka2026"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text == "smrzovka2026") {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPage()));
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

  @override
  Widget build(BuildContext context) {
    // Opraveno: odstraněna podtržítka u lokálních proměnných
    final List<Widget> pages = [
      _buildUserList('novinky'),
      _buildUserList('zápasy'),
      _buildUserList('výsledky'),
      _buildUserList('kategorie'),
      _buildUserList('stadion'),
    ];

    final List<String> titles = ['Novinky', 'Zápasy', 'Výsledky', 'Kategorie', 'Stadion'];

    return Scaffold(
      appBar: AppBar(
        title: Text('FK Smržovka - ${titles[_selectedIndex]}'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.lock_outline), onPressed: () => _checkAdminPassword(context)),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Novinky'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Zápasy'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Výsledky'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kategorie'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Stadion'),
        ],
      ),
    );
  }

  Widget _buildUserList(String collection) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          children: snapshot.data!.docs.map((doc) => Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(
                doc.data().toString().contains('titulek') ? doc['titulek'] : 
                (doc.data().toString().contains('souper') ? doc['souper'] : 
                (doc.data().toString().contains('zapas') ? doc['zapas'] : doc['nazev'])), 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                doc.data().toString().contains('obsah') ? doc['obsah'] : 
                (doc.data().toString().contains('datum') ? doc['datum'] : 
                (doc.data().toString().contains('skore') ? doc['skore'] : 
                (doc.data().toString().contains('popis') ? doc['popis'] : doc.data().toString().contains('info') ? doc['info'] : "")))),
            ),
          )).toList(),
        );
      },
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [Tab(text: "Novinky"), Tab(text: "Zápasy"), Tab(text: "Výsledky"), Tab(text: "Kategorie"), Tab(text: "Stadion")],
          ),
        ),
        body: const TabBarView( // Přidáno const
          children: [
            AdminSection(collection: 'novinky', fields: ['titulek', 'obsah']),
            AdminSection(collection: 'zápasy', fields: ['souper', 'datum', 'vysledek']),
            AdminSection(collection: 'výsledky', fields: ['zapas', 'skore']),
            AdminSection(collection: 'kategorie', fields: ['nazev', 'popis']),
            AdminSection(collection: 'stadion', fields: ['nazev', 'info']),
          ],
        ),
      ),
    );
  }
}

class AdminSection extends StatelessWidget {
  final String collection;
  final List<String> fields;
  const AdminSection({super.key, required this.collection, required this.fields}); // Opraveno const a klíč

  @override
  Widget build(BuildContext context) {
    final Map<String, TextEditingController> ctrls = {
      for (var f in fields) f: TextEditingController()
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              for (var f in fields) TextField(controller: ctrls[f], decoration: InputDecoration(labelText: f)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Map<String, dynamic> data = {};
                  for (var f in fields) { data[f] = ctrls[f]!.text; }
                  FirebaseFirestore.instance.collection(collection).add(data);
                  for (var c in ctrls.values) { c.clear(); }
                },
                child: Text("Uložit do $collection"),
              ),
            ],
          ),
        ),
        const Divider(thickness: 2),
        const Text("PRO SMAZÁNÍ KLIKNI NA POPELNICI:", style: TextStyle(fontSize: 11, color: Colors.grey)),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection(collection).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              return ListView(
                children: snapshot.data!.docs.map((doc) => ListTile(
                  title: Text(
                    doc.data().toString().contains('titulek') ? doc['titulek'] : 
                    (doc.data().toString().contains('souper') ? doc['souper'] : 
                    (doc.data().toString().contains('zapas') ? doc['zapas'] : doc['nazev']))),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => doc.reference.delete(),
                  ),
                )).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}