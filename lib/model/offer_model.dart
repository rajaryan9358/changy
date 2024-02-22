import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  String? offerId;
  String? offerCode;
  String? descriptionOffer;
  String? discount;
  String? discountType;
  Timestamp? expireOfferDate;
  bool? isEnableOffer;
  String? imageOffer = "";
  String? restaurantId;

  OfferModel({this.descriptionOffer, this.discount, this.discountType, this.expireOfferDate, this.imageOffer = "", this.isEnableOffer, this.offerCode, this.offerId, this.restaurantId});

  factory OfferModel.fromJson(Map<String, dynamic> parsedJson) {
    return OfferModel(
        descriptionOffer: parsedJson["description"],
        discount: parsedJson["discount"],
        discountType: parsedJson["discountType"],
        expireOfferDate: parsedJson["expiresAt"],
        imageOffer: parsedJson["image"] == null ? ((parsedJson["photo"] == null ? "" : parsedJson["photo"])) : parsedJson["image"],
        isEnableOffer: parsedJson["isEnabled"],
        offerCode: parsedJson["code"],
        offerId: parsedJson["id"],
        restaurantId: parsedJson["resturant_id"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "description": this.descriptionOffer,
      "discount": this.discount,
      "discountType": this.discountType,
      "expiresAt": this.expireOfferDate,
      "image": this.imageOffer,
      "isEnabled": this.isEnableOffer,
      "code": this.offerCode,
      "id": this.offerId,
      "resturant_id": this.restaurantId
    };
  }
}
