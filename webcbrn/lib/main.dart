// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const CbrnDashboardApp());
}

class CbrnDashboardApp extends StatelessWidget {
  const CbrnDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CBRN Tactical Command System',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F0D),
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38FF9C),
          secondary: Color(0xFF00D4FF),
          surface: Color(0xFF101915),
          error: Color(0xFFFF4D4F),
        ),
      ),
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

enum DrawingMode { none, zone, evac }

class _DashboardPageState extends State<DashboardPage> {
  final MapController mapController = MapController();
  final LatLng defaultCenter = const LatLng(51.505, -0.09);
  LatLng? currentLocation;

  String activeSection = 'overview';
  String role = 'commander';
  String selectedUnit = 'UAV-ALPHA-1';
  String layerType = 'standard';
  bool trackingOn = true;
  bool panMode = true;
  bool showTrails = false;
  bool incidentMode = false;
  String incidentSeverity = 'critical';
  String incidentNote = '';
  DrawingMode drawingMode = DrawingMode.none;
  final List<LatLng> drawingPoints = [];
  final List<LatLng> drawingRedoPoints = [];
  bool plumeOn = false;
  bool plumeSetMode = false;
  LatLng plumeSource = const LatLng(51.505, -0.09);
  double windDirection = 45;
  double windSpeed = 18;
  double plumeRangeKm = 3.0;
  bool showHeatmap = false;
  bool showRoutes = false;
  bool showGeofences = false;
  bool geofenceSetMode = false;
  bool mapControlsCollapsed = false;
  bool offlineMode = false;
  int syncQueue = 0;
  String commsChannel = 'Command';
  String commsDraft = '';
  final TextEditingController commsController = TextEditingController();

  final List<IncidentMarker> incidentMarkers = [];
  final List<ZonePolygon> zones = [];

  final List<SensorPoint> sensorPoints = [
    SensorPoint(location: LatLng(51.505, -0.09), intensity: 0.9),
    SensorPoint(location: LatLng(51.507, -0.093), intensity: 0.6),
    SensorPoint(location: LatLng(51.503, -0.088), intensity: 0.4),
    SensorPoint(location: LatLng(51.509, -0.096), intensity: 0.7),
    SensorPoint(location: LatLng(51.501, -0.084), intensity: 0.5),
  ];

  final List<MissionTask> missionTasks = [
    MissionTask(
      name: 'Recon Route A',
      priority: 'High',
      waypoints: [
        LatLng(51.505, -0.09),
        LatLng(51.507, -0.094),
        LatLng(51.509, -0.096),
      ],
    ),
    MissionTask(
      name: 'Supply Corridor B',
      priority: 'Medium',
      waypoints: [
        LatLng(51.502, -0.088),
        LatLng(51.504, -0.091),
        LatLng(51.506, -0.093),
      ],
    ),
  ];

  int selectedMissionIndex = 0;

  final List<GeofenceZone> geofences = [
    GeofenceZone(
      name: 'Perimeter A',
      center: LatLng(51.506, -0.092),
      radiusKm: 0.6,
    ),
  ];

  final List<AssetHealth> assets = [
    AssetHealth(name: 'UAV-ALPHA-1', health: 'Nominal', nextService: '36 hrs'),
    AssetHealth(name: 'UGV-DELTA-2', health: 'Degraded', nextService: '12 hrs'),
    AssetHealth(name: 'UAV-BRAVO-1', health: 'Nominal', nextService: '48 hrs'),
  ];

  final List<SopItem> sopChecklist = [
    SopItem(id: 1, label: 'Confirm hot zone perimeter'),
    SopItem(id: 2, label: 'Deploy decon corridor'),
    SopItem(id: 3, label: 'Establish medical triage'),
  ];

  final List<IncidentEvent> incidentEvents = [
    IncidentEvent(time: '00:00:12', message: 'Sensor trigger in Sector C-03'),
    IncidentEvent(time: '00:01:24', message: 'UAV-ALPHA-1 plume confirmation'),
  ];

  final List<AuditEntry> auditLog = [];

  final List<CommsMessage> commsMessages = [
    CommsMessage(
      channel: 'Command',
      sender: 'Ops',
      message: 'Stand by for plume update',
      time: '00:01:02',
    ),
    CommsMessage(
      channel: 'Medical',
      sender: 'Med-Lead',
      message: 'Triage team ready',
      time: '00:02:10',
    ),
  ];

  bool notificationSoundOn = true;
  final List<NotificationItem> notifications = [
    NotificationItem(
      id: 1,
      message: 'Perimeter sensor triggered · Sector C-03',
      time: '00:01:04',
    ),
    NotificationItem(
      id: 2,
      message: 'Team Bravo entered decon corridor',
      time: '00:02:20',
    ),
  ];

  final List<AlertItem> alertTimelineData = [
    AlertItem(
      id: 1,
      severity: 'critical',
      message: 'Chlorine plume detected · Sector A-12',
      time: '00:00:32',
    ),
    AlertItem(
      id: 2,
      severity: 'high',
      message: 'Biological sample positive · Zone B-05',
      time: '00:01:18',
    ),
    AlertItem(
      id: 3,
      severity: 'medium',
      message: 'Radiological spike · Checkpoint C-03',
      time: '00:02:52',
    ),
    AlertItem(
      id: 4,
      severity: 'low',
      message: 'Wind shift detected · Recalculate dispersal',
      time: '00:03:44',
    ),
  ];

  String timelineFilter = 'all';

  final Map<String, UnitInfo> unitData = {
    'UAV-ALPHA-1': UnitInfo(
      type: 'UAV',
      status: 'Active',
      battery: '98%',
      altitude: '320 m',
      speed: '41 km/h',
      signal: '92%',
    ),
    'UGV-DELTA-2': UnitInfo(
      type: 'UGV',
      status: 'Active',
      battery: '87%',
      altitude: 'N/A',
      speed: '18 km/h',
      signal: '78%',
    ),
    'UAV-BRAVO-1': UnitInfo(
      type: 'UAV',
      status: 'Standby',
      battery: '65%',
      altitude: '215 m',
      speed: 'Hovering',
      signal: '85%',
    ),
  };

  final Map<String, List<LatLng>> unitTrails = {
    'UAV-ALPHA-1': const [
      LatLng(51.505, -0.09),
      LatLng(51.506, -0.092),
      LatLng(51.507, -0.095),
      LatLng(51.508, -0.097),
    ],
    'UGV-DELTA-2': const [
      LatLng(51.503, -0.089),
      LatLng(51.502, -0.088),
      LatLng(51.501, -0.086),
    ],
    'UAV-BRAVO-1': const [
      LatLng(51.509, -0.091),
      LatLng(51.511, -0.093),
      LatLng(51.512, -0.096),
    ],
  };

  Map<String, List<SubstanceItem>> substanceDatabase = {
    'chemical': [
      SubstanceItem(
        name: 'Sarin',
        properties: 'Liquid, Volatile, Lethal',
        description: 'Nerve agent with rapid inhalation hazards.',
      ),
      SubstanceItem(
        name: 'Chlorine',
        properties: 'Gas, Greenish, Corrosive',
        description: 'Respiratory irritant with dense plume behavior.',
      ),
      SubstanceItem(
        name: 'VX',
        properties: 'Persistent, Oily',
        description: 'Extremely toxic nerve agent with surface persistence.',
      ),
    ],
    'biological': [
      SubstanceItem(
        name: 'Anthrax',
        properties: 'Spore-forming, Durable',
        description: 'Inhalational risk with long environmental persistence.',
      ),
      SubstanceItem(
        name: 'Ricin',
        properties: 'Toxin, Powder',
        description: 'Protein toxin derived from castor beans.',
      ),
      SubstanceItem(
        name: 'Botulinum',
        properties: 'Neurotoxin',
        description: 'Highly lethal toxin requiring rapid containment.',
      ),
    ],
    'radiological': [
      SubstanceItem(
        name: 'Cesium-137',
        properties: 'Radioactive, Long-lived',
        description: 'Gamma-emitting fission product.',
      ),
      SubstanceItem(
        name: 'Cobalt-60',
        properties: 'Radiation Source',
        description: 'Industrial source for irradiation.',
      ),
      SubstanceItem(
        name: 'Iodine-131',
        properties: 'Short-lived',
        description: 'Thyroid uptake risk after exposure.',
      ),
    ],
    'nuclear': [
      SubstanceItem(
        name: 'Uranium-235',
        properties: 'Fissile, Heavy metal',
        description: 'Criticality risk in enriched states.',
      ),
      SubstanceItem(
        name: 'Plutonium-239',
        properties: 'Fissile, Alpha emitter',
        description: 'Requires strict contamination controls.',
      ),
      SubstanceItem(
        name: 'Uranium-238',
        properties: 'Dense, Toxic',
        description: 'Depleted uranium handling protocols.',
      ),
    ],
  };

  String substanceFilter = 'all';
  String substanceSearch = '';

  @override
  void dispose() {
    commsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = unitData[selectedUnit]!;
    final bool isWide = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopbar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildSectionContent(isWide, unit),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF0F1412),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/irostech-logo.png', width: 60, height: 45),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CBRN Tactical',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Command System',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7C8B85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _navButton('Command Map', 'overview'),
          _navButton('Analysis', 'analysis'),
          _navButton('CBRN Substances', 'substances'),
          _navButton('Intelligence', 'intelligence'),
          _navButton('Planning', 'planning'),
          _navButton('Evacuation', 'evacuation'),
          _navButton('System Settings', 'settings'),
        ],
      ),
    );
  }

  Widget _navButton(String label, String section) {
    final bool active = activeSection == section;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: active
              ? const Color(0xFF16221C)
              : Colors.transparent,
          foregroundColor: active
              ? const Color(0xFF38FF9C)
              : const Color(0xFFE6F4EE),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.centerLeft,
        ),
        onPressed: () => setState(() => activeSection = section),
        child: Text(label),
      ),
    );
  }

  Widget _buildTopbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0F0D),
        border: Border(bottom: BorderSide(color: Color(0xFF1C2A24))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CBRN Tactical Command System',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                _StatusPill(text: 'Live Status · Updated 00:00:12'),
              ],
            ),
          ),
          const _StatusPill(text: 'DEFCON 3 · Round-the-clock watch'),
          const SizedBox(width: 12),
          _StatusPill(
            text: offlineMode
                ? 'Sync: Offline · Queue $syncQueue'
                : 'Sync: Online',
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: role,
            dropdownColor: const Color(0xFF101915),
            items: const [
              DropdownMenuItem(
                value: 'commander',
                child: Text('Role: Commander'),
              ),
              DropdownMenuItem(value: 'analyst', child: Text('Role: Analyst')),
              DropdownMenuItem(
                value: 'field',
                child: Text('Role: Field Operator'),
              ),
            ],
            onChanged: (value) => setState(() => role = value ?? 'commander'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(bool isWide, UnitInfo unit) {
    switch (activeSection) {
      case 'overview':
        return _buildOverviewSection(isWide, unit);
      case 'analysis':
        return _buildAnalysisSection();
      case 'substances':
        return _buildSubstancesSection();
      case 'intelligence':
        return _buildIntelligenceSection();
      case 'planning':
        return _buildPlanningSection();
      case 'evacuation':
        return _buildEvacuationSection();
      case 'settings':
        return _buildSettingsSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewSection(bool isWide, UnitInfo unit) {
    final content = Column(
      children: [
        _buildMapArea(),
        const SizedBox(height: 16),
        _grid(
          columns: 3,
          children: [
            _panel(
              title: 'Overlay Zones',
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: const [
                  _Chip(text: 'Risk Zone A-12'),
                  _Chip(text: 'POI: Lab Complex'),
                  _Chip(text: 'Alert Zone: C-03'),
                  _Chip(text: 'Movement Pattern Grid'),
                ],
              ),
            ),
            _panel(
              title: 'Active Alerts',
              child: Column(
                children: const [
                  _SeverityRow(
                    label: 'Critical',
                    value: '02',
                    severity: 'critical',
                  ),
                  _SeverityRow(label: 'High', value: '04', severity: 'high'),
                  _SeverityRow(
                    label: 'Medium',
                    value: '11',
                    severity: 'medium',
                  ),
                  _SeverityRow(label: 'Low', value: '23', severity: 'low'),
                ],
              ),
            ),
            _panel(
              title: 'Active Units',
              child: Column(
                children: const [
                  _ListRow(label: 'UAV-ALPHA-1', badge: 'Active'),
                  _ListRow(label: 'UGV-DELTA-2', badge: 'Returning'),
                  _ListRow(label: 'UAV-BRAVO-1', badge: 'Idle'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 3,
          children: [
            _panel(
              title: 'Incident Marker Workflow',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: incidentSeverity,
                          dropdownColor: const Color(0xFF101915),
                          items: const [
                            DropdownMenuItem(
                              value: 'critical',
                              child: Text('Severity: Critical'),
                            ),
                            DropdownMenuItem(
                              value: 'high',
                              child: Text('Severity: High'),
                            ),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text('Severity: Medium'),
                            ),
                            DropdownMenuItem(
                              value: 'low',
                              child: Text('Severity: Low'),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => incidentSeverity = value ?? 'critical',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => incidentMode = !incidentMode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: incidentMode
                              ? const Color(0xFF38FF9C)
                              : const Color(0xFF1C2A24),
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          incidentMode ? 'Add Incident: ON' : 'Add Incident',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Short incident note',
                    ),
                    onChanged: (value) => incidentNote = value,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mode: ${incidentMode ? 'On' : 'Off'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7C8B85),
                    ),
                  ),
                ],
              ),
            ),
            _panel(
              title: 'Alert Timeline',
              child: Column(
                children: [
                  DropdownButton<String>(
                    value: timelineFilter,
                    dropdownColor: const Color(0xFF101915),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(
                        value: 'critical',
                        child: Text('Critical'),
                      ),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                    ],
                    onChanged: (value) =>
                        setState(() => timelineFilter = value ?? 'all'),
                  ),
                  const SizedBox(height: 8),
                  ..._filteredAlerts().map(
                    (alert) => _TimelineRow(alert: alert),
                  ),
                ],
              ),
            ),
            _panel(
              title: 'Notification Center',
              child: Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(
                          () => notificationSoundOn = !notificationSoundOn,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C2A24),
                        ),
                        child: Text(
                          'Sound: ${notificationSoundOn ? 'On' : 'Off'}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleTestAlert,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C2A24),
                        ),
                        child: const Text('Test Alert'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...notifications.map(
                    (item) => _TimelineRow(notification: item),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'Data Export',
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _exportAlerts('json'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2A24),
                    ),
                    child: const Text('Alerts JSON'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _exportAlerts('csv'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2A24),
                    ),
                    child: const Text('Alerts CSV'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _exportUnitsJson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2A24),
                    ),
                    child: const Text('Units JSON'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              _buildTelemetryPanel(unit),
            ],
          )
        : Column(
            children: [
              content,
              const SizedBox(height: 20),
              _buildTelemetryPanel(unit),
            ],
          );
  }

  Widget _buildMapArea() {
    final polylines = showTrails
        ? unitTrails.values
              .map(
                (points) => Polyline(
                  points: points,
                  strokeWidth: 3,
                  color: const Color(0xFF38FF9C).withValues(alpha: 0.6),
                ),
              )
              .toList()
        : <Polyline>[];

    if (showRoutes && missionTasks.isNotEmpty) {
      final missionIndex =
          selectedMissionIndex.clamp(0, missionTasks.length - 1);
      final mission = missionTasks[missionIndex];
      polylines.add(
        Polyline(
          points: mission.waypoints,
          strokeWidth: 3,
          color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
        ),
      );
    }

    // Add preview polyline for drawing mode - show line connecting all points
    if (drawingMode != DrawingMode.none && drawingPoints.isNotEmpty) {
      final color = drawingMode == DrawingMode.zone
          ? const Color(0xFFFF4D4F)
          : const Color(0xFFFFB020);
      // If we have 2+ points, show the connecting lines
      if (drawingPoints.length >= 2) {
        polylines.add(
          Polyline(
            points: drawingPoints,
            strokeWidth: 3,
            color: color.withValues(alpha: 0.9),
          ),
        );
        // Also show closing line to first point
        polylines.add(
          Polyline(
            points: [drawingPoints.last, drawingPoints.first],
            strokeWidth: 2,
            color: color.withValues(alpha: 0.5),
          ),
        );
      }
    }

    final polygons = zones
        .map(
          (zone) => Polygon(
            points: zone.points,
            color: zone.color.withValues(alpha: 0.2),
            borderColor: zone.color,
            borderStrokeWidth: 2,
          ),
        )
        .toList();

    if (plumeOn) {
      polygons.add(
        Polygon(
          points: _buildPlumePolygon(plumeSource, windDirection, plumeRangeKm),
          color: const Color(0xFFFF7A45).withValues(alpha: 0.18),
          borderColor: const Color(0xFFFF7A45),
          borderStrokeWidth: 2,
        ),
      );
    }

    if (showGeofences) {
      for (final fence in geofences) {
        polygons.add(
          Polygon(
            points: _circlePolygon(fence.center, fence.radiusKm),
            color: const Color(0xFFFFB020).withValues(alpha: 0.12),
            borderColor: const Color(0xFFFFB020),
            borderStrokeWidth: 2,
          ),
        );
      }
    }

    final circles = <CircleMarker>[];
    if (showHeatmap) {
      for (final sensor in sensorPoints) {
        circles.add(
          CircleMarker(
            point: sensor.location,
            radius: 30 * sensor.intensity + 10,
            color: const Color(
              0xFFFF4D4F,
            ).withValues(alpha: 0.15 + (0.35 * sensor.intensity)),
            borderColor: const Color(0xFFFF4D4F).withValues(alpha: 0.4),
            borderStrokeWidth: 1,
          ),
        );
      }
    }

    final markers = <Marker>[
      if (currentLocation != null)
        Marker(
          point: currentLocation!,
          width: 28,
          height: 28,
          child: const Icon(Icons.my_location, color: Color(0xFF38FF9C)),
        ),
      if (plumeOn || plumeSetMode)
        Marker(
          point: plumeSource,
          width: 22,
          height: 22,
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF7A45),
          ),
        ),
      ...incidentMarkers.map(
        (incident) => Marker(
          point: incident.location,
          width: 20,
          height: 20,
          child: Tooltip(
            message: incident.note,
            child: Container(
              decoration: BoxDecoration(
                color: _severityColor(incident.severity),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
      // Add markers for drawing points
      ...drawingPoints.asMap().entries.map((entry) {
        final color = drawingMode == DrawingMode.zone
            ? const Color(0xFFFF4D4F)
            : const Color(0xFFFFB020);
        return Marker(
          point: entry.value,
          width: 16,
          height: 16,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${entry.key + 1}',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    ];

    return SizedBox(
      height: 460,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: defaultCenter,
                initialZoom: 13,
                onTap: (tapPosition, latLng) => _handleMapTap(latLng),
                interactionOptions: InteractionOptions(
                  flags: _interactiveFlags(),
                ),
              ),
              children: [
                _tileLayer(),
                PolygonLayer(polygons: polygons),
                PolylineLayer(polylines: polylines),
                CircleLayer(circles: circles),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          Positioned(top: 16, left: 16, child: _zoomButtons()),
          Positioned(
            top: 16,
            right: 16,
            child: SingleChildScrollView(
              child: _mapControls(),
            ),
          ),
          Positioned(bottom: 16, left: 16, child: _mapLocateButton()),
          Positioned(bottom: 16, right: 16, child: _mapTools()),
        ],
      ),
    );
  }

  Widget _zoomButtons() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101915).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1C2A24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(mapController.camera.center, currentZoom + 1);
            },
            icon: const Icon(Icons.add, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1C2A24),
              foregroundColor: const Color(0xFFE6F4EE),
            ),
          ),
          const SizedBox(height: 1),
          IconButton(
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(mapController.camera.center, currentZoom - 1);
            },
            icon: const Icon(Icons.remove, size: 20),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1C2A24),
              foregroundColor: const Color(0xFFE6F4EE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControls() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 160),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF101915).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1C2A24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Map Controls',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => mapControlsCollapsed = !mapControlsCollapsed),
                  icon: Icon(
                    mapControlsCollapsed ? Icons.expand_more : Icons.expand_less,
                    size: 16,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (!mapControlsCollapsed) ...[
            const SizedBox(height: 6),
            _mapButton(
              label: 'Pan Mode',
              active: panMode,
              onPressed: drawingMode != DrawingMode.none
                  ? () {} // Disabled during drawing mode
                  : () => setState(() => panMode = !panMode),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: 'Layer: Standard',
              active: layerType == 'standard',
              onPressed: () => setState(() => layerType = 'standard'),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: 'Layer: Satellite',
              active: layerType == 'satellite',
              onPressed: () => setState(() => layerType = 'satellite'),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: 'Layer: Terrain',
              active: layerType == 'terrain',
              onPressed: () => setState(() => layerType = 'terrain'),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: 'Tracking: ${trackingOn ? 'ON' : 'OFF'}',
              active: trackingOn,
              onPressed: () => setState(() => trackingOn = !trackingOn),
            ),
            const SizedBox(height: 6),
            const Text(
              'CBRN Overlays',
              style: TextStyle(fontSize: 10, color: Color(0xFF7C8B85)),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: 'Plume: ${plumeOn ? 'ON' : 'OFF'}',
              active: plumeOn,
              onPressed: () => setState(() => plumeOn = !plumeOn),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: plumeSetMode ? 'Click Map: Set Source' : 'Set Plume Source',
              active: plumeSetMode,
              onPressed: () => setState(() => plumeSetMode = !plumeSetMode),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: 'Heatmap: ${showHeatmap ? 'ON' : 'OFF'}',
              active: showHeatmap,
              onPressed: () => setState(() => showHeatmap = !showHeatmap),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: 'Routes: ${showRoutes ? 'ON' : 'OFF'}',
              active: showRoutes,
              onPressed: () => setState(() => showRoutes = !showRoutes),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: 'Geofences: ${showGeofences ? 'ON' : 'OFF'}',
              active: showGeofences,
              onPressed: () => setState(() => showGeofences = !showGeofences),
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: geofenceSetMode ? 'Click Map: Add' : 'Add Geofence',
              active: geofenceSetMode,
              onPressed: () => setState(() => geofenceSetMode = !geofenceSetMode),
            ),
            const SizedBox(height: 6),
            const Text(
              'Wind Direction',
              style: TextStyle(fontSize: 10, color: Color(0xFF7C8B85)),
            ),
            Slider(
              value: windDirection,
              min: 0,
              max: 360,
              divisions: 36,
              onChanged: (value) => setState(() => windDirection = value),
            ),
            const Text(
              'Wind Speed (km/h)',
              style: TextStyle(fontSize: 10, color: Color(0xFF7C8B85)),
            ),
            Slider(
              value: windSpeed,
              min: 1,
              max: 60,
              divisions: 59,
              onChanged: (value) => setState(() => windSpeed = value),
            ),
            const Text(
              'Plume Range (km)',
              style: TextStyle(fontSize: 10, color: Color(0xFF7C8B85)),
            ),
            Slider(
              value: plumeRangeKm,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => setState(() => plumeRangeKm = value),
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mapLocateButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101915).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1C2A24)),
      ),
      child: IconButton(
        onPressed: _locateUser,
        icon: const Text('📍', style: TextStyle(fontSize: 18)),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _mapTools() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF101915).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1C2A24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Map Tools',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _mapButton(
            label: drawingMode == DrawingMode.zone
                ? 'Finish Zone'
                : 'Draw Zone',
            active: drawingMode == DrawingMode.zone,
            onPressed: () => _toggleDrawingMode(DrawingMode.zone),
          ),
          const SizedBox(height: 4),
          _mapButton(
            label: drawingMode == DrawingMode.evac
                ? 'Finish Evac'
                : 'Draw Evac Zone',
            active: drawingMode == DrawingMode.evac,
            onPressed: () => _toggleDrawingMode(DrawingMode.evac),
          ),
          if (drawingMode != DrawingMode.none) ...[
            const SizedBox(height: 4),
            _mapButton(
              label: 'Undo Point',
              active: false,
              onPressed: drawingPoints.isEmpty ? null : _undoDrawingPoint,
            ),
            const SizedBox(height: 4),
            _mapButton(
              label: 'Redo Point',
              active: false,
              onPressed: drawingRedoPoints.isEmpty ? null : _redoDrawingPoint,
            ),
          ],
          const SizedBox(height: 4),
          _mapButton(
            label: 'Clear Zones',
            active: false,
            danger: true,
            onPressed: role == 'commander' ? _confirmClearZones : null,
          ),
          const SizedBox(height: 4),
          _mapButton(
            label: showTrails ? 'Hide Trails' : 'Show Trails',
            active: showTrails,
            onPressed: () => setState(() => showTrails = !showTrails),
          ),
          const SizedBox(height: 4),
          _mapButton(
            label: 'Check Geofences',
            active: false,
            onPressed: _checkGeofences,
          ),
          if (drawingMode != DrawingMode.none)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Click map · ${drawingPoints.length} pts',
                style: const TextStyle(fontSize: 10, color: Color(0xFF7C8B85)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapMiniButton({
    required String label,
    required bool active,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: active
              ? const Color(0xFF38FF9C)
              : const Color(0xFF1C2A24),
          foregroundColor: active ? Colors.black : const Color(0xFFE6F4EE),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 10)),
      ),
    );
  }

  Widget _mapButton({
    required String label,
    required bool active,
    VoidCallback? onPressed,
    bool danger = false,
  }) {
    return SizedBox(
      width: 140,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: danger
              ? const Color(0xFFFF4D4F)
              : active
              ? const Color(0xFF38FF9C)
              : const Color(0xFF1C2A24),
          foregroundColor: danger || active
              ? Colors.black
              : const Color(0xFFE6F4EE),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildTelemetryPanel(UnitInfo unit) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101915),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C2A24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Units & Telemetry',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedUnit,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${unit.type} · ${unit.status}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C8B85),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C2A24),
                ),
                child: const Text('Focus'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _telemetryRow('Battery', unit.battery),
          _telemetryRow('Altitude', unit.altitude),
          _telemetryRow('Speed', unit.speed),
          _telemetryRow('Signal Strength', unit.signal),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: selectedUnit,
            dropdownColor: const Color(0xFF101915),
            items: unitData.keys
                .map((key) => DropdownMenuItem(value: key, child: Text(key)))
                .toList(),
            onChanged: (value) =>
                setState(() => selectedUnit = value ?? selectedUnit),
          ),
        ],
      ),
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF7C8B85)),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Column(
      children: [
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'Mission Performance & Operational Metrics',
              child: _grid(
                columns: 2,
                children: const [
                  _Metric(label: 'Total Missions', value: '184'),
                  _Metric(label: 'Success Rate', value: '93%'),
                  _Metric(label: 'Avg Response Time', value: '4.6 min'),
                  _Metric(label: 'Total Distance', value: '8,240 km'),
                ],
              ),
            ),
            _panel(
              title: 'Mission Distribution',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Chip(text: 'Surveillance 44%'),
                      _Chip(text: 'Reconnaissance 26%'),
                      _Chip(text: 'Search & Rescue 18%'),
                      _Chip(text: 'Evacuation 12%'),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Pie/Bar visualization placeholder',
                    style: TextStyle(color: Color(0xFF7C8B85)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'Alert Statistics',
              child: Column(
                children: const [
                  _SeverityRow(
                    label: 'Critical',
                    value: '12',
                    severity: 'critical',
                  ),
                  _SeverityRow(label: 'High', value: '25', severity: 'high'),
                  _SeverityRow(
                    label: 'Medium',
                    value: '41',
                    severity: 'medium',
                  ),
                  _SeverityRow(label: 'Low', value: '78', severity: 'low'),
                ],
              ),
            ),
            _panel(
              title: 'Trend Analysis Charts',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _ListRow(label: 'CBRN Detection Trends'),
                  _ListRow(label: 'Alert Frequency Analysis'),
                  _ListRow(label: 'Robot Performance Metrics'),
                  SizedBox(height: 12),
                  Text(
                    'Line/area chart placeholders',
                    style: TextStyle(color: Color(0xFF7C8B85)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'Asset Health & Maintenance',
              child: Column(
                children: assets
                    .map(
                      (asset) => _ListRow(
                        label: '${asset.name} · ${asset.health}',
                        badge: 'Service ${asset.nextService}',
                      ),
                    )
                    .toList(),
              ),
            ),
            _panel(
              title: 'Sensor Fusion Status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Sensors: ${sensorPoints.length}',
                    style: const TextStyle(color: Color(0xFF7C8B85)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Heatmap Overlay: ${showHeatmap ? 'Enabled' : 'Disabled'}',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => showHeatmap = !showHeatmap),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2A24),
                    ),
                    child: Text(
                      showHeatmap ? 'Disable Heatmap' : 'Enable Heatmap',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubstancesSection() {
    final filtered = _filteredSubstances();
    return Column(
      children: [
        _panel(
          title: 'CBRN Substances Database',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _filterChip('All', 'all'),
                  _filterChip('Chem', 'chemical'),
                  _filterChip('Bio', 'biological'),
                  _filterChip('Rad', 'radiological'),
                  _filterChip('Nuc', 'nuclear'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search substances...',
                ),
                onChanged: (value) => setState(() => substanceSearch = value),
              ),
              const SizedBox(height: 12),
              _grid(
                columns: 2,
                children: filtered
                    .map(
                      (item) => _panel(
                        title: item.name,
                        compact: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.properties,
                              style: const TextStyle(
                                color: Color(0xFF38FF9C),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              style: const TextStyle(color: Color(0xFF7C8B85)),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _importSubstances,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2A24),
                    ),
                    child: const Text('Import'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _exportSubstances,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2A24),
                    ),
                    child: const Text('Export'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _showAddSubstanceDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2A24),
                    ),
                    child: const Text('Add Substance'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final active = substanceFilter == value;
    return GestureDetector(
      onTap: () => setState(() => substanceFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF38FF9C) : const Color(0xFF1C2A24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : const Color(0xFFE6F4EE),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildIntelligenceSection() {
    return Column(
      children: [
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'DEFCON Level Control',
              child: Column(
                children: const [
                  _ListRow(
                    label: 'Current Level: DEFCON 3',
                    badge: 'Round-the-clock watch',
                  ),
                  _ListRow(label: 'Level Selector: DEFCON 1 - 5'),
                ],
              ),
            ),
            _panel(
              title: 'Intelligence Sources',
              child: Column(
                children: const [
                  _ListRow(label: 'Satellite KH-11 · Live feed'),
                  _ListRow(label: 'Local Asset - 7 · Field report'),
                  _ListRow(label: 'SIGINT Node-3 · Threat chatter'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'Target Identification',
              child: Column(
                children: const [
                  _ListRow(
                    label: 'Target: Bio Lab 14 · Classification: High Risk',
                  ),
                  _ListRow(
                    label: 'Target: Cargo Bay 3 · Classification: Medium',
                  ),
                  _ListRow(label: 'Target: Water Plant · Classification: Low'),
                ],
              ),
            ),
            _panel(
              title: 'Intel Timeline',
              child: Column(
                children: const [
                  _ListRow(
                    label: '12:01:22 · Satellite KH-11 detected movement',
                  ),
                  _ListRow(
                    label: '12:03:10 · UAV-ALPHA-1 confirmed CBRN plume',
                  ),
                  _ListRow(label: '12:05:18 · Alert Level elevated to High'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'Comms Center',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: commsChannel,
                    dropdownColor: const Color(0xFF101915),
                    items: const [
                      DropdownMenuItem(
                        value: 'Command',
                        child: Text('Channel: Command'),
                      ),
                      DropdownMenuItem(
                        value: 'Operations',
                        child: Text('Channel: Operations'),
                      ),
                      DropdownMenuItem(
                        value: 'Medical',
                        child: Text('Channel: Medical'),
                      ),
                      DropdownMenuItem(
                        value: 'Hazmat',
                        child: Text('Channel: Hazmat'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => commsChannel = value ?? 'Command'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commsController,
                    decoration: const InputDecoration(
                      hintText: 'Type priority update...',
                    ),
                    onChanged: (value) => commsDraft = value,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _sendCommsMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2A24),
                    ),
                    child: const Text('Send Message'),
                  ),
                  const SizedBox(height: 10),
                  ...commsMessages
                      .where((msg) => msg.channel == commsChannel)
                      .take(6)
                      .map(
                        (msg) => _ListRow(
                          label: '${msg.time} · ${msg.sender}: ${msg.message}',
                        ),
                      ),
                ],
              ),
            ),
            _panel(
              title: 'Incident Timeline & Export',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...incidentEvents.map(
                    (e) => _ListRow(label: '${e.time} · ${e.message}'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _exportIncidentTimeline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C2A24),
                    ),
                    child: const Text('Export After-Action JSON'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanningSection() {
    return Column(
      children: [
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'Mission Tasking & Route Optimization',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<int>(
                    value: selectedMissionIndex,
                    dropdownColor: const Color(0xFF101915),
                    items: missionTasks
                        .asMap()
                        .entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              '${entry.value.name} · ${entry.value.priority}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedMissionIndex = value ?? 0),
                  ),
                  const SizedBox(height: 8),
                  _mapButton(
                    label: showRoutes ? 'Hide Route' : 'Show Route',
                    active: showRoutes,
                    onPressed: () => setState(() => showRoutes = !showRoutes),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Waypoints: ${missionTasks[selectedMissionIndex].waypoints.length}',
                    style: const TextStyle(color: Color(0xFF7C8B85)),
                  ),
                ],
              ),
            ),
            _panel(
              title: 'Mission Templates',
              child: Column(
                children: const [
                  _ListRow(
                    label: 'Surveillance · 3 UAV + 2 UGV · Risk: Medium',
                  ),
                  _ListRow(label: 'Extraction · 2 UGV + Support · Risk: High'),
                  _ListRow(label: 'Reconnaissance · 2 UAV · Risk: Low'),
                  _ListRow(label: 'Hazmat Containment · 1 UGV · Risk: High'),
                ],
              ),
            ),
            _panel(
              title: 'Planner & Waypoints',
              child: Column(
                children: const [
                  _ListRow(label: 'WP-1 · Entry Corridor'),
                  _ListRow(label: 'WP-2 · Sample Extraction'),
                  _ListRow(label: 'WP-3 · Decon Zone'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 3,
          children: [
            _panel(
              title: 'Mission Playbooks',
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: const [
                  _Chip(text: 'Evacuation'),
                  _Chip(text: 'Decontamination'),
                  _Chip(text: 'Triage'),
                  _Chip(text: 'Perimeter Lockdown'),
                ],
              ),
            ),
            _panel(
              title: 'Playbook Checklist',
              child: Column(
                children: const [
                  _ListRow(label: 'Confirm evacuation corridor'),
                  _ListRow(label: 'Deploy decon units'),
                  _ListRow(label: 'Seal HVAC intakes'),
                ],
              ),
            ),
            _panel(
              title: 'Rules of Engagement',
              child: Column(
                children: const [
                  _ListRow(label: 'Non-lethal priority'),
                  _ListRow(label: 'Civilian corridor protection'),
                  _ListRow(label: 'Escalation authorized by Commander'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'Routes (Mission Queue)',
              child: Column(
                children: const [
                  _ListRow(label: 'Queue #1 · Recon Route A'),
                  _ListRow(label: 'Queue #2 · Supply Corridor B'),
                ],
              ),
            ),
            _panel(
              title: 'Resource Staging',
              child: Column(
                children: const [
                  _ListRow(label: 'UGV Support: Ready'),
                  _ListRow(label: 'Hazmat Kits: 12 available'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'SOP Checklist & Acknowledgments',
              child: Column(
                children: sopChecklist
                    .map(
                      (item) => Row(
                        children: [
                          Expanded(child: Text(item.label)),
                          if (item.acknowledged)
                            Text(
                              item.ackTime ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7C8B85),
                              ),
                            )
                          else
                            TextButton(
                              onPressed: () => _ackSopItem(item.id),
                              child: const Text('Acknowledge'),
                            ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
            _panel(
              title: 'Geofence Management',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Geofences: ${geofences.length}'),
                  const SizedBox(height: 8),
                  _mapButton(
                    label: geofenceSetMode
                        ? 'Click Map to Add'
                        : 'Add Geofence',
                    active: geofenceSetMode,
                    onPressed: () =>
                        setState(() => geofenceSetMode = !geofenceSetMode),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEvacuationSection() {
    return Column(
      children: [
        _grid(
          columns: 4,
          children: [
            _panel(
              title: 'Evac Routes',
              compact: true,
              child: const _ListRow(label: 'Route Alpha · Clear'),
            ),
            _panel(
              title: 'Shelter Zones',
              compact: true,
              child: const _ListRow(label: 'Shelter B · 70% capacity'),
            ),
            _panel(
              title: 'Transport Assets',
              compact: true,
              child: const _ListRow(label: 'Vehicles · 12 ready'),
            ),
            _panel(
              title: 'Medical',
              compact: true,
              child: const _ListRow(label: 'Med Teams · 5 active'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _grid(
          columns: 2,
          children: [
            _panel(
              title: 'Evacuation Timeline',
              child: const _ListRow(label: '00:10 · Zone A cleared'),
            ),
            _panel(
              title: 'Resource Summary',
              child: const _ListRow(label: 'Supplies · 4 convoys inbound'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return _grid(
      columns: 2,
      children: [
        _panel(
          title: 'System Configuration',
          child: Column(
            children: const [
              _ListRow(label: 'Telemetry Refresh · 5s'),
              _ListRow(label: 'Map Cache · Enabled'),
            ],
          ),
        ),
        _panel(
          title: 'User Preferences',
          child: Column(
            children: const [
              _ListRow(label: 'Theme · Tactical Dark'),
              _ListRow(label: 'Notifications · Enabled'),
            ],
          ),
        ),
        _panel(
          title: 'Role Permissions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Role: $role'),
              const SizedBox(height: 8),
              Text(
                'Clear Zones: ${role == 'commander' ? 'Allowed' : 'Restricted'}',
              ),
              const SizedBox(height: 4),
              Text(
                'Export Data: ${role == 'commander' || role == 'analyst' ? 'Allowed' : 'Restricted'}',
              ),
            ],
          ),
        ),
        _panel(
          title: 'Offline / Edge Sync',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Offline Mode')),
                  Switch(
                    value: offlineMode,
                    onChanged: (value) => setState(() => offlineMode = value),
                  ),
                ],
              ),
              Text('Queue: $syncQueue event(s)'),
            ],
          ),
        ),
        _panel(
          title: 'Audit Log',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: auditLog
                .take(6)
                .map(
                  (entry) => _ListRow(
                    label: '${entry.time} · ${entry.actor} · ${entry.action}',
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _grid({required int columns, required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int adjustedColumns = width < 800
            ? 1
            : width < 1200
            ? (columns > 2 ? 2 : columns)
            : columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children
              .map(
                (child) => SizedBox(
                  width:
                      (width - (16 * (adjustedColumns - 1))) / adjustedColumns,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _panel({
    required String title,
    required Widget child,
    bool compact = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101915),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C2A24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (compact)
            DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 12),
              child: child,
            )
          else
            child,
        ],
      ),
    );
  }

  List<AlertItem> _filteredAlerts() {
    if (timelineFilter == 'all') return alertTimelineData;
    return alertTimelineData
        .where((alert) => alert.severity == timelineFilter)
        .toList();
  }

  List<SubstanceItem> _filteredSubstances() {
    final allItems = <SubstanceItem>[];
    if (substanceFilter == 'all') {
      substanceDatabase.forEach((_, items) => allItems.addAll(items));
    } else {
      allItems.addAll(substanceDatabase[substanceFilter] ?? []);
    }
    if (substanceSearch.trim().isEmpty) return allItems;
    final term = substanceSearch.toLowerCase();
    return allItems
        .where(
          (item) =>
              item.name.toLowerCase().contains(term) ||
              item.properties.toLowerCase().contains(term) ||
              item.description.toLowerCase().contains(term),
        )
        .toList();
  }

  int _interactiveFlags() {
    if (drawingMode != DrawingMode.none) {
      // During drawing: allow zoom but not drag
      return InteractiveFlag.pinchZoom |
          InteractiveFlag.scrollWheelZoom |
          InteractiveFlag.doubleTapZoom;
    }
    // Normal mode: explicitly enable all interactions including drag
    return InteractiveFlag.drag |
        InteractiveFlag.flingAnimation |
        InteractiveFlag.pinchMove |
        InteractiveFlag.pinchZoom |
        InteractiveFlag.doubleTapZoom |
        InteractiveFlag.doubleTapDragZoom |
        InteractiveFlag.scrollWheelZoom;
  }

  Widget _tileLayer() {
    switch (layerType) {
      case 'satellite':
        return TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.irostech.webcbrn',
        );
      case 'terrain':
        return TileLayer(
          urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.irostech.webcbrn',
        );
      case 'standard':
      default:
        return TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.irostech.webcbrn',
        );
    }
  }

  void _locateUser() {
    if (!kIsWeb) return;
    html.window.navigator.geolocation
        .getCurrentPosition()
        .then((position) {
          final coords = position.coords;
          final lat = coords?.latitude?.toDouble() ?? defaultCenter.latitude;
          final lng = coords?.longitude?.toDouble() ?? defaultCenter.longitude;
          setState(() {
            currentLocation = LatLng(lat, lng);
          });
          if (currentLocation != null) {
            mapController.move(currentLocation!, 14);
          }
        })
        .catchError((_) {
          setState(() => currentLocation = defaultCenter);
          mapController.move(defaultCenter, 13);
        });
  }

  void _handleMapTap(LatLng latLng) {
    if (plumeSetMode) {
      setState(() {
        plumeSource = latLng;
        plumeSetMode = false;
      });
      _logAction('Plume source set');
      return;
    }

    if (geofenceSetMode) {
      setState(() {
        geofences.add(
          GeofenceZone(
            name: 'Geofence ${geofences.length + 1}',
            center: latLng,
            radiusKm: 0.5,
          ),
        );
        geofenceSetMode = false;
        showGeofences = true;
      });
      _logAction('Geofence added');
      return;
    }

    if (incidentMode) {
      setState(() {
        incidentMarkers.add(
          IncidentMarker(
            location: latLng,
            severity: incidentSeverity,
            note: incidentNote.isEmpty ? 'Incident marker' : incidentNote,
          ),
        );
        incidentEvents.insert(
          0,
          IncidentEvent(
            time: _formatNow(),
            message:
                'Incident: ${incidentNote.isEmpty ? 'Marker added' : incidentNote}',
          ),
        );
        incidentNote = '';
      });
      _logAction('Incident marker added');
      return;
    }

    if (drawingMode != DrawingMode.none) {
      setState(() {
        drawingPoints.add(latLng);
        drawingRedoPoints.clear();
      });
    }
  }

  void _undoDrawingPoint() {
    if (drawingPoints.isEmpty) return;
    setState(() {
      final last = drawingPoints.removeLast();
      drawingRedoPoints.add(last);
    });
  }

  void _redoDrawingPoint() {
    if (drawingRedoPoints.isEmpty) return;
    setState(() {
      final last = drawingRedoPoints.removeLast();
      drawingPoints.add(last);
    });
  }

  void _toggleDrawingMode(DrawingMode mode) {
    setState(() {
      if (drawingMode == mode) {
        if (drawingPoints.length >= 3) {
          final color = mode == DrawingMode.zone
              ? const Color(0xFFFF4D4F)
              : const Color(0xFFFFB020);
          zones.add(ZonePolygon(points: List.of(drawingPoints), color: color));
          _logAction(
            mode == DrawingMode.zone ? 'Zone created' : 'Evac zone created',
          );
        }
        drawingPoints.clear();
        drawingRedoPoints.clear();
        drawingMode = DrawingMode.none;
        panMode = true; // Re-enable pan mode when exiting drawing
      } else {
        drawingPoints.clear();
        drawingRedoPoints.clear();
        drawingMode = mode;
        panMode = false; // Disable pan mode when entering drawing
        _logAction(
          mode == DrawingMode.zone
              ? 'Zone drawing started'
              : 'Evac drawing started',
        );
      }
    });
  }

  Future<void> _confirmClearZones() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101915),
          title: const Text('Clear all zones?'),
          content: const Text(
            'This will remove all drawn zones and reset the current drawing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        zones.clear();
        drawingPoints.clear();
        drawingRedoPoints.clear();
      });
      _logAction('Zones cleared');
    }
  }

  void _handleTestAlert() {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch,
      message: 'Test alert triggered by operator',
      time: _formatNow(),
    );
    setState(() => notifications.insert(0, newItem));
    if (notificationSoundOn) {
      _playNotificationSound();
    }
  }

  void _playNotificationSound() {
    if (!kIsWeb) return;
    final bytes = _generateBeepWavBytes();
    final blob = html.Blob([bytes], 'audio/wav');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(url)..volume = 0.2;
    audio.play();
    audio.onEnded.first.then((_) => html.Url.revokeObjectUrl(url));
  }

  void _exportAlerts(String format) {
    if (format == 'json') {
      final payload = jsonEncode(
        alertTimelineData.map((e) => e.toJson()).toList(),
      );
      _downloadFile('alerts.json', payload, 'application/json');
      return;
    }
    final rows = ['id,severity,message,time'];
    for (final alert in alertTimelineData) {
      rows.add(
        '${alert.id},${alert.severity},"${alert.message}",${alert.time}',
      );
    }
    _downloadFile('alerts.csv', rows.join('\n'), 'text/csv');
  }

  void _exportUnitsJson() {
    final payload = jsonEncode(
      unitData.map((key, value) => MapEntry(key, value.toJson())),
    );
    _downloadFile('units.json', payload, 'application/json');
  }

  void _exportSubstances() {
    final payload = jsonEncode(
      substanceDatabase.map(
        (key, value) =>
            MapEntry(key, value.map((item) => item.toJson()).toList()),
      ),
    );
    _downloadFile('substances.json', payload, 'application/json');
  }

  Future<void> _importSubstances() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    String? contents;
    if (file.bytes != null) {
      contents = utf8.decode(file.bytes!);
    }
    if (contents == null) return;
    final decoded = jsonDecode(contents) as Map<String, dynamic>;
    final updated = <String, List<SubstanceItem>>{};
    decoded.forEach((key, value) {
      final list = (value as List)
          .map((item) => SubstanceItem.fromJson(item))
          .toList();
      updated[key] = list;
    });
    setState(() => substanceDatabase = updated);
  }

  void _showAddSubstanceDialog() {
    final nameController = TextEditingController();
    final propertiesController = TextEditingController();
    final descriptionController = TextEditingController();
    String category = 'chemical';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101915),
          title: const Text('Add New Substance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Substance Name'),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: category,
                dropdownColor: const Color(0xFF101915),
                items: const [
                  DropdownMenuItem(value: 'chemical', child: Text('Chemical')),
                  DropdownMenuItem(
                    value: 'biological',
                    child: Text('Biological'),
                  ),
                  DropdownMenuItem(
                    value: 'radiological',
                    child: Text('Radiological'),
                  ),
                  DropdownMenuItem(value: 'nuclear', child: Text('Nuclear')),
                ],
                onChanged: (value) => category = value ?? 'chemical',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: propertiesController,
                decoration: const InputDecoration(labelText: 'Properties'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final item = SubstanceItem(
                  name: nameController.text.trim(),
                  properties: propertiesController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                if (item.name.isEmpty) return;
                setState(() {
                  substanceDatabase[category] = [
                    ...(substanceDatabase[category] ?? []),
                    item,
                  ];
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _downloadFile(String filename, String content, String mimeType) {
    if (!kIsWeb) return;
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  List<LatLng> _buildPlumePolygon(
    LatLng source,
    double directionDeg,
    double rangeKm,
  ) {
    final spreadDeg = 50.0;
    final left = (directionDeg - spreadDeg / 2) * (pi / 180);
    final right = (directionDeg + spreadDeg / 2) * (pi / 180);
    final distance = rangeKm + (windSpeed / 30);
    final leftPoint = _offsetLatLng(source, distance, left);
    final rightPoint = _offsetLatLng(source, distance, right);
    final midPoint = _offsetLatLng(
      source,
      distance * 0.75,
      directionDeg * (pi / 180),
    );
    return [source, leftPoint, midPoint, rightPoint];
  }

  List<LatLng> _circlePolygon(LatLng center, double radiusKm) {
    const points = 32;
    final coords = <LatLng>[];
    for (int i = 0; i < points; i++) {
      final angle = (2 * pi * i) / points;
      coords.add(_offsetLatLng(center, radiusKm, angle));
    }
    return coords;
  }

  LatLng _offsetLatLng(LatLng origin, double distanceKm, double bearingRad) {
    const earthRadiusKm = 6371.0;
    final lat1 = origin.latitudeInRad;
    final lon1 = origin.longitudeInRad;
    final angularDistance = distanceKm / earthRadiusKm;

    final lat2 = asin(
      sin(lat1) * cos(angularDistance) +
          cos(lat1) * sin(angularDistance) * cos(bearingRad),
    );
    final lon2 =
        lon1 +
        atan2(
          sin(bearingRad) * sin(angularDistance) * cos(lat1),
          cos(angularDistance) - sin(lat1) * sin(lat2),
        );

    return LatLng(lat2 * 180 / pi, lon2 * 180 / pi);
  }

  void _checkGeofences() {
    int hits = 0;
    for (final fence in geofences) {
      for (final entry in unitTrails.entries) {
        final point = entry.value.isNotEmpty ? entry.value.last : null;
        if (point == null) continue;
        final distance = const Distance().as(
          LengthUnit.Kilometer,
          fence.center,
          point,
        );
        if (distance <= fence.radiusKm) {
          hits++;
          notifications.insert(
            0,
            NotificationItem(
              id: DateTime.now().millisecondsSinceEpoch,
              message: 'Geofence breach: ${fence.name} by ${entry.key}',
              time: _formatNow(),
            ),
          );
        }
      }
    }
    if (hits > 0) {
      _logAction('Geofence check: $hits breach(es) detected');
    } else {
      _logAction('Geofence check: no breaches');
    }
    setState(() {});
  }

  void _logAction(String action) {
    auditLog.insert(
      0,
      AuditEntry(time: _formatNow(), action: action, actor: role),
    );
    if (offlineMode) {
      syncQueue += 1;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _exportIncidentTimeline() {
    final payload = jsonEncode(incidentEvents.map((e) => e.toJson()).toList());
    _downloadFile('incident_timeline.json', payload, 'application/json');
    _logAction('Incident timeline exported');
  }

  void _ackSopItem(int id) {
    final index = sopChecklist.indexWhere((item) => item.id == id);
    if (index == -1) return;
    setState(() {
      sopChecklist[index] = sopChecklist[index].copyWith(
        ackTime: _formatNow(),
        acknowledged: true,
      );
    });
    _logAction('SOP acknowledged: ${sopChecklist[index].label}');
  }

  void _sendCommsMessage() {
    if (commsDraft.trim().isEmpty) return;
    setState(() {
      commsMessages.insert(
        0,
        CommsMessage(
          channel: commsChannel,
          sender: role == 'commander' ? 'Commander' : role,
          message: commsDraft.trim(),
          time: _formatNow(),
        ),
      );
      commsDraft = '';
    });
    commsController.clear();
    _logAction('Comms message sent');
  }

  String _formatNow() {
    final now = DateTime.now();
    final minutes = now.minute.toString().padLeft(2, '0');
    final seconds = now.second.toString().padLeft(2, '0');
    return '${now.hour}:$minutes:$seconds';
  }

  Uint8List _generateBeepWavBytes({
    int sampleRate = 44100,
    int durationMs = 200,
    double frequency = 740,
  }) {
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataLength = numSamples * 2;
    final fileSize = 36 + dataLength;
    final buffer = ByteData(44 + dataLength);

    buffer.setUint32(0, 0x52494646, Endian.big); // RIFF
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint32(8, 0x57415645, Endian.big); // WAVE
    buffer.setUint32(12, 0x666d7420, Endian.big); // fmt
    buffer.setUint32(16, 16, Endian.little); // PCM header size
    buffer.setUint16(20, 1, Endian.little); // PCM format
    buffer.setUint16(22, 1, Endian.little); // Mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    buffer.setUint16(32, 2, Endian.little); // Block align
    buffer.setUint16(34, 16, Endian.little); // Bits per sample
    buffer.setUint32(36, 0x64617461, Endian.big); // data
    buffer.setUint32(40, dataLength, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final sample = (sin(2 * pi * frequency * t) * 0.35 * 32767).round();
      buffer.setInt16(44 + (i * 2), sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return const Color(0xFFFF4D4F);
      case 'high':
        return const Color(0xFFFF7A45);
      case 'medium':
        return const Color(0xFFFFB020);
      case 'low':
      default:
        return const Color(0xFF2F80ED);
    }
  }
}

class UnitInfo {
  UnitInfo({
    required this.type,
    required this.status,
    required this.battery,
    required this.altitude,
    required this.speed,
    required this.signal,
  });

  final String type;
  final String status;
  final String battery;
  final String altitude;
  final String speed;
  final String signal;

  Map<String, dynamic> toJson() => {
    'type': type,
    'status': status,
    'battery': battery,
    'altitude': altitude,
    'speed': speed,
    'signal': signal,
  };
}

class AlertItem {
  AlertItem({
    required this.id,
    required this.severity,
    required this.message,
    required this.time,
  });

  final int id;
  final String severity;
  final String message;
  final String time;

  Map<String, dynamic> toJson() => {
    'id': id,
    'severity': severity,
    'message': message,
    'time': time,
  };
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.message,
    required this.time,
  });

  final int id;
  final String message;
  final String time;
}

class SubstanceItem {
  SubstanceItem({
    required this.name,
    required this.properties,
    required this.description,
  });

  final String name;
  final String properties;
  final String description;

  Map<String, dynamic> toJson() => {
    'name': name,
    'properties': properties,
    'description': description,
  };

  factory SubstanceItem.fromJson(dynamic json) {
    return SubstanceItem(
      name: json['name']?.toString() ?? '',
      properties: json['properties']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class IncidentMarker {
  IncidentMarker({
    required this.location,
    required this.severity,
    required this.note,
  });

  final LatLng location;
  final String severity;
  final String note;
}

class ZonePolygon {
  ZonePolygon({required this.points, required this.color});

  final List<LatLng> points;
  final Color color;
}

class SensorPoint {
  SensorPoint({required this.location, required this.intensity});

  final LatLng location;
  final double intensity;
}

class MissionTask {
  MissionTask({
    required this.name,
    required this.priority,
    required this.waypoints,
  });

  final String name;
  final String priority;
  final List<LatLng> waypoints;
}

class GeofenceZone {
  GeofenceZone({
    required this.name,
    required this.center,
    required this.radiusKm,
  });

  final String name;
  final LatLng center;
  final double radiusKm;
}

class AssetHealth {
  AssetHealth({
    required this.name,
    required this.health,
    required this.nextService,
  });

  final String name;
  final String health;
  final String nextService;
}

class SopItem {
  SopItem({
    required this.id,
    required this.label,
    this.ackTime,
    this.acknowledged = false,
  });

  final int id;
  final String label;
  final String? ackTime;
  final bool acknowledged;

  SopItem copyWith({String? ackTime, bool? acknowledged}) {
    return SopItem(
      id: id,
      label: label,
      ackTime: ackTime ?? this.ackTime,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }
}

class IncidentEvent {
  IncidentEvent({required this.time, required this.message});

  final String time;
  final String message;

  Map<String, dynamic> toJson() => {'time': time, 'message': message};
}

class AuditEntry {
  AuditEntry({required this.time, required this.action, required this.actor});

  final String time;
  final String action;
  final String actor;
}

class CommsMessage {
  CommsMessage({
    required this.channel,
    required this.sender,
    required this.message,
    required this.time,
  });

  final String channel;
  final String sender;
  final String message;
  final String time;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFFE6F4EE)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFFE6F4EE)),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.label, this.badge});

  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2A24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(badge!, style: const TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _SeverityRow extends StatelessWidget {
  const _SeverityRow({
    required this.label,
    required this.value,
    required this.severity,
  });

  final String label;
  final String value;
  final String severity;

  Color _color() {
    switch (severity) {
      case 'critical':
        return const Color(0xFFFF4D4F);
      case 'high':
        return const Color(0xFFFF7A45);
      case 'medium':
        return const Color(0xFFFFB020);
      case 'low':
      default:
        return const Color(0xFF2F80ED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color(), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF7C8B85), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({this.alert, this.notification});

  final AlertItem? alert;
  final NotificationItem? notification;

  @override
  Widget build(BuildContext context) {
    final text = alert?.message ?? notification?.message ?? '';
    final time = alert?.time ?? notification?.time ?? '';
    final color = alert == null
        ? const Color(0xFF38FF9C)
        : _severityColor(alert!.severity);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: Color(0xFF7C8B85)),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return const Color(0xFFFF4D4F);
      case 'high':
        return const Color(0xFFFF7A45);
      case 'medium':
        return const Color(0xFFFFB020);
      case 'low':
      default:
        return const Color(0xFF2F80ED);
    }
  }
}
