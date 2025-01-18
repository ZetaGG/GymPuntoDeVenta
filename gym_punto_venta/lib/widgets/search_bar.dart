import 'package:flutter/material.dart';
import 'filter_button.dart';
import '../models/clients.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final List<Client> clients;
  final Function(String) onSearch;
  final bool darkMode;
  final String currentFilter;
  final Function(String) applyFilter;

  const SearchBar({
    Key? key,
    required this.searchController,
    required this.clients,
    required this.onSearch,
    required this.darkMode,
    required this.currentFilter,
    required this.applyFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintStyle: TextStyle(color: Colors.grey),
              hintText: 'Buscar por nombre, email o teléfono...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: onSearch,
          ),
        ),
        const SizedBox(width: 16),
        FilterButton(
          mode: darkMode,
          text: 'Todos',
          isActive: currentFilter == 'Todos',
          onPressed: () => applyFilter('Todos'),
        ),
        const SizedBox(width: 8),
        FilterButton(
          mode: darkMode,
          text: 'Activos',
          isActive: currentFilter == 'Activos',
          onPressed: () => applyFilter('Activos'),
        ),
        const SizedBox(width: 8),
        FilterButton(
          mode: darkMode,
          text: 'Inactivos',
          isActive: currentFilter == 'Inactivos',
          onPressed: () => applyFilter('Inactivos'),
        ),
        const SizedBox(width: 8),
        FilterButton(
          mode: darkMode,
          text: 'Próximos a vencer',
          isActive: currentFilter == 'Próximos a vencer',
          onPressed: () => applyFilter('Próximos a vencer'),
        ),
      ],
    );
  }
}