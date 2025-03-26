import 'dart:ui';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WondersMapPage extends StatefulWidget {
  const WondersMapPage({super.key});

  @override
  State<WondersMapPage> createState() => _WondersMapPageState();
}

class _WondersMapPageState extends State<WondersMapPage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _mapHeightAnimation;
  late final Animation<double> _marginAnimation;
  late final Animation<double> _headerRadiusAnimation;
  late final Animation<double> _detailsPanelRadiusAnimation;
  late final Animation<double> _toggleButtonPositionAnimation;
  late final Animation<double> _textScaleAnimation;
  late final Animation<double> _detailsPanelHeightAnimation;
  late final Animation<double> _imageHeightAnimation;

  // Create a controller for the map view and a map with a navigation basemap.
  final _mapViewController = ArcGISMapView.createController();
  final _arcGISMap = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISNavigation);

  final _graphicsOverlay = GraphicsOverlay();
  bool _mapReady = false;
  bool _largeView = false;
  bool _showMapStyleView = false;
  bool _showIntroText = true;
  Map<String, dynamic> _selectedWonderDetails = {};
  // Create a future to load basemaps.
  late Future _loadBaseMapsFuture;
  // Create a default image.
  final _defaultImage = Image.asset('assets/basemap_default.png');
  // Create a dictionary to store basemaps.
  final _baseMaps = <Basemap, Image>{};
  int selectedMapStyleIndex = -1;

  @override
  void initState() {
    super.initState();
    // Load basemaps when the app starts.
    _loadBaseMapsFuture = loadBaseMaps();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        setState(() => _showIntroText = false);
      } else if (status == AnimationStatus.completed) {
        setState(() {
          _largeView = true;
          _mapViewController.isAttributionTextVisible = true;
        });
      } else if (status == AnimationStatus.reverse) {
        setState(() {
          _largeView = false;
          _mapViewController.isAttributionTextVisible = false;
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _showIntroText = true);
      }
    });

    // Define animations
    _mapHeightAnimation = Tween<double>(
      begin: 0.25,
      end: 1,
    ).animate(_animationController);
    _marginAnimation = Tween<double>(
      begin: 25,
      end: 0,
    ).animate(_animationController);
    _headerRadiusAnimation = Tween<double>(
      begin: 20,
      end: 0,
    ).animate(_animationController);
    _detailsPanelRadiusAnimation = Tween<double>(
      begin: 0,
      end: 15,
    ).animate(_animationController);
    _toggleButtonPositionAnimation = Tween<double>(
      begin: 20,
      end: 60,
    ).animate(_animationController);
    _textScaleAnimation = Tween<double>(begin: 1.2, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _imageHeightAnimation = Tween<double>(begin: 0, end: 125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mediaQuery = MediaQuery.of(context);
      _detailsPanelHeightAnimation = Tween<double>(
        begin: mediaQuery.size.height * 0.2,
        end: 50,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleView() {
    _largeView
        ? _animationController.reverse()
        : _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildAnimatedMap(screenSize),
              if (_showIntroText) _buildIntroText(screenSize),
              if (!_mapReady) const Center(child: CircularProgressIndicator()),
              if (_selectedWonderDetails.isNotEmpty) _buildDetailsPanel(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedMap(Size screenSize) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: _marginAnimation.value),
        height: screenSize.height * _mapHeightAnimation.value,
        width: screenSize.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_headerRadiusAnimation.value),
          color: Colors.black38,
          boxShadow: [
            if (!_largeView)
              BoxShadow(
                blurRadius: 1,
                spreadRadius: 2,
                color: Colors.grey.shade200,
              ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(_headerRadiusAnimation.value),
              child: ArcGISMapView(
                controllerProvider: () => _mapViewController,
                onMapViewReady: onMapViewReady,
                onTap: _onMapTapped,
              ),
            ),
            Positioned(
              top: _toggleButtonPositionAnimation.value,
              right: 20,
              child: Column(
                spacing: 8,
                children: [
                  _buildToggleButton(),
                  if (_largeView && !_showMapStyleView) _buildMapStyleButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: _detailsPanelHeightAnimation.value,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            _detailsPanelRadiusAnimation.value,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _largeView ? 1.0 : 0.0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 650),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Image.asset(
                  _selectedWonderDetails['image'],
                  fit: BoxFit.cover,
                  height:
                      _imageHeightAnimation
                          .value, // Unique key to trigger animation when image changes
                  key: ValueKey<String>(_selectedWonderDetails['image']),
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(15 * _textScaleAnimation.value),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2), // Slight slide-up effect
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  key: ValueKey<String>(
                    '${_selectedWonderDetails['name'] as String} ${_selectedWonderDetails['country'] as String} ${_selectedWonderDetails['description'] as String}',
                  ),
                  spacing: 8 * _textScaleAnimation.value,
                  children: [
                    _buildText(
                      _selectedWonderDetails['name'],
                      bold: true,
                      fontSize: 15,
                    ),
                    _buildText(
                      _selectedWonderDetails['country'],
                      bold: true,
                      fontSize: 18,
                    ),
                    _buildText(
                      _selectedWonderDetails['description'],
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return MaterialButton(
      onPressed: _toggleView,
      padding: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      elevation: 2,
      minWidth: 0,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          _largeView
              ? CupertinoIcons.arrow_down_right_arrow_up_left
              : CupertinoIcons.arrow_up_left_arrow_down_right,
          key: ValueKey<bool>(_largeView),
          size: 25,
          color: Colors.black,
        ),
      ),
    );
  }

  Future<void> _onMapTapped(Offset offset) async {
    final identifiedGraphics = await _mapViewController.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: offset,
      tolerance: 12,
      maximumResults: 10,
    );

    // Check if the identified graphic is the same as the sample graphic.
    if (identifiedGraphics.graphics.isNotEmpty) {
      final graphic = identifiedGraphics.graphics.first;
      if (_graphicsOverlay.graphics.contains(graphic)) {
        setState(() => _selectedWonderDetails = graphic.attributes);
      }
    } else {
      setState(() => _selectedWonderDetails = {});
    }
  }

  Widget _buildMapStyleButton() {
    return MaterialButton(
      onPressed: () async {
        setState(() => _showMapStyleView = true);
        await _changeMapStyle();
      },
      padding: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      elevation: 2,
      minWidth: 0,
      child: const Icon(
        CupertinoIcons.layers_alt_fill,
        size: 25,
        color: Colors.black,
      ),
    );
  }

  Widget _buildIntroText(Size screenSize) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      top: screenSize.height * 0.3,
      left: 0,
      right: 0,
      child: const Column(
        children: [
          Text(
            'The Seven Wonders of the World',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            '(Click on a wonder to reveal more details.)',
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildText(
    String text, {
    bool bold = false,
    double fontSize = 14,
    int? maxLines,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: fontSize * _textScaleAnimation.value,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> onMapViewReady() async {
    _mapViewController.arcGISMap = _arcGISMap;
    _mapViewController.isAttributionTextVisible = false;
    await _addWondersToMap();
    // Set the ready state variable to true to enable the sample UI.
    setState(() => _mapReady = true);
  }

  // Add Seven Wonders as points on the map
  Future<void> _addWondersToMap() async {
    for (final wonder in sevenWonders) {
      // Create a picture marker symbol using an image asset.
      final image = await ArcGISImage.fromAsset(wonder['pin']);
      final pictureMarkerSymbol = PictureMarkerSymbol.withImage(image);
      pictureMarkerSymbol.width = 50;
      pictureMarkerSymbol.height = 50;
      pictureMarkerSymbol.offsetY = pictureMarkerSymbol.height / 2;
      _graphicsOverlay.graphics.add(
        Graphic(
          geometry: wonder['location'] as ArcGISPoint,
          symbol: pictureMarkerSymbol,
          attributes: {
            'name': wonder['name'],
            'country': wonder['country'],
            'description': wonder['description'],
            'image': wonder['image'],
          },
        ),
      );
    }
    // Add the graphics overlay to the map view controller.
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);
  }

  Future<void> _changeMapStyle() async {
    await showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (_) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: 4,
              ),
              child: Row(
                children: [
                  const Text(
                    'Choose Map',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.clear_circled_solid),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StatefulBuilder(
                builder: (context, modalState) {
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: FutureBuilder(
                      future: _loadBaseMapsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(14),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3, // 3 items per row
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: _baseMaps.length,
                            itemBuilder: (context, index) {
                              final basemap = _baseMaps.keys.elementAt(index);
                              final imageWidget =
                                  _baseMaps[basemap] ?? _defaultImage;
                              final isSelected = selectedMapStyleIndex == index;

                              return GestureDetector(
                                onTap: () async {
                                  modalState(() {
                                    selectedMapStyleIndex =
                                        index; // Update local state
                                    _arcGISMap.basemap = basemap;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.blue
                                              : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 1,
                                        spreadRadius: 2,
                                        color: Colors.grey.shade200,
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Stack(
                                      children: [
                                        // The Image
                                        SizedBox.expand(
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: imageWidget,
                                          ),
                                        ),
                                        // Blurred backdrop with text
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: SizedBox(
                                            height: 45,
                                            child: ClipRect(
                                              clipBehavior: Clip.antiAlias,
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(
                                                  sigmaX: 20,
                                                  sigmaY: 20,
                                                ),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                      ),
                                                  color: Colors.black.withAlpha(
                                                    120,
                                                  ), // Darker overlay
                                                  child: Text(
                                                    basemap.name,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          // Display a loading message while loading basemaps.
                          return const Center(
                            child: Text('Loading basemaps...'),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ).then((value) {
      // Show map style button after modal is dismissed.
      setState(() {
        _showMapStyleView = false;
      });
    });
  }

  Future loadBaseMaps() async {
    // Create a portal to access online items.
    final portal = Portal.arcGISOnline();
    // Load basemaps from portal.
    final basemaps = await portal.developerBasemaps();
    await Future.wait(basemaps.map((basemap) => basemap.load()));
    basemaps.sort((a, b) => a.name.compareTo(b.name));

    // Load each basemap to access and display attribute data in the UI.
    for (final basemap in basemaps) {
      if (basemap.item != null) {
        final thumbnail = basemap.item!.thumbnail;
        if (thumbnail != null) {
          await thumbnail.load();
          _baseMaps[basemap] = Image.network(thumbnail.uri.toString());
        }
      } else {
        // If the basemap does not have a thumbnail, use the default image.
        _baseMaps[basemap] = Image.asset('assets/basemap_default.png');
      }
    }
  }
}

final List<Map<String, dynamic>> sevenWonders = [
  {
    'name': 'Great Wall of China',
    'country': 'China 🇨🇳',
    'description':
    'A world-famous defensive wall in China, stretching over 13,000 miles.',
    'pin': 'assets/images/great_wall_of_china_pin.png',
    'image': 'assets/images/great_wall_of_china.jpg',
    'location': ArcGISPoint(
      x: 117.2360,
      y: 40.6769,
      spatialReference: SpatialReference.wgs84,
    ),
  },
  {
    'name': 'Chichén Itzá',
    'country': 'Mexico 🇲🇽',
    'description':
    'An ancient Mayan city in Mexico, famous for its pyramid, El Castillo.',
    'pin': 'assets/images/chichen_itza_pin.png',
    'image': 'assets/images/chichen_itza.jpg',
    'location': ArcGISPoint(
      x: -88.5678,
      y: 20.6843,
      spatialReference: SpatialReference.wgs84,
    ),
  },
  {
    'name': 'Petra',
    'country': 'Jordan 🇯🇴',
    'description':
    'A famous archaeological site in Jordan, known for its rock-cut architecture.',
    'pin': 'assets/images/petra_pin.png',
    'image': 'assets/images/petra.jpg',
    'location': ArcGISPoint(
      x: 35.4444,
      y: 30.3285,
      spatialReference: SpatialReference.wgs84,
    ),
  },
  {
    'name': 'Machu Picchu',
    'country': 'Peru 🇵🇪',
    'description':
    'A 15th-century Incan citadel in Peru, situated high in the Andes Mountains.',
    'pin': 'assets/images/machu_picchu_pin.png',
    'image': 'assets/images/machu_picchu.jpg',
    'location': ArcGISPoint(
      x: -72.5450,
      y: -13.1631,
      spatialReference: SpatialReference.wgs84,
    ),
  },
  {
    'name': 'Christ the Redeemer',
    'country': 'Brazil 🇧🇷',
    'description': 'A giant statue of Jesus Christ in Rio de Janeiro, Brazil.',
    'pin': 'assets/images/christ_the_redeemer_pin.png',
    'image': 'assets/images/christ_the_redeemer.jpg',
    'location': ArcGISPoint(
      x: -43.2105,
      y: -22.9519,
      spatialReference: SpatialReference.wgs84,
    ),
  },
  {
    'name': 'Colosseum',
    'country': 'Italy 🇮🇹',
    'description':
    'An ancient amphitheater in Rome, Italy, once used for gladiator battles.',
    'pin': 'assets/images/colosseum_pin.png',
    'image': 'assets/images/colosseum.jpg',
    'location': ArcGISPoint(
      x: 12.4922,
      y: 41.8902,
      spatialReference: SpatialReference.wgs84,
    ),
  },
  {
    'name': 'Taj Mahal',
    'country': 'India 🇮🇳',
    'description':
    'A white marble mausoleum in India, built by Emperor Shah Jahan.',
    'pin': 'assets/images/taj_mahal_pin.png',
    'image': 'assets/images/taj_mahal.jpg',
    'location': ArcGISPoint(
      x: 78.0421,
      y: 27.1751,
      spatialReference: SpatialReference.wgs84,
    ),
  },
];
