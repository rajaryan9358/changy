import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/main.dart';
import 'package:foodie_customer/model/BannerModel.dart';
import 'package:foodie_customer/model/FavouriteModel.dart';
import 'package:foodie_customer/model/ProductModel.dart';
import 'package:foodie_customer/model/User.dart';
import 'package:foodie_customer/model/VendorCategoryModel.dart';
import 'package:foodie_customer/model/VendorModel.dart';
import 'package:foodie_customer/model/offer_model.dart';
import 'package:foodie_customer/model/story_model.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/cuisinesScreen/CuisinesScreen.dart';
import 'package:foodie_customer/ui/home/CurrentAddressChangeScreen.dart';
import 'package:foodie_customer/ui/home/view_all_offer_screen.dart';
import 'package:foodie_customer/ui/home/view_all_restaurant.dart';
import 'package:foodie_customer/ui/productDetailsScreen/ProductDetailsScreen.dart';
import 'package:foodie_customer/ui/searchScreen/SearchScreen.dart';
import 'package:foodie_customer/ui/vendorProductsScreen/NewVendorProductsScreen.dart';
import 'package:foodie_customer/widget/gradiant_text.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart';
import 'package:place_picker/place_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story_view/story_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class HomeScreenTwo extends StatefulWidget {
  final User? user;

  const HomeScreenTwo({super.key, this.user});

  @override
  State<HomeScreenTwo> createState() => _HomeScreenTwoState();
}

class _HomeScreenTwoState extends State<HomeScreenTwo> {
  final fireStoreUtils = FireStoreUtils();

  late Future<List<ProductModel>> productsFuture;
  final PageController _controller = PageController(viewportFraction: 0.8, keepPage: true);
  List<VendorModel> vendors = [];
  List<VendorModel> offerVendorList = [];
  List<OfferModel> offersList = [];
  Stream<List<VendorModel>>? lstAllRestaurant;
  List<ProductModel> lstNearByFood = [];

  late Future<List<FavouriteModel>> lstFavourites;
  List<String> lstFav = [];

  String? name = "";

  String? currentLocation = "";

  String? selctedOrderTypeValue = "Delivery".tr();

  bool isLocationPermissionAllowed = false;
  loc.Location location = loc.Location();

  // Database db;

  @override
  void initState() {
    super.initState();
    getLocationData();
    getBanner();
  }

  List<VendorCategoryModel> categoryWiseProductList = [];

  List<BannerModel> bannerTopHome = [];
  List<BannerModel> bannerMiddleHome = [];

  bool isHomeBannerLoading = true;
  bool isHomeBannerMiddleLoading = true;
  List<OfferModel> offerList = [];
  bool? storyEnable = false;

  getBanner() async {
    await fireStoreUtils.getHomeTopBanner().then((value) {
      setState(() {
        bannerTopHome = value;
        isHomeBannerLoading = false;
      });
    });

    await fireStoreUtils.getHomePageShowCategory().then((value) {
      setState(() {
        categoryWiseProductList = value;
      });
    });

    await fireStoreUtils.getHomeMiddleBanner().then((value) {
      setState(() {
        bannerMiddleHome = value;
        isHomeBannerMiddleLoading = false;
      });
    });
    await FireStoreUtils().getPublicCoupons().then((value) {
      setState(() {
        offerList = value;
      });
    });

    await FirebaseFirestore.instance.collection(Setting).doc('story').get().then((value) {
      setState(() {
        storyEnable = value.data()!['isEnabled'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: isDarkMode(context) ? const Color(DARK_BG_COLOR) : const Color(0xffFAFAFA),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            color: isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                      ),
                                      Expanded(
                                        child: InkWell(
                                            onTap: () {
                                              Navigator.of(context)
                                                  .push(PageRouteBuilder(
                                                pageBuilder: (context, animation, secondaryAnimation) => const CurrentAddressChangeScreen(),
                                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                  return child;
                                                },
                                              ))
                                                  .then((value) {
                                                if (value != null && mounted) {
                                                  setState(() {
                                                    currentLocation = value;
                                                    getData();
                                                  });
                                                }
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Expanded(child: Text(currentLocation.toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: "Poppinsr")).tr()),
                                                Icon(Icons.arrow_drop_down)
                                              ],
                                            )),
                                      ),
                                      const SizedBox(
                                        width: 80,
                                      ),
                                      DropdownButton(
                                        value: selctedOrderTypeValue,
                                        isDense: true,
                                        onChanged: (newValue) async {
                                          int cartProd = 0;
                                          await Provider.of<CartDatabase>(context, listen: false).allCartProducts.then((value) {
                                            cartProd = value.length;
                                          });

                                          if (cartProd > 0) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) => ShowDialogToDismiss(
                                                title: '',
                                                content: "Do you really want to change the delivery option?".tr() + "Your cart will be empty".tr(),
                                                buttonText: 'CLOSE'.tr(),
                                                secondaryButtonText: 'OK'.tr(),
                                                action: () {
                                                  Navigator.of(context).pop();
                                                  Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();
                                                  setState(() {
                                                    selctedOrderTypeValue = newValue.toString();
                                                    saveFoodTypeValue();
                                                    getData();
                                                  });
                                                },
                                              ),
                                            );
                                          } else {
                                            setState(() {
                                              selctedOrderTypeValue = newValue.toString();

                                              saveFoodTypeValue();
                                              getData();
                                            });
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                        ),
                                        items: [
                                          'Delivery'.tr(),
                                          'Takeaway'.tr(),
                                        ].map((location) {
                                          return DropdownMenuItem(
                                            child: Text(location),
                                            value: location,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                InkWell(
                                  onTap: () {
                                    push(context, const SearchScreen());
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: TextFormField(
                                      textInputAction: TextInputAction.next,
                                      onChanged: (value) {},
                                      decoration: InputDecoration(
                                        hintText: 'Search menu, restaurant or etc...'.tr(),
                                        fillColor: Color(0XFFF2F2F2),
                                        filled: true,
                                        enabled: false,
                                        contentPadding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                                        prefixIcon: Icon(Icons.search, color: Colors.black),
                                        hintStyle: const TextStyle(color: Color(0XFF8A8989), fontFamily: 'Poppinsr'),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide(color: Color(COLOR_PRIMARY), width: 2.0)),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Theme.of(context).errorColor),
                                          borderRadius: BorderRadius.circular(30.0),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Theme.of(context).errorColor),
                                          borderRadius: BorderRadius.circular(30.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(30.0),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(30.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Divider(
                                  thickness: 1,
                                ),
                                Visibility(
                                  visible: bannerTopHome.isNotEmpty,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: isHomeBannerLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : SizedBox(
                                            height: MediaQuery.of(context).size.height * 0.18,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: PageView.builder(
                                                  padEnds: false,
                                                  itemCount: bannerTopHome.length,
                                                  scrollDirection: Axis.horizontal,
                                                  controller: _controller,
                                                  itemBuilder: (context, index) => buildBestDealPage(bannerTopHome[index])),
                                            )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Our Categories", style: TextStyle(color: isDarkMode(context) ? Colors.white : const Color(0xFF000000), fontFamily: "Poppinsm", fontSize: 18)),
                                        GestureDetector(
                                          onTap: () {
                                            push(
                                              context,
                                              const CuisinesScreen(
                                                isPageCallFromHomeScreen: true,
                                              ),
                                            );
                                          },
                                          child: Text('View All'.tr(), style: TextStyle(color: Color(COLOR_PRIMARY), fontFamily: "Poppinsm")),
                                        ),
                                      ],
                                    ),
                                    GradientText(
                                      'Best Servings Food',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontFamily: 'Inter Tight',
                                        fontWeight: FontWeight.w800,
                                      ),
                                      gradient: LinearGradient(colors: [
                                        Color(0xFF3961F1),
                                        Color(0xFF11D0EA),
                                      ]),
                                    ),
                                    SizedBox(height: 10),
                                    FutureBuilder<List<VendorCategoryModel>>(
                                        future: fireStoreUtils.getCuisines(),
                                        initialData: [],
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Center(
                                              child: CircularProgressIndicator.adaptive(
                                                valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                                              ),
                                            );
                                          }
                                          if ((snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) && mounted) {
                                            return GridView.builder(
                                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 5 / 6),
                                              itemCount: snapshot.data!.length >= 8 ? 8 : snapshot.data!.length,
                                              physics: NeverScrollableScrollPhysics(),
                                              shrinkWrap: true,
                                              itemBuilder: (context, index) {
                                                VendorCategoryModel vendorCategoryModel = snapshot.data![index];
                                                return Column(
                                                  children: [
                                                    ClipOval(
                                                      child: CachedNetworkImage(
                                                        width: 60,
                                                        height: 60,
                                                        imageUrl: getImageVAlidUrl(vendorCategoryModel.photo.toString()),
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) => ClipOval(
                                                          child: Image.network(
                                                            AppGlobal.placeHolderImage!,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                        errorWidget: (context, url, error) => ClipRRect(
                                                            borderRadius: BorderRadius.circular(20),
                                                            child: Image.network(
                                                              AppGlobal.placeHolderImage!,
                                                              fit: BoxFit.cover,
                                                            )),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 5),
                                                      child: Center(
                                                          child: Text(vendorCategoryModel.title.toString(),
                                                                  maxLines: 1,
                                                                  style: TextStyle(color: isDarkMode(context) ? Colors.white : const Color(0xFF000000), fontFamily: "Poppinsr", fontSize: 12))
                                                              .tr()),
                                                    )
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            return showEmptyState('No Categories'.tr(), context);
                                          }
                                        })
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          offerVendorList.isEmpty
                              ? Container()
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
                                      borderRadius: BorderRadius.all(Radius.circular(20)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text("Large Discounts", style: TextStyle(color: isDarkMode(context) ? Colors.white : const Color(0xFF000000), fontFamily: "Poppinsm", fontSize: 18)),
                                              GestureDetector(
                                                onTap: () {
                                                  push(
                                                    context,
                                                    OffersScreen(
                                                      vendors: vendors,
                                                    ),
                                                  );
                                                },
                                                child: Text('View All'.tr(), style: TextStyle(color: Color(COLOR_PRIMARY), fontFamily: "Poppinsm")),
                                              ),
                                            ],
                                          ),
                                          GradientText(
                                            'Save Upto 50% Off',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontFamily: 'Inter Tight',
                                              fontWeight: FontWeight.w800,
                                            ),
                                            gradient: LinearGradient(colors: [
                                              Color(0xFF39F1C5),
                                              Color(0xFF97EA11),
                                            ]),
                                          ),
                                          Container(
                                              width: MediaQuery.of(context).size.width,
                                              height: MediaQuery.of(context).size.width * 0.35,
                                              child: ListView.builder(
                                                  shrinkWrap: true,
                                                  scrollDirection: Axis.horizontal,
                                                  physics: const BouncingScrollPhysics(),
                                                  itemCount: offerVendorList.length >= 15 ? 15 : offerVendorList.length,
                                                  itemBuilder: (context, index) {
                                                    return buildCouponsForYouItem(context, offerVendorList[index], offersList[index]);
                                                  })),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                          SizedBox(
                            height: 20,
                          ),
                          Visibility(visible: storyEnable == true, child: storyWidget()),
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                            color: isDarkMode(context) ? null : Colors.white,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Best Restaurants", style: TextStyle(color: isDarkMode(context) ? Colors.white : const Color(0xFF000000), fontFamily: "Poppinsm", fontSize: 18)),
                                      GestureDetector(
                                        onTap: () {
                                          push(context, const ViewAllRestaurant());
                                        },
                                        child: Text('See All'.tr(), style: TextStyle(color: Color(COLOR_PRIMARY), fontFamily: "Poppinsm")),
                                      ),
                                    ],
                                  ),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
    );
  }

  final StoryController controller = StoryController();

  Widget storyWidget() {
    return storyList.isEmpty
        ? Container()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.30,
              decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20)), image: DecorationImage(image: AssetImage("assets/images/story_bg.png"), fit: BoxFit.cover)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Stories", style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.white, fontFamily: "Poppinsm", fontSize: 18)),
                    GradientText(
                      'Best Food Stories Ever',
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'Inter Tight',
                        fontWeight: FontWeight.w800,
                      ),
                      gradient: LinearGradient(colors: [
                        Color(0xFFF1C839),
                        Color(0xFFEA1111),
                      ]),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: storyList.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => MoreStories(
                                          storyList: storyList,
                                          index: index,
                                        )));
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                child: Container(
                                  height: 180,
                                  width: 130,
                                  child: Stack(
                                    children: [
                                      Stack(
                                        children: [
                                          CachedNetworkImage(
                                              imageUrl: storyList[index].videoThumbnail.toString(),
                                              imageBuilder: (context, imageProvider) => Container(
                                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: imageProvider, fit: BoxFit.cover)),
                                                  ),
                                              errorWidget: (context, url, error) => ClipRRect(
                                                  borderRadius: BorderRadius.circular(15),
                                                  child: Image.network(
                                                    AppGlobal.placeHolderImage!,
                                                    fit: BoxFit.cover,
                                                    width: MediaQuery.of(context).size.width,
                                                    height: MediaQuery.of(context).size.height,
                                                  ))),
                                          Container(
                                            color: Colors.black.withOpacity(0.30),
                                          )
                                        ],
                                      ),
                                      FutureBuilder(
                                          future: FireStoreUtils().getVendorByVendorID(storyList[index].vendorID.toString()),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return Center(child: CircularProgressIndicator());
                                            } else {
                                              if (snapshot.hasError)
                                                return Center(child: Text('Error: ${snapshot.error}'));
                                              else {
                                                return Positioned(
                                                    top: 4,
                                                    left: 2,
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.all(Radius.circular(30))),
                                                          child: ClipOval(
                                                            child: CachedNetworkImage(
                                                              width: 32,
                                                              height: 32,
                                                              imageUrl: getImageVAlidUrl(snapshot.data!.photo.toString()),
                                                              fit: BoxFit.cover,
                                                              placeholder: (context, url) => ClipOval(
                                                                child: Image.network(
                                                                  AppGlobal.placeHolderImage!,
                                                                  fit: BoxFit.cover,
                                                                ),
                                                              ),
                                                              errorWidget: (context, url, error) => ClipRRect(
                                                                  borderRadius: BorderRadius.circular(20),
                                                                  child: Image.network(
                                                                    AppGlobal.placeHolderImage!,
                                                                    fit: BoxFit.cover,
                                                                  )),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 5,
                                                        ),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              snapshot.data != null ? snapshot.data!.title.toString() : "cdc",
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 12,
                                                                fontFamily: 'Inter Tight',
                                                                fontWeight: FontWeight.w700,
                                                                height: 1.67,
                                                              ),
                                                            ),
                                                            Row(
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  Icons.star,
                                                                  size: 14,
                                                                  color: Colors.amber,
                                                                ),
                                                                SizedBox(
                                                                  width: 2,
                                                                ),
                                                                Text(
                                                                    "${snapshot.data!.reviewsCount != 0 ? '${(snapshot.data!.reviewsSum / snapshot.data!.reviewsCount).toStringAsFixed(1)}' : 0.toString()} reviews",
                                                                    style: TextStyle(
                                                                      fontFamily: "Poppinssr",
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 10,
                                                                      color: isDarkMode(context) ? Colors.white : Colors.white,
                                                                    )),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ));
                                              }
                                            }
                                          }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget buildAllRestaurantsData(VendorModel vendorModel) {
    debugPrint(vendorModel.photo);
    List<OfferModel> tempList = [];
    List<double> discountAmountTempList = [];
    offerList.forEach((element) {
      if (vendorModel.id == element.restaurantId && element.expireOfferDate!.toDate().isAfter(DateTime.now())) {
        tempList.add(element);
        discountAmountTempList.add(double.parse(element.discount.toString()));
      }
    });
    return GestureDetector(
      onTap: () => push(
        context,
        NewVendorProductsScreen(vendorModel: vendorModel),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Container(
          // decoration: BoxDecoration(
          //   borderRadius: BorderRadius.circular(20),
          //   border: Border.all(color: isDarkMode(context) ? const Color(DarkContainerBorderColor) : Colors.grey.shade100, width: 1),
          //   color: isDarkMode(context) ? const Color(DarkContainerColor) : Colors.white,
          //   boxShadow: [
          //     isDarkMode(context)
          //         ? const BoxShadow()
          //         : BoxShadow(
          //             color: Colors.grey.withOpacity(0.5),
          //             blurRadius: 5,
          //           ),
          //   ],
          // ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: vendorModel.photo,
                            height: 120,
                            width: 108,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  height: 120,
                                  width: 90,
                                  AppGlobal.placeHolderImage!,
                                  fit: BoxFit.cover,
                                )),
                          ),
                          Container(
                            height: 120,
                            width: 108,
                            color: Colors.black.withOpacity(0.30),
                          )
                        ],
                      ),
                    ),
                    if (discountAmountTempList.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save Upto',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Inter Tight',
                                fontWeight: FontWeight.w700,
                                height: 1.20,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                // "30 %",
                                discountAmountTempList.reduce(min).toStringAsFixed(currencyModel!.decimal) + "% OFF".tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      )
                  ],
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
                              vendorModel.title,
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
                              vendorModel.location,
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
                          Text(vendorModel.reviewsCount != 0 ? '${(vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1)}' : 0.toString(),
                              style: TextStyle(
                                fontFamily: "Poppinsm",
                                letterSpacing: 0.5,
                                color: isDarkMode(context) ? Colors.white : const Color(0xff000000),
                              )),
                          const SizedBox(width: 3),
                          Text('(${vendorModel.reviewsCount.toStringAsFixed(1)})',
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

  @override
  void dispose() {
    fireStoreUtils.closeVendorStream();
    fireStoreUtils.closeNewArrivalStream();
    super.dispose();
  }

  Widget buildBestDealPage(BannerModel categoriesModel) {
    return InkWell(
      onTap: () async {
        if (categoriesModel.redirect_type == "store") {
          VendorModel? vendorModel = await FireStoreUtils.getVendor(categoriesModel.redirect_id.toString());
          push(
            context,
            NewVendorProductsScreen(vendorModel: vendorModel!),
          );
        } else if (categoriesModel.redirect_type == "product") {
          ProductModel? productModel = await fireStoreUtils.getProductByProductID(categoriesModel.redirect_id.toString());
          VendorModel? vendorModel = await FireStoreUtils.getVendor(productModel.vendorID);

          if (vendorModel != null) {
            push(
              context,
              ProductDetailsScreen(
                vendorModel: vendorModel,
                productModel: productModel,
              ),
            );
          }
        } else if (categoriesModel.redirect_type == "external_link") {
          final uri = Uri.parse(categoriesModel.redirect_id.toString());
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            throw "Could not launch".tr() + " ${categoriesModel.redirect_id.toString()}";
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          child: CachedNetworkImage(
            imageUrl: getImageVAlidUrl(categoriesModel.photo.toString()),
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
            color: Colors.black.withOpacity(0.5),
            placeholder: (context, url) => Center(
                child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
            )),
            errorWidget: (context, url, error) => ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  AppGlobal.placeHolderImage!,
                  width: MediaQuery.of(context).size.width * 0.75,
                  fit: BoxFit.fitWidth,
                )),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  openCouponCode(
    BuildContext context,
    OfferModel offerModel,
  ) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              margin: const EdgeInsets.only(
                left: 40,
                right: 40,
              ),
              padding: const EdgeInsets.only(
                left: 50,
                right: 50,
              ),
              decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/offer_code_bg.png"))),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  offerModel.offerCode!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.9),
                ),
              )),
          GestureDetector(
            onTap: () {
              FlutterClipboard.copy(offerModel.offerCode!).then((value) {
                final SnackBar snackBar = SnackBar(
                  content: Text(
                    "Coupon code copied".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.black38,
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                return Navigator.pop(context);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 30, bottom: 30),
              child: Text(
                "COPY CODE".tr(),
                style: TextStyle(color: Color(COLOR_PRIMARY), fontWeight: FontWeight.w500, letterSpacing: 0.1),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            child: RichText(
              text: TextSpan(
                text: "Use code".tr(),
                style: const TextStyle(fontSize: 16.0, color: Colors.grey, fontWeight: FontWeight.w700),
                children: <TextSpan>[
                  TextSpan(
                    text: offerModel.offerCode,
                    style: TextStyle(color: Color(COLOR_PRIMARY), fontWeight: FontWeight.w500, letterSpacing: 0.1),
                  ),
                  TextSpan(
                    text: " & get".tr() +
                        " ${offerModel.discountType == "Fix Price" ? "${currencyModel!.symbol}" : ""}${offerModel.discount} ${offerModel.discountType == "Percentage" ? "% off".tr() : "off".tr()} ",
                    style: const TextStyle(fontSize: 16.0, color: Colors.grey, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCouponsForYouItem(BuildContext context1, VendorModel? vendorModel, OfferModel offerModel) {
    return vendorModel == null
        ? Container()
        : Container(
            // margin: const EdgeInsets.symmetric(horizontal: 5),
            child: GestureDetector(
              onTap: () {
                if (vendorModel.id.toString() == offerModel.restaurantId.toString()) {
                  push(
                    context,
                    NewVendorProductsScreen(vendorModel: vendorModel),
                  );
                } else {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    isDismissible: true,
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    backgroundColor: Colors.transparent,
                    enableDrag: true,
                    builder: (context) => openCouponCode(context, offerModel),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: vendorModel.photo,
                            height: 134,
                            width: 130,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  height: 120,
                                  width: 90,
                                  AppGlobal.placeHolderImage!,
                                  fit: BoxFit.cover,
                                )),
                          ),
                          Container(
                            height: 134,
                            width: 130,
                            color: Colors.black.withOpacity(0.30),
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vendorModel.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Inter Tight',
                              fontWeight: FontWeight.w700,
                              height: 1.20,
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Container(
                            decoration: ShapeDecoration(
                              color: Color(0xFF356FDC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2000),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: Text(
                                "${offerModel.discountType == "Fix Price" ? "${currencyModel!.symbol}" : ""}${offerModel.discount}${offerModel.discountType == "Percentage" ? "% off".tr() : "off".tr()} ",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
  }

  Widget buildVendorItem(VendorModel vendorModel) {
    return GestureDetector(
      onTap: () => push(
        context,
        NewVendorProductsScreen(vendorModel: vendorModel),
      ),
      child: Container(
        height: 120,
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              memCacheWidth: (MediaQuery.of(context).size.width).toInt(),
              memCacheHeight: 120,
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
              errorWidget: (context, url, error) => ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(AppGlobal.placeHolderImage!)),
              fit: BoxFit.cover,
            )),
            const SizedBox(height: 8),
            ListTile(
              title: Text(vendorModel.title,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: "Poppinsm",
                    letterSpacing: 0.5,
                    color: Color(0xff000000),
                  )).tr(),
              subtitle: Row(
                children: [
                  ImageIcon(
                    AssetImage('assets/images/location3x.png'),
                    size: 15,
                    color: Color(COLOR_PRIMARY),
                  ),
                  SizedBox(
                    width: 200,
                    child: Text(vendorModel.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: "Poppinsm",
                          letterSpacing: 0.5,
                          color: Color(0xff555353),
                        )),
                  ),
                ],
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(top: 8.0),
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
                            style: const TextStyle(
                              fontFamily: "Poppinsm",
                              letterSpacing: 0.5,
                              color: Color(0xff000000),
                            )),
                        const SizedBox(width: 3),
                        Text('(${vendorModel.reviewsCount.toStringAsFixed(1)})',
                            style: const TextStyle(
                              fontFamily: "Poppinsm",
                              letterSpacing: 0.5,
                              color: Color(0xff666666),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> saveFoodTypeValue() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString('foodType', selctedOrderTypeValue!);
  }

  getFoodType() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        selctedOrderTypeValue = sp.getString("foodType") == "" || sp.getString("foodType") == null ? "Delivery" : sp.getString("foodType");
      });
    }
    if (selctedOrderTypeValue == "Takeaway") {
      productsFuture = fireStoreUtils.getAllTakeAWayProducts();
    } else {
      productsFuture = fireStoreUtils.getAllDelevryProducts();
    }
  }

  bool isLoading = true;

  getLocationData() async {
    await getCurrentLocation().then((value) {
      setState(() {
        MyAppState.selectedPosotion = value;
      });
      getData();
      setState(() {
        isLoading = false;
      });
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

  Future<void> getData() async {
    getFoodType();
    lstNearByFood.clear();
    fireStoreUtils.getRestaurantNearBy().whenComplete(() async {
      lstAllRestaurant = fireStoreUtils.getAllRestaurants().asBroadcastStream();

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
        productsFuture.then((value) {
          for (int a = 0; a < event.length; a++) {
            for (int d = 0; d < (value.length > 20 ? 20 : value.length); d++) {
              if (event[a].id == value[d].vendorID && !lstNearByFood.contains(value[d])) {
                lstNearByFood.add(value[d]);
              }
            }
          }
        });

        FireStoreUtils().getPublicCoupons().then((value) {
          offersList.clear();
          offerVendorList.clear();
          value.forEach((element1) {
            event.forEach((element) {
              if (element1.restaurantId == element.id && element1.expireOfferDate!.toDate().isAfter(DateTime.now())) {
                offersList.add(element1);
                offerVendorList.add(element);
              }
            });
          });
          setState(() {});
        });

        FireStoreUtils().getStory().then((value) {
          storyList.clear();
          value.forEach((element1) {
            vendors.forEach((element) {
              if (element1.vendorID == element.id) {
                storyList.add(element1);
              }
            });
          });
          setState(() {});
        });
      });

      setState(() {});
    });
  }

  List<StoryModel> storyList = [];
}

// ignore: camel_case_types
class buildTitleRow extends StatelessWidget {
  final String titleValue;
  final Function? onClick;
  final bool? isViewAll;

  const buildTitleRow({
    Key? key,
    required this.titleValue,
    this.onClick,
    this.isViewAll = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDarkMode(context) ? const Color(DARK_COLOR) : const Color(0xffFFFFFF),
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titleValue.tr(), style: TextStyle(color: isDarkMode(context) ? Colors.white : const Color(0xFF000000), fontFamily: "Poppinsm", fontSize: 18)),
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

// ignore: must_be_immutable
class MoreStories extends StatefulWidget {
  List<StoryModel> storyList = [];
  int index;

  MoreStories({Key? key, required this.index, required this.storyList}) : super(key: key);

  @override
  _MoreStoriesState createState() => _MoreStoriesState();
}

class _MoreStoriesState extends State<MoreStories> {
  final storyController = StoryController();

  @override
  void dispose() {
    storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        StoryView(
            storyItems: List.generate(
              widget.storyList[widget.index].videoUrl.length,
              (i) {
                return StoryItem.pageVideo(
                  widget.storyList[widget.index].videoUrl[i],
                  controller: storyController,
                );
              },
            ).toList(),
            onStoryShow: (s) {
              debugPrint("Showing a story");
            },
            onComplete: () {
              debugPrint("--------->");
              debugPrint(widget.storyList.length.toString());
              debugPrint(widget.index.toString());
              if (widget.storyList.length - 1 != widget.index) {
                // Navigator.pop(context);
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => MoreStories(
                //       storyList: widget.storyList,
                //       index: widget.index + 1,
                //     )));

                setState(() {
                  widget.index = widget.index + 1;
                });
              } else {
                Navigator.pop(context);
              }
            },
            progressPosition: ProgressPosition.top,
            repeat: true,
            controller: storyController,
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.pop(context);
              }
            }),
        FutureBuilder(
          future: FireStoreUtils().getVendorByVendorID(widget.storyList[widget.index].vendorID.toString()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Container());
            } else {
              if (snapshot.hasError) {
                return Center(child: Text("Error".tr() + ": ${snapshot.error}"));
              } else {
                VendorModel? vendorModel = snapshot.data;
                double distanceInMeters = Geolocator.distanceBetween(vendorModel!.latitude, vendorModel.longitude, MyAppState.selectedPosotion.latitude, MyAppState.selectedPosotion.longitude);
                double kilometer = distanceInMeters / 1000;
                return Positioned(
                  top: 55,
                  child: InkWell(
                    onTap: () {
                      push(
                        context,
                        NewVendorProductsScreen(vendorModel: vendorModel),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: CachedNetworkImage(
                              imageUrl: vendorModel.photo,
                              height: 50,
                              width: 50,
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                                ),
                              ),
                              placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator.adaptive(
                                valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                              )),
                              errorWidget: (context, url, error) => ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.network(
                                    AppGlobal.placeHolderImage!,
                                    fit: BoxFit.cover,
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height,
                                  )),
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vendorModel.title.toString(), style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(vendorModel.reviewsCount != 0 ? (vendorModel.reviewsSum / vendorModel.reviewsCount).toStringAsFixed(1) : 0.toString(),
                                              style: const TextStyle(
                                                fontFamily: "Poppinsm",
                                                letterSpacing: 0.5,
                                                fontSize: 12,
                                                color: Colors.white,
                                              )),
                                          const SizedBox(width: 3),
                                          const Icon(
                                            Icons.star,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Icon(
                                    Icons.location_pin,
                                    size: 16,
                                    color: Color(COLOR_PRIMARY),
                                  ),
                                  SizedBox(
                                    width: 3,
                                  ),
                                  Text("${kilometer.toDouble().toStringAsFixed(currencyModel!.decimal)} KM", style: TextStyle(color: Colors.white, fontFamily: "Poppinsr")),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Container(
                                    height: 15,
                                    child: VerticalDivider(
                                      color: Colors.white,
                                      thickness: 2,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                      DateTime.now().difference(widget.storyList[widget.index].createdAt!.toDate()).inDays == 0
                                          ? 'Today'.tr()
                                          : "${DateTime.now().difference(widget.storyList[widget.index].createdAt!.toDate()).inDays.toString()} d",
                                      style: TextStyle(color: Colors.white, fontFamily: "Poppinsr")),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }
            }
          },
        )
      ],
    ));
  }
}
