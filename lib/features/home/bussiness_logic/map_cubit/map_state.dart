import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitialState extends MapState {}

class MapLoadingState extends MapState {}

class MapLoadedState extends MapState {
  final Position position;

  const MapLoadedState(this.position);

  @override
  List<Object?> get props => [position];
}

class MapErrorState extends MapState {
  final String message;

  const MapErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class UpdateDriverLocationStateLoading extends MapState {
  const UpdateDriverLocationStateLoading();

  @override
  List<Object?> get props => [];
}
