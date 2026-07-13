import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';

class SubdomainScreen extends StatefulWidget {
  final String initialDomain;
  const SubdomainScreen({super.key, this.initialDomain = ''});

  @override
  State<SubdomainScreen> createState() => _SubdomainScreenState();
}

class _SubdomainScreenState extends State<SubdomainScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allSubdomains = [];
  List<dynamic> _filteredSubdomains = [];
  bool _isLoading = false;
  String? _error;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialDomain;
    _searchController.addListener(_filterSubdomains);
    if (widget.initialDomain.isNotEmpty) _lookup();
  }

  void _filterSubdomains() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSubdomains = List.from(_allSubdomains);
      } else {
        _filteredSubdomains = _allSubdomains
            .where((sub) => sub.toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _lookup() async {
    final domain = _controller.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _searched = true;
      _searchController.clear();
    });
    await StorageService.addHistory(domain, 'Subdomains');

    try {
      final result = await ApiService.subdomainFinder(domain);
      setState(() {
        _allSubdomains = result['subdomains'] as List<dynamic>? ?? [];
        _filteredSubdomains = List.from(_allSubdomains);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subdomain Finder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Enter domain (e.g. google.com)...',
                      prefixIcon: Icon(Icons.lan_outlined, size: 18),
                    ),
                    onSubmitted: (_) => _lookup(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _lookup,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Icon(Icons.search_rounded, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(child: Center(child: LoadingShimmer(itemCount: 4))),

            if (_error != null && !_isLoading)
              ErrorCard(message: _error!, onRetry: _lookup),

            if (_searched && !_isLoading && _error == null) ...[
              // Results Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Found ${_allSubdomains.length} subdomains',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy All', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _allSubdomains.join('\n')));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All subdomains copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search Filter Bar
              if (_allSubdomains.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Filter results...',
                      prefixIcon: const Icon(Icons.filter_list_rounded, size: 16),
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

              Expanded(
                child: _filteredSubdomains.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching subdomains',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredSubdomains.length,
                        itemBuilder: (context, index) {
                          final sub = _filteredSubdomains[index].toString();
                          return CyberCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            glowColor: AppColors.accentAlt,
                            child: Row(
                              children: [
                                const Icon(Icons.link_rounded, color: AppColors.accentAlt, size: 14),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SelectableText(
                                    sub,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: sub));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Copied: $sub')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
