import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/zones/data/datasources/zone_remote_datasourche.dart';
import 'package:meta_tracking/features/zones/domain/entities/zone_entity.dart';

abstract class ZoneRepository {
  Stream<List<ZoneEntity>> watchZones(String ownerId);
  Future<ZoneEntity> createZone(ZoneEntity zone, String ownerId);
  Future<void> updateZone(ZoneEntity zone);
  Future<void> deleteZone(String zoneId);
}

class ZoneRepositoryImpl implements ZoneRepository {
  final ZoneRemoteDataSource _remote;

  ZoneRepositoryImpl(this._remote);

  @override
  Stream<List<ZoneEntity>> watchZones(String ownerId) {
    AppLogger.melumat('ZONE REPO', 'watchZones: $ownerId');
    return _remote.watchZones(ownerId);
  }

  @override
  Future<ZoneEntity> createZone(ZoneEntity zone, String ownerId) async {
    AppLogger.melumat('ZONE REPO', 'createZone: ${zone.name}');
    return await _remote.createZone(zone, ownerId);
  }

  @override
  Future<void> updateZone(ZoneEntity zone) async {
    AppLogger.melumat('ZONE REPO', 'updateZone: ${zone.id}');
    await _remote.updateZone(zone);
  }

  @override
  Future<void> deleteZone(String zoneId) async {
    AppLogger.melumat('ZONE REPO', 'deleteZone: $zoneId');
    await _remote.deleteZone(zoneId);
  }
}