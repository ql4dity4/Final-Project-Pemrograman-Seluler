import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';

class TechScreen extends StatefulWidget {
  final String initialDomain;
  const TechScreen({super.key, this.initialDomain = ''});

  @override
  State<TechScreen> createState() => _TechScreenState();
}

class _TechScreenState extends State<TechScreen> {
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
    await StorageService.addHistory(domain, 'Tech Detect');

    try {
      final result = await ApiService.techDetection(domain);
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
      appBar: AppBar(title: const Text('Technology Detector')),
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
                      prefixIcon: Icon(Icons.code),
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
              const LoadingShimmer(itemCount: 3),

            if (_error != null && !_isLoading)
              ErrorCard(message: _error!, onRetry: _lookup),

            if (_result != null && !_isLoading) ...[
              _buildTechList(),
              const SizedBox(height: 16),
              _buildSecurityHeaders(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTechList() {
    final techs = _result!['technologies'] as List<dynamic>? ?? [];
    return CyberCard(
      glowColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.code,
            title: 'Detected Technologies',
            iconColor: AppColors.warning,
          ),
          const SizedBox(height: 10),
          if (techs.isEmpty)
            const Text('No technologies detected. Only basic passive headers analyze is run.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: techs.length,
              itemBuilder: (context, index) {
                final item = techs[index] as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.integration_instructions, color: AppColors.warning),
                  title: Text(item['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  subtitle: Text('${item['category']} (${item['source']})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityHeaders() {
    final secHeaders = _result!['securityHeaders'] as Map<String, dynamic>? ?? {};
    final allHeaders = _result!['allHeaders'] as Map<String, dynamic>? ?? {};

    return CyberCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            icon: Icons.security,
            title: 'Security Headers Check',
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildHeaderStatus('Strict-Transport-Security (HSTS)', secHeaders['strict-transport-security']),
          _buildHeaderStatus('Content-Security-Policy (CSP)', secHeaders['content-security-policy']),
          _buildHeaderStatus('X-Frame-Options (Clickjacking protection)', secHeaders['x-frame-options']),
          _buildHeaderStatus('X-Content-Type-Options (Mime sniffing protection)', secHeaders['x-content-type-options']),
          _buildHeaderStatus('Referrer-Policy', secHeaders['referrer-policy']),
          const Divider(color: Color(0xFF1E293B), height: 24),
          const Text('All Received HTTP Headers:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 8),
          ...allHeaders.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(e.value.toString(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHeaderStatus(String headerName, dynamic value) {
    final bool isPresent = value != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? AppColors.success : AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headerName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (isPresent)
                  Text(value.toString(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted))
                else
                  const Text('Missing', style: TextStyle(fontSize: 10, color: AppColors.error)),
              ],
            ),
          )
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
