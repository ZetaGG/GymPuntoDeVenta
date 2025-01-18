import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';


import 'package:gym_punto_venta/models/clients.dart';
import 'package:gym_punto_venta/widgets/client_table.dart';
import 'package:gym_punto_venta/widgets/statscard.dart';
import 'package:gym_punto_venta/widgets/filter_button.dart';
import 'package:gym_punto_venta/dialogs/add_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/edit_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/renew_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/edit_prices_dialog.dart';

class GymManagementScreen extends StatefulWidget {
  const GymManagementScreen({super.key});

  @override
  State<GymManagementScreen> createState() => GymManagementScreenState();
}

class GymManagementScreenState extends State<GymManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  String _currentFilter = 'Todos';

  double _balance = 0.0;
  double _monthlyFee = 30.0;
  double _weeklyFee = 10.0;
  double _visitFee = 5.0;
  bool _showBalanceView = false;
  bool _darkMode = false;

  bool darkModeSwitch() {
    return _darkMode;
  }

  @override
  void initState() {
    super.initState();
    _loadGymData();
  }

  Future<void> _loadGymData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gymDataJson = prefs.getString('gymData');
    if (gymDataJson != null) {
      final Map<String, dynamic> decodedJson = json.decode(gymDataJson);
      setState(() {
        _clients = (decodedJson['clients'] as List)
            .map((item) => Client.fromJson(item))
            .toList();
        _balance = decodedJson['balance'] ?? 0.0;
        _monthlyFee = decodedJson['monthlyFee'] ?? 30.0;
        _weeklyFee = decodedJson['weeklyFee'] ?? 10.0;
        _visitFee = decodedJson['visitFee'] ?? 5.0;
        _applyFilter(_currentFilter);
      });
    }
  }

  Future<void> _saveGymData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedJson = json.encode({
      'clients': _clients.map((e) => e.toJson()).toList(),
      'balance': _balance,
      'monthlyFee': _monthlyFee,
      'weeklyFee': _weeklyFee,
      'visitFee': _visitFee,
    });
    await prefs.setString('gymData', encodedJson);
  }

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      switch (filter) {
        case 'Activos':
          _filteredClients = _clients
              .where((client) => client.isActive && _calculateRemainingDays(client.endDate) > 0)
              .toList();
          break;
        case 'Inactivos':
          _filteredClients = _clients
              .where((client) => !client.isActive || _calculateRemainingDays(client.endDate) <= 0)
              .toList();
          break;
        case 'Próximos a vencer':
          _filteredClients = _clients
              .where((client) {
                final daysRemaining = _calculateRemainingDays(client.endDate);
                return client.isActive && daysRemaining <= 7 && daysRemaining > 0;
              })
              .toList();
          break;
        default:
          _filteredClients = List.from(_clients);
      }
    });
  }

  int _calculateRemainingDays(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(today).inDays;
  }

  void _deleteClient(Client client) {
    setState(() {
      _clients.removeWhere((c) => c.id == client.id);
      _applyFilter(_currentFilter);
    });
    _saveGymData();
  }

  void _addNewClient({bool isVisit = false}) {
    if (isVisit) {
      setState(() {
        _balance += _visitFee;
      });
      _saveGymData();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddClientDialog(
          mode: _darkMode,
          onSave: (Client newClient) {
            setState(() {
              _clients.add(newClient);
              _balance += newClient.endDate.difference(newClient.startDate).inDays > 7 ? _monthlyFee : _weeklyFee;
              _applyFilter(_currentFilter);
            });
            _saveGymData();
          },
        );
      },
    );
  }

  void _editClient(Client client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditClientDialog(
          client: client,
          onSave: (Client updatedClient) {
            setState(() {
              final index = _clients.indexWhere((c) => c.id == updatedClient.id);
              if (index != -1) {
                _clients[index] = updatedClient;
                _applyFilter(_currentFilter);
              }
            });
            _saveGymData();
          },
        );
      },
    );
  }

  void _renewClient(Client client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RenewClientDialog(
          mode: _darkMode,
          client: client,
          onRenew: (Client updatedClient, String membershipType) {
            setState(() {
              final index = _clients.indexWhere((c) => c.id == updatedClient.id);
              if (index != -1) {
                _clients[index] = updatedClient;
                _balance += membershipType == 'Mensual' ? _monthlyFee : _weeklyFee;
                _applyFilter(_currentFilter);
              }
            });
            _saveGymData();
          },
        );
      },
    );
  }

  void _editPrices() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditPricesDialog(
          mode: _darkMode,
          monthlyFee: _monthlyFee,
          weeklyFee: _weeklyFee,
          visitFee: _visitFee,
          onSave: (double newMonthlyFee, double newWeeklyFee, double newVisitFee) {
            setState(() {
              _monthlyFee = newMonthlyFee;
              _weeklyFee = newWeeklyFee;
              _visitFee = newVisitFee;
            });
            _saveGymData();
          },
        );
      },
    );
  }

void _exportToJson() async {
  try {
    // Obtener los datos de SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> allPrefs = prefs.getKeys().fold({}, (map, key) {
      map[key] = prefs.get(key);
      return map;
    });
    
    // Convertir a JSON
    final jsonString = jsonEncode(allPrefs);
    
    // Permitir al usuario elegir dónde guardar el archivo
    String? selectedDirectory = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar archivo de configuración',
      fileName: 'gym_config.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (selectedDirectory != null) {
      final file = File(selectedDirectory);
      await file.writeAsString(jsonString);

      await _loadGymData();

      setState(() {
        
      });
      // Mostrar un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo guardado en: ${file.path}')),
      );
    }
  } catch (e) {
    // Mostrar error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al exportar: $e')),
    );
  }
}

void _importFromJson() async {
  try {
    // Permitir al usuario seleccionar el archivo
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Seleccionar archivo de configuración',
    );

    if (result != null) {
      // Leer el archivo seleccionado
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      
      // Decodificar el JSON
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      // Obtener SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Restaurar los datos
      await Future.forEach(data.entries, (MapEntry<String, dynamic> entry) async {
        final key = entry.key;
        final value = entry.value;
        
        if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        } else {
          print('Tipo no soportado para la clave: $key');
        }
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuración importada correctamente')),
      );
    }
  } catch (e) {
    // Mostrar error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al importar: $e')),
    );
  }
}

void _showSettingsMenu() {
  showModalBottomSheet(
    backgroundColor: _darkMode ? const Color.fromARGB(255, 49, 49, 49) : Colors.white,
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.upload_file, 
                    color: _darkMode ? Colors.white : Colors.black),
                  title: Text('Exportar JSON',
                    style: TextStyle(color: _darkMode ? Colors.white : Colors.black)),
                  onTap: () {
                    _exportToJson();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.download,
                    color: _darkMode ? Colors.white : Colors.black),
                  title: Text('Importar JSON',
                    style: TextStyle(color: _darkMode ? Colors.white : Colors.black)),
                  onTap: () {
                    _importFromJson();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.dark_mode,
                    color: _darkMode ? Colors.white : Colors.black),
                  title: Text('Modo Oscuro',
                    style: TextStyle(color: _darkMode ? Colors.white : Colors.black)),
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: (value) {
                      setModalState(() {
                        setState(() {
                          _darkMode = value;
                        });
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? const Color.fromARGB(255, 49, 49, 49) : Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sistema de Gestión - Nombre de tu Gimnasio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor:_darkMode ? Colors.grey[800] : Colors.white),
                  onPressed: () => _addNewClient(isVisit: true),
                  child: const Text('Visita' , style: TextStyle(color: Colors.blue)),
                ),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor:_darkMode ? Colors.grey[800] : Colors.white),
                  onPressed: () => _addNewClient(isVisit: false),
                  child: const Text('Nuevo Cliente' , style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              inactiveTrackColor: _darkMode ? Colors.grey[800] : Colors.white,
              inactiveThumbColor: _darkMode ? Colors.white : Colors.grey, 
                title: Text(
                'Mostrar Balance',
                style: TextStyle(color: _darkMode ? Colors.white : Colors.grey),
                ),
              value: _showBalanceView,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _showBalanceView = value;
                });
              },
            ),
            if (_showBalanceView)
              Row(
                children: [
                  Expanded(
                    child: StatCard(mode: _darkMode,title: 'Balance Anual', value: _balance.toStringAsFixed(2)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(mode: _darkMode, title: 'Balance Mensual', value: (_balance / 12).toStringAsFixed(2)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor:_darkMode ? Colors.grey[800] : Colors.white),
                      onPressed: _editPrices,
                      child: const Text('Editar Precios',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: StatCard(mode: _darkMode,title: 'Total Clientes', value: _clients.length.toString()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      mode: _darkMode,
                      title: 'Clientes Activos',
                      value: _clients.where((c) => c.isActive && _calculateRemainingDays(c.endDate) > 0).length.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      mode: _darkMode,
                      title: 'Clientes Inactivos',
                      value: _clients.where((c) => !c.isActive || _calculateRemainingDays(c.endDate) <= 0).length.toString(),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    
                    controller: _searchController,
                    decoration:  const InputDecoration(
                      hintStyle: TextStyle(color: Colors.grey),
                      hintText: 'Buscar por nombre, email o teléfono...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filteredClients = _clients.where((client) =>
                            client.name.toLowerCase().contains(value.toLowerCase()) ||
                            client.email.toLowerCase().contains(value.toLowerCase()) ||
                            client.phone.toLowerCase().contains(value.toLowerCase())
                        ).toList();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                FilterButton(
                  mode: _darkMode,
                  text: 'Todos',
                  isActive: _currentFilter == 'Todos',
                  onPressed: () => _applyFilter('Todos'),
                ),
                const SizedBox(width: 8),
                FilterButton(
                  mode: _darkMode,
                  text: 'Activos',
                  isActive: _currentFilter == 'Activos',
                  onPressed: () => _applyFilter('Activos'),
                ),
                const SizedBox(width: 8),
                FilterButton(
                  mode: _darkMode,
                  text: 'Inactivos',
                  isActive: _currentFilter == 'Inactivos',
                  onPressed: () => _applyFilter('Inactivos'),
                ),
                const SizedBox(width: 8),
                FilterButton(
                  mode: _darkMode,
                  text: 'Próximos a vencer',
                  isActive: _currentFilter == 'Próximos a vencer',
                  onPressed: () => _applyFilter('Próximos a vencer'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClientTable(
                mode: _darkMode,
                clients: _filteredClients,
                onEdit: _editClient,
                onRenew: _renewClient,
                onDelete: _deleteClient,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
  onPressed: _showSettingsMenu,
  child: const Icon(Icons.settings),
),
floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}


