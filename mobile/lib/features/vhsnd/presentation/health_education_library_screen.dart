import 'package:flutter/material.dart';
import '../domain/vhsnd_models.dart';

/// Screen displaying the offline multimedia health education library and active public health campaigns
/// (Requirements 27.4, 27.5).
class HealthEducationLibraryScreen extends StatefulWidget {
  final List<HealthEducationAsset> initialAssets;
  final List<CommunityCampaign> activeCampaigns;

  const HealthEducationLibraryScreen({
    super.key,
    required this.initialAssets,
    this.activeCampaigns = const [],
  });

  @override
  State<HealthEducationLibraryScreen> createState() => _HealthEducationLibraryScreenState();
}

class _HealthEducationLibraryScreenState extends State<HealthEducationLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HealthEducationTopic? _selectedTopic;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<HealthEducationAsset> get _filteredAssets {
    return widget.initialAssets.where((a) {
      if (_selectedTopic != null && a.topic != _selectedTopic) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = a.title.toLowerCase().contains(q);
        final matchDesc = a.description.toLowerCase().contains(q);
        final matchTag = a.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchTitle && !matchDesc && !matchTag) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Education & Campaigns'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Education Library'),
            Tab(icon: Icon(Icons.campaign), text: 'Active Campaigns'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEducationLibraryTab(context),
          _buildActiveCampaignsTab(context),
        ],
      ),
    );
  }

  Widget _buildEducationLibraryTab(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search audio clips, topics, danger signs...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // Topic filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Topics'),
                selected: _selectedTopic == null,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedTopic = null);
                },
              ),
              const SizedBox(width: 8),
              ...HealthEducationTopic.values.map((topic) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(topic.label),
                    selected: _selectedTopic == topic,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTopic = selected ? topic : null;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Assets list
        Expanded(
          child: _filteredAssets.isEmpty
              ? const Center(child: Text('No health education materials matching criteria.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredAssets.length,
                  itemBuilder: (context, index) {
                    final asset = _filteredAssets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getMediaColor(asset.mediaType).withValues(alpha: 0.15),
                          child: Icon(
                            _getMediaIcon(asset.mediaType),
                            color: _getMediaColor(asset.mediaType),
                          ),
                        ),
                        title: Text(asset.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(asset.description, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '${asset.mediaType.replaceAll('_', ' ').toUpperCase()} • ${asset.languageCode.toUpperCase()}${asset.durationSeconds > 0 ? ' • ${asset.durationSeconds}s' : ''}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_circle_fill, color: Color(0xFF1B5E20), size: 36),
                          onPressed: () => _showMediaPreviewModal(context, asset),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActiveCampaignsTab(BuildContext context) {
    if (widget.activeCampaigns.isEmpty) {
      return const Center(child: Text('No active health campaigns at this time.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.activeCampaigns.length,
      itemBuilder: (context, index) {
        final campaign = widget.activeCampaigns[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: const Icon(Icons.campaign, color: Color(0xFFE65100), size: 32),
            title: Text(campaign.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Target: ${campaign.targetDescription}', style: const TextStyle(fontSize: 13)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Campaign Checklist & Protocol:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...campaign.checklistItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getMediaIcon(String mediaType) {
    switch (mediaType) {
      case 'audio_clip':
        return Icons.audiotrack;
      case 'illustrated_card':
        return Icons.image;
      case 'video_clip':
        return Icons.videocam;
      default:
        return Icons.article;
    }
  }

  Color _getMediaColor(String mediaType) {
    switch (mediaType) {
      case 'audio_clip':
        return Colors.orange;
      case 'illustrated_card':
        return Colors.blue;
      case 'video_clip':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  void _showMediaPreviewModal(BuildContext context, HealthEducationAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(asset.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getMediaIcon(asset.mediaType), size: 48, color: _getMediaColor(asset.mediaType)),
                    const SizedBox(height: 8),
                    Text(
                      'Offline Media Playing: ${asset.mediaType.replaceAll('_', ' ')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(asset.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: asset.tags.map((t) => Chip(label: Text('#$t', style: const TextStyle(fontSize: 11)))).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
