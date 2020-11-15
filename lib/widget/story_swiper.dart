import 'package:flutter/widgets.dart';

typedef Widget StorySwiperWidgetBuilder(int index);

class StorySwiper extends StatefulWidget {
  final StorySwiperWidgetBuilder widgetBuilder;
  final int itemCount;
  final int visiblePageCount;
  final double dx;
  final double dy;
  final double aspectRatio;
  final double depthFactor;
  final double paddingStart;
  final double verticalPadding;

  final Widget endWidget;
  final int limitLength;

  final Function onPageChanged;
  final Function onPointUp;

  StorySwiper.builder(
      {Key key,
      @required this.widgetBuilder,
      this.itemCount,
      this.visiblePageCount = 4,
      this.dx = 60,
      this.dy = 20,
      this.aspectRatio = 2 / 3,
      this.depthFactor = 0.2,
      this.paddingStart = 32,
      this.verticalPadding = 8,
      this.endWidget,
      this.limitLength,
      this.onPageChanged,
      this.onPointUp})
      : super(key: key);

  @override
  _StorySwiperState createState() => _StorySwiperState();
}

class _StorySwiperState extends State<StorySwiper> {
  PageController _pageController;
  double _pagePosition = 0;
  List<Widget> _widgetList = [];
  double itemWidth;
  int _pageIndex = 0;

  List numbers = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _pagePosition = _pageController.page;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    itemWidth = MediaQuery.of(context).size.width;
  }

  @override
  Widget build(BuildContext context) {
    double positionX = 0.0;
    return Container(
      child: Stack(children: <Widget>[
        _getPages(),
        // TODO(lei): 两个Listener后续合并
        Listener(
          onPointerDown: (e) {
            positionX = e.position.dx;
          },
          onPointerUp: (e) {
            if (positionX == e.position.dx) {
              int index = _pageController.page.floor();
              double x = e.position.dx;
              for (var i = 1; i < numbers.length; ++i) {
                var num = numbers[i];
                if (x > numbers[i - 1] && x < num) {
                  index += i;
                  break;
                }
              }
              widget.onPointUp(index);
            }
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification && _pageController.page != _pageController.page.floor()) {
                Future.delayed(Duration.zero, () {
                  _pageController.animateToPage(
                    _pageController.page.round(),
                    duration: Duration(
                      milliseconds: 400,
                    ),
                    curve: Curves.ease,
                  );
                });
              }

              // onPageChanged
              if (notification.depth == 0 && widget.onPageChanged != null && notification is ScrollUpdateNotification) {
                final PageMetrics metrics = notification.metrics as PageMetrics;
                final int currentPage = metrics.page.round();
                if (currentPage != _pageIndex) {
                  _pageIndex = currentPage;
                  int itemCount = widget.itemCount > widget.limitLength ? widget.limitLength + 1 : widget.itemCount;
                  if (_pageIndex == itemCount - 1) {
                    widget.onPageChanged();
                  } else {
                    if (widget.onPageChanged != null) {
                      widget.onPageChanged(_pageIndex);
                    }
                  }
                }
              }
              return false;
            },
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: ClampingScrollPhysics(),
              controller: _pageController,
              itemCount: widget.itemCount > widget.limitLength ? widget.limitLength + 1 : widget.itemCount,
              itemBuilder: (context, index) => Container(
                width: itemWidth,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _getPages() {
    final List<Widget> pageList = [];
    final int currentPageIndex = _pagePosition.floor();
    final int lastPage = currentPageIndex + widget.visiblePageCount;
    final double width = MediaQuery.of(context).size.width;
    final double delta = _pagePosition - currentPageIndex;
    double top = -widget.dy * delta + widget.verticalPadding;
    double start = -widget.dx * delta + widget.paddingStart;

    if (widget.itemCount == 0) return Container();
    pageList.add(_getWidgetForValues(top, -width * delta + widget.paddingStart, currentPageIndex));

    int i;
    int rIndex = 1;
    for (i = currentPageIndex + 1; i < lastPage; i++) {
      start += widget.dx;
      top += widget.dy;
      if (i >= widget.itemCount) continue;
      pageList.add(_getWidgetForValues(top, start * _getDepthFactor(rIndex, delta), i));
      rIndex++;
    }
    if (i < widget.itemCount) {
      start += widget.dx * delta;
      top += widget.dy;
      pageList.add(_getWidgetForValues(top, start * _getDepthFactor(rIndex, delta), i));
    }
    if (numbers.isEmpty && widget.itemCount != 0) {
      for (var j = 0; j < pageList.length; ++j) {
        Positioned pageItem = pageList[j];
        numbers.add(pageItem.left);
      }
    }
    return Stack(children: pageList.reversed.toList());
  }

  double _getDepthFactor(int index, double delta) {
    return (1 - widget.depthFactor * (index - delta) / widget.visiblePageCount);
  }

  Widget _getWidgetForValues(double top, double start, int index) {
    Widget childWidget;
    if (index < _widgetList.length) {
      childWidget = _widgetList[index];
    } else {
      if (widget.limitLength > index) {
        childWidget = widget.widgetBuilder(index);
        _widgetList.insert(index, childWidget);
      } else if (widget.limitLength == index) {
        childWidget = widget.endWidget;
        _widgetList.insert(index, childWidget);
      }
    }
    return Positioned.directional(
      top: top,
      bottom: top,
      start: start,
      textDirection: TextDirection.ltr,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: childWidget,
      ),
    );
  }
}
