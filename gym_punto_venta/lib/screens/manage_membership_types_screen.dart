import 'package:flutter/material.dart';
import '../functions/funtions.dart';
import '../dialogs/add_edit_membership_dialog.dart';

class ManageMembershipTypesScreen extends StatefulWidget {
  final GymManagementFunctions functions;
  const ManageMembershipTypesScreen({Key? key, required this.functions}) : super(key: key);

  @override
  _ManageMembershipTypesScreenState createState() => _ManageMembershipTypesScreenState();
}

class _ManageMembershipTypesScreenState extends State<ManageMembershipTypesScreen> {
  List<Map<String, dynamic>> _membershipTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembershipTypes();
  }

  Future<void> _loadMembershipTypes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    // Ensure this method fetches id, name, price, duration_days
    _membershipTypes = await widget.functions.getAllMembershipTypesForManagement();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? membership}) {
    showDialog(
      context: context, // Use the BuildContext from the builder if needed for theme, or the class context.
      builder: (BuildContext dialogContext) {
        return AddEditMembershipDialog(
          mode: widget.functions.darkMode, // Pass dark mode state
          membership: membership,
          onSave: (data) async {
            if (membership == null) {
              await widget.functions.addMembershipType(data);
            } else {
              await widget.functions.updateMembershipType(membership, data);
            }
            _loadMembershipTypes();
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext scaffoldContext, Map<String, dynamic> membership) {
    showDialog(
        context: scaffoldContext, // This context should be from the builder of ListTile or similar
        builder: (BuildContext ctx) {
            return AlertDialog(
                backgroundColor: widget.functions.darkMode ? Colors.grey[850] : Colors.white,
                title: Text('Confirm Delete', style: TextStyle(color: widget.functions.darkMode ? Colors.white : Colors.black)),
                content: Text('Are you sure you want to delete "${membership['name']}"?', style: TextStyle(color: widget.functions.darkMode ? Colors.white70 : Colors.black87)),
                actions: [
                    TextButton(
                        child: Text('Cancel', style: TextStyle(color: widget.functions.darkMode ? Colors.blueGrey[200] : Colors.blueGrey)),
                        onPressed: () => Navigator.of(ctx).pop()
                    ),
                    TextButton(
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                            await widget.functions.deleteMembershipType(membership['id']);
                            Navigator.of(ctx).pop(); // Close confirmation dialog
                            _loadMembershipTypes(); // Refresh the list
                            if (mounted) {
                                ScaffoldMessenger.of(scaffoldContext).showSnackBar( // Use context that has a Scaffold
                                    SnackBar(content: Text('"${membership['name']}" deleted.'))
                                );
                            }
                        },
                    ),
                ],
            );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.functions.darkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Manage Membership Types'),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMembershipTypes,
              child: _membershipTypes.isEmpty
                  ? Center(
                      child: Padding( // Added padding for the empty state message
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "No membership types defined yet.\nClick '+' to add one.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _membershipTypes.length,
                      itemBuilder: (ctx, index) {
                        final type = _membershipTypes[index];
                        return Card(
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), // Adjusted margin
                          elevation: 2, // Added slight elevation
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Adjusted padding
                            title: Text(
                              type['name'] ?? 'Unnamed Type',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w600)
                            ),
                            subtitle: Text(
                              'Price: ${type['price']?.toStringAsFixed(2) ?? 'N/A'} - Duration: ${type['duration_days'] ?? 'N/A'} days',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDarkMode ? Colors.white70 : Colors.black87)
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: Icon(Icons.edit, color: isDarkMode ? Colors.orangeAccent : Colors.orange[700]), onPressed: () => _showAddEditDialog(membership: type)),
                                IconButton(icon: Icon(Icons.delete, color: isDarkMode ? Colors.redAccent[100] : Colors.red[700]), onPressed: () => _confirmDelete(context, type)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDarkMode ? Colors.teal : Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _showAddEditDialog(),
      ),
    );
  }
}
