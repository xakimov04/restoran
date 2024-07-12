import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:restoran/service/yandex_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:restoran/bloc/restoran_cubit.dart';
import 'package:restoran/bloc/restoran_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late YandexMapController mapController;
  LocationPermission? permission;
  Point? myCurrentLocation;
  List<MapObject> mapObjects = [];
  List<MapObject> polylines = [];
  double searchHeight = 250;
  List<SuggestItem> _suggestionList = [];
  Point _initialLocation = const Point(latitude: 41.02155, longitude: 69.0112);
  final YandexSearch yandexSearch = YandexSearch();
  final TextEditingController _searchTextController = TextEditingController();

  final ValueNotifier<bool> _isBottomSheetVisible = ValueNotifier(false);
  String _bottomSheetTitle = "";
  String _bottomSheetAddress = "";
  Point? _bottomSheetLocation;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _initLocation();

    _loadUserEmail();
  }

  _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail') ?? 'No Email';
    });
  }

  Future<void> _initLocation() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _initialLocation = Point(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
    _moveCameraTo(_initialLocation);
  }

  Future<void> _moveCameraTo(Point target) async {
    await mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 17),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: .2,
      ),
    );
  }

  void _toggleBottomSheet(Point destination, String title, String address) {
    setState(() {
      _bottomSheetTitle = title;
      _bottomSheetAddress = address;
      _bottomSheetLocation = destination;
      _isBottomSheetVisible.value = !_isBottomSheetVisible.value;
    });
  }

  Future<void> _showBottomSheet(Point destination,
      [String? title, String? address]) async {
    String displayAddress = address ?? "Unknown location";
    String displayTitle = title ?? "";

    if (address == null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          destination.latitude,
          destination.longitude,
        );
        if (placemarks.isNotEmpty) {
          displayAddress =
              "${placemarks.first.subLocality}, ${placemarks.first.street}";
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Restaurant title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onChanged: (value) {
                    displayTitle = value;
                  },
                  controller: title == null
                      ? null
                      : TextEditingController(text: displayTitle),
                ),
                const Gap(30),
                const Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.red,
                    ),
                    Text(
                      "Location",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Gap(10),
                Text(
                  displayAddress,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const Gap(10),
                Text(
                  "${destination.latitude}, ${destination.longitude}",
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    context.read<RestoranCubit>().addLocation(
                          displayTitle,
                          destination.toString(),
                          displayAddress,
                        );
                    _addPlacemark(destination, displayTitle, displayAddress);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.teal,
                    ),
                    child: const Center(
                      child: Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<SuggestSessionResult> _suggest() async {
    final resultWithSession = await YandexSuggest.getSuggestions(
      text: _searchTextController.text,
      boundingBox: const BoundingBox(
        northEast: Point(latitude: 56.0421, longitude: 38.0284),
        southWest: Point(latitude: 55.5143, longitude: 37.24841),
      ),
      suggestOptions: const SuggestOptions(
        suggestType: SuggestType.geo,
        suggestWords: true,
        userPosition: Point(latitude: 56.0321, longitude: 38),
      ),
    );

    return await resultWithSession.$2;
  }

  void _addPlacemark(Point point, String title, String address) {
    final placemark = PlacemarkMapObject(
      mapId: MapObjectId(title),
      onTap: (mapObject, point) {
        _toggleBottomSheet(point, title, address);
      },
      point: point,
      opacity: 1,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          scale: .15,
          image: BitmapDescriptor.fromAssetImage("assets/restoran.png"),
        ),
      ),
    );
    setState(() {
      mapObjects.add(placemark);
    });
  }

  Future<void> _drawRoute(Point from, Point to) async {
    try {
      List<MapObject> route =
          await YandexMapService.getDirection(from, to, mode: 'driving');
      setState(() {
        polylines = route;
      });
      mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: to,
            zoom: 15,
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1.5,
        ),
      );

      double distance = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );
      double travelTime = distance / 50 * 60;

      _showTripDetailsSheet(distance, travelTime);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showTripDetailsSheet(double distance, double travelTime) {
    int hours = travelTime ~/ 3600;
    int minutes = (travelTime % 60).toInt();
    String formattedTime = '';

    if (hours > 0) {
      formattedTime = '${hours}h ${minutes}m';
    } else {
      formattedTime = '${minutes}m';
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Trip Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(20),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: Colors.teal,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        "Distance: ${(distance / 1000).toStringAsFixed(2)} km",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Colors.teal,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        "Estimated Time: $formattedTime",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        polylines = [];
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text(
                        "Cancel Trip",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.teal,
        onPressed: () {
          _moveCameraTo(_initialLocation);
        },
        child: const Icon(CupertinoIcons.location_fill, color: Colors.white),
      ),
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            onMapLongTap: (point) {
              setState(() {
                myCurrentLocation = point;
              });
              _moveCameraTo(point).then((_) => _showBottomSheet(point));
            },
            mapObjects: [
              PlacemarkMapObject(
                mapId: const MapObjectId("My location"),
                point: _initialLocation,
                opacity: 1,
                icon: PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    scale: .1,
                    image: BitmapDescriptor.fromAssetImage("assets/marker.png"),
                  ),
                ),
              ),
              ...mapObjects,
              ...polylines,
            ],
          ),
          Positioned(
            top: 70,
            left: 10,
            right: 10,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _searchTextController.text.isNotEmpty ? searchHeight : 0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: ListView.builder(
                itemCount: _suggestionList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () {
                      setState(() {
                        searchHeight = 0;
                        myCurrentLocation = _suggestionList[index].center;
                        _showBottomSheet(myCurrentLocation!);
                      });

                      mapController.moveCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: myCurrentLocation!,
                            zoom: 17,
                          ),
                        ),
                        animation: const MapAnimation(
                          type: MapAnimationType.smooth,
                          duration: 1.5,
                        ),
                      );
                    },
                    title: Text(
                      _suggestionList[index].title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _suggestionList[index].subtitle ?? "",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          if (polylines.isNotEmpty)
            Positioned(
              top: 100,
              left: 10,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    polylines = [];
                  });
                },
                child: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  radius: 25,
                  child: Icon(
                    Icons.clear,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 40,
            left: 10,
            right: 10,
            child: ValueListenableBuilder(
                valueListenable: _isBottomSheetVisible,
                builder: (context, isVisible, child) {
                  return Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          onTap: () {
                            _isBottomSheetVisible.value = false;
                          },
                          decoration: InputDecoration(
                            suffixIcon: _searchTextController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _searchTextController.text = "";
                                        searchHeight = 250;
                                      });
                                    },
                                    child: const Icon(
                                      CupertinoIcons.clear_fill,
                                      color: Colors.grey,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () {},
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircleAvatar(
                                        backgroundImage: AssetImage(
                                            "assets/images/person.png"),
                                      ),
                                    ),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.location_on_rounded,
                                color: Colors.red),
                            hintText: "Search for a place and address",
                            hintStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.green),
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          controller: _searchTextController,
                          onChanged: (value) async {
                            final res = await _suggest();
                            if (res.items != null) {
                              setState(() {
                                searchHeight = 250;
                                _suggestionList = res.items!.toSet().toList();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }),
          ),
          Positioned(
            bottom: 80,
            left: 10,
            right: 10,
            child: ValueListenableBuilder(
              valueListenable: _isBottomSheetVisible,
              builder: (context, isVisible, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isVisible ? 250 : 0,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: isVisible
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  _bottomSheetTitle,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Image.asset(
                                      "assets/resto.png",
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 120,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_rounded,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _bottomSheetAddress,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Gap(20),
                                        Row(
                                          children: [
                                            const Gap(5),
                                            Text(
                                              "${Random(2).nextInt(5) + 1}",
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Gap(15),
                                            for (var i = 0; i < 5; i++)
                                              Icon(
                                                i < Random(2).nextInt(5) + 1
                                                    ? Icons.star_rate_rounded
                                                    : Icons.star_border_rounded,
                                                color:
                                                    i < Random(2).nextInt(5) + 1
                                                        ? Colors.amber
                                                        : Colors.grey,
                                              )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        _isBottomSheetVisible.value = false;
                                      },
                                      child: const SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: Center(
                                          child: Text(
                                            "Back",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (myCurrentLocation != null &&
                                            _bottomSheetLocation != null) {
                                          _drawRoute(
                                            _initialLocation,
                                            _bottomSheetLocation!,
                                          );
                                        }
                                        _isBottomSheetVisible.value = false;
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          color: Colors.teal,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "Go",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
