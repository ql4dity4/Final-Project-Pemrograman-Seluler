import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/common_widgets.dart';

class HashScreen extends StatefulWidget {
  const HashScreen({super.key});

  @override
  State<HashScreen> createState() => _HashScreenState();
}

class _HashScreenState extends State<HashScreen> {
  final TextEditingController _hashController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  String _selectedAlgo = 'md5';

  Map<String, dynamic>? _identifyResult;
  Map<String, dynamic>? _generateResult;
  bool _isIdentifying = false;
  bool _isGenerating = false;
  String? _idError;
  String? _genError;

  final List<String> _algorithms = ['md5', 'sha1', 'sha256', 'sha512'];

  Future<void> _identify() async {
    final hash = _hashController.text.trim();
    if (hash.isEmpty) return;

    setState(() {
      _isIdentifying = true;
      _idError = null;
      _identifyResult = null;
    });

    try {
      final res = await ApiService.identifyHash(hash);
      setState(() {
        _identifyResult = res;
        _isIdentifying = false;
      });
    } catch (e) {
      setState(() {
        _idError = e.toString();
        _isIdentifying = false;
      });
    }
  }

  Future<void> _generate() async {
    final text = _textController.text;
    if (text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _genError = null;
      _generateResult = null;
    });

    try {
      final res = await ApiService.generateHash(text, _selectedAlgo);
      setState(() {
        _generateResult = res;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _genError = e.toString();
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hash Tools'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Identify'),
              Tab(text: 'Generate'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildIdentifyTab(),
            _buildGenerateTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentifyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _hashController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Paste hash here...',
              prefixIcon: Icon(Icons.fingerprint),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isIdentifying ? null : _identify,
              child: _isIdentifying
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('IDENTIFY HASH'),
            ),
          ),
          const SizedBox(height: 20),

          if (_idError != null)
            ErrorCard(message: _idError!, onRetry: _identify),

          if (_identifyResult != null)
            CyberCard(
              glowColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    icon: Icons.search,
                    title: 'Analysis Results',
                  ),
                  InfoRow(label: 'Hash Length', value: '${_identifyResult!['length'] ?? 0} characters'),
                  const SizedBox(height: 10),
                  const Text('Possible Types:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_identifyResult!['possibleTypes'] as List<dynamic>? ?? []).map((type) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          type.toString(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _textController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Enter text to hash...',
              prefixIcon: Icon(Icons.text_fields),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Algorithm:', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAlgo,
                      dropdownColor: AppColors.bgCard,
                      items: _algorithms.map((algo) {
                        return DropdownMenuItem(
                          value: algo,
                          child: Text(algo.toUpperCase(), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAlgo = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generate,
              child: _isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('GENERATE HASH'),
            ),
          ),
          const SizedBox(height: 20),

          if (_genError != null)
            ErrorCard(message: _genError!, onRetry: _generate),

          if (_generateResult != null)
            CyberCard(
              glowColor: AppColors.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Result (${_generateResult!['algorithm']?.toString().toUpperCase()})',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          final h = _generateResult!['hash']?.toString() ?? '';
                          Clipboard.setData(ClipboardData(text: h));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hash copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _generateResult!['hash']?.toString() ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.success,
                      ),
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
    _hashController.dispose();
    _textController.dispose();
    super.dispose();
  }
}
