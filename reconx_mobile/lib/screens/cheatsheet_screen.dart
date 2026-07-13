import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../utils/cheatsheet_data.dart';
import '../widgets/common_widgets.dart';

class CheatsheetScreen extends StatefulWidget {
  const CheatsheetScreen({super.key});

  @override
  State<CheatsheetScreen> createState() => _CheatsheetScreenState();
}

class _CheatsheetScreenState extends State<CheatsheetScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  List<Map<String, String>> _filteredPayloads = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = CheatsheetData.categories.keys.first;
    _searchController.addListener(_filterPayloads);
    _filterPayloads();
  }

  void _filterPayloads() {
    final query = _searchController.text.trim().toLowerCase();
    final allForCat = CheatsheetData.categories[_selectedCategory] ?? [];
    setState(() {
      if (query.isEmpty) {
        _filteredPayloads = List.from(allForCat);
      } else {
        _filteredPayloads = allForCat
            .where((item) =>
                (item['name']?.toLowerCase().contains(query) ?? false) ||
                (item['payload']?.toLowerCase().contains(query) ?? false))
            .toList();
      }
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterPayloads();
  }

  @override
  Widget build(BuildContext context) {
    final categories = CheatsheetData.categories.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Payload Cheatsheet')),
      body: Column(
        children: [
          // Filter Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.bgDark,
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search payloads...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 14),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Sidebar categories
                Container(
                  width: 120,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Color(0xFF1E293B),
                        width: 1,
                      ),
                    ),
                    color: AppColors.bgSurface,
                  ),
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = cat == _selectedCategory;
                      return Material(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectCategory(cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Payloads list
                Expanded(
                  child: _filteredPayloads.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching payloads',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredPayloads.length,
                          itemBuilder: (context, index) {
                            final item = _filteredPayloads[index];
                            return CyberCard(
                              padding: const EdgeInsets.all(12),
                              glowColor: AppColors.primary,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['name'] ?? 'Payload',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          final p = item['payload'] ?? '';
                                          Clipboard.setData(ClipboardData(text: p));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Copied: ${item['name']}'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgDark,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    child: SelectableText(
                                      item['payload'] ?? '',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10.5,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
