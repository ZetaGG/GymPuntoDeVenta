import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gym_punto_venta/models/clients.dart';
import 'package:gym_punto_venta/dialogs/add_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/edit_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/renew_client_dialog.dart';
import 'package:gym_punto_venta/dialogs/edit_prices_dialog.dart';

class GymManagementFunctions {
  final BuildContext context;
  final bool darkMode;
  final List<Client> clients;
  final Function(List<Client>) updateClients;
  final Function(double) updateBalance;
  final Function(String) applyFilter;
  final double monthlyFee;
  final double weeklyFee;
  final double visitFee;
  double balance; // Añadir balance como una variable de instancia

  GymManagementFunctions({
    required this.context,
    required this.darkMode,
    required this.clients,
    required this.updateClients,
    required this.updateBalance,
    required this.applyFilter,
    required this.monthlyFee,
    required this.weeklyFee,
    required this.visitFee,
    required this.balance, // Asegúrate de pasar el balance actual
  });

  Future<void> loadGymData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gymDataJson = prefs.getString('gymData');
    if (gymDataJson != null) {
      final Map<String, dynamic> decodedJson = json.decode(gymDataJson);
      updateClients((decodedJson['clients'] as List)
          .map((item) => Client.fromJson(item))
          .toList());
      balance = decodedJson['balance'] ?? 0.0;
      updateBalance(balance);
      applyFilter('Todos');
    }
  }

  Future<void> saveGymData(List<Client> clients, double balance) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedJson = json.encode({
      'clients': clients.map((e) => e.toJson()).toList(),
      'balance': balance,
      'monthlyFee': monthlyFee,
      'weeklyFee': weeklyFee,
      'visitFee': visitFee,
    });
    await prefs.setString('gymData', encodedJson);
  }

  void addNewClient({bool isVisit = false,bool darkMode = false}) {
    if (isVisit) {
      balance += visitFee; // Actualiza el balance sumando la tarifa de visita
      updateBalance(balance); // Actualiza el balance en el estado
      saveGymData(clients, balance); // Guarda los datos con el nuevo balance
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddClientDialog(
          mode: darkMode,
          onSave: (Client newClient) {
            clients.add(newClient);
            balance += (newClient.endDate.difference(newClient.startDate).inDays > 7 ? monthlyFee : weeklyFee);
            updateBalance(balance); // Actualiza el balance sumando la tarifa correspondiente
            updateClients(clients); // Actualiza la lista de clientes
            applyFilter('Todos');
            saveGymData(clients, balance); // Guarda los datos con el nuevo balance
          },
        );
      },
    );
  }

  void editClient(Client client, ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditClientDialog(
          mode: darkMode,
          client: client,
          onSave: (Client updatedClient) {
            final index = clients.indexWhere((c) => c.id == updatedClient.id);
            if (index != -1) {
              clients[index] = updatedClient;
              applyFilter('Todos');
            }
            saveGymData(clients, visitFee);
          },
        );
      },
    );
  }

  void renewClient(Client client , bool mode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RenewClientDialog(
          mode: mode,
          client: client,
          onRenew: (Client updatedClient, String membershipType) {
            final index = clients.indexWhere((c) => c.id == updatedClient.id);
            if (index != -1) {
              clients[index] = updatedClient;
              updateBalance(membershipType == 'Mensual' ? monthlyFee : weeklyFee);
              applyFilter('Todos');
            }
            saveGymData(clients, visitFee);
          },
        );
      },
    );
  }

  void editPrices() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditPricesDialog(
          mode: darkMode,
          monthlyFee: monthlyFee,
          weeklyFee: weeklyFee,
          visitFee: visitFee,
          onSave: (double newMonthlyFee, double newWeeklyFee, double newVisitFee) {
            saveGymData(clients, visitFee);
          },
        );
      },
    );
  }

  Future<void> exportToJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> allPrefs = prefs.getKeys().fold({}, (map, key) {
        map[key] = prefs.get(key);
        return map;
      });

      final jsonString = jsonEncode(allPrefs);

      String? selectedDirectory = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo de configuración',
        fileName: 'gym_config.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (selectedDirectory != null) {
        final file = File(selectedDirectory);
        await file.writeAsString(jsonString);

        loadGymData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo guardado en: ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  Future<void> importFromJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Seleccionar archivo de configuración',
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();

        final Map<String, dynamic> data = jsonDecode(jsonString);

        final prefs = await SharedPreferences.getInstance();

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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configuración importada correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al importar: $e')),
      );
    }
  }
}