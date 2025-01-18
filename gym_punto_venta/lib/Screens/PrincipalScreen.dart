import 'package:flutter/material.dart';
import 'package:gym_punto_venta/widgets/statscard.dart';
import 'package:gym_punto_venta/widgets/filter_button.dart';
import 'package:gym_punto_venta/widgets/client_table.dart';
import 'package:gym_punto_venta/widgets/balane_view.dart';
import 'package:gym_punto_venta/widgets/clients_stas_view.dart';
import 'package:gym_punto_venta/widgets/search_bar.dart' as custom;
import 'package:gym_punto_venta/widgets/settins_model.dart';
import '../functions/funtions.dart';
import '../models/clients.dart';

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

  double _balance = 0.0; // Asegúrate de que esta variable esté definida
  double _monthlyFee = 30.0;
  double _weeklyFee = 10.0;
  double _visitFee = 5.0;
  bool _showBalanceView = false;
  bool _darkMode = false;

  late GymManagementFunctions _functions;

  @override
  void initState() {
    super.initState();
    _functions = GymManagementFunctions(
      context: context,
      darkMode: _darkMode,
      clients: _clients,
      updateClients: (clients) {
        setState(() {
          _clients = clients;
          _applyFilter(_currentFilter);
        });
      },
      updateBalance: (balance) {
        setState(() {
          _balance = balance;
        });
      },
      applyFilter: _applyFilter,
      monthlyFee: _monthlyFee,
      weeklyFee: _weeklyFee,
      visitFee: _visitFee,
      balance: _balance, // Pasa el balance actual
    );
    _functions.loadGymData();
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
                  onPressed: () => _functions.addNewClient(isVisit: true),
                  child: const Text('Visita' , style: TextStyle(color: Colors.blue)),
                ),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor:_darkMode ? Colors.grey[800] : Colors.white),
                  onPressed: () => _functions.addNewClient(isVisit: false , darkMode: _darkMode),
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
              BalanceView(darkMode: _darkMode, balance: _balance, functions: _functions)
            else
              ClientStatsView(darkMode: _darkMode, clients: _clients, calculateRemainingDays: _calculateRemainingDays),
            const SizedBox(height: 20),
            custom.SearchBar(
              searchController: _searchController,
              clients: _clients,
              onSearch: (value) {
                setState(() {
                  _filteredClients = _clients.where((client) =>
                      client.name.toLowerCase().contains(value.toLowerCase()) ||
                      client.email.toLowerCase().contains(value.toLowerCase()) ||
                      client.phone.toLowerCase().contains(value.toLowerCase())
                  ).toList();
                });
              },
              darkMode: _darkMode,
              currentFilter: _currentFilter,
              applyFilter: _applyFilter,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ClientTable(
                mode: _darkMode,
                clients: _filteredClients,
                onEdit: _functions.editClient,
                onRenew: (client) => _functions.renewClient(client, _darkMode),
                onDelete: (client) {
                  setState(() {
                    _clients.removeWhere((c) => c.id == client.id);
                    _applyFilter(_currentFilter);
                  });
                  _functions.saveGymData(_clients, _balance);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            backgroundColor: _darkMode ? const Color.fromARGB(255, 49, 49, 49) : Colors.white,
            context: context,
            builder: (BuildContext context) {
              return SettingsModal(
                darkMode: _darkMode,
                onExport: _functions.exportToJson,
                onImport: _functions.importFromJson,
                onDarkModeToggle: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                },
              );
            },
          );
        },
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}