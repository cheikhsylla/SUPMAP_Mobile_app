import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignalementPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const SignalementPage({required this.latitude, required this.longitude});

  @override
  _SignalementPageState createState() => _SignalementPageState();
}

class _SignalementPageState extends State<SignalementPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  bool _isSending = false;
  bool _showSuccess = false;
  String _confirmationCode = '';

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: Duration(seconds: 1), vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String generateConfirmationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> submitIncident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final url = Uri.parse('http://10.0.2.2:8002/incidents/incidents/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        _isSending = false;
        _showSuccess = true;
        _confirmationCode = generateConfirmationCode();
      });
      _animationController.forward();

      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context, {
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'title': title,
          'description': description
        });
      }
    } else {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'envoi 🚫")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                    parent: _animationController, curve: Curves.elasticOut),
                child: Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 100),
              ),
              SizedBox(height: 16),
              Text(
                "Incident signalé ✅",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text("Code : $_confirmationCode",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Signaler un incident"),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text("Type d'incident", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: title.isEmpty ? null : title,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      'Accident',
                      'Embouteillage',
                      'Route fermée',
                      'Contrôle policier',
                      'Obstacle sur la route',
                    ]
                        .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => title = value);
                    },
                    validator: (value) =>
                    value == null ? 'Veuillez choisir un type' : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Description (facultative)',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    maxLines: 3,
                    onChanged: (value) => description = value,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey),
                      SizedBox(width: 6),
                      Text("Localisation détectée"),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text("Latitude : ${widget.latitude.toStringAsFixed(6)}"),
                  Text("Longitude : ${widget.longitude.toStringAsFixed(6)}"),
                  SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : submitIncident,
                    icon: Icon(Icons.send),
                    label: Text(_isSending ? "Envoi en cours..." : "Envoyer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}