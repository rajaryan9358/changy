import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/model/OrderModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel orderModel;

  const OrderTrackingScreen({Key? key, required this.orderModel}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<OrderTrackingScreen> {
  final fireStoreUtils = FireStoreUtils();

  GoogleMapController? _mapController;

  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? taxiIcon;

  Map<PolylineId, Polyline> polyLines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  final Map<String, Marker> _markers = {};

  setIcons() async {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(
              size: Size(10, 10),
            ),
            "assets/images/location_black3x.png")
        .then((value) {
      departureIcon = value;
    });

    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(
              size: Size(10, 10),
            ),
            "assets/images/location_orange3x.png")
        .then((value) {
      destinationIcon = value;
    });

    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(
              size: Size(10, 10),
            ),
            "assets/images/food_delivery.png")
        .then((value) {
      taxiIcon = value;
    });
  }

  @override
  void initState() {
    getCurrentOrder();
    getDriver();

    setIcons();
    super.initState();
  }

  late Stream<OrderModel?> ordersFuture;
  OrderModel? currentOrder;

  late Stream<User> driverStream;
  User? _driverModel = User();

  getCurrentOrder() async {
    ordersFuture = FireStoreUtils().getOrderByID(widget.orderModel.id.toString());
    ordersFuture.listen((event) {
      print("------->${event!.status}");
      setState(() {
        currentOrder = event;
        getDirections();
      });
    });
  }

  getDriver() {
    driverStream = FireStoreUtils().getDriver(widget.orderModel.driverID.toString());
    driverStream.listen((event) {
      _driverModel = event;
      getDirections();
    });
  }

  @override
  void dispose() {
    _mapController!.dispose();
    FireStoreUtils().driverStreamSub.cancel();
    FireStoreUtils().ordersStreamController!.close();
    FireStoreUtils().ordersStreamSub!.cancel();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (isDarkMode(context))
      _mapController?.setMapStyle('[{"featureType": "all","'
          'elementType": "'
          'geo'
          'met'
          'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]');
  }

  bool isShow = false;

  @override
  Widget build(BuildContext context) {
    isDarkMode(context)
        ? _mapController?.setMapStyle('[{"featureType": "all","'
            'elementType": "'
            'geo'
            'met'
            'ry","stylers": [{"color": "#242f3e"}]},{"featureType": "all","elementType": "labels.text.stroke","stylers": [{"lightness": -80}]},{"featureType": "administrative","elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},{"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},{"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},{"featureType": "road","elementType": "geometry.fill","stylers": [{"color": "#2b3544"}]},{"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},{"featureType": "road.arterial","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.arterial","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "road.highway","elementType": "geometry.fill","stylers": [{"color": "#746855"}]},{"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},{"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},{"featureType": "road.local","elementType": "geometry.fill","stylers": [{"color": "#38414e"}]},{"featureType": "road.local","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},{"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},{"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},{"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},{"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},{"featureType": "water","elementType": "labels.text.stroke","stylers": [{"lightness": -20}]}]')
        : _mapController?.setMapStyle(null);

    return Scaffold(
      appBar: AppBar(title: Text("Track")),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        myLocationEnabled: _driverModel!.inProgressOrderID != null ? false : true,
        myLocationButtonEnabled: true,
        mapType: MapType.terrain,
        zoomControlsEnabled: false,
        polylines: Set<Polyline>.of(polyLines.values),
        markers: _markers.values.toSet(),
        padding: EdgeInsets.only(
          top: 10.0,
        ),
        initialCameraPosition: CameraPosition(
          zoom: 15,
          target: LatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
        ),
      ),
    );
  }

  getDirections() async {
    print("------>${currentOrder}");
    if (currentOrder != null) {
      if (currentOrder!.status == ORDER_STATUS_SHIPPED) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          GOOGLE_API_KEY,
          PointLatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
          PointLatLng(currentOrder!.vendor.latitude, currentOrder!.vendor.longitude),
          travelMode: TravelMode.driving,
        );

        print("----?${result.points}");
        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
        setState(() {
          _markers.remove("Driver");
          _markers['Driver'] = Marker(
              markerId: const MarkerId('Driver'),
              infoWindow: const InfoWindow(title: "Driver"),
              position: LatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
              icon: taxiIcon!,
              rotation: double.parse(_driverModel!.rotation.toString()));
        });

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(currentOrder!.vendor.latitude, currentOrder!.vendor.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      } else if (currentOrder!.status == ORDER_STATUS_IN_TRANSIT) {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          GOOGLE_API_KEY,
          PointLatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
          PointLatLng(currentOrder!.author.shippingAddress.location.latitude, currentOrder!.author.shippingAddress.location.longitude),
          travelMode: TravelMode.driving,
        );

        print("----?${result.points}");
        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
        setState(() {
          _markers.remove("Driver");
          _markers['Driver'] = Marker(
            markerId: const MarkerId('Driver'),
            infoWindow: const InfoWindow(title: "Driver"),
            position: LatLng(_driverModel!.location.latitude, _driverModel!.location.longitude),
            rotation: double.parse(_driverModel!.rotation.toString()),
            icon: taxiIcon!,
          );
        });

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
          markerId: const MarkerId('Destination'),
          infoWindow: const InfoWindow(title: "Destination"),
          position: LatLng(currentOrder!.author.shippingAddress.location.latitude, currentOrder!.author.shippingAddress.location.longitude),
          icon: destinationIcon!,
        );
        addPolyLine(polylineCoordinates);
      } else {
        List<LatLng> polylineCoordinates = [];

        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          GOOGLE_API_KEY,
          PointLatLng(currentOrder!.author.shippingAddress.location.latitude, currentOrder!.author.shippingAddress.location.longitude),
          PointLatLng(currentOrder!.vendor.latitude, currentOrder!.vendor.longitude),
          travelMode: TravelMode.driving,
        );

        print("----?${result.points}");
        if (result.points.isNotEmpty) {
          for (var point in result.points) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          }
        }
        _markers.remove("Departure");
        _markers['Departure'] = Marker(
            markerId: const MarkerId('Departure'),
            infoWindow: const InfoWindow(title: "Departure"),
            position: LatLng(currentOrder!.author.shippingAddress.location.latitude, currentOrder!.author.shippingAddress.location.longitude),
            icon: departureIcon!);

        _markers.remove("Destination");
        _markers['Destination'] = Marker(
            markerId: const MarkerId('Destination'),
            infoWindow: const InfoWindow(title: "Destination"),
            position: LatLng(currentOrder!.vendor.latitude, currentOrder!.vendor.longitude),
            icon: destinationIcon!);
        addPolyLine(polylineCoordinates);
      }
    }
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Color(COLOR_PRIMARY),
      points: polylineCoordinates,
      width: 8,
      geodesic: true,
    );
    polyLines[id] = polyline;
    updateCameraLocation(polylineCoordinates.first, polylineCoordinates.last, _mapController);
    setState(() {});
  }

  Future<void> updateCameraLocation(
    LatLng source,
    LatLng destination,
    GoogleMapController? mapController,
  ) async {
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: source,
          zoom: 18,
        ),
      ),
    );
    // if (mapController == null) return;
    //
    // LatLngBounds bounds;
    //
    // if (source.latitude > destination.latitude && source.longitude > destination.longitude) {
    //   bounds = LatLngBounds(southwest: destination, northeast: source);
    // } else if (source.longitude > destination.longitude) {
    //   bounds = LatLngBounds(southwest: LatLng(source.latitude, destination.longitude), northeast: LatLng(destination.latitude, source.longitude));
    // } else if (source.latitude > destination.latitude) {
    //   bounds = LatLngBounds(southwest: LatLng(destination.latitude, source.longitude), northeast: LatLng(source.latitude, destination.longitude));
    // } else {
    //   bounds = LatLngBounds(southwest: source, northeast: destination);
    // }
    //
    // CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);
    //
    // return checkCameraLocation(cameraUpdate, mapController);
  }

  Future<void> checkCameraLocation(CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    print("------>");
    print(l1);
    print(l2);
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == 90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }
}
