import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restoran/models/restoran_models.dart';
import 'restoran_state.dart';

class RestoranCubit extends Cubit<RestoranState> {
  RestoranCubit() : super(RestoranInitial());

  final List<RestoranModels> restorans = [];

  void addLocation(String title, String point, String locationName) {
    restorans.add(
        RestoranModels(title: title, point: point, locationName: locationName));
    emit(RestoranLoaded(restorans: restorans));
  }
}
