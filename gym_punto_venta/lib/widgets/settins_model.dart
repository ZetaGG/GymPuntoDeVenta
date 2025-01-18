import 'package:flutter/material.dart';

class SettingsModal extends StatelessWidget {
  final bool darkMode;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final ValueChanged<bool> onDarkModeToggle;

  const SettingsModal({
    Key? key,
    required this.darkMode,
    required this.onExport,
    required this.onImport,
    required this.onDarkModeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.upload_file, color: darkMode ? Colors.white : Colors.black),
            title: Text('Exportar JSON', style: TextStyle(color: darkMode ? Colors.white : Colors.black)),
            onTap: onExport,
          ),
          ListTile(
            leading: Icon(Icons.download, color: darkMode ? Colors.white : Colors.black),
            title: Text('Importar JSON', style: TextStyle(color: darkMode ? Colors.white : Colors.black)),
            onTap: onImport,
          ),
          ListTile(
            leading: Icon(Icons.dark_mode, color: darkMode ? Colors.white : Colors.black),
            title: Text('Modo Oscuro', style: TextStyle(color: darkMode ? Colors.white : Colors.black)),
            trailing: Switch(
              value: darkMode,
              onChanged: onDarkModeToggle,
            ),
          ),
        ],
      ),
    );
  }
}