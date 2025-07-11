import 'package:flutter/material.dart';
import 'package:gym_punto_venta/widgets/client_table.dart';
// import 'package:gym_punto_venta/widgets/balane_view.dart'; // Eliminado: ya no se usa
import 'package:gym_punto_venta/widgets/clients_stas_view.dart';
import 'package:gym_punto_venta/widgets/search_bar.dart' as custom;
// import 'package:gym_punto_venta/widgets/settins_model.dart'; // Removed
import 'package:gym_punto_venta/screens/settings_screen.dart'; // Added
// import 'package:gym_punto_venta/screens/product_registration_screen.dart'; // Replaced by AddProductDialog
import 'package:gym_punto_venta/dialogs/add_product_dialog.dart'; // Added for AddProductDialog
import 'package:gym_punto_venta/dialogs/sell_product_dialog.dart'; // Added for SellProductDialog
import 'package:gym_punto_venta/widgets/product_list.dart'; // Added for ProductList widget
import 'package:gym_punto_venta/widgets/sales_summary.dart'; // Added for SalesSummary widget
import 'package:gym_punto_venta/dialogs/edit_stock_dialog.dart'; // Added for EditStockDialog
import '../models/product.dart'; // Added for Product model
import '../functions/funtions.dart';
import '../models/clients.dart';
import '../widgets/balance_dashboard_widget.dart'; // Import for BalanceDashboardWidget
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
  List<String> _productCategories = []; // Lista para almacenar categorías de productos
  bool _showStoreView = false; // Estado para alternar entre vista de Clientes y Tienda
  bool _showBalanceDashboard = false; // Estado para alternar a la vista de Balance

  GymManagementFunctions? _functions;
  bool _isLoadingCategories = true;
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
      updateProductsCallback: (updatedProducts) { // Added callback for products
        if (mounted) {
          setState(() {
            _products = updatedProducts;
          });
        }
      },
    );
    // loadGymData (which also calls loadProducts) is called in GymManagementFunctions constructor.
    _loadProductCategories(); // Cargar categorías después de inicializar _functions
  }

  Future<void> _loadProductCategories() async {
    if (mounted) {
      setState(() {
        _isLoadingCategories = true;
      });
    }
    
    try {
      if (_functions != null) {
        final categories = await _functions!.getAvailableCategories();
        if (mounted) {
          setState(() {
            _productCategories = categories;
            _isLoadingCategories = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _productCategories = [];
            _isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _productCategories = [];
          _isLoadingCategories = false;
        });
      }
    }
  }

  // _loadProducts is now handled by GymManagementFunctions and its callback

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

  // Updated to use GymManagementFunctions
  Future<void> _addProduct(Product product) async {
    if (mounted && _functions != null) {
      await _functions!.addProduct(product); // This will also trigger the callback to update _products
      // After adding a product, reload categories in case a new one was added
      await _loadProductCategories();
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} agregado a la lista de productos.')),
        );
      }
    }
  }

  // Nueva función para manejar la confirmación de la venta desde el diálogo
  Future<void> _confirmSale(Product product, int quantity) async {
    if (mounted && _functions != null) {
      final currentProductInList = _products.firstWhere((p) => p.id == product.id, orElse: () => product);

      if (currentProductInList.stock >= quantity) {
        await _functions!.recordSale(currentProductInList, quantity);
        // recordSale ya actualiza el stock y refresca la UI via callback
        // y debería manejar sus propios SnackBars de éxito/error.
        // Si queremos un SnackBar específico aquí:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venta de $quantity unidad(es) de ${product.name} procesada.')),
        );
      } else {
        // Esta validación también está en el diálogo, pero es bueno tenerla aquí como respaldo.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock insuficiente para ${product.name}. Venta no procesada.')),
        );
      }
    }
  }

  // Modificado para mostrar SellProductDialog
  Future<void> _sellProduct(Product productToSell) async {
    if (!mounted) return;

    // Asegurarse de tener la información más actualizada del producto desde la lista local
    final currentProductInList = _products.firstWhere((p) => p.id == productToSell.id, orElse: () => productToSell);

    if (currentProductInList.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${currentProductInList.name} está sin stock.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SellProductDialog(
          product: currentProductInList, // Usar el producto actualizado
          darkMode: _darkMode,
          onConfirmSale: _confirmSale,
        );
      },
    );
  }

  // This method is now for direct stock adjustments (e.g., from EditStockDialog)
  // It should call the modified updateProductStock in GymManagementFunctions
  void _updateProductStock(Product productToUpdate, int newStock) {
    if (mounted && _functions != null) {
      // It's important that productToUpdate contains the correct ID.
      _functions!.updateProductStock(productToUpdate.id, newStock);
      // UI will update via callback.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock de ${productToUpdate.name} actualizado a $newStock.')),
      );
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
            backgroundImage: (_functions!.gymLogoPath != null && _functions!.gymLogoPath!.isNotEmpty)
                ? FileImage(File(_functions!.gymLogoPath!))
                : null,
            onBackgroundImageError: (_functions!.gymLogoPath != null && _functions!.gymLogoPath!.isNotEmpty)
                ? (exception, stackTrace) {
                    print("Error loading AppBar logo: $exception. Path: ${_functions!.gymLogoPath}");
                  }
                : null,
            child: (_functions!.gymLogoPath == null || _functions!.gymLogoPath!.isEmpty)
                ? const Icon(Icons.business_center, color: Colors.white)
                : null,
          ),
        ),
        title: Text(_functions!.gymName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding( // Display License Status
            padding: const EdgeInsets.only(right: 8.0, top: 18.0), // Adjust padding as needed
            child: Text(_functions!.getLicenseDisplayStatus(), style: const TextStyle(fontSize: 12, color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.store, color: Colors.white),
            tooltip: 'Ver Tienda/Clientes',
            onPressed: () {
              if (mounted) {
                setState(() {
                  _showStoreView = !_showStoreView;
                  if (_showStoreView) _showBalanceDashboard = false; // Ensure only one view is active
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.analytics, color: _showBalanceDashboard ? Colors.amber : Colors.white),
            tooltip: 'Ver Balance Financiero',
            onPressed: () {
              if (mounted) {
                setState(() {
                  _showBalanceDashboard = !_showBalanceDashboard;
                  if (_showBalanceDashboard) _showStoreView = false; // Ensure only one view is active
                });
              }
            },
          ),
          IconButton(
            icon: Icon(_darkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            tooltip: _darkMode ? 'Modo Claro' : 'Modo Oscuro',
            onPressed: () {
              _functions!.updateDarkMode(!_darkMode);
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
                    await _functions!.logVisitFeeAsIncome();
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
                  onPressed: () => _functions!.addNewClientDialog(), // Removed isVisit parameter
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

            // Lógica condicional para mostrar la vista de Clientes, Tienda o Balance
            if (_showBalanceDashboard) ...[
              // --- VISTA DE BALANCE ---
              // Placeholder for BalanceDashboardWidget
              Expanded(
                child: BalanceDashboardWidget(functions: _functions!, darkMode: _darkMode),
              ),
            ] else if (_showStoreView) ...[
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
              ClientStatsView(darkMode: _darkMode, clients: _functions!.clients, calculateRemainingDays: _calculateRemainingDays),
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
                onEdit: _functions!.editClientDialog,
                onRenew: (client) => _functions!.renewClientDialog(client, context),
                onDelete: (client) async {
                  await _functions!.deleteClient(client);
                },
                onRegisterVisit: (client) async {
                  await _functions!.registerClientVisit(client);
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
        onPressed: () async { // Hacer async para poder usar await dentro si es necesario
          if (_showStoreView) {
            // Asegurarse de que las categorías estén cargadas antes de mostrar el diálogo
            if (_isLoadingCategories) {
              await _loadProductCategories(); // Esperar a que se carguen si aún no lo están
            }
            if (!mounted) return; // Verificar si el widget sigue montado después de operaciones asíncronas
            // Acción para la vista de Tienda: Mostrar AddProductDialog
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AddProductDialog(
                  darkMode: _darkMode,
                  onProductSaved: _addProduct,
                  availableCategories: _productCategories, // Pasar las categorías cargadas
                );
              },
            );
          } else {
            // Acción para la vista de Clientes: Navegar a SettingsScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen(functions: _functions!)),
            ).then((_) {
              if (mounted) { // Rebuild to reflect potential changes in gymName, logo, or darkMode
                setState(() {
                   _darkMode = _functions!.darkMode; // ensure darkMode is synced back
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