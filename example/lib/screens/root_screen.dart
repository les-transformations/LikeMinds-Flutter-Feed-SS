import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_ss_fl/likeminds_feed_ss_fl.dart';

class TabApp extends StatefulWidget {
  final Widget feedWidget;
  final String uuid;

  const TabApp({
    super.key,
    required this.feedWidget,
    required this.uuid,
  });

  @override
  State<TabApp> createState() => _TabAppState();
}

class _TabAppState extends State<TabApp> with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    LMFeedThemeData lmFeedThemeData = LMFeedTheme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        backgroundColor: lmFeedThemeData.container,
        selectedIndex: tabController.index,
        onDestinationSelected: (index) {
          tabController.animateTo(index);
          setState(() {});
        },
        elevation: 10,
        indicatorColor: lmFeedThemeData.primaryColor,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home,
              color: lmFeedThemeData.onContainer,
            ),
            selectedIcon: Icon(
              Icons.home,
              color: lmFeedThemeData.onPrimary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_2_sharp,
              color: lmFeedThemeData.onContainer,
            ),
            selectedIcon: Icon(
              Icons.person_2_sharp,
              color: lmFeedThemeData.onPrimary,
            ),
            label: 'Activity',
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          HomeScreen(
            feedWidget: widget.feedWidget,
          ), // First tab content
          LMFeedActivityScreen(
            uuid: widget.uuid,
            postBuilder: suraasaPostWidgetBuilder,
            commentBuilder: suraasaCommentWidgetBuilder,
          ), // Second tab content
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Widget feedWidget;

  const HomeScreen({
    super.key,
    required this.feedWidget,
  });

  @override
  Widget build(BuildContext context) {
    return feedWidget;
  }
}
