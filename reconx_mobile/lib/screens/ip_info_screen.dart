import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';

class IpInfoScreen extends StatefulWidget {
  final String initialDomain;
  const IpInfoScreen({super.key, this.initialDomain = ''});

  @override
  State<IpInfoScreen> createState() => _IpInfoScreenState();
}

class _IpInfoScreenState extends State<IpInfoScreen> {
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
    await StorageService.addHistory(domain, 'IP & Hosting');

    try {
      final result = await ApiService.ipInfo(domain);
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
      appBar: AppBar(title: const Text('IP & Hosting Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Enter domain (e.g. google.com)...',
                      prefixIcon: Icon(Icons.cloud),
                    ),
                    onSubmitted: (_) => _lookup(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _lookup,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const LoadingShimmer(itemCount: 2),

            if (_error != null && !_isLoading)
              ErrorCard(message: _error!, onRetry: _lookup),

            if (_result != null && !_isLoading) ...[
              CyberCard(
                glowColor: AppColors.accentAlt,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      icon: Icons.info,
                      title: 'Resolved IP Information',
                      iconColor: AppColors.accentAlt,
                    ),
                    InfoRow(label: 'Domain', value: _result!['domain']?.toString() ?? 'N/A'),
                    InfoRow(label: 'Resolved IP', value: _result!['ip']?.toString() ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildHostingDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHostingDetails() {
    final hosting = _result!['hosting'] as Map<String, dynamic>? ?? {};
    if (hosting.isEmpty) return const SizedBox.shrink();

    return CyberCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.business,
            title: 'ISP & Geolocation Details',
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: 10),
          InfoRow(label: 'ISP / Provider', value: hosting['isp']?.toString() ?? 'N/A'),
          InfoRow(label: 'Organization', value: hosting['org']?.toString() ?? 'N/A'),
          InfoRow(label: 'ASN / Routing', value: hosting['as']?.toString() ?? 'N/A'),
          InfoRow(label: 'ASN Name', value: hosting['asname']?.toString() ?? 'N/A'),
          const Divider(color: Color(0xFF1E293B), height: 24),
          InfoRow(label: 'Country', value: '${hosting['country'] ?? 'N/A'} (${hosting['countryCode'] ?? 'N/A'})'),
          InfoRow(label: 'Region', value: hosting['regionName']?.toString() ?? 'N/A'),
          InfoRow(label: 'City', value: hosting['city']?.toString() ?? 'N/A'),
          InfoRow(label: 'Zip / Postal Code', value: hosting['zip']?.toString() ?? 'N/A'),
          InfoRow(label: 'Latitude', value: hosting['lat']?.toString() ?? 'N/A'),
          InfoRow(label: 'Longitude', value: hosting['lon']?.toString() ?? 'N/A'),
          InfoRow(label: 'Timezone', value: hosting['timezone']?.toString() ?? 'N/A'),
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
