import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/AppGlobal.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/model/VendorCategoryModel.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/ui/categoryDetailsScreen/CategoryDetailsScreen.dart';

class CuisinesScreen extends StatefulWidget {
  const CuisinesScreen({Key? key, this.isPageCallFromHomeScreen = false, this.isPageCallForDineIn = false}) : super(key: key);

  @override
  _CuisinesScreenState createState() => _CuisinesScreenState();
  final bool? isPageCallFromHomeScreen;
  final bool? isPageCallForDineIn;
}

class _CuisinesScreenState extends State<CuisinesScreen> {
  final fireStoreUtils = FireStoreUtils();
  late Future<List<VendorCategoryModel>> categoriesFuture;

  @override
  void initState() {
    super.initState();
    categoriesFuture = fireStoreUtils.getCuisines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: isDarkMode(context) ? Color(DARK_VIEWBG_COLOR) : null,
        appBar: widget.isPageCallFromHomeScreen! ? AppGlobal.buildAppBar(context, "Categories") : null,
        body: FutureBuilder<List<VendorCategoryModel>>(
            future: categoriesFuture,
            initialData: [],
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  ),
                );

              if (snapshot.hasData || (snapshot.data?.isNotEmpty ?? false)) {
                return homePageThem == "theme_2"
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 5 / 6),
                          itemCount: snapshot.data!.length,
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
                                              maxLines: 1, style: TextStyle(color: isDarkMode(context) ? Colors.white : const Color(0xFF000000), fontFamily: "Poppinsr", fontSize: 12))
                                          .tr()),
                                )
                              ],
                            );
                          },
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(10),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return snapshot.data != null ? buildCuisineCell(snapshot.data![index]) : showEmptyState('No Categories'.tr(), context, description: "add-categories".tr());
                        });
              }
              return CircularProgressIndicator();
            }));
  }

  Widget buildCuisineCell(VendorCategoryModel cuisineModel) {
    return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () => push(
            context,
            CategoryDetailsScreen(
              category: cuisineModel,
              isDineIn: widget.isPageCallForDineIn!,
            ),
          ),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              image: DecorationImage(
                image: NetworkImage(cuisineModel.photo.toString()),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
              ),
            ),
            child: Center(
              child: Text(
                cuisineModel.title.toString(),
                style: TextStyle(color: Colors.white, fontFamily: "Poppinsm", fontSize: 27),
              ).tr(),
            ),
          ),
        ));
  }
}
