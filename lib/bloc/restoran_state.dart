import 'package:restoran/models/restoran_models.dart';

sealed class RestoranState {}

class RestoranInitial extends RestoranState {}

class RestoranLoading extends RestoranState {}

class RestoranLoaded extends RestoranState {
  List<RestoranModels> restorans;

  RestoranLoaded({required this.restorans});
}

class RestoranError extends RestoranState {
  String message;

  RestoranError(this.message);
}
