import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';

class DnsScreen extends StatefulWidget {
  final String initialDomain;
  const DnsScreen({super.key, this.initialDomain = ''});

  @override
  State<DnsScreen> createState() => _DnsScreenState();
}

class _DnsScreenState extends State<DnsScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialDomain;
    if (widget.initialDomain.isNotEmpty) _lookup();
  }

  Future<void> _lookup() async {
    final domain = _controller.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    await StorageService.addHistory(domain, 'DNS Lookup');

    try {
      final result = await ApiService.dnsLookup(domain);
      setState(() {
        _result = result;
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
      appBar: AppBar(title: const Text('DNS Lookup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Enter target domain (e.g. google.com)...',
                      prefixIcon: Icon(Icons.dns_outlined, size: 18),
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
            const SizedBox(height: 20),

            if (_isLoading)
              const LoadingShimmer(itemCount: 4),

            if (_error != null && !_isLoading)
              ErrorCard(message: _error!, onRetry: _lookup),

            if (_result != null && _result!['records'] != null && !_isLoading)
              _buildResults(_result!['records']),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(Map<String, dynamic> records) {
    return Column(
      children: [
        _buildRecordCard('A Records', records['A'], Icons.computer_outlined, AppColors.primary),
        _buildRecordCard('AAAA Records', records['AAAA'], Icons.language_outlined, AppColors.info),
        _buildMxCard(records['MX']),
        _buildRecordCard('NS Records', records['NS'], Icons.dns_outlined, AppColors.accent),
        _buildRecordCard('TXT Records', records['TXT'], Icons.description_outlined, AppColors.warning),
        _buildRecordCard('CNAME Records', records['CNAME'], Icons.alt_route_outlined, AppColors.accentAlt),
        if (records['SOA'] != null) _buildSoaCard(records['SOA']),
      ],
    );
  }

  Widget _buildRecordCard(String title, List<dynamic>? records, IconData icon, Color color) {
    if (records == null || records.isEmpty) return const SizedBox.shrink();
    return CyberCard(
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${records.length}',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...records.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: SelectableText(
                        r.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMxCard(List<dynamic>? records) {
    if (records == null || records.isEmpty) return const SizedBox.shrink();
    return CyberCard(
      glowColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.email_outlined, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              const Text('MX Records',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${records.length}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...records.map((r) {
            final exchange = r is Map ? r['exchange']?.toString() ?? '' : r.toString();
            final priority = r is Map ? r['priority']?.toString() ?? '' : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (priority.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Priority $priority',
                          style: const TextStyle(color: AppColors.accent, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  Expanded(
                    child: SelectableText(
                      exchange,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSoaCard(Map<String, dynamic> soa) {
    return CyberCard(
      glowColor: AppColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, color: AppColors.info, size: 16),
              SizedBox(width: 8),
              Text('SOA Record',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          InfoRow(label: 'Nameserver', value: soa['nsname']?.toString() ?? 'N/A'),
          InfoRow(label: 'Hostmaster', value: soa['hostmaster']?.toString() ?? 'N/A'),
          InfoRow(label: 'Serial', value: soa['serial']?.toString() ?? 'N/A'),
          InfoRow(label: 'Refresh', value: soa['refresh']?.toString() ?? 'N/A'),
          InfoRow(label: 'Retry', value: soa['retry']?.toString() ?? 'N/A'),
          InfoRow(label: 'Expire', value: soa['expire']?.toString() ?? 'N/A'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
