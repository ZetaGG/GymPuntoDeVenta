import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Añadido para FilteringTextInputFormatter
import 'package:gym_punto_venta/functions/funtions.dart';
import 'package:image_picker/image_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key, required this.functions}) : super(key: key);
  final GymManagementFunctions functions;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _gymNameController;
  late TextEditingController _inactiveDaysController;
  late TextEditingController _licenseKeyController;
  String? _currentLogoPath;
  bool _darkModeEnabled = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _gymNameController = TextEditingController(text: widget.functions.gymName);
    _inactiveDaysController = TextEditingController(text: widget.functions.inactiveDaysThreshold.toString());
    _licenseKeyController = TextEditingController();
    _currentLogoPath = widget.functions.gymLogoPath;
    _darkModeEnabled = widget.functions.darkMode;
  }

  @override
  void dispose() {
    _gymNameController.dispose();
    _inactiveDaysController.dispose();
    _licenseKeyController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _currentLogoPath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkModeEnabled ? const Color.fromARGB(255, 49, 49, 49) : Colors.white,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: _darkModeEnabled ? Colors.grey[800] : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              widget.functions.getLicenseDisplayStatus(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _darkModeEnabled
                    ? (widget.functions.isTrialActive() ? Colors.yellowAccent : (widget.functions.isLicensed() ? Colors.greenAccent : Colors.redAccent))
                    : (widget.functions.isTrialActive() ? Colors.orange[700] : (widget.functions.isLicensed() ? Colors.green[700] : Colors.red[700])),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (!widget.functions.isLicensed())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Activate License",
                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkModeEnabled ? Colors.white : Colors.black)),
                  TextFormField(
                    controller: _licenseKeyController,
                    style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: "Enter License Key",
                      labelStyle: TextStyle(color: _darkModeEnabled ? Colors.white70 : Colors.black54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _darkModeEnabled ? Colors.white54 : Colors.black38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.green[700] : Colors.green),
                    onPressed: () async {
                      if (_licenseKeyController.text.isEmpty) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a license key.")));
                        return;
                      }
                      bool success = await widget.functions.activateLicense(_licenseKeyController.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? "License Activated Successfully!" : "Invalid License Key.")),
                        );
                        if (success) {
                          setState(() {
                            _licenseKeyController.clear();
                          });
                        }
                      }
                    },
                    child: const Text("Activate License", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: _darkModeEnabled ? Colors.white24 : Colors.black12),
                ],
              ),
            ),
          TextFormField(
            controller: _gymNameController,
            enabled: widget.functions.areFeaturesUnlocked(),
            style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: "Gym Name",
              labelStyle: TextStyle(color: _darkModeEnabled ? Colors.white70 : Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _darkModeEnabled ? Colors.white54 : Colors.black38),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _inactiveDaysController,
            enabled: widget.functions.areFeaturesUnlocked(),
            style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Days until inactive deletion (e.g., 30)',
              hintText: 'Enter number of days',
              labelStyle: TextStyle(color: _darkModeEnabled ? Colors.white70 : Colors.black54),
              hintStyle: TextStyle(color: _darkModeEnabled ? Colors.white38 : Colors.black38),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _darkModeEnabled ? Colors.white54 : Colors.black38),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),
          Text("Gym Logo", style: TextStyle(fontSize: 16, color: _darkModeEnabled ? Colors.white : Colors.black)),
          const SizedBox(height: 10),
          Center(
            child: _currentLogoPath != null && _currentLogoPath!.isNotEmpty
                ? Image.file(File(_currentLogoPath!), height: 100, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 100))
                : Icon(Icons.image, size: 100, color: _darkModeEnabled ? Colors.white54 : Colors.grey),
          ),
          TextButton.icon(
            icon: Icon(Icons.upload_file, color: _darkModeEnabled ? Colors.tealAccent[400] : Colors.teal),
            label: Text("Upload Logo", style: TextStyle(color: _darkModeEnabled ? Colors.tealAccent[400] : Colors.teal)),
            onPressed: widget.functions.areFeaturesUnlocked() ? _pickLogo : null,
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text("Dark Mode", style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black)),
            value: _darkModeEnabled,
            activeColor: Colors.teal,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
              });
              widget.functions.updateDarkMode(value);
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.grey[700] : Colors.blue),
            onPressed: () async {
              bool settingsActuallySaved = false;
              if (widget.functions.areFeaturesUnlocked()) {
                final String daysText = _inactiveDaysController.text;
                final int? days = int.tryParse(daysText);
                if (days != null && days > 0) {
                  await widget.functions.saveInactiveDaysThreshold(days);
                  settingsActuallySaved = true;
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid value for inactive days. Not saved.")),
                    );
                  }
                }
                await widget.functions.saveGymName(_gymNameController.text);
                if (_currentLogoPath != null) {
                  await widget.functions.saveGymLogoPath(_currentLogoPath!);
                } else {
                  await widget.functions.saveGymLogoPath('');
                }
                settingsActuallySaved = true;
              }

              if (settingsActuallySaved || !widget.functions.areFeaturesUnlocked()) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settings Saved"), duration: Duration(seconds: 2)),
                  );
                }
              }
            },
            child: const Text("Save All Settings", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          Divider(color: _darkModeEnabled ? Colors.white24 : Colors.black12),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.orange[800] : Colors.orangeAccent),
            onPressed: () async {
              int count = await widget.functions.deleteInactiveClients();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$count inactive clients deleted.")),
                );
              }
            },
            child: const Text("Run Inactive Client Cleanup Now", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.blueGrey[700] : Colors.blueGrey),
            onPressed: () {
              widget.functions.exportToJson();
              // No es necesario verificar mounted ya que exportToJson maneja su propia notificación
            },
            child: const Text("Export Data (Placeholder)", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.blueGrey[700] : Colors.blueGrey),
            onPressed: () {
              widget.functions.importFromJson();
              // No es necesario verificar mounted ya que importFromJson maneja su propia notificación
            },
            child: const Text("Import Data (Placeholder)", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}