import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';

class PortScreen extends StatefulWidget {
  final String initialDomain;
  const PortScreen({super.key, this.initialDomain = ''});

  @override
  State<PortScreen> createState() => _PortScreenState();
}

class _PortScreenState extends State<PortScreen> {
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
    await StorageService.addHistory(domain, 'Port Search');

    try {
      final result = await ApiService.portInfo(domain);
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
      appBar: AppBar(title: const Text('Passive Port Information')),
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
                      prefixIcon: Icon(Icons.router),
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
              _buildPortsCard(),
              const SizedBox(height: 12),
              _buildVulnerabilitiesCard(),
              const SizedBox(height: 12),
              _buildMetadataCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPortsCard() {
    final ports = _result!['ports'] as List<dynamic>? ?? [];
    return CyberCard(
      glowColor: AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.router,
            title: 'Passive Port Info (via Shodan)',
            iconColor: AppColors.error,
          ),
          const SizedBox(height: 10),
          if (ports.isEmpty)
            const Text('No public open ports discovered passively.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else ...[
            Text('Discovered Open Ports (${ports.length}):',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ports.map((port) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    port.toString(),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVulnerabilitiesCard() {
    final vulns = _result!['vulns'] as List<dynamic>? ?? [];
    if (vulns.isEmpty) return const SizedBox.shrink();

    return CyberCard(
      glowColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.warning_amber_rounded,
            title: 'Reported CVEs / Vulnerabilities',
            iconColor: AppColors.warning,
          ),
          const SizedBox(height: 10),
          ...vulns.map((cve) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        cve.toString(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
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

  Widget _buildMetadataCard() {
    final hostnames = _result!['hostnames'] as List<dynamic>? ?? [];
    final cpes = _result!['cpes'] as List<dynamic>? ?? [];
    final tags = _result!['tags'] as List<dynamic>? ?? [];

    if (hostnames.isEmpty && cpes.isEmpty && tags.isEmpty) return const SizedBox.shrink();

    return CyberCard(
      glowColor: AppColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.analytics,
            title: 'System Metadata (CPE & Tags)',
            iconColor: AppColors.info,
          ),
          if (hostnames.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Hostnames:', style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.bold)),
            ...hostnames.map((h) => Text(h.toString(), style: const TextStyle(fontSize: 12))),
          ],
          if (cpes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('CPE (Common Platform Enumeration):', style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.bold)),
            ...cpes.map((c) => Text(c.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('System Tags:', style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 6,
              children: tags.map((t) => Chip(
                    label: Text(t.toString(), style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
            ),
          ],
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
