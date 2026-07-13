import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';

class ReconResultScreen extends StatelessWidget {
  final String domain;
  final Map<String, dynamic> data;

  const ReconResultScreen({
    super.key,
    required this.domain,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recon: $domain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
              Clipboard.setData(ClipboardData(text: jsonStr));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Results copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.bgDark, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain,
                          style: const TextStyle(
                            color: AppColors.bgDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Scan completed • ${data['timestamp'] ?? 'N/A'}',
                          style: TextStyle(
                            color: AppColors.bgDark.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // DNS Section
            if (data['dns'] != null) ...[
              const SectionHeader(icon: Icons.dns, title: 'DNS RECORDS'),
              _buildDnsSection(data['dns']),
              const SizedBox(height: 16),
            ],

            // IP & Hosting
            if (data['ip'] != null || data['hosting'] != null) ...[
              const SectionHeader(
                icon: Icons.cloud,
                title: 'IP & HOSTING',
                iconColor: AppColors.accentAlt,
              ),
              _buildHostingSection(),
              const SizedBox(height: 16),
            ],

            // Ports
            if (data['ports'] != null && data['ports'] is Map) ...[
              const SectionHeader(
                icon: Icons.router,
                title: 'PORT INFORMATION',
                iconColor: AppColors.error,
              ),
              _buildPortSection(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDnsSection(Map<String, dynamic> dns) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dns['A'] != null && (dns['A'] as List).isNotEmpty)
            _buildRecordList('A Records', dns['A'], AppColors.primary),
          if (dns['MX'] != null && (dns['MX'] as List).isNotEmpty)
            _buildMxRecords(dns['MX']),
          if (dns['NS'] != null && (dns['NS'] as List).isNotEmpty)
            _buildRecordList('NS Records', dns['NS'], AppColors.info),
          if (dns['TXT'] != null && (dns['TXT'] as List).isNotEmpty)
            _buildRecordList('TXT Records', dns['TXT'], AppColors.warning),
          if (dns['CNAME'] != null && (dns['CNAME'] as List).isNotEmpty)
            _buildRecordList('CNAME Records', dns['CNAME'], AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildRecordList(String title, List<dynamic> records, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 8),
          child: Text(
            title,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        ...records.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.arrow_right, color: color, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.toString(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildMxRecords(List<dynamic> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6, top: 8),
          child: Text(
            'MX Records',
            style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        ...records.map((r) {
          final exchange = r is Map ? r['exchange'] ?? r.toString() : r.toString();
          final priority = r is Map ? r['priority']?.toString() ?? '' : '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.arrow_right, color: AppColors.accent, size: 16),
                const SizedBox(width: 6),
                if (priority.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(priority,
                        style: const TextStyle(color: AppColors.accent, fontSize: 10)),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    exchange,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHostingSection() {
    final hosting = data['hosting'] as Map<String, dynamic>? ?? {};
    return CyberCard(
      glowColor: AppColors.accentAlt,
      child: Column(
        children: [
          InfoRow(label: 'IP Address', value: data['ip']?.toString() ?? 'N/A'),
          InfoRow(label: 'ISP', value: hosting['isp']?.toString() ?? 'N/A'),
          InfoRow(label: 'Organization', value: hosting['org']?.toString() ?? 'N/A'),
          InfoRow(label: 'AS', value: hosting['as']?.toString() ?? 'N/A'),
          InfoRow(label: 'Country', value: hosting['country']?.toString() ?? 'N/A'),
          InfoRow(label: 'Region', value: hosting['regionName']?.toString() ?? 'N/A'),
          InfoRow(label: 'City', value: hosting['city']?.toString() ?? 'N/A'),
          if (hosting['lat'] != null && hosting['lon'] != null)
            InfoRow(
              label: 'Coordinates',
              value: '${hosting['lat']}, ${hosting['lon']}',
            ),
        ],
      ),
    );
  }

  Widget _buildPortSection() {
    final ports = data['ports'];
    if (ports is! Map) return const SizedBox.shrink();

    final portList = ports['ports'] as List? ?? [];
    final vulns = ports['vulns'] as List? ?? [];

    return Column(
      children: [
        if (portList.isNotEmpty)
          CyberCard(
            glowColor: AppColors.error,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open Ports (${portList.length})',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: portList.map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        p.toString(),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        if (vulns.isNotEmpty)
          CyberCard(
            glowColor: AppColors.warning,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Potential Vulnerabilities',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...vulns.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: AppColors.warning, size: 14),
                          const SizedBox(width: 6),
                          Text(v.toString(),
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 12)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }
}
