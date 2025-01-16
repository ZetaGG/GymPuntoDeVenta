import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';

import 'package:shared_preferences/shared_preferences.dart';

class GymManagementScreen extends StatefulWidget {
  const GymManagementScreen({super.key});

  @override
  State<GymManagementScreen> createState() => _GymManagementScreenState();
}

class _GymManagementScreenState extends State<GymManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  String _currentFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final prefs = await SharedPreferences.getInstance();
    final String? clientsJson = prefs.getString('clients');
    if (clientsJson != null) {
      final List<dynamic> decodedJson = json.decode(clientsJson);
      setState(() {
        _clients = decodedJson.map((item) => Client.fromJson(item)).toList();
        _applyFilter(_currentFilter);
      });
    }
  }

  Future<void> _saveClients() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedJson = json.encode(_clients.map((e) => e.toJson()).toList());
    await prefs.setString('clients', encodedJson);
  }

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      switch (filter) {
        case 'Activos':
          _filteredClients = _clients.where((client) => client.isActive).toList();
          break;
        case 'Inactivos':
          _filteredClients = _clients.where((client) => !client.isActive).toList();
          break;
        case 'Próximos a vencer':
          _filteredClients = _clients.where((client) {
            final daysRemaining = _calculateRemainingDays(client.endDate);
            return client.isActive && daysRemaining <= 7 && daysRemaining >= 0;
          }).toList();
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

      void _addNewClient() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController();
        final emailController = TextEditingController();
        final phoneController = TextEditingController();
        String membershipType = 'Mensual';
        DateTime startDate = DateTime.now();
        DateTime endDate = DateTime(
          DateTime.now().add(const Duration(days: 30)).year,
          DateTime.now().add(const Duration(days: 30)).month,
          DateTime.now().add(const Duration(days: 30)).day,
          23,
          59,
          59,
        );

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nuevo Cliente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Tipo de Membresía: '),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: membershipType,
                          items: const [
                            DropdownMenuItem(
                              value: 'Mensual',
                              child: Text('Mensual (30 días)'),
                            ),
                            DropdownMenuItem(
                              value: 'Semanal',
                              child: Text('Semanal (7 días)'),
                            ),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              membershipType = value!;
                              endDate = DateTime(
                                DateTime.now().add(Duration(days: value == 'Mensual' ? 30 : 7)).year,
                                DateTime.now().add(Duration(days: value == 'Mensual' ? 30 : 7)).month,
                                DateTime.now().add(Duration(days: value == 'Mensual' ? 30 : 7)).day,
                                23,
                                59,
                                59,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newClient = Client(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      email: emailController.text,
                      phone: phoneController.text,
                      startDate: startDate,
                      endDate: endDate,
                      isActive: true,
                    );
                    setState(() {
                      _clients.add(newClient);
                      _applyFilter(_currentFilter);
                    });
                    _saveClients();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _renewClient(Client client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String membershipType = 'Mensual';
        DateTime newEndDate = DateTime(
          DateTime.now().add(const Duration(days: 30)).year,
          DateTime.now().add(const Duration(days: 30)).month,
          DateTime.now().add(const Duration(days: 30)).day,
          23,
          59,
          59,
        );

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Renovar Membresía'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Cliente: ${client.name}'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Tipo de Renovación: '),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: membershipType,
                        items: const [
                          DropdownMenuItem(
                            value: 'Mensual',
                            child: Text('Mensual (30 días)'),
                          ),
                          DropdownMenuItem(
                            value: 'Semanal',
                            child: Text('Semanal (7 días)'),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            membershipType = value!;
                            newEndDate = DateTime(
                              DateTime.now().add(Duration(days: value == 'Mensual' ? 30 : 7)).year,
                              DateTime.now().add(Duration(days: value == 'Mensual' ? 30 : 7)).month,
                              DateTime.now().add(Duration(days: value == 'Mensual' ? 30 : 7)).day,
                              23,
                              59,
                              59,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      final index = _clients.indexWhere((c) => c.id == client.id);
                      if (index != -1) {
                        _clients[index] = Client(
                          id: client.id,
                          name: client.name,
                          email: client.email,
                          phone: client.phone,
                          startDate: DateTime.now(),
                          endDate: newEndDate,
                          isActive: true,
                        );
                        _applyFilter(_currentFilter);
                      }
                    });
                    _saveClients();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Renovar'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  void _deleteClient(Client client) {
    setState(() {
      _clients.removeWhere((c) => c.id == client.id);
      _applyFilter(_currentFilter);
    });
    _saveClients();
  }

  void _editClient(Client client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime newEndDate = client.endDate;
        DateTime initialDate = client.endDate.isBefore(DateTime.now())
            ? DateTime.now()
            : client.endDate;

        return AlertDialog(
          title: Text('Editar fecha de vencimiento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cliente: ${client.name}'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    newEndDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      23,
                      59,
                      59,
                    );
                  }
                },
                child: Text('Seleccionar nueva fecha'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final index = _clients.indexWhere((c) => c.id == client.id);
                  if (index != -1) {
                    _clients[index] = Client(
                      id: client.id,
                      name: client.name,
                      email: client.email,
                      phone: client.phone,
                      startDate: client.startDate,
                      endDate: newEndDate,
                      isActive: true,
                    );
                    _applyFilter(_currentFilter);
                  }
                });
                _saveClients();
                Navigator.of(context).pop();
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  DataCell _buildStatusCell(Client client) {
    final daysRemaining = _calculateRemainingDays(client.endDate);
    final isExpired = daysRemaining <= 0;
    final isNearExpiration = daysRemaining <= 7 && daysRemaining > 0;

    Color backgroundColor;
    Color textColor;
    String statusText;

    if (isExpired || !client.isActive) {
      backgroundColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red.shade700;
      statusText = 'Inactivo';
    } else if (isNearExpiration) {
      backgroundColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange.shade700;
      statusText = 'Activo - $daysRemaining días restantes';
    } else {
      backgroundColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green.shade700;
      statusText = 'Activo - $daysRemaining días restantes';
    }

    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  onPressed: _addNewClient,
                  child: const Text('Nuevo Cliente'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Clientes', _clients.length.toString()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Clientes Activos', _clients.where((c) => c.isActive).length.toString()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Clientes Inactivos', _clients.where((c) => !c.isActive).length.toString()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
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
                _buildFilterButton('Todos', _currentFilter == 'Todos'),
                const SizedBox(width: 8),
                _buildFilterButton('Activos', _currentFilter == 'Activos'),
                const SizedBox(width: 8),
                _buildFilterButton('Inactivos', _currentFilter == 'Inactivos'),
                const SizedBox(width: 8),
                _buildFilterButton('Próximos a vencer', _currentFilter == 'Próximos a vencer'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Teléfono')),
                    DataColumn(label: Text('Fecha Inicio')),
                    DataColumn(label: Text('Fecha Vencimiento')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: _filteredClients.map((client) {
                    return DataRow(
                      cells: [
                        DataCell(Text(client.name)),
                        DataCell(Text(client.email)),
                        DataCell(Text(client.phone)),
                        DataCell(Text(client.startDate.toString().split(' ')[0])),
                        DataCell(Text(client.endDate.toString().split(' ')[0])),
                        _buildStatusCell(client),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _editClient(client),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: const Text('Editar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _renewClient(client),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: const Text('Renovar'),
                              ),
                              const SizedBox(width: 8),
                      ElevatedButton(
                                onPressed: () => _deleteClient(client),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isActive) {
    return ElevatedButton(
      onPressed: () => _applyFilter(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue : Colors.white,
        foregroundColor: isActive ? Colors.white : Colors.blue,
      ),
      child: Text(text),
    );
  }
}