import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';

class WhoisScreen extends StatefulWidget {
  final String initialDomain;
  const WhoisScreen({super.key, this.initialDomain = ''});

  @override
  State<WhoisScreen> createState() => _WhoisScreenState();
}

class _WhoisScreenState extends State<WhoisScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;
  bool _showRaw = false;

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
    await StorageService.addHistory(domain, 'WHOIS Lookup');

    try {
      final result = await ApiService.whoisLookup(domain);
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
      appBar: AppBar(title: const Text('WHOIS Lookup')),
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
                      hintText: 'Enter domain...',
                      prefixIcon: Icon(Icons.search),
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

            if (_error != null)
              ErrorCard(message: _error!, onRetry: _lookup),

            if (_result != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Show Raw WHOIS', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _showRaw,
                    onChanged: (val) {
                      setState(() => _showRaw = val);
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _showRaw ? _buildRawView() : _buildParsedView(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildParsedView() {
    final parsed = _result!['parsed'] as Map<String, dynamic>? ?? {};
    if (parsed.isEmpty) {
      return const CyberCard(
        child: Center(
          child: Text('No parsed WHOIS data available. Try raw view.',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return CyberCard(
      glowColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parsed.entries.map((entry) {
          final val = entry.value;
          final valString = val is List ? val.join(', ') : val.toString();
          return InfoRow(label: entry.key, value: valString);
        }).toList(),
      ),
    );
  }

  Widget _buildRawView() {
    final raw = _result!['raw']?.toString() ?? 'No raw WHOIS data';
    return CyberCard(
      glowColor: AppColors.primary,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            raw,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.success,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
