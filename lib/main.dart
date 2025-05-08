import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(CarServiceCalendarApp());
}

class Auto {
  String nazov;
  DateTime? stk;
  DateTime? servis;
  DateTime? dialnicna;
  DateTime? vymenaOleja;
  DateTime? emisna;
  DateTime? vymenaPneumatik;

  Auto({
    required this.nazov,
    this.stk,
    this.servis,
    this.dialnicna,
    this.vymenaOleja,
    this.emisna,
    this.vymenaPneumatik,
  });

  Map<String, dynamic> toJson() => {
        'nazov': nazov,
        'stk': stk?.toIso8601String(),
        'servis': servis?.toIso8601String(),
        'dialnicna': dialnicna?.toIso8601String(),
        'vymenaOleja': vymenaOleja?.toIso8601String(),
        'emisna': emisna?.toIso8601String(),
        'vymenaPneumatik': vymenaPneumatik?.toIso8601String(),
      };

  static Auto fromJson(Map<String, dynamic> json) => Auto(
        nazov: json['nazov'],
        stk: json['stk'] != null ? DateTime.parse(json['stk']) : null,
        servis: json['servis'] != null ? DateTime.parse(json['servis']) : null,
        dialnicna: json['dialnicna'] != null ? DateTime.parse(json['dialnicna']) : null,
        vymenaOleja: json['vymenaOleja'] != null ? DateTime.parse(json['vymenaOleja']) : null,
        emisna: json['emisna'] != null ? DateTime.parse(json['emisna']) : null,
        vymenaPneumatik: json['vymenaPneumatik'] != null ? DateTime.parse(json['vymenaPneumatik']) : null,
      );
}

class CarServiceCalendarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Service Calendar',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Auto> auta = [];
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _loadAuticka();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(DateTime date, String title) async {
    var scheduledDate = date.subtract(Duration(days: 1));
    var androidDetails = AndroidNotificationDetails(
      'channel_id',
      'Auto Reminder',
      importance: Importance.high,
      priority: Priority.high,
    );
    var platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.schedule(
      0,
      'Pripomienka: $title',
      'Máte termín: ${scheduledDate.toLocal().toString().split(' ')[0]}',
      scheduledDate,
      platformDetails,
    );
  }

  Future<void> _loadAuticka() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('auta');
    if (data != null) {
      List decoded = jsonDecode(data);
      setState(() {
        auta = decoded.map((item) => Auto.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveAuticka() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(auta.map((auto) => auto.toJson()).toList());
    await prefs.setString('auta', data);
  }

  void _pridajAuto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AutoDetailScreen(
          onSave: (newAuto) {
            setState(() {
              auta.add(newAuto);
            });
            _saveAuticka();
          },
        ),
      ),
    );
  }

  void _editujAuto(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AutoDetailScreen(
          auto: auta[index],
          onSave: (upravenyAuto) {
            setState(() {
              auta[index] = upravenyAuto;
            });
            _saveAuticka();
          },
        ),
      ),
    );
  }

  void _odstranAuto(int index) {
    setState(() {
      auta.removeAt(index);
    });
    _saveAuticka();
  }

  Widget _buildDeleteButton(int index) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        bool? delete = await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Odstrániť auto'),
            content: Text('Naozaj chcete odstrániť toto auto?'),
            actions: [
              TextButton(child: Text('Nie'), onPressed: () => Navigator.of(context).pop(false)),
              TextButton(child: Text('Áno'), onPressed: () => Navigator.of(context).pop(true)),
            ],
          ),
        );
        if (delete == true) _odstranAuto(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Moje autá')),
      body: auta.isEmpty
          ? Center(child: Text('Zatiaľ nemáš žiadne auto'))
          : ListView.builder(
              itemCount: auta.length,
              itemBuilder: (_, index) {
                final auto = auta[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(auto.nazov, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateRow('STK', auto.stk),
                        _buildDateRow('Servis', auto.servis),
                        _buildDateRow('Dialničná', auto.dialnicna),
                        _buildDateRow('Výmena oleja', auto.vymenaOleja),
                        _buildDateRow('Emisná', auto.emisna),
                        _buildDateRow('Výmena pneumatík', auto.vymenaPneumatik),
                      ],
                    ),
                    onTap: () => _editujAuto(index),
                    trailing: _buildDeleteButton(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pridajAuto,
        child: Icon(Icons.add),
        tooltip: 'Pridať auto',
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime? date) {
    if (date == null) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16),
          SizedBox(width: 6),
          Text('$label: ${date.toLocal().toString().split(' ')[0]}'),
        ],
      ),
    );
  }
}

class AutoDetailScreen extends StatefulWidget {
  final Auto? auto;
  final Function(Auto) onSave;

  AutoDetailScreen({this.auto, required this.onSave});

  @override
  State<AutoDetailScreen> createState() => _AutoDetailScreenState();
}

class _AutoDetailScreenState extends State<AutoDetailScreen> {
  final List<String> znacky = [
    'Mazda', 'Škoda', 'Hyundai', 'BMW', 'Mercedes',
    'Audi', 'Peugeot', 'Citroën', 'Renault', 'Volkswagen'
  ];
  String? vybranaZnacka;
  DateTime? stk, servis, dialnicna, vymenaOleja, emisna, vymenaPneumatik;

  @override
  void initState() {
    super.initState();
    final auto = widget.auto;
    vybranaZnacka = auto?.nazov;
    stk = auto?.stk;
    servis = auto?.servis;
    dialnicna = auto?.dialnicna;
    vymenaOleja = auto?.vymenaOleja;
    emisna = auto?.emisna;
    vymenaPneumatik = auto?.vymenaPneumatik;
  }

  Future<void> _pickDate(String typ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        switch (typ) {
          case 'STK': stk = picked; break;
          case 'Servis': servis = picked; break;
          case 'Dialničná': dialnicna = picked; break;
          case 'Výmena oleja': vymenaOleja = picked; break;
          case 'Emisná': emisna = picked; break;
          case 'Výmena pneumatík': vymenaPneumatik = picked; break;
        }
      });
    }
  }

  Widget _buildDateTile(String label, DateTime? date) {
    return ListTile(
      title: Text(label),
      subtitle: Text(date != null ? date.toLocal().toString().split(' ')[0] : 'Nezadaný'),
      trailing: Icon(Icons.calendar_today),
      onTap: () => _pickDate(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail auta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: vybranaZnacka,
              items: znacky.map((znacka) => DropdownMenuItem(
                value: znacka,
                child: Text(znacka),
              )).toList(),
              onChanged: (value) => setState(() => vybranaZnacka = value),
              decoration: InputDecoration(labelText: 'Značka auta'),
            ),
            _buildDateTile('STK', stk),
            _buildDateTile('Servis', servis),
            _buildDateTile('Dialničná', dialnicna),
            _buildDateTile('Výmena oleja', vymenaOleja),
            _buildDateTile('Emisná', emisna),
            _buildDateTile('Výmena pneumatík', vymenaPneumatik),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (vybranaZnacka != null) {
                  final newAuto = Auto(
                    nazov: vybranaZnacka!,
                    stk: stk,
                    servis: servis,
                    dialnicna: dialnicna,
                    vymenaOleja: vymenaOleja,
                    emisna: emisna,
                    vymenaPneumatik: vymenaPneumatik,
                  );
                  widget.onSave(newAuto);
                  Navigator.pop(context);
                }
              },
              child: Text(widget.auto == null ? 'Pridať auto' : 'Uložiť auto'),
            ),
          ],
        ),
      ),
    );
  }
}
