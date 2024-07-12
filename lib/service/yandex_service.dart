import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class YandexMapService {
  static Future<List<MapObject>> getDirection(Point from, Point to,
      {required String mode}) async {
    switch (mode) {
      case 'walking':
        return _getWalkingDirection(from, to);
      case 'cycling':
        return _getCyclingDirection(from, to);
      case 'driving':
        return _getDrivingDirection(from, to);
      default:
        return [];
    }
  }

  static Future<List<MapObject>> _getWalkingDirection(
      Point from, Point to) async {
    final result = await YandexPedestrian.requestRoutes(
      points: [
        RequestPoint(point: from, requestPointType: RequestPointType.wayPoint),
        RequestPoint(point: to, requestPointType: RequestPointType.wayPoint),
      ],
      avoidSteep: true,
      timeOptions: const TimeOptions(),
    );

    final pedestrianResults = await result.$2;

    if (pedestrianResults.error != null) {
      print("Yurish marshruti olinmadi");
      return [];
    }

    final points = pedestrianResults.routes!.map((route) {
      return PolylineMapObject(
        strokeColor: Colors.green,
        mapId: MapObjectId(UniqueKey().toString()),
        polyline: route.geometry,
      );
    }).toList();

    return points;
  }

  static Future<List<MapObject>> _getCyclingDirection(
      Point from, Point to) async {
    final result = await YandexBicycle.requestRoutes(
      points: [
        RequestPoint(point: from, requestPointType: RequestPointType.wayPoint),
        RequestPoint(point: to, requestPointType: RequestPointType.wayPoint),
      ],
      bicycleVehicleType: BicycleVehicleType.bicycle,
    );

    final bicycleResults = await result.$2;

    if (bicycleResults.error != null) {
      print("Velosiped marshruti olinmadi");
      return [];
    }

    final points = bicycleResults.routes!.map((route) {
      return PolylineMapObject(
        strokeColor: Colors.deepPurple,
        mapId: MapObjectId(UniqueKey().toString()),
        polyline: route.geometry,
      );
    }).toList();

    return points;
  }

  static Future<List<MapObject>> _getDrivingDirection(
      Point from, Point to) async {
    final result = await YandexDriving.requestRoutes(
      points: [
        RequestPoint(point: from, requestPointType: RequestPointType.wayPoint),
        RequestPoint(point: to, requestPointType: RequestPointType.wayPoint),
      ],
      drivingOptions: const DrivingOptions(
        initialAzimuth: 1,
        routesCount: 1,
        avoidTolls: true,
      ),
    );

    final drivingResults = await result.$2;

    if (drivingResults.error != null) {
      print("Haydash marshruti olinmadi");
      return [];
    }

    final points = drivingResults.routes!.map((route) {
      return PolylineMapObject(
        strokeColor: Colors.blue,
        mapId: MapObjectId(UniqueKey().toString()),
        polyline: route.geometry,
      );
    }).toList();

    return points;
  }
}
