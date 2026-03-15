import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SpartakApp(),
  ));
}

class SpartakApp extends StatefulWidget {
  const SpartakApp({super.key});

  @override
  State<SpartakApp> createState() => _SpartakAppState();
}

class _SpartakAppState extends State<SpartakApp> {
  int _index = 0;
  final List<String> sekce = ['NOVINKY', 'ZÁPASY', 'STADION', 'KATEGORIE', 'VÝSLEDKY'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TJ SPARTAK SMRŽOVKA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF003399),
        centerTitle: true,
      ),
      body: _index == 0 ? stavbaMenu() : AdminPanel(vsechnySekce: sekce),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'MENU'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'ADMIN'),
        ],
      ),
    );
  }

  Widget stavbaMenu() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: sekce.length,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => DetailSekce(nazevSekce: sekce[i])));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(color: const Color(0xFF003399), borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(sekce[i], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

class DetailSekce extends StatelessWidget {
  final String nazevSekce;
  const DetailSekce({super.key, required this.nazevSekce});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nazevSekce), backgroundColor: const Color(0xFF003399)),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('zpravy').where('sekce', isEqualTo: nazevSekce).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) => Card(
              child: ListTile(
                title: Text(doc['titulek'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${doc['datum'] ?? ''}\n${doc['info'] ?? ''}"),
              ),
            )).toList(),
          );
        },
      ),
    );
  }
}

class AdminPanel extends StatefulWidget {
  final List<String> vsechnySekce;
  const AdminPanel({super.key, required this.vsechnySekce});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final tCtrl = TextEditingController();
  final dCtrl = TextEditingController();
  final iCtrl = TextEditingController();
  String vybranaSekce = 'NOVINKY';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        DropdownButton<String>(
          value: vybranaSekce,
          isExpanded: true,
          items: widget.vsechnySekce.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) => setState(() => vybranaSekce = val!),
        ),
        TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'NÁZEV / SOUPEŘ')),
        TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'DATUM')),
        TextField(controller: iCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'POPIS')),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
          onPressed: () {
            FirebaseFirestore.instance.collection('zpravy').add({
              'sekce': vybranaSekce,
              'titulek': tCtrl.text,
              'datum': dCtrl.text,
              'info': iCtrl.text,
              'cas': Timestamp.now()
            });
            tCtrl.clear();
            dCtrl.clear();
            iCtrl.clear();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('POSLÁNO!')));
          },
          child: const Text('ODESLAT', style: TextStyle(color: Colors.white)),
        )
      ]),
    );
  }
}