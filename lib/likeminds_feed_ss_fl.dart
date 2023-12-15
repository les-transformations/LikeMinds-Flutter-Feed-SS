library likeminds_feed_ss_fl;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_no_internet_widget/flutter_no_internet_widget.dart';
import 'package:likeminds_feed/likeminds_feed.dart';
import 'package:likeminds_feed_ss_fl/src/blocs/bloc.dart';
import 'package:likeminds_feed_ss_fl/src/utils/network_handling.dart';
import 'package:likeminds_feed_ss_fl/src/utils/notifications/notification_handler.dart';
import 'package:likeminds_feed_ss_fl/src/views/universal_feed_page.dart';
import 'package:likeminds_feed_ui_fl/likeminds_feed_ui_fl.dart';

import 'package:likeminds_feed_ss_fl/src/services/service_locator.dart';
import 'package:likeminds_feed_ss_fl/src/utils/constants/ui_constants.dart';
import 'package:likeminds_feed_ss_fl/src/utils/credentials/credentials.dart';
import 'package:media_kit/media_kit.dart';

export 'src/services/service_locator.dart';
export 'src/utils/analytics/analytics.dart';
export 'src/utils/notifications/notification_handler.dart';
export 'src/utils/share/share_post.dart';
export 'src/utils/local_preference/user_local_preference.dart';
export 'src/blocs/bloc.dart';
export 'src/utils/deep_link/deep_link_handler.dart';

/// Flutter environment manager v0.0.1
const prodFlag = !bool.fromEnvironment('DEBUG');

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class LMFeed extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String apiKey;
  final String? imageUrl;
  final Function(BuildContext context)? openChatCallback;
  final LMSDKCallback? callback;

  /// INIT - Get the LMFeed instance and pass the credentials (if any)
  /// to the instance. This will be used to initialize the app.
  /// If no credentials are provided, the app will run with the default
  /// credentials of Bot user in your community in `credentials.dart`
  static LMFeed instance({
    String? userId,
    String? userName,
    String? imageUrl,
    LMSDKCallback? callback,
    Function(BuildContext context)? openChatCallback,
    required String apiKey,
  }) {
    return LMFeed._(
      userId: userId,
      userName: userName,
      callback: callback,
      apiKey: apiKey,
      imageUrl: imageUrl,
      openChatCallback: openChatCallback,
    );
  }

  static Future<void> setupFeed({
    required String apiKey,
    LMSDKCallback? lmCallBack,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    await setupLMFeed(
      lmCallBack,
      apiKey,
      navigatorKey,
    );
  }

  static void logout() {
    locator<LMFeedClient>().logout(LogoutRequestBuilder().build());
  }

  const LMFeed._(
      {Key? key,
      this.userId,
      this.userName,
      this.imageUrl,
      required this.callback,
      required this.apiKey,
      this.openChatCallback})
      : super(key: key);

  @override
  _LMFeedState createState() => _LMFeedState();
}

class _LMFeedState extends State<LMFeed> {
  User? user;
  late final String userId;
  String? imageUrl;
  late final String userName;
  late final bool isProd;
  late final NetworkConnectivity networkConnectivity;
  Future<InitiateUserResponse>? initiateUser;
  Future<MemberStateResponse>? memberState;
  ValueNotifier<bool> rebuildOnConnectivityChange = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    networkConnectivity = NetworkConnectivity.instance;
    networkConnectivity.initialise();
    MediaKit.ensureInitialized();
    isProd = prodFlag;
    userId = widget.userId!.isEmpty
        ? isProd
            ? CredsProd.botId
            : CredsDev.botId
        : widget.userId!;
    imageUrl = widget.imageUrl;
    userName = widget.userName!.isEmpty ? "Test username" : widget.userName!;
    callInitiateUser();
    firebase();
  }

  void callSetupFunctions(InitiateUserResponse response) {
    locator<LMFeedBloc>().getCommunityConfigurations();
    memberState = locator<LMFeedBloc>().getMemberState();
    LMNotificationHandler.instance
        .registerDevice(response.initiateUser!.user.id);
  }

  void callInitiateUser() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      initiateUser = locator<LMFeedBloc>()
          .initiateUser((InitiateUserRequestBuilder()
                ..userId(userId)
                ..userName(userName))
              .build())
          .then((value) {
        if (value.success) {
          callSetupFunctions(value);
        }
        return value;
      });
    } else {
      initiateUser = locator<LMFeedBloc>()
          .initiateUser((InitiateUserRequestBuilder()
                ..userId(userId)
                ..userName(userName)
                ..imageUrl(imageUrl!))
              .build())
          .then((value) {
        if (value.success) {
          callSetupFunctions(value);
        }
        return value;
      });
    }
  }

  void firebase() {
    try {
      final firebase = Firebase.app();
      debugPrint("Firebase - ${firebase.options.appId}");
    } on FirebaseException catch (e) {
      debugPrint("Make sure you have initialized firebase, ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screeSize = MediaQuery.of(context).size;
    return InternetWidget(
      offline: FullScreenWidget(
        child: Container(
          width: screeSize.width,
          color: Colors.white,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.signal_wifi_off,
                size: 40,
                color: LMThemeData.kPrimaryColor,
              ),
              LMThemeData.kVerticalPaddingLarge,
              Text("No internet\nCheck your connection and try again",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LMThemeData.kPrimaryColor,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
      connectivity: networkConnectivity.networkConnectivity,
      // ignore: avoid_print
      whenOffline: () {
        debugPrint('No Internet');
        rebuildOnConnectivityChange.value = !rebuildOnConnectivityChange.value;
      },
      // ignore: avoid_print
      whenOnline: () {
        debugPrint('Connected to internet');
        callInitiateUser();
        rebuildOnConnectivityChange.value = !rebuildOnConnectivityChange.value;
      },

      loadingWidget: const Center(
          child: LMLoader(
        color: LMThemeData.kPrimaryColor,
      )),
      online: Theme(
        data: LMThemeData.suraasaTheme,
        child: ValueListenableBuilder(
          valueListenable: rebuildOnConnectivityChange,
          builder: (context, _, __) {
            return FutureBuilder<InitiateUserResponse>(
              future: initiateUser,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  InitiateUserResponse response = snapshot.data;
                  if (response.success) {
                    user = response.initiateUser?.user;

                    return FutureBuilder(
                      future: memberState,
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          return UniversalFeedScreen(
                            openChatCallback: widget.openChatCallback,
                          );
                        }

                        return Container(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          color: LMThemeData.kBackgroundColor,
                          child: const Center(
                            child: LMLoader(
                              color: LMThemeData.kPrimaryColor,
                            ),
                          ),
                        );
                      },
                    );
                  } else {}
                } else if (snapshot.hasError) {
                  debugPrint("Error - ${snapshot.error}");
                  return Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    color: LMThemeData.kBackgroundColor,
                    child: const Center(
                      child: Text("An error has occured",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          )),
                    ),
                  );
                }
                return Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  color: LMThemeData.kBackgroundColor,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
