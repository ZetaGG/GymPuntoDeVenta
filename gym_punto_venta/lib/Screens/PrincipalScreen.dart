import 'package:flutter/material.dart';
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
  State<GymManagementScreen> createState() => _GymManagementScreenState();
}

class _GymManagementScreenState extends State<GymManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  String _currentFilter = 'Todos';

  double _balance = 0.0;
  double _monthlyFee = 30.0;
  double _weeklyFee = 10.0;
  double _visitFee = 5.0;
  bool _showBalanceView = false;

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
                  onPressed: () => _addNewClient(isVisit: true),
                  child: const Text('Visita'),
                ),
                ElevatedButton(
                  onPressed: () => _addNewClient(isVisit: false),
                  child: const Text('Nuevo Cliente'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Mostrar Balance'),
              value: _showBalanceView,
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
                    child: StatCard(title: 'Balance Anual', value: _balance.toStringAsFixed(2)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(title: 'Balance Mensual', value: (_balance / 12).toStringAsFixed(2)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _editPrices,
                      child: const Text('Editar Precios'),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: StatCard(title: 'Total Clientes', value: _clients.length.toString()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Clientes Activos',
                      value: _clients.where((c) => c.isActive && _calculateRemainingDays(c.endDate) > 0).length.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
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
                FilterButton(
                  text: 'Todos',
                  isActive: _currentFilter == 'Todos',
                  onPressed: () => _applyFilter('Todos'),
                ),
                const SizedBox(width: 8),
                FilterButton(
                  text: 'Activos',
                  isActive: _currentFilter == 'Activos',
                  onPressed: () => _applyFilter('Activos'),
                ),
                const SizedBox(width: 8),
                FilterButton(
                  text: 'Inactivos',
                  isActive: _currentFilter == 'Inactivos',
                  onPressed: () => _applyFilter('Inactivos'),
                ),
                const SizedBox(width: 8),
                FilterButton(
                  text: 'Próximos a vencer',
                  isActive: _currentFilter == 'Próximos a vencer',
                  onPressed: () => _applyFilter('Próximos a vencer'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClientTable(
                clients: _filteredClients,
                onEdit: _editClient,
                onRenew: _renewClient,
                onDelete: _deleteClient,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


