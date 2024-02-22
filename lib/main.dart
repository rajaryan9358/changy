import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodie_customer/constants.dart';
import 'package:foodie_customer/model/CurrencyModel.dart';
import 'package:foodie_customer/model/mail_setting.dart';
import 'package:foodie_customer/services/FirebaseHelper.dart';
import 'package:foodie_customer/services/helper.dart';
import 'package:foodie_customer/services/localDatabase.dart';
import 'package:foodie_customer/ui/auth/AuthScreen.dart';
import 'package:foodie_customer/ui/container/ContainerScreen.dart';
import 'package:foodie_customer/ui/onBoarding/OnBoardingScreen.dart';
import 'package:foodie_customer/userPrefrence.dart';
import 'package:foodie_customer/utils/DarkThemeProvider.dart';
import 'package:foodie_customer/utils/Styles.dart';
import 'package:foodie_customer/utils/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/User.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  await UserPreference.init();
  runApp(
    MultiProvider(
      providers: [
        Provider<CartDatabase>(
          create: (_) => CartDatabase(),
        )
      ],
      child: EasyLocalization(
          supportedLocales: [Locale('en'), Locale('ar'),Locale('th')],
          path: 'assets/translations',
          fallbackLocale: Locale('en'),
          saveLocale: true,
          useOnlyLangCode: true,
          useFallbackTranslations: true,
          child: MyApp()),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static User? currentUser;
  static Position selectedPosotion = Position.fromMap({'latitude': 0.0, 'longitude': 0.0});

  // Define an async function to initialize FlutterFire
  NotificationService notificationService = NotificationService();

  notificationInit() {
    notificationService.initInfo().then((value) async {
      String token = await NotificationService.getToken();
      log(":::::::TOKEN:::::: $token");
      if (currentUser != null) {
        await FireStoreUtils.getCurrentUser(currentUser!.userID).then((value) {
          if (value != null) {
            currentUser = value;
            currentUser!.fcmToken = token;
            FireStoreUtils.updateCurrentUser(currentUser!);
          }
        });
      }
    });
  }

  void initializeFlutterFire() async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      final FlutterExceptionHandler? originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails errorDetails) async {
        await FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
        originalOnError!(errorDetails);
        // Forward to original handler.
      };
      await FirebaseFirestore.instance.collection(Setting).doc("globalSettings").get().then((dineinresult) {
        if (dineinresult.exists && dineinresult.data() != null && dineinresult.data()!.containsKey("website_color")) {
          COLOR_PRIMARY = int.parse(dineinresult.data()!["website_color"].replaceFirst("#", "0xff"));
        }
      });

      await FirebaseFirestore.instance.collection(Setting).doc("DineinForRestaurant").get().then((dineinresult) {
        if (dineinresult.exists) {
          isDineInEnable = dineinresult.data()!["isEnabledForCustomer"];
        }
      });

      await FirebaseFirestore.instance.collection(Setting).doc("emailSetting").get().then((value) {
        if (value.exists) {
          mailSettings = MailSettings.fromJson(value.data()!);
        }
      });

      await FirebaseFirestore.instance.collection(Setting).doc("home_page_theme").get().then((value) {
        if (value.exists) {
          homePageThem = value.data()!["theme"];
        }
      });

      await FirebaseFirestore.instance.collection(Setting).doc("Version").get().then((value) {
        debugPrint(value.data().toString());
        appVersion = value.data()!['app_version'].toString();
      });

      await FirebaseFirestore.instance.collection(Setting).doc("googleMapKey").get().then((value) {
        print(value.data());
        GOOGLE_API_KEY = value.data()!['key'].toString();
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return themeChangeProvider;
      },
      child: Consumer<DarkThemeProvider>(
        builder: (context, value, child) {
          return MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              debugShowCheckedModeBanner: false,
              theme: Styles.themeData(themeChangeProvider.darkTheme, context),
              home: OnBoarding());
        },
      ),
    );
  }

  @override
  void initState() {
    notificationInit();
    initializeFlutterFire();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}
}

class OnBoarding extends StatefulWidget {
  @override
  State createState() {
    return OnBoardingState();
  }
}

class OnBoardingState extends State<OnBoarding> {
  late Future<List<CurrencyModel>> futureCurrency;

  Future hasFinishedOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool finishedOnBoarding = (prefs.getBool(FINISHED_ON_BOARDING) ?? false);

    if (finishedOnBoarding) {
      auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        User? user = await FireStoreUtils.getCurrentUser(firebaseUser.uid);
        if (user != null) {
          if (user.role == USER_ROLE_CUSTOMER) {
            if (user.active) {
              user.active = true;
              user.role = USER_ROLE_CUSTOMER;
              user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken() ?? '';
              await FireStoreUtils.updateCurrentUser(user);
              MyAppState.currentUser = user;
              pushReplacement(context, ContainerScreen(user: user));
            } else {
              user.lastOnlineTimestamp = Timestamp.now();
              user.fcmToken = "";
              await FireStoreUtils.updateCurrentUser(user);
              await auth.FirebaseAuth.instance.signOut();
              MyAppState.currentUser = null;
              Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();
              pushAndRemoveUntil(context, AuthScreen(), false);
            }
          } else {
            pushReplacement(context, AuthScreen());
          }
        } else {
          pushReplacement(context, AuthScreen());
        }
      } else {
        pushReplacement(context, AuthScreen());
      }
    } else {
      pushReplacement(context, OnBoardingScreen());
    }
  }

  @override
  void initState() {
    super.initState();
    hasFinishedOnBoarding();
    // futureCurrency= FireStoreUtils().getCurrency();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
        ),
      ),
    );
  }
}
