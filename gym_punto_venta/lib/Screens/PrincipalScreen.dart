import 'package:flutter/material.dart';
import 'package:gym_punto_venta/models/clients.dart';
import 'package:gym_punto_venta/widgets/statscard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Client> clients = [];
  String currentFilter = 'todos';
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final activeClients = clients.where((c) => c.isActive).length;
    final inactiveClients = clients.where((c) => !c.isActive).length;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement new client functionality
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Cliente'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Clientes',
                    value: clients.length.toString(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Clientes Activos',
                    value: activeClients.toString(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatsCard(
                    title: 'Clientes Inactivos',
                    value: inactiveClients.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search and Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, email o teléfono...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('Todos'),
                  selected: currentFilter == 'todos',
                  onSelected: (selected) {
                    setState(() => currentFilter = 'todos');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Activos'),
                  selected: currentFilter == 'activos',
                  onSelected: (selected) {
                    setState(() => currentFilter = 'activos');
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Inactivos'),
                  selected: currentFilter == 'inactivos',
                  onSelected: (selected) {
                    setState(() => currentFilter = 'inactivos');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Clients Table
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
                  rows: clients.map((client) {
                    return DataRow(
                      cells: [
                        DataCell(Text(client.name)),
                        DataCell(Text(client.email)),
                        DataCell(Text(client.phone)),
                        DataCell(Text(client.startDate.toString().split(' ')[0])),
                        DataCell(Text(client.endDate.toString().split(' ')[0])),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: client.isActive
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              client.isActive ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color:
                                    client.isActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement renew functionality
                                },
                                child: const Text('Renovar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement delete functionality
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
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
}