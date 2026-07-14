import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';
import 'recon_result_screen.dart';
import 'dns_screen.dart';
import 'whois_screen.dart';
import 'subdomain_screen.dart';
import 'tech_screen.dart';
import 'ip_info_screen.dart';
import 'port_screen.dart';
import 'cheatsheet_screen.dart';
import 'hash_screen.dart';
import 'history_screen.dart';
import 'bookmark_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _domainController = TextEditingController();
  bool _isScanning = false;
  int _currentNavIndex = 0;
  List<Map<String, dynamic>> _recentHistory = [];
  bool _isBackendOnline = false;
  bool _checkingStatus = true;

  final List<_ToolItem> _reconTools = [
    _ToolItem(Icons.dns_outlined, 'DNS Lookup', 'Query DNS resource records', AppColors.primary),
    _ToolItem(Icons.search_outlined, 'WHOIS Lookup', 'Find domain ownership data', AppColors.accent),
    _ToolItem(Icons.lan_outlined, 'Subdomains', 'Enumerate passive subdomains', AppColors.accentAlt),
    _ToolItem(Icons.code_rounded, 'Tech Detect', 'Analyze stack & HTTP headers', AppColors.warning),
    _ToolItem(Icons.public_outlined, 'IP & Geolocation', 'Identify server physical hosting', AppColors.info),
    _ToolItem(Icons.router_outlined, 'Passive Ports', 'Retrieve port records (Shodan)', AppColors.error),
  ];

  final List<_ToolItem> _utilityTools = [
    _ToolItem(Icons.menu_book_outlined, 'Payload Cheatsheet', 'Pentest reference & commands', AppColors.accent),
    _ToolItem(Icons.fingerprint_outlined, 'Hash Utility', 'Identify & generate hash strings', AppColors.primary),
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentHistory();
    _checkBackendStatus();
  }

  Future<void> _checkBackendStatus() async {
    setState(() => _checkingStatus = true);
    final online = await ApiService.healthCheck();
    if (mounted) {
      setState(() {
        _isBackendOnline = online;
        _checkingStatus = false;
      });
    }
  }

  Future<void> _loadRecentHistory() async {
    final history = await StorageService.getHistory();
    if (mounted) {
      setState(() {
        _recentHistory = history.take(4).toList();
      });
    }
  }

  void _showApiSettingsDialog() {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          title: Row(
            children: [
              const Icon(Icons.settings_ethernet, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'API Settings',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the backend API server URL. Use localhost for Emulator/Web, or your computer\'s local IP address if running on a physical Android device.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E293B)),
                  color: AppColors.bgCard,
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    hintText: 'http://192.168.1.x:3000',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await StorageService.setCustomApiUrl(null);
                await ApiService.init();
                if (context.mounted) Navigator.pop(context);
                _checkBackendStatus();
              },
              child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  await StorageService.setCustomApiUrl(newUrl);
                  ApiService.setBaseUrl(newUrl);
                }
                if (context.mounted) Navigator.pop(context);
                _checkBackendStatus();
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  String _cleanDomain(String input) {
    String domain = input.trim().toLowerCase();
    domain = domain.replaceAll(RegExp(r'^https?://'), '');
    domain = domain.replaceAll(RegExp(r'/.*$'), '');
    domain = domain.replaceAll(RegExp(r':.*$'), '');
    return domain;
  }

  Future<void> _startFullRecon() async {
    final domain = _cleanDomain(_domainController.text);
    if (domain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target domain')),
      );
      return;
    }

    setState(() => _isScanning = true);
    await StorageService.addHistory(domain, 'Full Recon');

    try {
      final result = await ApiService.fullRecon(domain);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReconResultScreen(domain: domain, data: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete scan: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
        _loadRecentHistory();
      }
    }
  }

  void _navigateToReconTool(int index) {
    final domain = _cleanDomain(_domainController.text);
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (_) => DnsScreen(initialDomain: domain)));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => WhoisScreen(initialDomain: domain)));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => SubdomainScreen(initialDomain: domain)));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => TechScreen(initialDomain: domain)));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (_) => IpInfoScreen(initialDomain: domain)));
        break;
      case 5:
        Navigator.push(context, MaterialPageRoute(builder: (_) => PortScreen(initialDomain: domain)));
        break;
    }
  }

  void _navigateToUtilityTool(int index) {
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CheatsheetScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HashScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomePage(),
          const HistoryScreen(),
          const BookmarkScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(
            top: BorderSide(
              color: Color(0xFF1E293B),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (i) {
            setState(() => _currentNavIndex = i);
            if (i == 0) {
              _loadRecentHistory();
              _checkBackendStatus();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.security_outlined, size: 20),
              activeIcon: Icon(Icons.security, size: 20),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined, size: 20),
              activeIcon: Icon(Icons.history, size: 20),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline, size: 20),
              activeIcon: Icon(Icons.bookmark, size: 20),
              label: 'Bookmarks',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDomainInput(),
            const SizedBox(height: 12),
            ScanButton(
              onPressed: _startFullRecon,
              isLoading: _isScanning,
              label: 'RUN PASSIVE RECON',
            ),
            const SizedBox(height: 32),
            const SectionHeader(
              icon: Icons.radar_outlined,
              title: 'Reconnaissance Modules',
            ),
            _buildToolsGrid(_reconTools, true),
            const SizedBox(height: 24),
            const SectionHeader(
              icon: Icons.construction_outlined,
              title: 'Utilities & References',
            ),
            _buildToolsGrid(_utilityTools, false),
            const SizedBox(height: 28),
            if (_recentHistory.isNotEmpty) ...[
              SectionHeader(
                icon: Icons.history,
                title: 'Recent Scans',
                trailing: TextButton(
                  onPressed: () => setState(() => _currentNavIndex = 1),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              _buildRecentHistory(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ReconX Toolkit',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 2),
            Text(
              'Passive Intelligence & OSINT Aggregator',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        // Health check status pill
        GestureDetector(
          onTap: _showApiSettingsDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _checkingStatus
                    ? const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                      )
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isBackendOnline ? AppColors.success : AppColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isBackendOnline ? AppColors.success : AppColors.error).withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                const SizedBox(width: 6),
                Text(
                  _checkingStatus
                      ? 'Checking'
                      : (_isBackendOnline ? 'API Online' : 'API Offline'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _checkingStatus
                        ? AppColors.textMuted
                        : (_isBackendOnline ? AppColors.textPrimary : AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDomainInput() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B)),
        color: AppColors.bgCard,
      ),
      child: TextField(
        controller: _domainController,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Enter target domain (e.g. example.com)',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.language_outlined, size: 18),
          suffixIcon: _domainController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _domainController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.search,
        onChanged: (val) => setState(() {}),
        onSubmitted: (_) => _startFullRecon(),
      ),
    );
  }

  Widget _buildToolsGrid(List<_ToolItem> items, bool isRecon) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final tool = items[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => isRecon ? _navigateToReconTool(index) : _navigateToUtilityTool(index),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1E293B),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: tool.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(tool.icon, color: tool.color, size: 18),
                      ),
                      Icon(Icons.arrow_outward_rounded, color: AppColors.textMuted.withValues(alpha: 0.5), size: 14),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        tool.subtitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentHistory() {
    return Column(
      children: _recentHistory.map((item) {
        return CyberCard(
          onTap: () {
            _domainController.text = item['domain'] ?? '';
            setState(() {});
          },
          glowColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['domain'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${item['type'] ?? 'Scan'} • ${_formatTime(item['timestamp'])}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_right_alt_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return '';
    }
  }
}

class _ToolItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _ToolItem(this.icon, this.title, this.subtitle, this.color);
}
