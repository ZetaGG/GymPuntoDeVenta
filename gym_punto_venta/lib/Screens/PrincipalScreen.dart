import 'package:flutter/material.dart';
import 'package:gym_punto_venta/widgets/statscard.dart';
import 'package:gym_punto_venta/widgets/filter_button.dart';
import 'package:gym_punto_venta/widgets/client_table.dart';
// import 'package:gym_punto_venta/widgets/balane_view.dart'; // Eliminado: ya no se usa
import 'package:gym_punto_venta/widgets/clients_stas_view.dart';
import 'package:gym_punto_venta/widgets/search_bar.dart' as custom;
// import 'package:gym_punto_venta/widgets/settins_model.dart'; // Removed
import 'package:gym_punto_venta/screens/settings_screen.dart'; // Added
import 'package:gym_punto_venta/screens/product_registration_screen.dart'; // Added for product registration
import 'package:gym_punto_venta/widgets/product_list.dart'; // Added for ProductList widget
import 'package:gym_punto_venta/widgets/sales_summary.dart'; // Added for SalesSummary widget
import 'package:gym_punto_venta/dialogs/edit_stock_dialog.dart'; // Added for EditStockDialog
import '../models/product.dart'; // Added for Product model
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

  // bool _showBalanceView = false; // Eliminado
  bool _darkMode = false;
  List<Product> _products = []; // Lista para almacenar productos en memoria
  bool _showStoreView = false; // Estado para alternar entre vista de Clientes y Tienda

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

  void _addProduct(Product product) {
    if (mounted) {
      setState(() {
        _products.add(product);
      });
    }
     // Opcional: Mostrar un SnackBar o mensaje de confirmación aquí si se desea
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} agregado a la lista de productos.')),
    );
  }

  void _sellProduct(Product productToSell) {
    if (mounted) {
      setState(() {
        final productIndex = _products.indexWhere((p) => p.id == productToSell.id);
        if (productIndex != -1) {
          if (_products[productIndex].stock > 0) {
            // Crear una nueva instancia del producto con el stock actualizado
            _products[productIndex] = _products[productIndex].copyWith(
              stock: _products[productIndex].stock - 1,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('¡Venta exitosa! 1 unidad de ${productToSell.name} vendida.')),
            );
          } else {
            // Esto no debería ocurrir si el botón está bien deshabilitado en ProductCard
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${productToSell.name} está sin stock.')),
            );
          }
        } else {
          // Esto tampoco debería ocurrir normalmente
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Producto ${productToSell.name} no encontrado.')),
          );
        }
      });
    }
  }

  void _updateProductStock(Product productToUpdate, int newStock) {
    if (mounted) {
      setState(() {
        final productIndex = _products.indexWhere((p) => p.id == productToUpdate.id);
        if (productIndex != -1) {
          _products[productIndex] = _products[productIndex].copyWith(stock: newStock);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stock de ${productToUpdate.name} actualizado a $newStock.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Producto ${productToUpdate.name} no encontrado para actualizar stock.')),
          );
        }
      });
    }
  }

  Future<void> _showEditStockDialog(Product product) async {
    final newStock = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditStockDialog(
          product: product,
          darkMode: _darkMode,
        );
      },
    );

    if (newStock != null) {
      _updateProductStock(product, newStock);
    }
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
        leading: Padding(
          padding: const EdgeInsets.all(4.0),
          child: CircleAvatar(
            backgroundColor: _darkMode ? Colors.grey[750] : Colors.blue[700],
            backgroundImage: (_functions.gymLogoPath != null && _functions.gymLogoPath!.isNotEmpty)
                ? FileImage(File(_functions.gymLogoPath!))
                : null,
            onBackgroundImageError: (_functions.gymLogoPath != null && _functions.gymLogoPath!.isNotEmpty)
                ? (exception, stackTrace) {
                    print("Error loading AppBar logo: $exception. Path: ${_functions.gymLogoPath}");
                  }
                : null,
            child: (_functions.gymLogoPath == null || _functions.gymLogoPath!.isEmpty)
                ? const Icon(Icons.business_center, color: Colors.white)
                : null,
          ),
        ),
        title: Text(_functions.gymName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding( // Display License Status
            padding: const EdgeInsets.only(right: 8.0, top: 18.0), // Adjust padding as needed
            child: Text(_functions.getLicenseDisplayStatus(), style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            tooltip: 'Vender Producto',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductRegistrationScreen(
                    darkMode: _darkMode,
                    onProductSaved: _addProduct, // Pasar el callback
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.store, color: Colors.white),
            tooltip: 'Ver Tienda/Clientes',
            onPressed: () {
              if (mounted) {
                setState(() {
                  _showStoreView = !_showStoreView;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            tooltip: _darkMode ? 'Modo Claro' : 'Modo Oscuro',
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
                  style: ElevatedButton.styleFrom(backgroundColor:_darkMode ? Colors.grey[700] : Colors.lightBlue[100],foregroundColor: _darkMode ? Colors.blue : Colors.blue),
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
                  style: ElevatedButton.styleFrom(backgroundColor:_darkMode ? Colors.grey[700] : Colors.lightBlue[100],foregroundColor: _darkMode ? Colors.blue : Colors.blue),
                  onPressed: () => _functions.addNewClientDialog(), // Removed isVisit parameter
                ),
                // const SizedBox(width: 8),
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
            // El SwitchListTile y BalanceView permanecen eliminados.

            // Lógica condicional para mostrar la vista de Clientes o la Tienda
            if (_showStoreView) ...[
              // --- VISTA DE TIENDA ---
              SalesSummary(
                products: _products,
                darkMode: _darkMode,
              ),
              Expanded(
                child: ProductList(
                  products: _products,
                  darkMode: _darkMode,
                  onSellProduct: _sellProduct,
                   onEditStockProduct: _showEditStockDialog, // Pasar el nuevo callback
                ),
              ),
            ] else ...[
              // --- VISTA DE CLIENTES (POR DEFECTO) ---
              ClientStatsView(darkMode: _darkMode, clients: _functions.clients, calculateRemainingDays: _calculateRemainingDays),
              const SizedBox(height: 20),
              custom.SearchBar(
                searchController: _searchController,
                clients: _clients,
                onSearch: (value) {
                  setState(() {
                    _filteredClients = _clients.where((client) =>
                        client.name.toLowerCase().contains(value.toLowerCase()) ||
                        (client.email?.toLowerCase() ?? '').contains(value.toLowerCase()) ||
                        (client.phone?.toLowerCase() ?? '').contains(value.toLowerCase())
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
                onRenew: (client) => _functions.renewClientDialog(client, context),
                onDelete: (client) async {
                  await _functions.deleteClient(client);
                },
                onRegisterVisit: (client) async {
                  await _functions.registerClientVisit(client);
                },
              ),
            ),
          ],
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _darkMode ? Colors.grey[700] : (_showStoreView ? Colors.teal : Colors.blue),
        foregroundColor: Colors.white,
        tooltip: _showStoreView ? 'Agregar Producto' : 'Configuración',
        onPressed: () {
          if (_showStoreView) {
            // Acción para la vista de Tienda: Navegar a ProductRegistrationScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductRegistrationScreen(
                  darkMode: _darkMode,
                  onProductSaved: _addProduct,
                ),
              ),
            );
          } else {
            // Acción para la vista de Clientes: Navegar a SettingsScreen
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
          }
        },
        child: Icon(_showStoreView ? Icons.add_shopping_cart : Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}