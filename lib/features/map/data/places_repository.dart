import 'dart:convert';
import '../../../core/database/database_helper.dart';
import '../../sos/domain/models.dart';

class PlacesRepository {
  final DatabaseHelper _db;

  PlacesRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper.instance;

  static final List<CachedPlaceRecord> defaultEmergencyPlaces = [
    CachedPlaceRecord(
      placeId: 'SH-01',
      category: 'shelter',
      name: 'Ridgecrest High School Disaster Shelter',
      latitude: 17.3850,
      longitude: 78.4867,
      source: 'State Disaster Management Authority (SDMA)',
      updatedAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
      availabilityStatus: 'Open • 120 / 400 capacity filled',
      metadataJson: jsonEncode({
        'has_generator': true,
        'water_purifier': true,
        'medical_station': true,
        'contact': '+91 40 2345 6789',
      }),
    ),
    CachedPlaceRecord(
      placeId: 'SH-02',
      category: 'shelter',
      name: 'Central Sports Complex Relief Camp',
      latitude: 17.3912,
      longitude: 78.4981,
      source: 'Civil Defense & Red Cross',
      updatedAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 5)),
      availabilityStatus: 'Open • 310 / 500 capacity filled',
      metadataJson: jsonEncode({
        'has_generator': true,
        'water_purifier': true,
        'medical_station': true,
      }),
    ),
    CachedPlaceRecord(
      placeId: 'HP-01',
      category: 'hospital',
      name: 'Osmania General Emergency Hospital & Trauma Unit',
      latitude: 17.3753,
      longitude: 78.4744,
      source: 'State Health Ministry',
      updatedAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      availabilityStatus: 'Operational • Trauma triage active',
      metadataJson: jsonEncode({
        'blood_bank': true,
        'icu_beds': 18,
        'emergency_helpline': '108',
      }),
    ),
    CachedPlaceRecord(
      placeId: 'FS-01',
      category: 'fire_station',
      name: 'District Fire & Rescue Command Station #3',
      latitude: 17.3800,
      longitude: 78.4800,
      source: 'Fire & Emergency Services',
      updatedAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 6)),
      availabilityStatus: 'Responding • 4 rescue boats deployed',
      metadataJson: jsonEncode({
        'rescue_boats': 4,
        'hazmat_crew': true,
      }),
    ),
    CachedPlaceRecord(
      placeId: 'EV-01',
      category: 'evacuation_point',
      name: 'Sector 4 High Ground Evacuation Landing Zone',
      latitude: 17.3995,
      longitude: 78.4920,
      source: 'National Disaster Response Force (NDRF)',
      updatedAtUtc: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      availabilityStatus: 'Clear • Helicopter winch extraction zone',
      metadataJson: jsonEncode({
        'elevation_m': 542,
        'safe_from_flood': true,
      }),
    ),
  ];

  Future<void> seedDefaultPlacesIfEmpty() async {
    final existing = await _db.getCachedPlaces();
    if (existing.isEmpty) {
      await _db.upsertCachedPlaces(defaultEmergencyPlaces);
    }
  }

  Future<List<CachedPlaceRecord>> getPlaces({String? category}) async {
    await seedDefaultPlacesIfEmpty();
    return await _db.getCachedPlaces(category: category);
  }
}
