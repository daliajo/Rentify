import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _roleFilter = 'All';
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Unable to load users at the moment.'));
                }

                final docs = snapshot.data?.docs ?? [];
                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final fullName =
                      '${(data['firstName'] ?? '')} ${(data['lastName'] ?? '')}'
                          .trim()
                          .toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final role =
                      (data['role'] ?? 'customer').toString().toLowerCase();
                  final status = ((data['accountStatus'] ?? 'active') as String)
                      .toLowerCase();

                  final query = _searchCtrl.text.toLowerCase();
                  final matchesSearch = query.isEmpty ||
                      fullName.contains(query) ||
                      email.contains(query);

                  final roleMatches = _roleFilter == 'All'
                      ? true
                      : role == _roleFilter.toLowerCase();

                  final statusMatches = _statusFilter == 'All'
                      ? true
                      : status == _statusFilter.toLowerCase();

                  return matchesSearch && roleMatches && statusMatches;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                      child: Text('No users match your filters.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    return _UserTile(
                      userId: doc.id,
                      firstName: data['firstName'],
                      lastName: data['lastName'],
                      email: data['email'],
                      role: data['role'],
                      status: data['accountStatus'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  value: _roleFilter,
                  label: 'Role',
                  items: const ['All', 'admin', 'customer', 'renter'],
                  onChanged: (value) => setState(() => _roleFilter = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterDropdown(
                  value: _statusFilter,
                  label: 'Status',
                  items: const ['All', 'active', 'blocked'],
                  onChanged: (value) => setState(() => _statusFilter = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(_capitalize(item)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

class _UserTile extends StatelessWidget {
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? role;
  final String? status;
 

  const _UserTile({
    required this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.role,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final rawName =
        '${(firstName ?? '').trim()} ${(lastName ?? '').trim()}'.trim();
    final headline = rawName.isEmpty ? 'No name' : rawName;
    final theme = Theme.of(context);
    final statusValue = (status ?? 'active').toLowerCase();
    final roleValue = (role ?? 'customer').toLowerCase();
    final initial =
        headline == 'No name' ? '?' : headline.substring(0, 1).toUpperCase();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepOrange.withOpacity(.1),
              child: Text(
                initial,
                style: const TextStyle(color: Colors.deepOrange),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email ?? 'No email',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.black54),
                  ),
                  Text(
                    'UID: $userId',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.black45),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(roleValue.toUpperCase()),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<_UserAction>(
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (context) => [
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _UserAction.makeAdmin,
                  child: const Text('Make admin'),
                ),
                PopupMenuItem(
                  value: _UserAction.makeCustomer,
                  child: const Text('Make customer'),
                ),
                PopupMenuItem(
                  value: _UserAction.makeRenter,
                  child: const Text('Make renter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, _UserAction action) async {
    try {
      switch (action) {
        case _UserAction.makeAdmin:
          await _applyRoleChange(context, 'admin');
          break;
        case _UserAction.makeCustomer:
          await _applyRoleChange(context, 'customer');
          break;
        case _UserAction.makeRenter:
          await _applyRoleChange(context, 'renter');
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    }
  }

  Future<void> _applyRoleChange(BuildContext context, String newRole) async {
    final currentAdminId = FirebaseAuth.instance.currentUser?.uid;
    if (currentAdminId == userId && newRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("You can't remove your own admin rights."),
      ));
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'role': newRole});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Role changed to $newRole')),
    );
  }

  Future<bool> _confirm(
      BuildContext context, String title, String description) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

enum _UserAction { makeAdmin, makeCustomer, makeRenter }
