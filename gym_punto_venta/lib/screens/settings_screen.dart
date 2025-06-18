import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_punto_venta/functions/funtions.dart';
import 'package:gym_punto_venta/dialogs/add_transaction_dialog.dart';
import 'package:gym_punto_venta/screens/manage_membership_types_screen.dart';
import 'package:gym_punto_venta/screens/financial_reports_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart'; // Import local_auth

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key, required this.functions}) : super(key: key);
  final GymManagementFunctions functions;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _gymNameController;
  late TextEditingController _inactiveDaysController;
  late TextEditingController _licenseKeyController; // Added controller
  String? _currentLogoPath;
  bool _darkModeEnabled = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _gymNameController = TextEditingController(text: widget.functions.gymName);
    _inactiveDaysController = TextEditingController(text: widget.functions.inactiveDaysThreshold.toString());
    _licenseKeyController = TextEditingController(); // Initialize
    _currentLogoPath = widget.functions.gymLogoPath;
    _darkModeEnabled = widget.functions.darkMode;
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
          Padding( // Added Padding for license status
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

          // Section: License Activation
          if (!widget.functions.isLicensed())
            _buildSection(<Widget>[
              Text("Activate License", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _darkModeEnabled ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
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
                child: const Text("Activate License", style: TextStyle(color: Colors.white)),
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
                      setState(() { _licenseKeyController.clear(); });
                    }
                  }
                },
              ),
            ]),

          // Section: General Settings
          _buildSection(<Widget>[
            Text("General Settings", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _darkModeEnabled ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
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
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            Text("Gym Logo", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _darkModeEnabled ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 8),
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
          ]),

          _buildSection(<Widget>[ // Display Settings
            Text("Display Settings", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _darkModeEnabled ? Colors.white : Colors.black)),
            SwitchListTile(
              title: Text("Dark Mode", style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black)),
              value: _darkModeEnabled,
              activeColor: Colors.teal,
              onChanged: (bool value) {
                setState(() { _darkModeEnabled = value; });
                widget.functions.updateDarkMode(value);
              },
            ),
          ]),

          ElevatedButton( // Save All Settings Button
            style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.grey[700] : Colors.blue),
            child: const Text("Save All Settings", style: TextStyle(color: Colors.white)),
            onPressed: () async { /* ... existing save logic ... */ },
          ),

          _buildSection(<Widget>[ // Data Management Section
             Text("Data Management", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _darkModeEnabled ? Colors.white : Colors.black)),
             const SizedBox(height: 8),
             ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.orange[800] : Colors.orangeAccent),
              child: const Text("Run Inactive Client Cleanup Now", style: TextStyle(color: Colors.white)),
              onPressed: widget.functions.areFeaturesUnlocked() ? () async { /* ... */ } : null,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.blueGrey[700] : Colors.blueGrey),
              child: const Text("Export Data (Placeholder)", style: TextStyle(color: Colors.white)),
              onPressed: () { /* ... */ },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.blueGrey[700] : Colors.blueGrey),
              child: const Text("Import Data (Placeholder)", style: TextStyle(color: Colors.white)),
              onPressed: () { /* ... */ },
            ),
          ]),

          _buildSection(<Widget>[ // Membership & Financial Tools Section
            Text("Tools", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _darkModeEnabled ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            ListTile(
              tileColor: _darkModeEnabled ? Colors.grey[800] : Colors.grey[200],
              leading: Icon(Icons.price_change_outlined, color: _darkModeEnabled ? Colors.white70 : Colors.black54),
              title: Text("Manage Membership Types", style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black)),
              trailing: Icon(Icons.arrow_forward_ios, color: _darkModeEnabled ? Colors.white70 : Colors.black54),
              onTap: () { /* ... */ },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.cyan[700] : Colors.cyan),
              child: const Text("Add Manual Transaction", style: TextStyle(color: Colors.white)),
              onPressed: () { /* ... */ },
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: _darkModeEnabled ? Colors.grey[800] : Colors.grey[200],
              leading: Icon(Icons.insights, color: _darkModeEnabled ? Colors.white70 : Colors.black54),
              title: Text("View Financial Reports", style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black)),
              trailing: Icon(Icons.arrow_forward_ios, color: _darkModeEnabled ? Colors.white70 : Colors.black54),
              onTap: () { /* ... */ },
            ),
          ]),

          // Section: OS-Level Biometric Authentication
          _buildSection(<Widget>[
            Text("OS-Level Biometric Authentication",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _darkModeEnabled ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
              "This feature uses your operating system's built-in biometric authentication (e.g., Windows Hello, macOS Touch ID, Fingerprint on mobile). "
              "It does NOT connect to external USB fingerprint scanners for client identification. "
              "It can be used to verify the current operator of this software.",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: _darkModeEnabled ? Colors.white70 : Colors.black54),
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: Future.wait([
                LocalAuthentication().canCheckBiometrics,
                LocalAuthentication().getAvailableBiometrics()
            ]),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              final textStyle = TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black);
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text("Error checking biometrics: ${snapshot.error}", style: const TextStyle(color: Colors.red));
              }
              bool canCheck = snapshot.data?[0] as bool? ?? false;
              List<BiometricType> availableTypes = snapshot.data?[1] as List<BiometricType>? ?? [];
              String typesString = availableTypes.isEmpty ? "None" : availableTypes.map((t) => t.toString().split('.').last).join(', ');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("OS Biometrics Available: ${canCheck ? 'Yes' : 'No'}", style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                  if (canCheck) Text("Available Types: $typesString", style: textStyle),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkModeEnabled ? Colors.indigo[700] : Colors.indigo),
            child: const Text("Test OS Biometric Authentication", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              String result = await widget.functions.testBiometricAuthentication();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result), duration: const Duration(seconds: 5))
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
