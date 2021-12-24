import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// import 'configure/configure_nonweb.dart' if (dart.library.html) 'configure/configure_web.dart';
import 'layout/layout.dart';
import 'model/app_store_card_data.dart';
import 'route/view_routes.dart';
import 'template/app_store_card_description.dart';
import 'util/math_util.dart';
import 'widget/app_store_card.dart';
import 'widget/combine_list_view.dart';
import 'wrapper/image_wraper.dart';

void main() {
  // configureApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Flutter',
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        primaryColor: Colors.white,
      ),
      home: Layout(
        child: const MyHomePage(),
      ),
      routes: viewRoutes,
      onGenerateRoute: (RouteSettings settings) {
        final WidgetBuilder builder = (BuildContext context) {
          final String pageName = kIsWeb ? settings.name!.substring(1) : findSimilarPageName(settings.name!);
          return Layout(
            child: viewRoutes.containsKey(pageName) ? viewRoutes[pageName]!(context) : const MyHomePage(),
          );
        };

        return (kIsWeb || Platform.isAndroid)
            ? MaterialPageRoute(builder: builder)
            : CupertinoPageRoute(builder: builder);
      },
      debugShowCheckedModeBanner: false,
    );
  }

  String findSimilarPageName(String pageName) {
    return viewRoutes.keys.firstWhere(
      (e) => pageName.contains(e),
      orElse: () => 'index',
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  _MyHomePageState();

  List<AppStoreCardData> _cardDataList = <AppStoreCardData>[];
  List<Widget> _noEnabledList = <Widget>[];

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() {
    rootBundle.loadString('assets/data/CardDataList.json').then(
      (value) {
        if (value.isNotEmpty) {
          json.decode(value)['cardDataList']?.forEach((item) {
            _cardDataList.add(AppStoreCardData.fromMap(item));
          });

          viewRoutes.forEach((k, v) {
            if (!_cardDataList.any((e) => e.detailViewRouteName == k)) {
              _noEnabledList.add(appStoreCardItem(context, AppStoreCardData.simple(k)));
            }
          });

          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: _cardDataList.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                ),
              )
            : CombineListView(
                primary: true,
                list: _cardDataList,
                itemBuilder: (context, index) => appStoreCardItem(context, _cardDataList[index]),
                combineList: _noEnabledList,
                combineItemBuilder: (context, index) => _noEnabledList[index],
                combineLoopSize: 1,
              ),
      ),
    );
  }

  Widget placeholder() {
    return Container(
      height: random(123.456, 654.321),
      color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
    );
  }

  Widget appStoreCardItem(BuildContext context, AppStoreCardData data) {
    return AppStoreCard(
      key: Key(data.hashCode.toString()),
      elevation: 5,
      padding: EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 10,
      ),
      radius: BorderRadius.circular(20),
      showBackgroundWidget: (data.imagePath?.isNotEmpty ?? false) ? ImageWraper.path(data.imagePath!) : placeholder(),
      showForegroundWidget: AppStoreCardDescription(
        mode: data.descriptionMode,
        data: data.descriptionData,
      ),
      detailWidget: viewRoutes[data.detailViewRouteName]!(context),
      isAlwayShow: data.descriptionMode == AppStoreCardDescriptionMode.classic,
    );
  }
}
