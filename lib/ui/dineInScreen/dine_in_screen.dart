import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/FavouriteModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/model/VendorCategoryModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/categoryDetailsScreen/CategoryDetailsScreen.dart';
import 'package:foodie_customer/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:foodie_customer/ui/dineInScreen/dine_in_restaurant_details_screen.dart';
import 'package:foodie_customer/ui/dineInScreen/view_all_dine_in_restaurant.dart';
import 'package:foodie_customer/ui/home/CurrentAddressChangeScreen.dart';
import 'package:foodie_customer/ui/home/HomeScreen.dart';
import 'package:foodie_customer/ui/home/view_all_new_arrival_restaurant_screen.dart';
import 'package:foodie_customer/ui/home/view_all_popular_restaurant_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import 'package:place_picker/entities/entities.dart';
import 'package:place_picker/widgets/place_picker.dart';

class DineInScreen extends StatefulWidget {
  final User? user;

  const DineInScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<DineInScreen> createState() => _DineInScreenState();
}

class _DineInScreenState extends State<DineInScreen> {
  loc.Location location = new loc.Location();
  String? currentLocation = "", name = "";
  final fireStoreUtils = FireStoreUtils();

  Stream<List<VendorModel>>? lstAllRestaurant;
  late Future<List<FavouriteModel>> lstFavourites;
  late Future<List<VendorCategoryModel>> cuisinesFuture;
  List<String> lstFav = [];
  List<VendorModel> newArrivalLst = [];
  List<VendorModel> restaurantAllLst = [];
  List<VendorModel> popularRestaurantLst = [];
  bool showLoader = true;
  List<VendorModel> vendors = [];
  VendorModel? popularNearFoodVendorModel;

  @override
  void initState() {
    super.initState();
    getLocationData();
    cuisinesFuture = fireStoreUtils.getCuisines();
  }

  bool isLoading = true;

  getLocationData() async {
    await getCurrentLocation().then((value) {
      setState(() {
        MyAppState.selectedPosotion = value;
      });
      getData();
    }).onError((error, stackTrace) {
      getPermission();
    });

    await placemarkFromCoordinates(MyAppState.selectedPosotion.latitude, MyAppState.selectedPosotion.longitude).then((value) {
      Placemark placeMark = value[0];

      setState(() {
        currentLocation = "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
      });
    }).catchError((error) {
      debugPrint("------>${error.toString()}");
    });

    setState(() {
      isLoading = false;
    });
  }

  getPermission() async {
    setState(() {
      isLoading = false;
    });
    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        getData();
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void dispose() {
    FireStoreUtils().closeVendorStream();
    super.dispose();
  }

  Future<void> getData() async {
    await fireStoreUtils.getRestaurantNearBy().whenComplete(() {
      lstAllRestaurant = fireStoreUtils.getAllRestaurants(path: "isDineIn").asBroadcastStream();

      if (MyAppState.currentUser != null) {
        lstFavourites = fireStoreUtils.getFavouriteRestaurant(MyAppState.currentUser!.userID);
        lstFavourites.then((event) {
          lstFav.clear();
          for (int a = 0; a < event.length; a++) {
            lstFav.add(event[a].restaurantId!);
          }
        });
        name = toBeginningOfSentenceCase(widget.user!.firstName);
      }

      lstAllRestaurant!.listen((event) {
        vendors.clear();
        vendors.addAll(event);
        allstoreList.clear();
        allstoreList.addAll(event);

        popularRestaurantLst.addAll(event);
        List<VendorModel> temp5 = popularRestaurantLst.where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) == 5).toList();
        List<VendorModel> temp5_ = popularRestaurantLst
            .where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) > 4 && num.parse((element.reviewsSum / element.reviewsCount).toString()) < 5)
            .toList();
        List<VendorModel> temp4 = popularRestaurantLst
            .where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) > 3 && num.parse((element.reviewsSum / element.reviewsCount).toString()) < 4)
            .toList();
        List<VendorModel> temp3 = popularRestaurantLst
            .where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) > 2 && num.parse((element.reviewsSum / element.reviewsCount).toString()) < 3)
            .toList();
        List<VendorModel> temp2 = popularRestaurantLst
            .where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) > 1 && num.parse((element.reviewsSum / element.reviewsCount).toString()) < 2)
            .toList();
        List<VendorModel> temp1 = popularRestaurantLst.where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) == 1).toList();
        List<VendorModel> temp0 = popularRestaurantLst.where((element) => num.parse((element.reviewsSum / element.reviewsCount).toString()) == 0).toList();
        List<VendorModel> temp0_ = popularRestaurantLst.where((element) => element.reviewsSum == 0 && element.reviewsCount == 0).toList();

        popularRestaurantLst.clear();
        popularRestaurantLst.addAll(temp5);
        popularRestaurantLst.addAll(temp5_);
        popularRestaurantLst.addAll(temp4);
        popularRestaurantLst.addAll(temp3);
        popularRestaurantLst.addAll(temp2);
        popularRestaurantLst.addAll(temp1);
        popularRestaurantLst.addAll(temp0);
        popularRestaurantLst.addAll(temp0_);
        setState(() {});
      });

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? Color(DARK_COLOR) : Color(0xffFFFFFF),
      body: isLoading == true
          ? Center(child: CircularProgressIndicator())
          : (MyAppState.selectedPosotion.latitude == 0 && MyAppState.selectedPosotion.longitude == 0)
              ? Center(
                  child: showEmptyState("We don't have your location.".tr(), context, description: "Set your location to started searching for restaurants in your area".tr(), action: () async {
                    LocationResult result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlacePicker(GOOGLE_API_KEY)));

                    setState(() {
                      MyAppState.selectedPosotion = Position.fromMap({'latitude': result.latLng!.latitude, 'longitude': result.latLng!.longitude});

                      currentLocation = result.formattedAddress;
                      getData();
                    });
                  }, buttonTitle: 'Select'.tr()),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Color(COLOR_PRIMARY),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Text(currentLocation.toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(COLOR_PRIMARY), fontFamily: "Poppinsr")).tr(),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context)
                                    .push(PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => CurrentAddressChangeScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return child;
                                  },
                                ))
                                    .then((value) {
                                  if (value != null) {
                                    setState(() {
                                      currentLocation = value;
                                      getData();
                                    });
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
                                decoration: BoxDecoration(borderRadius: new BorderRadius.circular(10), color: Colors.black12, boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: Offset(0, 3), // changes position of shadow
                                  ),
                                ]),
                                child: Text("Change", style: TextStyle(fontSize: 14, color: Color(COLOR_PRIMARY), fontFamily: "Poppinsr")).tr(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 10),
                        child: Text("Find your restaurant", style: TextStyle(fontSize: 24, color: isDarkMode(context) ? Colors.white : Color(0xFF333333), fontFamily: "Poppinssb")).tr(),
                      ),
                      buildDineInTitleRow(
                        titleValue: "Categories".tr(),
                        onClick: () {
                          push(
                            context,
                            CuisinesScreen(
                              isPageCallFromHomeScreen: true,
                              isPageCallForDineIn: true,
                            ),
                          );
                        },
                      ),
                      Container(
                        color: isDarkMode(context) ? Color(DARK_COLOR) : Color(0xffFFFFFF),
                        child: FutureBuilder<List<VendorCategoryModel>>(
                            future: cuisinesFuture,
                            initialData: [],
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting)
                                return Center(
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                                  ),
                                );

                              if (snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) {
                                return Container(
                                    height: 150,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: snapshot.data!.length >= 15 ? 15 : snapshot.data!.length,
                                      itemBuilder: (context, index) {
                                        return buildCategoryItem(snapshot.data![index]);
                                      },
                                    ));
                              } else {
                                return showEmptyState('No Categories'.tr(), context);
                              }
                            }),
                      ),
                      buildDineInTitleRow(
                        titleValue: "New Arrivals".tr(),
                        onClick: () {
                          push(
                              context,
                              ViewAllNewArrivalRestaurantScreen(
                                isPageCallForDineIn: true,
                              ));
                        },
                      ),
                      StreamBuilder<List<VendorModel>>(
                          stream: fireStoreUtils.getVendorsForNewArrival(path: "isDineIn").asBroadcastStream(),
                          initialData: [],
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting)
                              return Center(
                                child: CircularProgressIndicator.adaptive(
                                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                                ),
                              );

                            if (snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) {
                              newArrivalLst = snapshot.data!;

                              return Container(
                                  height: MediaQuery.of(context).size.height * 0.32,
                                  margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: BouncingScrollPhysics(),
                                      itemCount: newArrivalLst.length >= 15 ? 15 : newArrivalLst.length,
                                      itemBuilder: (context, index) => buildNewArrivalItem(newArrivalLst[index])));
                            } else {
                              return showEmptyState('No Restaurant found'.tr(), context);
                            }
                          }),
                      Column(
                        children: [
                          buildTitleRow(
                            titleValue: "Popular Restaurant".tr(),
                            onClick: () {
                              push(
                                context,
                                const ViewAllPopularRestaurantScreen(
                                  isPageCallForDineIn: true,
                                ),
                              );
                            },
                          ),
                          popularRestaurantLst.isEmpty
                              ? showEmptyState('No Popular restaurant'.tr(), context)
                              : Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 260,
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: popularRestaurantLst.length >= 5 ? 5 : popularRestaurantLst.length,
                                      itemBuilder: (context, index) => buildPopularsItem(popularRestaurantLst[index]))),
                        ],
                      ),
                      buildTitleRow(
                        titleValue: "All Restaurant".tr(),
                        onClick: () {},
                        isViewAll: true,
                      ),
                      vendors.isEmpty
                          ? showEmptyState('No Vendors'.tr(), context)
                          : Container(
                              width: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                              child: ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                physics: const BouncingScrollPhysics(),
                                itemCount: vendors.length > 15 ? 15 : vendors.length,
                                itemBuilder: (context, index) {
                                  VendorModel vendorModel = vendors[index];
                                  return buildAllRestaurantsData(vendorModel);
                                },
                              ),
                            ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.06,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(COLOR_PRIMARY),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  side: BorderSide(
                                    color: Color(COLOR_PRIMARY),
                                  ),
                                ),
                              ),
                              child: Text(
                                'See All restaurant around you'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                              ).tr(),
                              onPressed: () {
                                push(
                                  context,
                                  const ViewAllDineInRestaurant(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget buildPopularsItem(VendorModel vendorModel) {
    if (!mounted) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => push(
          context,
          DineInRestaurantDetailsScreen(vendorModel: vendorModel),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.75,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDarkMode(context) ? const Color(DarkContainerBorderColor) : Colors.grey.shade100, width: 1),
            color: isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
            boxShadow: [
              isDarkMode(context)
                  ? const BoxShadow()
                  : BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 5,
                    ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: CachedNetworkImage(
                imageUrl: getImageVAlidUrl(vendorModel.photo),
                memCacheWidth: (MediaQuery.of(context).size.width * 0.75).toInt(),
                memCacheHeight: 250,
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                  ),
                ),
                placeholder: (context, url) => Center(
                    child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                )),
                errorWidget: (context, url, error) => ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    AppGlobal.placeHolderImage!,
                    width: MediaQuery.of(context).size.width * 0.75,
                    fit: BoxFit.fitHeight,
                  ),
                ),
                fit: BoxFit.cover,
              )),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.fromLTRB(15, 0, 5, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendorModel.title,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: "Poppinsm",
                          letterSpacing: 0.5,
                          color: isDarkMode(context) ? Colors.white : const Color(0xff000000),
                        )).tr(),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ImageIcon(
                          const AssetImage('assets/images/location3x.png'),
                          size: 15,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(vendorModel.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                letterSpacing: 0.5,
                                color: isDarkMode(context) ? Colors.white70 : const Color(0xff555353),
                              )),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 20,
                                color: Color(COLOR_PRIMARY),
                              ),
                              const SizedBox(width: 3),
                              Text(vendorModel.reviewsCount != 0 ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}' : 0.toString(),
                                  style: TextStyle(
                                    fontFamily: "Poppinsm",
                                    letterSpacing: 0.5,
                                    color: isDarkMode(context) ? Colors.white70 : const Color(0xff000000),
                                  )),
                              const SizedBox(width: 3),
                              Text('(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                                  style: TextStyle(
                                    fontFamily: "Poppinsm",
                                    letterSpacing: 0.5,
                                    color: isDarkMode(context) ? Colors.white60 : const Color(0xff666666),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  buildCategoryItem(VendorCategoryModel cuisineModel) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          push(
              context,
              CategoryDetailsScreen(
                category: cuisineModel,
                isDineIn: true,
              ));
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CachedNetworkImage(
                imageUrl: getImageVAlidUrl(cuisineModel.photo.toString()),
                imageBuilder: (context, imageProvider) => Container(
                  height: MediaQuery.of(context).size.height * 0.11,
                  width: MediaQuery.of(context).size.width * 0.22,
                  decoration: BoxDecoration(border: Border.all(width: 4, color: Color(COLOR_PRIMARY)), borderRadius: BorderRadius.circular(25)),
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                          width: 4,
                          color: isDarkMode(context) ? Color(DARK_COLOR) : Color(0xffE0E2EA),
                        ),
                        borderRadius: BorderRadius.circular(30)),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      AppGlobal.placeHolderImage!,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                    )),
                placeholder: (context, url) => ClipOval(
                  child: Container(
                    // padding: EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(75 / 1)),
                      border: Border.all(
                        color: Color(COLOR_PRIMARY),
                        style: BorderStyle.solid,
                        width: 2.0,
                      ),
                    ),
                    width: 75,
                    height: 75,
                    child: Icon(
                      Icons.fastfood,
                      color: Color(COLOR_PRIMARY),
                    ),
                  ),
                ),
              ),
              // displayCircleImage(model.photo, 90, false),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(cuisineModel.title.toString(),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode(context) ? Colors.white : Color(0xFF000000),
                      fontFamily: "Poppinsr",
                    )).tr(),
              )
            ],
          ),
        ),
      ),
    );
  }

  buildNewArrivalItem(VendorModel vendorModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          push(
            context,
            DineInRestaurantDetailsScreen(vendorModel: vendorModel),
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.60,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDarkMode(context) ? Colors.grey.shade900 : Colors.grey.shade100, width: 0.1),
                boxShadow: [
                  isDarkMode(context)
                      ? BoxShadow()
                      : BoxShadow(
                          color: isDarkMode(context) ? Colors.grey.shade600 : Colors.grey.shade400,
                          blurRadius: 8.0,
                          spreadRadius: 1.2,
                          offset: Offset(0.2, 0.2),
                        ),
                ],
                color: isDarkMode(context) ? Color(DARK_CARD_BG_COLOR) : Colors.white),
            child: Column(
              children: [
                Expanded(
                    child: CachedNetworkImage(
                  imageUrl: getImageVAlidUrl(vendorModel.photo),
                  width: MediaQuery.of(context).size.width * 0.75,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                    ),
                  ),
                  placeholder: (context, url) => Center(
                      child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  )),
                  errorWidget: (context, url, error) => ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        placeholderImage,
                        width: MediaQuery.of(context).size.width * 0.75,
                        fit: BoxFit.fitWidth,
                      )),
                  fit: BoxFit.cover,
                )),
                SizedBox(height: 8),
                Container(
                  margin: EdgeInsets.fromLTRB(15, 0, 5, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendorModel.title,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: "Poppinssm",
                            letterSpacing: 0.5,
                            color: isDarkMode(context) ? Colors.white : Color(0xff000000),
                          )).tr(),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ImageIcon(
                            AssetImage('assets/images/location3x.png'),
                            size: 15,
                            color: isDarkMode(context) ? Colors.white60 : Color(0xff9091A4),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: Text(vendorModel.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: "Poppinssr",
                                  letterSpacing: 0.5,
                                  color: isDarkMode(context) ? Colors.grey.shade400 : Color(0xff555353),
                                )),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Row(
                              children: [
                                Container(
                                  height: 5,
                                  width: 5,
                                  decoration: new BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDarkMode(context) ? Colors.grey.shade300 : Color(0xff555353),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 10.0),
                                  child: Text(getKm(vendorModel.latitude, vendorModel.longitude)! + " km",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: "Poppinssr",
                                        color: isDarkMode(context) ? Colors.grey.shade300 : Color(0xff555353),
                                      )),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 20,
                                  color: Color(COLOR_PRIMARY),
                                ),
                                SizedBox(width: 3),
                                Text(vendorModel.reviewsCount != 0 ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}' : 0.toString(),
                                    style: TextStyle(
                                      fontFamily: "Poppinssr",
                                      letterSpacing: 0.5,
                                      color: isDarkMode(context) ? Colors.white : Color(0xff000000),
                                    )),
                                SizedBox(width: 3),
                                Text('(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                                    style: TextStyle(
                                      fontFamily: "Poppinssr",
                                      letterSpacing: 0.5,
                                      color: isDarkMode(context) ? Colors.white60 : Color(0xff666666),
                                    )),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? getKm(double latitude, double longitude) {
    double distanceInMeters = Geolocator.distanceBetween(latitude, longitude, MyAppState.selectedPosotion.latitude, MyAppState.selectedPosotion.longitude);
    double kilometer = distanceInMeters / 1000;

    return kilometer.toStringAsFixed(2).toString();
  }

  buildAllRestaurantsData(VendorModel vendor) {
    return GestureDetector(
      onTap: () {
        push(
          context,
          DineInRestaurantDetailsScreen(vendorModel: vendor),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDarkMode(context) ? const Color(DarkContainerBorderColor) : Colors.grey.shade100, width: 1),
            color: isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
            boxShadow: [
              isDarkMode(context)
                  ? const BoxShadow()
                  : BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 5,
                    ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  // child: Image.network(height: 80,
                  //     width: 80,vendorModel.photo),
                  child: CachedNetworkImage(
                    imageUrl: vendor.photo,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          AppGlobal.placeHolderImage!,
                          fit: BoxFit.cover,
                        )),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendor.title,
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode(context) ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_pin,
                            size: 20,
                            color: Color(COLOR_PRIMARY),
                          ),
                          Expanded(
                            child: Text(
                              vendor.location,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                color: isDarkMode(context) ? Colors.white70 : const Color(0xff9091A4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 20,
                            color: Color(COLOR_PRIMARY),
                          ),
                          const SizedBox(width: 3),
                          Text(vendor.reviewsCount != 0 ? '${(vendor.reviewsSum / vendor.reviewsCount).toStringAsFixed(1)}' : 0.toString(),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                letterSpacing: 0.5,
                                color: isDarkMode(context) ? Colors.white : const Color(0xff000000),
                              )),
                          const SizedBox(width: 3),
                          Text('(${vendor.reviewsCount.toStringAsFixed(1)})',
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                letterSpacing: 0.5,
                                color: isDarkMode(context) ? Colors.white60 : const Color(0xff666666),
                              )),
                          const SizedBox(width: 5),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: camel_case_types
class buildDineInTitleRow extends StatelessWidget {
  final String titleValue;
  final Function? onClick;
  final bool? isViewAll;

  const buildDineInTitleRow({
    Key? key,
    required this.titleValue,
    this.onClick,
    this.isViewAll = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Container(
        color: isDarkMode(context) ? Color(DARK_COLOR) : Color(0xffFFFFFF),
        child: Align(
          alignment: Alignment.topLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titleValue.tr(), style: TextStyle(color: isDarkMode(context) ? Colors.white : Color(0xFF000000), fontSize: 16, fontFamily: "Poppinsm")),
              isViewAll!
                  ? Container()
                  : GestureDetector(
                      onTap: () {
                        onClick!.call();
                      },
                      child: Text('View All'.tr(), style: TextStyle(color: Color(COLOR_PRIMARY), fontFamily: "Poppinsm")),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
