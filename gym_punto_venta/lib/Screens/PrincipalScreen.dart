import 'package:flutter/material.dart';
import 'package:gym_punto_venta/widgets/statscard.dart';
import 'package:gym_punto_venta/widgets/filter_button.dart';
import 'package:gym_punto_venta/widgets/client_table.dart';
import 'package:gym_punto_venta/widgets/balane_view.dart';
import 'package:gym_punto_venta/widgets/clients_stas_view.dart';
import 'package:gym_punto_venta/widgets/search_bar.dart' as custom;
// import 'package:gym_punto_venta/widgets/settins_model.dart'; // Removed
import 'package:gym_punto_venta/screens/settings_screen.dart'; // Added
import '../functions/funtions.dart';
import '../models/clients.dart';
import 'dart:io'; // For File object in AppBar logo

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

  bool _showBalanceView = false;
  bool _darkMode = false;

  late GymManagementFunctions _functions;
  // Key for Scaffold to show SnackBars from anywhere if needed, or pass context.
  // final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _functions = GymManagementFunctions(
      context: context,
      darkMode: _darkMode, // Pass initial, it will update from DB
      initialClients: _clients, // Pass empty list, it will be populated by loadGymData
      updateClients: (updatedClients) {
        if (mounted) {
          setState(() {
            _clients = updatedClients;
            _applyFilter(_currentFilter); // Apply filter after clients are updated
          });
        }
      },
      updateBalanceCallback: (newBalance) {
        if (mounted) {
          setState(() {
            // Balance is read from _functions.balance getter
          });
        }
      },
      applyFilter: _applyFilter,
      updateDarkModeCallback: (newMode) { // Added callback for dark mode
        if (mounted) {
          setState(() {
            _darkMode = newMode;
          });
        }
      },
    );
    // loadGymData is called in GymManagementFunctions constructor.
    // It now also calls updateDarkModeCallback.
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
    // Ensure _functions is initialized before trying to access its properties in build
    if (_functions == null) { // Should not happen if initState completes
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      // key: _scaffoldKey, // If using GlobalKey for Scaffold
      backgroundColor: _darkMode ? const Color.fromARGB(255, 49, 49, 49) : Colors.white,
      appBar: AppBar(
        backgroundColor: _darkMode ? Colors.grey[850] : Colors.blue,
        foregroundColor: Colors.white,
        leading: _functions.gymLogoPath != null && _functions.gymLogoPath!.isNotEmpty
           ? Padding(
               padding: const EdgeInsets.all(4.0), // Reduced padding
               child: CircleAvatar( // Using CircleAvatar for a nicer look
                 backgroundImage: FileImage(File(_functions.gymLogoPath!)),
                 onBackgroundImageError: (exception, stackTrace) {
                    print("Error loading AppBar logo: $exception");
                    // Icon(Icons.business_center) will be shown by child if error
                 },
                 child: _functions.gymLogoPath == null || _functions.gymLogoPath!.isEmpty || _functions.gymLogoPath!.contains("Error")
                        ? const Icon(Icons.business_center, color: Colors.white)
                        : null, // Show icon only if path is bad or error occurred (already handled by onBackgroundImageError)
               ),
             )
           : const Icon(Icons.business_center, color: Colors.white),
        title: Text(_functions.gymName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding( // Display License Status
            padding: const EdgeInsets.only(right: 8.0, top: 18.0), // Adjust padding as needed
            child: Text(_functions.getLicenseDisplayStatus(), style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            onPressed: () {
              _functions.updateDarkMode(!_darkMode);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the end
              children: [
                 // Removed the large title text from here, it's now in AppBar
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Visita'),
                  style: ElevatedButton.styleFrom(backgroundColor:_darkMode ? Colors.grey[700] : Colors.lightBlue[100]),
                  onPressed: () async {
                    await _functions.logVisitFeeAsIncome();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Visit fee logged as income.')),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Nuevo Cliente'),
                  style: ElevatedButton.styleFrom(backgroundColor:_darkMode ? Colors.grey[700] : Colors.lightBlue[100]),
                  onPressed: () => _functions.addNewClientDialog(isVisit: false),
                ),
                // const SizedBox(width: 8), // Removed Test Bio button from here
                // ElevatedButton.icon(
                //   icon: const Icon(Icons.fingerprint),
                //   label: const Text("Test Bio"),
                //   style: ElevatedButton.styleFrom(backgroundColor: _darkMode ? Colors.tealAccent[700] : Colors.teal, foregroundColor: Colors.white),
                //   onPressed: () async {
                //     String result = await _functions.testBiometricAuthentication();
                //     if (mounted) {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         SnackBar(content: Text(result), duration: const Duration(seconds: 3))
                //       );
                //     }
                //   },
                // ),
              ],
            ),
            const SizedBox(height: 10), // Reduced space
            SwitchListTile(
              inactiveTrackColor: _darkMode ? Colors.grey[800] : Colors.white,
              inactiveThumbColor: _darkMode ? Colors.white : Colors.grey,
              title: Text(
                'Mostrar Balance',
                style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
              ),
              value: _showBalanceView,
              activeColor: Colors.blue,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _showBalanceView = value;
                  });
                }
              },
            ),
            if (_showBalanceView)
              // Use getter for balance from _functions
              BalanceView(darkMode: _darkMode, balance: _functions.balance, functions: _functions)
            else
              // Use getter for clients from _functions
              ClientStatsView(darkMode: _darkMode, clients: _functions.clients, calculateRemainingDays: _calculateRemainingDays),
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
                onEdit: _functions.editClientDialog,
                onRenew: (client) => _functions.renewClientDialog(client),
                onDelete: (client) async {
                  await _functions.deleteClient(client);
                  // _applyFilter(_currentFilter); // Re-apply filter after delete if needed, though updateClients should handle it
                },
                onRegisterVisit: (client) async { // Add this callback
                  await _functions.registerClientVisit(client);
                  // _applyFilter(_currentFilter); // Re-apply filter if isActive status change affects visibility
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _darkMode ? Colors.grey[700] : Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsScreen(functions: _functions)),
          ).then((_) {
            if (mounted) { // Rebuild to reflect potential changes in gymName, logo, or darkMode
              setState(() {
                 _darkMode = _functions.darkMode; // ensure darkMode is synced back
              });
            }
          });
        },
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}