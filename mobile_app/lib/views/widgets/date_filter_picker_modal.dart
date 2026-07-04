import 'package:flutter/material.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';

class DateFilterPickerModal extends StatefulWidget {
  final String selectedWaktu;
  final DateTime? customDate;
  final int? customMonth;
  final int? customYear;
  final String title;

  const DateFilterPickerModal({
    super.key,
    required this.selectedWaktu,
    this.customDate,
    this.customMonth,
    this.customYear,
    this.title = 'Pilih Periode Waktu',
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String selectedWaktu,
    DateTime? customDate,
    int? customMonth,
    int? customYear,
    String title = 'Pilih Periode Waktu',
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateFilterPickerModal(
        selectedWaktu: selectedWaktu,
        customDate: customDate,
        customMonth: customMonth,
        customYear: customYear,
        title: title,
      ),
    );
  }

  @override
  State<DateFilterPickerModal> createState() => _DateFilterPickerModalState();
}

class _DateFilterPickerModalState extends State<DateFilterPickerModal> {
  String _getMonthName(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.customDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      Navigator.pop(context, {'waktu': 'CUSTOM_TANGGAL', 'date': picked});
    }
  }

  Future<void> _pickCustomYear() async {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(15, (i) => 2020 + i);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pilih Tahun Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: years.length,
              itemBuilder: (context, index) {
                final yr = years[index];
                final isSelected = (widget.customYear ?? currentYear) == yr;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx, yr);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                    ),
                    child: Text(
                      '$yr',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((selectedYr) {
      if (selectedYr != null && mounted) {
        Navigator.pop(context, {'waktu': 'CUSTOM_TAHUN', 'year': selectedYr});
      }
    });
  }

  Future<void> _pickCustomMonth() async {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    int tempYear = widget.customYear ?? DateTime.now().year;
    int? selectedMonth = widget.customMonth;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pilih Bulan & Tahun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tahun Filter:', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_left, size: 22),
                            onPressed: () => setDialogState(() => tempYear--),
                          ),
                          Text('$tempYear', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.chevron_right, size: 22),
                            onPressed: () => setDialogState(() => tempYear++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 320,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final mIdx = index + 1;
                    final isSelected = selectedMonth == mIdx && (widget.customYear ?? DateTime.now().year) == tempYear;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx, {'month': mIdx, 'year': tempYear});
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
                        ),
                        child: Text(
                          months[index].substring(0, 3),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    ).then((res) {
      if (res != null && mounted) {
        Navigator.pop(context, {'waktu': 'CUSTOM_BULAN', 'month': res['month'], 'year': res['year']});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allOptions = [
      {
        'id': 'SEMUA',
        'label': 'Semua Waktu',
        'sublabel': 'Tampilkan seluruh riwayat transaksi dari awal',
        'icon': Icons.all_inclusive,
      },
      {
        'id': 'CUSTOM_TANGGAL',
        'label': 'Pilih Tanggal Spesifik',
        'sublabel': widget.selectedWaktu == 'CUSTOM_TANGGAL' && widget.customDate != null
            ? 'Terpilih: ${AppFormatters.date(widget.customDate!)} (Klik untuk ganti)'
            : 'Cari transaksi pada tanggal tertentu via kalender',
        'icon': Icons.event,
        'action': _pickCustomDate,
      },
      {
        'id': 'CUSTOM_BULAN',
        'label': 'Pilih Bulan & Tahun',
        'sublabel': widget.selectedWaktu == 'CUSTOM_BULAN' && widget.customMonth != null && widget.customYear != null
            ? 'Terpilih: ${_getMonthName(widget.customMonth!)} ${widget.customYear} (Klik untuk ganti)'
            : 'Cari transaksi pada bulan dan tahun tertentu',
        'icon': Icons.date_range,
        'action': _pickCustomMonth,
      },
      {
        'id': 'CUSTOM_TAHUN',
        'label': 'Pilih Tahun Spesifik',
        'sublabel': widget.selectedWaktu == 'CUSTOM_TAHUN' && widget.customYear != null
            ? 'Terpilih: Tahun ${widget.customYear} (Klik untuk ganti)'
            : 'Cari rekap transaksi pada tahun tertentu',
        'icon': Icons.history,
        'action': _pickCustomYear,
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
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

          const Divider(),

          // Options List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: allOptions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final opt = allOptions[index];
                final id = opt['id'] as String;
                final label = opt['label'] as String;
                final sublabel = opt['sublabel'] as String;
                final icon = opt['icon'] as IconData;
                final action = opt['action'] as Function?;

                      final isSelected = widget.selectedWaktu == id;

                      return InkWell(
                        onTap: () {
                          if (action != null) {
                            action();
                          } else {
                            Navigator.pop(context, {'waktu': id});
                          }
                        },
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
                                  color: isSelected
                                      ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sublabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.8) : AppTheme.textSecondary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
