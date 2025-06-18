// import 'dart:io'; // Keep for FilePicker if export/import is re-enabled
// import 'package:file_picker/file_picker.dart'; // Keep for FilePicker
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gym_punto_venta/models/clients.dart';
import 'package:gym_punto_venta/dialogs/add_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/edit_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/renew_client_dialog.dart';
// import 'package:gym_punto_venta/dialogs/edit_prices_dialog.dart'; // Removed import
import 'package:gym_punto_venta/database/database_helper.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:uuid/uuid.dart'; // Added import for Uuid

class GymManagementFunctions {
  final BuildContext context;
  final Uuid _uuid = Uuid(); // Added Uuid instance
  bool darkMode; // Made non-final as it might be loaded from DB
  List<Client> _clients; // Made private and mutable
  final Function(List<Client>) updateClients;
  final Function(double) updateBalanceCallback; // Renamed for clarity
  final Function(String) applyFilter;
  double _monthlyFee = 0.0; // Made private, mutable, with default
  double _weeklyFee = 0.0;  // Made private, mutable, with default
  double _visitFee = 0.0;   // Made private, mutable, with default
  double _balance = 0.0;    // Made private, mutable, with default

  final DatabaseHelper dbHelper = DatabaseHelper(); // Initialize DatabaseHelper

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
  String? activatedDeviceId; // Added
  static const int trialDurationDays = 40;
  static const String masterLicenseKey = "SUPER_GYM_LICENSE_2024"; // Added


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
        // print('Migration already done. Skipping.');
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
            // Default membershipType to "Monthly" for migration
            // dbHelper.insertClient will look up its ID and price.
            Client migratedClient = Client(
              id: oldClientMap['id']?.toString() ?? _uuid.v4(), // Use Uuid for new ID
              name: oldClientMap['name'] ?? 'Unknown Name',
              email: oldClientMap['email']?.toString(),
              phone: oldClientMap['phone']?.toString(),
              startDate: oldClientMap['startDate'] != null ? DateTime.parse(oldClientMap['startDate']) : DateTime.now(),
              endDate: oldClientMap['endDate'] != null ? DateTime.parse(oldClientMap['endDate']) : DateTime.now().add(Duration(days:30)),
              isActive: oldClientMap['isActive'] ?? true,
              membershipType: oldClientMap['membershipType'] ?? "Monthly", // Old data might have this, or default
              paymentStatus: "Paid", // Default for old migrated data
              photo: null, // No photo in old data
              lastVisitDate: null, // No last visit date in old data
              // currentMembershipPrice and membershipTypeId will be set by insertClient logic
            );
            await dbHelper.insertClient(migratedClient);
          }
        }
      }

      // Migrate Balance
      print('Migrating balance: $oldBalance');
      await dbHelper.updateSetting('current_balance', oldBalance.toString());

      // Migrate Fees if they existed separately and you want to ensure default memberships exist
      // This part assumes your Memberships table might be empty or you want to ensure these exist.
      // The `insertMembership` in DatabaseHelper should ideally handle conflicts if they already exist (e.g. UNIQUE name constraint).
      // For simplicity, we assume default memberships ('Monthly', 'Weekly', 'Visit') are created by _onCreate if not present.
      // If old fees were stored, e.g., prefs.getDouble('monthlyFee'), you could use them here.
      // For now, relying on _onCreate to populate default memberships.

      // Finalize Migration
      await prefs.remove('gymData'); // Remove old data key
      // Also remove individual fee keys if they existed
      await prefs.remove('monthlyFee');
      await prefs.remove('weeklyFee');
      await prefs.remove('visitFee');

      await prefs.setBool('migration_done_v1_to_sqlite', true);
      print('Data migration from SharedPreferences to SQLite completed successfully.');

    } catch (e) {
      print('Error during data migration: $e');
      // Decide if you want to re-throw, or mark migration as done to avoid re-attempts on error,
      // or leave it to retry next time. For now, we'll let it retry.
    }
  }

  Future<void> loadGymData() async {
    await migrateOldDataToSqliteIfNeeded();

    // Initialize/Load license settings
    String? storedInstallDate = await dbHelper.getSetting('installation_date');
    licenseStatus = await dbHelper.getSetting('license_status') ?? "Uninitialized";
    licenseKey = await dbHelper.getSetting('license_key');
    activatedDeviceId = await dbHelper.getSetting('activated_device_id'); // Load activated_device_id

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
    darkMode = darkModeStr == 'true'; // Update internal state
    updateDarkModeCallback(darkMode); // Notify PrincipalScreen

    gymName = await dbHelper.getSetting('gym_name') ?? 'My Gym';
    gymLogoPath = await dbHelper.getSetting('gym_logo_path');
    final String thresholdStr = await dbHelper.getSetting('inactive_days_threshold') ?? '30';
    inactiveDaysThreshold = int.tryParse(thresholdStr) ?? 30;


    applyFilter('Todos');

    // Automatic deletion on startup
    int deletedCount = await deleteInactiveClients();
    if (deletedCount > 0) {
      print("$deletedCount inactive clients were automatically deleted during startup.");
      // Optionally show a non-blocking notification or log.
      // A SnackBar here might be too intrusive for startup or require _scaffoldKey.
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
    // Full implementation in next subtask will save to DB and update balance
    print("Placeholder: Save manual income: $incomeData");
    // For now, let's insert it so we can test retrieval later
    await dbHelper.insertIncome(incomeData);
    // TODO: Update overall balance if this type of income affects it.
    // For now, let's add the income to the current balance.
    double amount = incomeData['amount'] as double? ?? 0.0;
    _balance += amount;
    await dbHelper.updateSetting('current_balance', _balance.toString());
    updateBalanceCallback(_balance);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manual income of ${amount.toStringAsFixed(2)} added successfully.')),
    );
  }

  Future<void> addManualExpense(Map<String, dynamic> expenseData) async {
    // Full implementation in next subtask will save to DB and update balance
    print("Placeholder: Save manual expense: $expenseData");
    // For now, let's insert it so we can test retrieval later
    await dbHelper.insertExpense(expenseData);
    // TODO: Update overall balance.
    double amount = expenseData['amount'] as double? ?? 0.0;
    _balance -= amount;
    await dbHelper.updateSetting('current_balance', _balance.toString());
    updateBalanceCallback(_balance);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manual expense of ${amount.toStringAsFixed(2)} added successfully.')),
    );
  }

  Future<void> logVisitFeeAsIncome() async {
    var visitMembership = await dbHelper.getMembershipByName('Visit');
    double visitFeeAmount = visitMembership?['price'] as double? ?? 5.0; // Default if 'Visit' price not found

    Map<String, dynamic> incomeData = {
      'description': 'Walk-in Visit Fee',
      'amount': visitFeeAmount,
      'date': DateTime.now().toIso8601String(),
      'type': 'Visit Fee',
      // 'related_client_id': null // No specific client for a generic walk-in
    };
    await dbHelper.insertIncome(incomeData);

    // Also update the main balance
    // _balance is already up-to-date via loadGymData or previous operations.
    _balance += visitFeeAmount;
    await dbHelper.updateSetting('current_balance', _balance.toString());
    updateBalanceCallback(_balance); // Notify UI
    print("Visit fee logged. New balance: $_balance");
  }

  // Licensing methods
  // ... (isTrialActive, isLicensed, areFeaturesUnlocked, getLicenseDisplayStatus remain the same)

  Future<List<Map<String, dynamic>>> getAllMembershipTypesForManagement() async {
    return await dbHelper.getMembershipTypes();
  }

  Future<void> addMembershipType(Map<String, dynamic> data) async {
    await dbHelper.insertMembership({'name': data['name'], 'price': data['price'], 'duration_days': data['duration_days']});
    await loadGymData(); // Reload fees and potentially other data dependent on memberships
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
    await loadGymData(); // Reload fees and potentially other data
  }

  Future<void> deleteMembershipType(int membershipId) async {
    await dbHelper.deleteMembership(membershipId);
    await loadGymData(); // Reload fees and potentially other data
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

    // Fetch all clients directly from DB to ensure we have the latest data for this operation
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
      // After deletion, refresh the main client list in GymManagementFunctions and notify PrincipalScreen
      // This is important if deleteInactiveClients is called manually too.
      // Calling loadGymData() here might be too much if called from within loadGymData itself (recursion risk).
      // Instead, directly update _clients and call updateClients.
      _clients = await dbHelper.getAllClients(); // Re-fetch the list
      updateClients(List.from(_clients)); // Notify UI
    }
    return deletedCount;
  }


  Future<List<Map<String, dynamic>>> getMembershipTypesForDialog() async {
    return await dbHelper.getMembershipTypes();
  }

  void addNewClientDialog() { // isVisit parameter removed
    // The isVisit logic was previously removed/commented out as it's handled by PrincipalScreen's direct call
    // to logVisitFeeAsIncome. This method is now solely for adding full new clients.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddClientDialog(
          mode: darkMode,
          membershipTypesFuture: getMembershipTypesForDialog(),
          onSave: (Client clientDataFromDialog) async { // Renamed for clarity
            var membershipDetails = await dbHelper.getMembershipByName(clientDataFromDialog.membershipType);
            if (membershipDetails == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Tipo de membresía no encontrado.')),
              );
              return;
            }

            int durationDays = membershipDetails['duration_days'];
            double price = membershipDetails['price'];

            // Populate remaining fields for the newClient object before saving
            newClient.startDate = DateTime.now();
            newClient.endDate = newClient.startDate.add(Duration(days: durationDays));
            newClient.isActive = true;
            // newClient.paymentStatus is already set by dialog
            newClient.currentMembershipPrice = price;
            // newClient.id should be generated if not provided by dialog, but UUID is typically client-side
            // newClient.photo is already set by dialog (placeholder for now)

            // Create the definitive Client object HERE with a new UUID
            final Client newClient = Client(
              id: _uuid.v4(), // Generate new UUID here
              name: clientDataFromDialog.name,
              email: clientDataFromDialog.email,
              phone: clientDataFromDialog.phone,
              membershipType: clientDataFromDialog.membershipType,
              paymentStatus: clientDataFromDialog.paymentStatus,
              photo: clientDataFromDialog.photo,
              startDate: DateTime.now(),
              endDate: DateTime.now().add(Duration(days: durationDays)),
              isActive: true,
              currentMembershipPrice: price,
              // membershipTypeId will be set by dbHelper.insertClient
            );

            // Show potential duplicate dialog (using newClient with generated ID)
            List<Client> similarClients = await dbHelper.findClientsBySimilarity(
                newClient.name, newClient.phone, newClient.email // Pass newClient's data
            );

            if (similarClients.isNotEmpty) {
              bool? proceed = await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Potential Duplicate Client'),
                    content: Text(
                      'A client with a similar name and contact information already exists:

' +
                      similarClients.map((c) => '- ${c.name} (${c.phone ?? c.email ?? 'No contact'})').join('
') +
                      '

Are you sure you want to add this new client?'
                    ),
                    actions: <Widget>[
                      TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop(false)),
                      ElevatedButton(child: const Text('Add Anyway'), onPressed: () => Navigator.of(dialogContext).pop(true)),
                    ],
                  );
                },
              );
              if (proceed != true) {
                return; // User cancelled
              }
            }

            await dbHelper.insertClient(newClient);

            // Record income for new membership
            Map<String, dynamic> incomeData = {
              'description': 'New Membership: ${newClient.name} (${newClient.membershipType})',
              'amount': newClient.currentMembershipPrice, // This is the price of the membership
              'date': DateTime.now().toIso8601String(),
              'type': 'Membership',
              'related_client_id': newClient.id
            };
            await dbHelper.insertIncome(incomeData);

            _balance += price; // Add price to balance only if paymentStatus is 'Paid'
            await dbHelper.updateSetting('current_balance', _balance.toString());

            // Reload or update local list
            // _clients.add(newClient); // This might lack joined data like membership_name
            // updateClients(_clients);
            loadGymData(); // Reload all data to ensure consistency
            // applyFilter('Todos'); // loadGymData calls this
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
          membershipTypesFuture: getMembershipTypesForDialog(), // Pass future here
          onSave: (Client updatedClient) async {
            // Ensure currentMembershipPrice is updated if membershipType changes
            if (updatedClient.membershipType != client.membershipType) {
              var membershipDetails = await dbHelper.getMembershipByName(updatedClient.membershipType);
              if (membershipDetails != null) {
                updatedClient.currentMembershipPrice = membershipDetails['price'];
                // Potentially update endDate if duration changes, though Edit usually doesn't do this.
                // For now, we assume EditClientDialog primarily changes descriptive fields,
                // and RenewClientDialog handles membership period changes.
                // If EditClientDialog *can* change membership type resulting in new duration/price,
                // then startDate, endDate, and balance logic would be needed here too.
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: Nuevo tipo de membresía no encontrado.')),
                );
                return; // Or handle error more gracefully
              }
            }
            await dbHelper.updateClient(updatedClient);
            loadGymData(); // Reload to reflect changes
          },
        );
      },
    );
  }

  void renewClientDialog(Client client) {
     showDialog(
      context: context,
      builder: (BuildContext context) {
        return RenewClientDialog(
          mode: darkMode,
          client: client,
          membershipTypesFuture: getMembershipTypesForDialog(), // Pass future here
          onRenew: (Client clientToRenew, String newMembershipTypeName) async {
            final membershipDetails = await dbHelper.getMembershipByName(newMembershipTypeName);
            if (membershipDetails == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: Membership type "$newMembershipTypeName" not found.')),
              );
              return;
            }

            final double price = membershipDetails['price'];
            final int durationDays = membershipDetails['duration_days'];

            clientToRenew.startDate = DateTime.now();
            clientToRenew.endDate = clientToRenew.startDate.add(Duration(days: durationDays));
            clientToRenew.membershipType = newMembershipTypeName; // Store name
            clientToRenew.currentMembershipPrice = price;
            clientToRenew.paymentStatus = 'Paid';
            clientToRenew.isActive = true;
            // clientToRenew.lastVisitDate = DateTime.now(); // Optionally update last visit on renewal

            await dbHelper.updateClient(clientToRenew);

            // Record income for renewal
            Map<String, dynamic> incomeData = {
              'description': 'Membership Renewal: ${clientToRenew.name} ($newMembershipTypeName)',
              'amount': price,
              'date': DateTime.now().toIso8601String(),
              'type': 'Membership',
              'related_client_id': clientToRenew.id
            };
            await dbHelper.insertIncome(incomeData);

            // Update balance
            _balance += price;
            await dbHelper.updateSetting('current_balance', _balance.toString());
            updateBalanceCallback(_balance);


            // Reload all clients and update UI
            await loadGymData();
            ScaffoldMessenger.of(context).showSnackBar(
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
    updateClients(List<Client>.from(_clients)); // Update UI with a new list instance
    // Note: Balance is not typically affected by deleting a client, unless refunds are processed.
    // If a refund logic is needed, it should be added here.
  }

  Future<void> registerClientVisit(Client client) async {
    DateTime originalLastVisitDate = client.lastVisitDate ?? DateTime.fromMillisecondsSinceEpoch(0) ; // Store original in case of rollback
    bool clientWasInactive = !client.isActive;

    client.lastVisitDate = DateTime.now();
    if (clientWasInactive) {
      client.isActive = true; // Activate client if they were inactive
    }

    try {
      int result = await dbHelper.updateClient(client);

      if (result > 0) {
        // Update the client in the local list to reflect changes immediately
        final index = _clients.indexWhere((c) => c.id == client.id);
        if (index != -1) {
          _clients[index] = client;
          updateClients(List.from(_clients)); // Notify PrincipalScreen to rebuild ClientTable
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${client.name} visit registered successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register visit for ${client.name}.')),
        );
        // Revert local changes if DB update failed
        if (clientWasInactive) {
          client.isActive = false;
        }
        client.lastVisitDate = originalLastVisitDate;
         // Optionally, re-update local list if you want to revert UI immediately before a full reload
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
        // Revert local changes on error
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

  // void editPricesDialog() { // This method is now replaced by ManageMembershipTypesScreen functionality
  // }

  Future<void> exportToJson() async {
    // TODO: Implement export logic using SQLite data.
    // This will involve querying tables and serializing to JSON.
    // Consider using dbHelper.getAllClients(), dbHelper.getMembershipTypes(), dbHelper.getSetting() for all settings.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exportar a JSON no implementado para SQLite todavía.')),
    );
    // try {
    //   // Example: Fetch all data
    //   final allClients = await dbHelper.getAllClients();
    //   final allMemberships = await dbHelper.getMembershipTypes();
    //   final settings = {
    //     'gym_name': await dbHelper.getSetting('gym_name'),
    //     'dark_mode': await dbHelper.getSetting('dark_mode'),
    //     'inactive_days_threshold': await dbHelper.getSetting('inactive_days_threshold'),
    //     'current_balance': await dbHelper.getSetting('current_balance'),
    //   };

    //   final Map<String, dynamic> dataToExport = {
    //     'clients': allClients.map((c) => c.toJson()).toList(),
    //     'memberships': allMemberships,
    //     'appSettings': settings,
    //   };

    //   final jsonString = jsonEncode(dataToExport);

    //   String? selectedDirectory = await FilePicker.platform.saveFile(
    //     dialogTitle: 'Guardar archivo de datos del gimnasio',
    //     fileName: 'gym_data_export.json',
    //     type: FileType.custom,
    //     allowedExtensions: ['json'],
    //   );

    //   if (selectedDirectory != null) {
    //     final file = File(selectedDirectory);
    //     await file.writeAsString(jsonString);
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Datos guardados en: ${file.path}')),
    //     );
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error al exportar: $e')),
    //   );
    // }
  }

  Future<void> importFromJson() async {
    // TODO: Implement import logic for SQLite data.
    // This will involve parsing JSON and inserting/updating data into SQLite tables.
    // Careful consideration for conflicts, data validation, and table clearing might be needed.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Importar desde JSON no implementado para SQLite todavía.')),
    );
    // try {
    //   FilePickerResult? result = await FilePicker.platform.pickFiles(
    //     type: FileType.custom,
    //     allowedExtensions: ['json'],
    //     dialogTitle: 'Seleccionar archivo de datos del gimnasio',
    //   );

    //   if (result != null) {
    //     final file = File(result.files.single.path!);
    //     final jsonString = await file.readAsString();
    //     final Map<String, dynamic> data = jsonDecode(jsonString);

    //     // Example: Clear existing data (optional, depends on desired import behavior)
    //     // await dbHelper.clearAllData(); // You'd need to implement this in DatabaseHelper

    //     // Import AppSettings
    //     if (data['appSettings'] is Map) {
    //       for (var entry in (data['appSettings'] as Map).entries) {
    //         await dbHelper.updateSetting(entry.key, entry.value.toString());
    //       }
    //     }

    //     // Import Memberships
    //     if (data['memberships'] is List) {
    //       for (var item in (data['memberships'] as List)) {
    //         // Assuming item is Map<String, dynamic> compatible with dbHelper.insertMembership
    //         // Might need to clear existing memberships first or handle conflicts
    //         await dbHelper.insertMembership(item);
    //       }
    //     }

    //     // Import Clients
    //     if (data['clients'] is List) {
    //       for (var item in (data['clients'] as List)) {
    //         // Client.fromJson might need adjustment if JSON structure differs from DB map
    //         Client client = Client.fromJson(item);
    //         await dbHelper.insertClient(client);
    //       }
    //     }

    //     await loadGymData(); // Reload data from DB

    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Datos importados correctamente')),
    //     );
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Error al importar: $e')),
    //   );
    // }
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
          stickyAuth: true, // Keep auth dialog open on app switch
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
}