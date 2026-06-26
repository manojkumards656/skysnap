import 'package:flutter/material.dart';

class AltitudeChart extends StatefulWidget {
  final String activeCloudLabel;

  const AltitudeChart({
    super.key,
    required this.activeCloudLabel,
  });

  @override
  State<AltitudeChart> createState() => _AltitudeChartState();
}

class _AltitudeChartState extends State<AltitudeChart> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Cloud categories by altitude
  static const List<String> highClouds = ['Ci', 'Cc', 'Cs', 'Ct'];
  static const List<String> midClouds = ['Ac', 'As'];
  static const List<String> lowClouds = ['Cu', 'Ns', 'Sc', 'St'];
  // Cb is multi-altitude (spans all levels)

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getCloudFullName(String abbrev) {
    switch (abbrev) {
      case 'Ci': return 'Cirrus';
      case 'Cc': return 'Cirrocumulus';
      case 'Cs': return 'Cirrostratus';
      case 'Ct': return 'Contrails';
      case 'Ac': return 'Altocumulus';
      case 'As': return 'Altostratus';
      case 'Cu': return 'Cumulus';
      case 'Ns': return 'Nimbostratus';
      case 'Sc': return 'Stratocumulus';
      case 'St': return 'Stratus';
      case 'Cb': return 'Cumulonimbus';
      default: return abbrev;
    }
  }

  String _getAltitudeRange(String level) {
    if (level == 'HIGH') return '5,000 – 13,000 m\n(16,500 – 43,000 ft)';
    if (level == 'MID') return '2,000 – 6,000 m\n(6,500 – 20,000 ft)';
    if (level == 'LOW') return '0 – 2,000 m\n(0 – 6,500 ft)';
    return '500 – 16,000 m\n(1,600 – 52,000 ft)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String activeLabel = widget.activeCloudLabel;

    // Determine current cloud level
    String activeLevel = 'LOW';
    if (highClouds.contains(activeLabel)) {
      activeLevel = 'HIGH';
    } else if (midClouds.contains(activeLabel)) {
      activeLevel = 'MID';
    } else if (lowClouds.contains(activeLabel)) {
      activeLevel = 'LOW';
    } else if (activeLabel == 'Cb') {
      activeLevel = 'VERTICAL';
    }

    return Card(
      color: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'METEOROLOGICAL ALTITUDE CHART',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white70,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Level: $activeLevel',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Layout of the chart
            SizedBox(
              height: 320,
              child: Row(
                children: [
                  // Left column: Altitude scales
                  SizedBox(
                    width: 75,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildAltitudeScaleLabel('13,000 m', 'Tropopause'),
                        _buildAltitudeScaleLabel('5,000 m', 'Cirro- level'),
                        _buildAltitudeScaleLabel('2,000 m', 'Alto- level'),
                        _buildAltitudeScaleLabel('Sea Level', 'Surface'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),

                  // Middle column: Vertical Atmosphere Bar
                  Expanded(
                    child: Stack(
                      children: [
                        // Background Atmospheric gradient
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF0F0C20), // High altitude: Dark space
                                Color(0xFF241B45), // Mid altitude: Deep purple
                                Color(0xFF3B2E75), // Low altitude: Navy/Blue
                                Color(0xFF1E3C72), // Surface: Twilight blue
                              ],
                            ),
                          ),
                        ),

                        // Grid overlays/separators
                        Column(
                          children: [
                            Expanded(child: Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12, width: 1))))),
                            Expanded(child: Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12, width: 1))))),
                            Expanded(child: Container()),
                          ],
                        ),

                        // Vertical span for Cb (Cumulonimbus)
                        if (activeLabel == 'Cb')
                          Positioned(
                            top: 25,
                            bottom: 25,
                            left: 10,
                            right: 10,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.redAccent.withValues(alpha: _pulseAnimation.value),
                                      width: 1.5,
                                    ),
                                    color: Colors.redAccent.withValues(alpha: 0.1 * _pulseAnimation.value),
                                  ),
                                  child: const Center(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Text(
                                        'CUMULONIMBUS VERTICAL COLUMN',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // Interactive Level Slots
                        Column(
                          children: [
                            // High level
                            Expanded(
                              child: _buildAltitudeLevelZone(
                                levelName: 'HIGH',
                                clouds: highClouds,
                                activeLabel: activeLabel,
                                isLevelActive: activeLevel == 'HIGH',
                                theme: theme,
                              ),
                            ),
                            // Mid level
                            Expanded(
                              child: _buildAltitudeLevelZone(
                                levelName: 'MID',
                                clouds: midClouds,
                                activeLabel: activeLabel,
                                isLevelActive: activeLevel == 'MID',
                                theme: theme,
                              ),
                            ),
                            // Low level
                            Expanded(
                              child: _buildAltitudeLevelZone(
                                levelName: 'LOW',
                                clouds: lowClouds,
                                activeLabel: activeLabel,
                                isLevelActive: activeLevel == 'LOW',
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Bottom details info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_getCloudFullName(activeLabel)} ($activeLabel) occupies the $activeLevel atmosphere band:\n${_getAltitudeRange(activeLevel)}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAltitudeScaleLabel(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAltitudeLevelZone({
    required String levelName,
    required List<String> clouds,
    required String activeLabel,
    required bool isLevelActive,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: isLevelActive
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : Border.all(color: Colors.transparent),
        color: isLevelActive
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
      ),
      child: Stack(
        children: [
          // Background title of level
          Positioned(
            left: 8,
            top: 4,
            child: Text(
              levelName,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isLevelActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.6)
                    : Colors.white24,
                letterSpacing: 1.0,
              ),
            ),
          ),
          // Clouds inside
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: clouds.map((c) {
                  final isActive = c == activeLabel;
                  return Tooltip(
                    message: _getCloudFullName(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : isLevelActive
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive
                              ? Colors.white
                              : isLevelActive
                                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                  : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? Colors.black
                              : isLevelActive
                                  ? Colors.white
                                  : Colors.white38,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Pulsing active dot
          if (isLevelActive)
            Positioned(
              right: 6,
              top: 6,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: _pulseAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.8 * _pulseAnimation.value),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
