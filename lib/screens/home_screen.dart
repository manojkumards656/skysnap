import 'dart:io';
import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../widgets/glass_card.dart';
import '../utils/constants.dart';
import 'camera_screen.dart';
import 'result_screen.dart';
import '../models/prediction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveService _hiveService = HiveService();
  List<Map<String, dynamic>> _snaps = [];
  int _discoveredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _snaps = _hiveService.getAllSnaps();
      _discoveredCount = _hiveService.getDiscoveredCloudCount();
    });
  }

  Future<void> _openCamera() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
    _loadData(); // Reload data when returning
  }

  void _viewSnap(Map<String, dynamic> snap) {
    final List<dynamic>? topThreeData = snap['topThree'];
    final List<Prediction>? topThree = topThreeData != null
        ? topThreeData.map((item) {
            final Map<dynamic, dynamic> map = item as Map;
            final label = map['label'] as String;
            return Prediction(
              label: label,
              fullName: map['fullName'] as String? ?? AppConstants.cloudFullNames[label] ?? label,
              confidence: (map['confidence'] as num).toDouble(),
              inferenceTimeMs: snap['inferenceTimeMs'] ?? 0,
            );
          }).toList()
        : null;

    final prediction = Prediction(
      label: snap['predictionLabel'],
      fullName: snap['predictionFullName'],
      confidence: snap['confidence'],
      inferenceTimeMs: snap['inferenceTimeMs'],
      topThree: topThree,
    );
    final cloudInfo = _hiveService.getCloudInfo(prediction.label);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          imagePath: snap['imagePath'],
          prediction: prediction,
          cloudInfo: cloudInfo,
          userGuess: snap['userGuess'] ?? '',
          isHistoryView: true,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _deleteSnap(String id) async {
    // Show a confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Delete Snap', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this cloud snap from your journal?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _hiveService.deleteSnap(id);
      _loadData();
    }
  }

  void _showCloudEncyclopediaDetails(String abbrev) {
    final info = _hiveService.getCloudInfo(abbrev);
    if (info == null) return;
    
    final isDiscovered = _hiveService.isCloudDiscovered(abbrev);
    final userImage = _hiveService.getDiscoveredCloudImage(abbrev);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return GlassCard(
              borderRadius: 24,
              color: const Color(0xFF0F0E24).withValues(alpha: 0.9),
              border: Border.all(color: Colors.white10),
              child: Stack(
                children: [
                  ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                    children: [
                      // Header title
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Image / Abbreviation Circle
                      Center(
                        child: userImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(userImage),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.05),
                                  border: Border.all(color: Colors.white12, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    abbrev,
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white30,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        info['fullName'] ?? '',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isDiscovered ? 'Discovered 🎉' : 'Locked // Not Yet Discovered 🔒',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDiscovered ? Colors.greenAccent : Colors.white38,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Info stats
                      _buildInfoSection(Icons.description, 'Description', info['description']),
                      _buildInfoSection(Icons.height, 'Typical Altitude', info['typicalAltitude']),
                      _buildInfoSection(Icons.wb_sunny_outlined, 'Weather Meaning', info['weatherMeaning']),
                      _buildInfoSection(Icons.auto_awesome, 'Fun Fact', info['funFact']),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value ?? 'Unknown',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          const Divider(color: Colors.white10, height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070512), // Midnight Indigo
              Color(0xFF0F0C2A), // Twilight Purple
              Color(0xFF06050F), // Dark Space
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Dashboard App Bar
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Row(
                  children: [
                    Icon(Icons.radar, color: Colors.cyanAccent, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'SkySnap Journal',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white70),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1E2C),
                          title: const Text('SkySnap AI', style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'SkySnap utilizes an offline EfficientNetV2-S model to accurately classify 11 meteorological cloud configurations in real-time.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Dismiss', style: TextStyle(color: Colors.cyanAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Collection Tracker
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CLOUD JOURNAL STATUS',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$_discoveredCount / 11 Types Discovered',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _discoveredCount / 11,
                                  minHeight: 8,
                                  backgroundColor: Colors.white10,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: _discoveredCount / 11,
                                strokeWidth: 5,
                                backgroundColor: Colors.white10,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                              ),
                            ),
                            Text(
                              '${((_discoveredCount / 11) * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Title: Encyclopedia
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text(
                    'METEOROLOGICAL ENCYCLOPEDIA',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              // Encyclopedia Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildListDelegate(
                    AppConstants.cloudFullNames.keys.map((key) {
                      final isDiscovered = _hiveService.isCloudDiscovered(key);
                      final userImage = _hiveService.getDiscoveredCloudImage(key);
                      
                      return InkWell(
                        onTap: () => _showCloudEncyclopediaDetails(key),
                        borderRadius: BorderRadius.circular(16),
                        child: GlassCard(
                          borderRadius: 16,
                          padding: EdgeInsets.zero,
                          color: isDiscovered
                              ? const Color(0xFF1B2C4E).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.03),
                          border: Border.all(
                            color: isDiscovered
                                ? Colors.cyanAccent.withValues(alpha: 0.3)
                                : Colors.white12,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Thumbnail background if discovered
                                if (isDiscovered && userImage != null)
                                  Opacity(
                                    opacity: 0.35,
                                    child: Image.file(
                                      File(userImage),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        key,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: isDiscovered ? Colors.cyanAccent : Colors.white24,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppConstants.cloudFullNames[key] ?? '',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDiscovered ? Colors.white70 : Colors.white24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Lock indicator
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(
                                    isDiscovered ? Icons.check_circle : Icons.lock_outline,
                                    size: 14,
                                    color: isDiscovered ? Colors.greenAccent : Colors.white24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Title: Sky Journal
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 10),
                  child: Text(
                    'RECENT SNAP HISTORY',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              // Sky Journal snaps list
              _snaps.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_queue, color: Colors.white24, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Journal is Empty',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Scan clouds to populate your personal journal and encyclopedia.',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _openCamera,
                                icon: const Icon(Icons.radar),
                                label: const Text('Open Cloud Radar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // leaves space for FAB
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final snap = _snaps[index];
                            final timestamp = DateTime.tryParse(snap['timestamp'] ?? '') ?? DateTime.now();
                            final dateStr = '${timestamp.day}/${timestamp.month}/${timestamp.year} — ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
                            final isGuessCorrect = snap['isCorrect'] == true;
                            final guessText = snap['userGuess'] as String? ?? '';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: InkWell(
                                onTap: () => _viewSnap(snap),
                                onLongPress: () => _deleteSnap(snap['id']),
                                borderRadius: BorderRadius.circular(16),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Thumbnail
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(snap['imagePath']),
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Metadata
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${snap['predictionLabel']} — ${snap['predictionFullName']}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isGuessCorrect
                                                        ? Colors.green.withValues(alpha: 0.15)
                                                        : Colors.red.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: isGuessCorrect
                                                          ? Colors.green.withValues(alpha: 0.5)
                                                          : Colors.red.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isGuessCorrect
                                                        ? 'GUESS CORRECT 🎉'
                                                        : guessText.isEmpty
                                                            ? 'NO GUESS 💤'
                                                            : 'GUESS INACCURATE ❌',
                                                    style: TextStyle(
                                                      color: isGuessCorrect ? Colors.greenAccent : Colors.redAccent,
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Conf: ${(snap['confidence'] * 100).toStringAsFixed(1)}%',
                                                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontFamily: 'Courier'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                        onPressed: () => _deleteSnap(snap['id']),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _snaps.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _openCamera,
        shape: const CircleBorder(),
        backgroundColor: Colors.cyanAccent,
        elevation: 10,
        child: const Icon(Icons.radar, size: 36, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.black.withValues(alpha: 0.7),
        height: 60,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.dashboard_outlined, color: Colors.cyanAccent),
              onPressed: () {},
            ),
            const SizedBox(width: 48), // notch placeholder
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white30),
              onPressed: () {
                // Already displaying snaps list on dashboard
              },
            ),
          ],
        ),
      ),
    );
  }
}
