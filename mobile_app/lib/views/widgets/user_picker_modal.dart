import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class UserPickerModal extends StatefulWidget {
  final List<Map<String, String>> users;
  final String selectedUserId;
  final String title;

  const UserPickerModal({
    super.key,
    required this.users,
    this.selectedUserId = 'SEMUA',
    this.title = 'Pilih Filter User',
  });

  static Future<String?> show(
    BuildContext context,
    List<Map<String, String>> users, {
    String selected = 'SEMUA',
    String title = 'Pilih Filter User',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserPickerModal(
        users: users,
        selectedUserId: selected,
        title: title,
      ),
    );
  }

  @override
  State<UserPickerModal> createState() => _UserPickerModalState();
}

class _UserPickerModalState extends State<UserPickerModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Filter users by search query
    List<Map<String, String>> filtered = widget.users.where((u) {
      final label = u['label'] ?? '';
      return label.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              autofocus: false,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari nama atau role user...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(),

          // User List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('User tidak ditemukan', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final u = filtered[index];
                      final id = u['id'] ?? 'SEMUA';
                      final label = u['label'] ?? '';
                      final isSelected = widget.selectedUserId == id;

                      // Extract role color or icon if available
                      bool isOwner = label.toLowerCase().contains('owner');
                      bool isAll = id == 'SEMUA';

                      return InkWell(
                        onTap: () => Navigator.pop(context, id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isAll
                                      ? Colors.grey.shade200
                                      : (isOwner ? Colors.amber.withValues(alpha: 0.15) : AppTheme.primaryColor.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isAll ? Icons.people_outline : (isOwner ? Icons.admin_panel_settings : Icons.person_outline),
                                  color: isAll ? AppTheme.textSecondary : (isOwner ? Colors.amber.shade800 : AppTheme.primaryColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAll ? 'Tampilkan transaksi dari seluruh user' : (isOwner ? 'Akun Pendiri Utama (Owner)' : 'Akun Admin Operasional'),
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                              else
                                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
