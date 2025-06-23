import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gym_punto_venta/models/clients.dart';
import 'package:gym_punto_venta/models/product.dart'; // Importar Product
import 'package:gym_punto_venta/dialogs/add_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/edit_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/renew_client_dialog.dart';
import 'package:gym_punto_venta/database/database_helper.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

class GymManagementFunctions {
  final BuildContext context;
  bool darkMode;
  List<Client> _clients;
  final Function(List<Client>) updateClients;
  final Function(double) updateBalanceCallback;
  final Function(String) applyFilter;
  double _monthlyFee = 0.0;
  double _weeklyFee = 0.0;
  double _visitFee = 0.0;
  double _balance = 0.0;

  final DatabaseHelper dbHelper = DatabaseHelper();

  // Public getters for fees and balance
  double get monthlyFee => _monthlyFee;
  double get weeklyFee => _weeklyFee;
  double get visitFee => _visitFee;
  double get balance => _balance;
  List<Client> get clients => _clients;

  // Add callback for updating dark mode in PrincipalScreen
  final Function(bool) updateDarkModeCallback;
  String gymName = "My Gym";
  String? gymLogoPath;
  int inactiveDaysThreshold = 30;

  // Trial/License variables
  DateTime? installationDate;
  String licenseStatus = "Uninitialized";
  String? licenseKey;
  String? activatedDeviceId;
  static const int trialDurationDays = 40;
  static const String masterLicenseKey = "SUPER_GYM_LICENSE_2024";

  GymManagementFunctions({
    required this.context,
    required this.darkMode,
    required List<Client> initialClients,
    required this.updateClients,
    required this.updateBalanceCallback,
    required this.applyFilter,
    required this.updateDarkModeCallback,
  }) : _clients = initialClients, _balance = 0.0 {
    loadGymData();
  }

  Future<void> migrateOldDataToSqliteIfNeeded() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool migrationDone = prefs.getBool('migration_done_v1_to_sqlite') ?? false;

      if (migrationDone) {
        return;
      }

      print('Starting data migration from SharedPreferences to SQLite...');

      String? oldGymDataJson = prefs.getString('gymData');

      if (oldGymDataJson == null || oldGymDataJson.isEmpty) {
        print('No old gymData found in SharedPreferences. Marking migration as done.');
        await prefs.setBool('migration_done_v1_to_sqlite', true);
        return;
      }

      Map<String, dynamic> decodedOldJson = json.decode(oldGymDataJson);
      List<dynamic>? oldClientsJson = decodedOldJson['clients'] as List<dynamic>?;
      double oldBalance = (decodedOldJson['balance'] ?? 0.0).toDouble();

      // Migrate Clients
      if (oldClientsJson != null) {
        print('Migrating ${oldClientsJson.length} clients...');
        for (var oldClientMap in oldClientsJson) {
          if (oldClientMap is Map<String, dynamic>) {
            Client migratedClient = Client(
              id: oldClientMap['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: oldClientMap['name'] ?? 'Unknown Name',
              email: oldClientMap['email']?.toString(),
              phone: oldClientMap['phone']?.toString(),
              startDate: oldClientMap['startDate'] != null ? DateTime.parse(oldClientMap['startDate']) : DateTime.now(),
              endDate: oldClientMap['endDate'] != null ? DateTime.parse(oldClientMap['endDate']) : DateTime.now().add(const Duration(days: 30)),
              isActive: oldClientMap['isActive'] ?? true,
              membershipType: oldClientMap['membershipType'] ?? "Monthly",
              paymentStatus: "Paid",
              photo: null,
              lastVisitDate: null,
            );
            await dbHelper.insertClient(migratedClient);
          }
        }
      }

      // Migrate Balance
      print('Migrating balance: $oldBalance');
      await dbHelper.updateSetting('current_balance', oldBalance.toString());

      // Finalize Migration
      await prefs.remove('gymData');
      await prefs.remove('monthlyFee');
      await prefs.remove('weeklyFee');
      await prefs.remove('visitFee');

      await prefs.setBool('migration_done_v1_to_sqlite', true);
      print('Data migration from SharedPreferences to SQLite completed successfully.');

    } catch (e) {
      print('Error during data migration: $e');
    }
  }

  Future<void> loadGymData() async {
    await migrateOldDataToSqliteIfNeeded();

    // Initialize/Load license settings
    String? storedInstallDate = await dbHelper.getSetting('installation_date');
    licenseStatus = await dbHelper.getSetting('license_status') ?? "Uninitialized";
    licenseKey = await dbHelper.getSetting('license_key');
    activatedDeviceId = await dbHelper.getSetting('activated_device_id');

    if (storedInstallDate == null || storedInstallDate.isEmpty) {
      // First proper run
      installationDate = DateTime.now();
      await dbHelper.updateSetting('installation_date', installationDate!.toIso8601String());
      licenseStatus = "Trial";
      await dbHelper.updateSetting('license_status', licenseStatus);
      print("First run: Initialized trial period. Installation date: $installationDate");
    } else {
      installationDate = DateTime.tryParse(storedInstallDate);
    }

    // Check and update trial status if currently in Trial
    if (licenseStatus == "Trial" && installationDate != null) {
      if (DateTime.now().difference(installationDate!).inDays > trialDurationDays) {
        licenseStatus = "TrialExpired";
        await dbHelper.updateSetting('license_status', licenseStatus);
        print("Trial period expired.");
      }
    }

    // Load other data
    _clients = await dbHelper.getAllClients();
    updateClients(_clients);

    String? balanceStr = await dbHelper.getSetting('current_balance');
    _balance = double.tryParse(balanceStr ?? '0.0') ?? 0.0;
    updateBalanceCallback(_balance);

    var monthly = await dbHelper.getMembershipByName('Monthly');
    if (monthly != null) _monthlyFee = monthly['price'];
    var weekly = await dbHelper.getMembershipByName('Weekly');
    if (weekly != null) _weeklyFee = weekly['price'];
    var visit = await dbHelper.getMembershipByName('Visit');
    if (visit != null) _visitFee = visit['price'];

    // Load dark_mode setting if needed
    final String? darkModeStr = await dbHelper.getSetting('dark_mode');
    darkMode = darkModeStr == 'true';
    updateDarkModeCallback(darkMode);

    gymName = await dbHelper.getSetting('gym_name') ?? 'My Gym';
    gymLogoPath = await dbHelper.getSetting('gym_logo_path');
    final String thresholdStr = await dbHelper.getSetting('inactive_days_threshold') ?? '30';
    inactiveDaysThreshold = int.tryParse(thresholdStr) ?? 30;

    applyFilter('Todos');

    // Automatic deletion on startup
    int deletedCount = await deleteInactiveClients();
    if (deletedCount > 0) {
      print("$deletedCount inactive clients were automatically deleted during startup.");
    }
  }

  Future<Map<String, dynamic>> getFinancialOverview({DateTimeRange? dateRange}) async {
    List<Map<String, dynamic>> allIncome = await dbHelper.getAllIncome();
    List<Map<String, dynamic>> allExpenses = await dbHelper.getAllExpenses();

    if (dateRange != null) {
      allIncome = allIncome.where((i) {
        final itemDate = DateTime.parse(i['date']);
        // Inclusive of start and end date
        return !itemDate.isBefore(dateRange.start.subtract(const Duration(microseconds: 1))) &&
               !itemDate.isAfter(dateRange.end.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)));
      }).toList();
      allExpenses = allExpenses.where((e) {
        final itemDate = DateTime.parse(e['date']);
        return !itemDate.isBefore(dateRange.start.subtract(const Duration(microseconds: 1))) &&
               !itemDate.isAfter(dateRange.end.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1)));
      }).toList();
    }

    double totalIncome = allIncome.fold(0.0, (sum, item) => sum + (item['amount'] as double? ?? 0.0));
    double totalExpenses = allExpenses.fold(0.0, (sum, item) => sum + (item['amount'] as double? ?? 0.0));
    double netProfit = totalIncome - totalExpenses;

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'allIncomeTransactions': allIncome,
      'allExpenseTransactions': allExpenses,
    };
  }

  Future<void> addManualIncome(Map<String, dynamic> incomeData) async {
    await dbHelper.insertIncome(incomeData);
  }

  Future<void> addManualExpense(Map<String, dynamic> expenseData) async {
    await dbHelper.insertExpense(expenseData);
  }

  Future<void> logVisitFeeAsIncome() async {
    var visitMembership = await dbHelper.getMembershipByName('Visit');
    double visitFeeAmount = visitMembership?['price'] as double? ?? 5.0;

    Map<String, dynamic> incomeData = {
      'description': 'Walk-in Visit Fee',
      'amount': visitFeeAmount,
      'date': DateTime.now().toIso8601String(),
      'type': 'Visit Fee',
    };
    await dbHelper.insertIncome(incomeData);

    _balance += visitFeeAmount;
    await dbHelper.updateSetting('current_balance', _balance.toString());
    updateBalanceCallback(_balance);
    print("Visit fee logged. New balance: $_balance");
  }

  Future<List<Map<String, dynamic>>> getAllMembershipTypesForManagement() async {
    return await dbHelper.getMembershipTypes();
  }

  Future<void> addMembershipType(Map<String, dynamic> data) async {
    await dbHelper.insertMembership({'name': data['name'], 'price': data['price'], 'duration_days': data['duration_days']});
    await loadGymData();
  }

  Future<void> updateMembershipType(Map<String, dynamic> oldData, Map<String, dynamic> newData) async {
    final Map<String, dynamic> dataToUpdate = {
      'id': oldData['id'],
      'name': newData['name'],
      'price': newData['price'],
      'duration_days': newData['duration_days'],
    };

    if (oldData['price'] != newData['price']) {
      await dbHelper.insertPriceChange({
        'membership_id': oldData['id'],
        'old_price': oldData['price'],
        'new_price': newData['price'],
        'change_date': DateTime.now().toIso8601String(),
      });
    }
    await dbHelper.updateMembership(dataToUpdate);
    await loadGymData();
  }

  Future<void> deleteMembershipType(int membershipId) async {
    await dbHelper.deleteMembership(membershipId);
    await loadGymData();
  }

  bool isTrialActive() {
    if (licenseStatus == "Trial" && installationDate != null) {
      return DateTime.now().difference(installationDate!).inDays <= trialDurationDays;
    }
    return false;
  }

  bool isLicensed() {
    return licenseStatus == "Licensed";
  }

  bool areFeaturesUnlocked() {
    return isLicensed() || isTrialActive();
  }

  String getLicenseDisplayStatus() {
    if (isLicensed()) {
      return "Licensed Version";
    }
    if (isTrialActive() && installationDate != null) {
      final daysRemaining = trialDurationDays - DateTime.now().difference(installationDate!).inDays;
      return "Trial: $daysRemaining days remaining";
    }
    if (licenseStatus == "TrialExpired") {
      return "Trial Expired. Please purchase a license.";
    }
    return "Unlicensed. Error determining status.";
  }

  Future<String> getDeviceIdentifier() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String identifier = "unknown_device";
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        identifier = "android_${androidInfo.id}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        identifier = "ios_${iosInfo.identifierForVendor ?? 'unavailable'}";
      } else if (Platform.isLinux) {
        LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        identifier = "linux_${linuxInfo.machineId ?? linuxInfo.id}";
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
        identifier = "macos_${macInfo.systemGUID ?? macInfo.model}";
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        identifier = "windows_${windowsInfo.computerName}_${windowsInfo.numberOfCores}_${windowsInfo.systemMemoryInMegabytes}";
      }
    } catch (e) {
      print("Error getting device identifier: $e");
      identifier = "error_getting_id";
    }
    return identifier;
  }

  Future<bool> activateLicense(String keyEntered) async {
    if (keyEntered == masterLicenseKey) {
      String currentDeviceIdentifier = await getDeviceIdentifier();

      licenseStatus = "Licensed";
      licenseKey = keyEntered;
      activatedDeviceId = currentDeviceIdentifier;

      await dbHelper.updateSetting('license_status', licenseStatus);
      await dbHelper.updateSetting('license_key', licenseKey!);
      await dbHelper.updateSetting('activated_device_id', activatedDeviceId!);

      print("License Activated. Device ID: $activatedDeviceId");
      return true;
    }
    return false;
  }

  Future<void> saveGymName(String name) async {
    this.gymName = name;
    await dbHelper.updateSetting('gym_name', name);
  }

  Future<void> saveGymLogoPath(String path) async {
    this.gymLogoPath = path;
    await dbHelper.updateSetting('gym_logo_path', path);
  }

  Future<void> saveInactiveDaysThreshold(int days) async {
    this.inactiveDaysThreshold = days;
    await dbHelper.updateSetting('inactive_days_threshold', days.toString());
  }

  Future<void> updateDarkMode(bool newMode) async {
    darkMode = newMode;
    await dbHelper.updateSetting('dark_mode', darkMode.toString());
    updateDarkModeCallback(darkMode);
  }

  Future<int> deleteInactiveClients() async {
    int deletedCount = 0;
    final DateTime visitThresholdDate = DateTime.now().subtract(Duration(days: this.inactiveDaysThreshold));
    final DateTime today = DateTime.now();

    List<Client> allClients = await dbHelper.getAllClients();
    List<Client> clientsToDelete = [];

    for (Client client in allClients) {
      bool isMembershipExpired = client.endDate.isBefore(today);
      bool hasNotVisitedRecently = client.lastVisitDate == null || client.lastVisitDate!.isBefore(visitThresholdDate);

      if (isMembershipExpired && hasNotVisitedRecently) {
        clientsToDelete.add(client);
      }
    }

    if (clientsToDelete.isNotEmpty) {
      print("Found ${clientsToDelete.length} inactive clients to delete.");
      for (Client clientToDelete in clientsToDelete) {
        await dbHelper.deleteClient(clientToDelete.id);
        deletedCount++;
      }
      _clients = await dbHelper.getAllClients();
      updateClients(List.from(_clients));
    }
    return deletedCount;
  }

  Future<List<Map<String, dynamic>>> getMembershipTypesForDialog() async {
    return await dbHelper.getMembershipTypes();
  }

  void addNewClientDialog({bool isVisit = false}) {
    if (isVisit) {
      print("addNewClientDialog called with isVisit=true. This flow might be deprecated. Use logVisitFeeAsIncome directly.");
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddClientDialog(
          mode: darkMode,
          membershipTypesFuture: getMembershipTypesForDialog(),
          onSave: (Client newClient) async {
            var membershipDetails = await dbHelper.getMembershipByName(newClient.membershipType);
            if (membershipDetails == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: Tipo de membresía no encontrado.')),
              );
              return;
            }

            int durationDays = membershipDetails['duration_days'];
            double price = membershipDetails['price'];

            newClient.startDate = DateTime.now();
            newClient.endDate = newClient.startDate.add(Duration(days: durationDays));
            newClient.isActive = true;
            newClient.currentMembershipPrice = price;

            List<Client> similarClients = await dbHelper.findClientsBySimilarity(
                newClient.name, newClient.phone, newClient.email
            );

            if (similarClients.isNotEmpty) {
              bool? proceed = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Potential Duplicate Client'),
                    content: Text(
                      'A client with a similar name and contact information already exists:\n\n' +
                      similarClients.map((c) => '- ${c.name} (${c.phone ?? c.email ?? 'No contact'})').join('\n') +
                      '\n\nAre you sure you want to add this new client?'
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'), 
                        onPressed: () => Navigator.of(dialogContext).pop(false)
                      ),
                      ElevatedButton(
                        child: const Text('Add Anyway'), 
                        onPressed: () => Navigator.of(dialogContext).pop(true)
                      ),
                    ],
                  );
                },
              );
              if (proceed != true) {
                return;
              }
            }

            await dbHelper.insertClient(newClient);

            Map<String, dynamic> incomeData = {
              'description': 'New Membership: ${newClient.name} (${newClient.membershipType})',
              'amount': newClient.currentMembershipPrice,
              'date': DateTime.now().toIso8601String(),
              'type': 'Membership',
              'related_client_id': newClient.id
            };
            await dbHelper.insertIncome(incomeData);

            _balance += price;
            await dbHelper.updateSetting('current_balance', _balance.toString());
            loadGymData();
          },
        );
      },
    );
  }

  void editClientDialog(Client client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditClientDialog(
          mode: darkMode,
          client: client,
          membershipTypesFuture: getMembershipTypesForDialog(),
          onSave: (Client updatedClient) async {
            if (updatedClient.membershipType != client.membershipType) {
              var membershipDetails = await dbHelper.getMembershipByName(updatedClient.membershipType);
              if (membershipDetails != null) {
                updatedClient.currentMembershipPrice = membershipDetails['price'];
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error: Nuevo tipo de membresía no encontrado.')),
                );
                return;
              }
            }
            await dbHelper.updateClient(updatedClient);
            loadGymData();
          },
        );
      },
    );
  }

void renewClientDialog(Client client, BuildContext mainContext) {
    showDialog(
      context: mainContext,
      builder: (BuildContext dialogContext) {
        return RenewClientDialog(
          mode: darkMode,
          client: client,
          membershipTypesFuture: getMembershipTypesForDialog(),
          onRenew: (Client clientToRenew, String newMembershipTypeName) async {
            final membershipDetails = await dbHelper.getMembershipByName(newMembershipTypeName);
            if (membershipDetails == null) {
              // Usa mainContext, no dialogContext
              ScaffoldMessenger.of(mainContext).showSnackBar(
                SnackBar(content: Text('Error: Membership type "$newMembershipTypeName" not found.')),
              );
              return;
            }

            final double price = membershipDetails['price'];
            final int durationDays = membershipDetails['duration_days'];

            clientToRenew.startDate = DateTime.now();
            clientToRenew.endDate = clientToRenew.startDate.add(Duration(days: durationDays));
            clientToRenew.membershipType = newMembershipTypeName;
            clientToRenew.currentMembershipPrice = price;
            clientToRenew.paymentStatus = 'Paid';
            clientToRenew.isActive = true;

            await dbHelper.updateClient(clientToRenew);

            Map<String, dynamic> incomeData = {
              'description': 'Membership Renewal: ${clientToRenew.name} ($newMembershipTypeName)',
              'amount': price,
              'date': DateTime.now().toIso8601String(),
              'type': 'Membership',
              'related_client_id': clientToRenew.id
            };
            await dbHelper.insertIncome(incomeData);

            _balance += price;
            await dbHelper.updateSetting('current_balance', _balance.toString());
            updateBalanceCallback(_balance);

            await loadGymData();

            // Usa mainContext, no dialogContext
            ScaffoldMessenger.of(mainContext).showSnackBar(
              SnackBar(content: Text('${clientToRenew.name} renewed successfully.')),
            );
          },
        );
      },
    );
  }

  Future<void> deleteClient(Client client) async {
    await dbHelper.deleteClient(client.id);
    _clients.removeWhere((c) => c.id == client.id);
    updateClients(List<Client>.from(_clients));
  }

  Future<void> registerClientVisit(Client client) async {
    DateTime originalLastVisitDate = client.lastVisitDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    bool clientWasInactive = !client.isActive;

    client.lastVisitDate = DateTime.now();
    if (clientWasInactive) {
      client.isActive = true;
    }

    try {
      int result = await dbHelper.updateClient(client);

      if (result > 0) {
        final index = _clients.indexWhere((c) => c.id == client.id);
        if (index != -1) {
          _clients[index] = client;
          updateClients(List.from(_clients));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${client.name} visit registered successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register visit for ${client.name}.')),
        );
        if (clientWasInactive) {
          client.isActive = false;
        }
        client.lastVisitDate = originalLastVisitDate;
        final index = _clients.indexWhere((c) => c.id == client.id);
        if (index != -1) {
          _clients[index] = client;
          updateClients(List.from(_clients));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering visit: $e')),
      );
      if (clientWasInactive) {
        client.isActive = false;
      }
      client.lastVisitDate = originalLastVisitDate;
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
        updateClients(List.from(_clients));
      }
    }
  }

  Future<void> exportToJson() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportar a JSON no implementado para SQLite todavía.')),
    );
  }

  Future<void> importFromJson() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Importar desde JSON no implementado para SQLite todavía.')),
    );
  }

  Future<String> testBiometricAuthentication() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (!canAuthenticate) {
      return "Biometrics not available on this device.";
    }

    List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
    String biometricsString = availableBiometrics.isEmpty ? "None" : availableBiometrics.map((b) => b.toString()).join(", ");

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate for gym check-in',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        return "Biometric authentication successful! Available types: $biometricsString";
      } else {
        return "Biometric authentication failed. Available types: $biometricsString";
      }
    } catch (e) {
      return "Error during biometric authentication: $e. Available types: $biometricsString";
    }
  }

  // --- Product Database Operations ---

  Future<List<Product>> loadProductsFromDB() async {
    return await dbHelper.getAllProducts();
  }

  Future<void> saveNewProductToDB(Product product) async {
    await dbHelper.insertProduct(product);
    // Podríamos querer actualizar alguna lista en memoria aquí o depender de que PrincipalScreen lo haga.
    // Por ahora, solo guardamos. La carga se hará en initState de PrincipalScreen.
  }

  Future<void> updateProductInDB(Product product) async {
    await dbHelper.updateProduct(product);
  }

  Future<void> deleteProductFromDB(String id) async {
    await dbHelper.deleteProduct(id);
  }
}