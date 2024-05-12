// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, non_constant_identifier_names

import 'dart:async';

import 'package:feather_icons_svg/feather_icons_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icon_shadow/flutter_icon_shadow.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_weather_client/enums/languages.dart';
import 'package:open_weather_client/open_weather.dart';
import 'package:lottie/lottie.dart';
import 'package:daylight/daylight.dart';
import 'package:country_list_pick/country_list_pick.dart';
import 'package:stuff/MapScreen.dart';
import 'package:stuff/weatherForecast.dart';

OpenWeather openWeather =  OpenWeather(apiKey: 'ce048c5ef796ba7005eb0e78b4a10bc4');

void main() {
  runApp(const SkySage());
}

class SkySage extends StatelessWidget {
  const SkySage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,

      ),
      home: const SkySageWid(),
    );
  }
}

class SkySageWid extends StatefulWidget {
  const SkySageWid({super.key});

  @override
  State<SkySageWid> createState() => _SkySageWidState();
}

class _SkySageWidState extends State<SkySageWid> with TickerProviderStateMixin {

  bool _isSearching = false;
  bool _isSearchingZC = false;
  bool _isSearchingCoord = false;

  bool currentInfoDisplayedWithName = false;
  late String cityNameOut;
  bool currentInfoDisplayedWithZC = false;
  late int zipCodeOut;
  bool currentInfoDisplayedWithCoords = false;
  late double latOut;
  late double lonOut;
  bool currentInfoDisplayedWithMaps = false;

  String _selectedCountryCode = "US"; //starting default
  Future<WeatherData>? _weatherDataFuture;
  Future<WeatherForecastData>? _weatherDataForecastFuture;
  String dayNight = "";
  String _unit = "Imperial";
  TextEditingController latitudeController = TextEditingController();

  //
  late AnimationController _controller;
  late Animation _animation;


  @override
  void initState(){
    super.initState();
    _weatherDataFuture = _fetchWeatherData();
    _weatherDataForecastFuture = _fetchForecastData();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInSine));
  }

  @override
  void dispose()
  {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildWeatherImage(String weatherShortDescription)
  {

    switch(weatherShortDescription.toLowerCase())
    {
            case 'clear':
                  if (dayNight == 'day')
                  {
                    return Image.asset('assets/sun.png');
                  } else {
                    return Image.asset('assets/moon.png');
                  }
            case 'clouds':
                  return Image.asset('assets/clouds.png');
            case 'snow':
                  return Image.asset('assets/snow.png');
            case 'rain':
            case 'drizzle':
                  return Image.asset('assets/rain.png');
            case 'mist':
                  return Image.asset('assets/mist.png');
            default:
                  return Image.asset('assets/missing.png');          
    }
  }

  //to update the weather unit while not reseting location
  Future<WeatherData> _updateWeatherData() async {
          WeatherData weatherDataFut;
          if (currentInfoDisplayedWithName) {
                weatherDataFut = await openWeather.currentWeatherByCityName(
                    cityName: cityNameOut,
                    weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                );
          } else if (currentInfoDisplayedWithZC) {
                weatherDataFut = await openWeather.currentWeatherByZipCode(
                zipCode: zipCodeOut, 
                countryCode: _selectedCountryCode,
                weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                );
          } else if (currentInfoDisplayedWithCoords || currentInfoDisplayedWithMaps)
          {
            weatherDataFut = await openWeather.currentWeatherByLocation(
              latitude: latOut, 
              longitude: lonOut,
              weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
              );
          }
          else {
                weatherDataFut = await _fetchWeatherData();
          }
        return weatherDataFut;
}

  Future<WeatherForecastData> _updateForecastData() async {
          WeatherForecastData weatherDataFut;
          if (currentInfoDisplayedWithName) {
                weatherDataFut = await openWeather.fiveDaysWeatherForecastByCityName(
                    cityName: cityNameOut,
                    weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                );
          } else if (currentInfoDisplayedWithZC) {
                weatherDataFut = await openWeather.fiveDaysWeatherForecastByZipCode(
                zipCode: zipCodeOut, 
                countryCode: _selectedCountryCode,
                weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                );
          } else if (currentInfoDisplayedWithCoords || currentInfoDisplayedWithMaps)
          {
            weatherDataFut = await openWeather.fiveDaysWeatherForecastByLocation(
              latitude: latOut, 
              longitude: lonOut,
              weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
              );
          }
          else {
                weatherDataFut = await _fetchForecastData();
          }
        return weatherDataFut;
}


  Future<WeatherData> _fetchWeatherData() async{
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled)
    {
      return Future.error('Location service is not enabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
    {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
      {
        return Future.error('Location perms denied');
      }
    }

    if (permission == LocationPermission.deniedForever)
    {
      return Future.error('perm denied');
    }

    Position pos =  await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );

    WeatherData weatherData = await openWeather
    .currentWeatherByLocation(
    latitude: pos.latitude,
    longitude: pos.longitude,
    weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC)
    .catchError((err) => print(err));

    final loc = DaylightLocation(pos.latitude, pos.longitude);
    final locCalc = DaylightCalculator(loc);
    final results = locCalc.calculateForDay(DateTime.now(), Zenith.astronomical);

    if (results.sunrise != null && results.sunset != null)
    {
      DateTime sunrise = results.sunrise!;
      DateTime sunset = results.sunset!;

      if (DateTime.now().toUtc().isAfter(sunrise) && DateTime.now().toUtc().isBefore(sunset))
        {
          dayNight = "day";
          print('day');
        } else {
          dayNight = "night";
          print('night');
        }
    } else {
      print('error');
    }

    return weatherData;
  }

  Future<WeatherForecastData> _fetchForecastData() async {

      Position pos =  await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
      );

      WeatherForecastData weatherData = await openWeather.fiveDaysWeatherForecastByLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
        language: Languages.ENGLISH
      );

      return weatherData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait<dynamic>([_weatherDataFuture as Future<dynamic>, _weatherDataForecastFuture as Future<dynamic>]),
      builder: (context, snapshot) 
      {
        if (snapshot.connectionState == ConnectionState.waiting)
        {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            )
          );
        } else {
          //final weatherData = snapshot.data!;
          final List<dynamic> data = snapshot.data as List<dynamic>;
          final WeatherData weatherData = data[0] as WeatherData;
          final WeatherForecastData forecastData = data[1] as WeatherForecastData;
          String weatherShortDescription = '';

          List<myWeatherForecast> MyWeatherF = myWeatherForecast.aggregate(forecastData); //ignore index 0, that's the current day which is already displayed

          for (var detail in weatherData.details) {
              weatherShortDescription = detail.weatherShortDescription;
          }

          //print(weatherData.name);
          return  Scaffold(
            resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [

            Container( //wrapped drawerheader with a container to decrease its height (SizedBox also works)
              height: 100,
              child: const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  '↯ Options ↯',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  )
              ),
            ),

            ListTile(
              title: const Text('Search by city name'),
              onTap: () async {
                setState(() {
                  _isSearchingCoord = false;
                  _isSearchingZC = false;
                  _isSearching = true; //activate isSearching
                });

                Navigator.pop(context);
              },
            ),

            
            ListTile(
              title: const Text('Search by zip code'),
              onTap: () async {
                setState(() {
                  _isSearchingCoord = false;
                  _isSearching = false;
                  _isSearchingZC = true; //activate isSearchingZC
                });

                Navigator.pop(context);
              },
            ),

              ListTile(
              title: const Text('Search by coordinates'),
              onTap: () async {
                setState(() {
                  _isSearching = false;
                  _isSearchingZC = false;
                  latitudeController.clear();
                  _isSearchingCoord = true;
                });

                Navigator.pop(context);
              },
            ),

            ListTile(
              title: const Text('Change Unit'),
            ),

            RadioListTile(
              title: Text("Imperial"),
              value: 'Imperial',
              groupValue: _unit,
              onChanged: (value) {
                setState(() {
                  _unit = value.toString();
                  //_weatherDataFuture = _fetchWeatherData();
                  _weatherDataFuture = _updateWeatherData();
                  _weatherDataForecastFuture = _updateForecastData();
                });
                Navigator.pop(context);
              },
            ),

              RadioListTile(
              title: Text("Metric"),
              value: 'Metric',
              groupValue: _unit,
              onChanged: (value) {
                
                setState(() {
                  _unit = value.toString();
                  //_weatherDataFuture = _fetchWeatherData();
                  _weatherDataFuture = _updateWeatherData();
                  _weatherDataForecastFuture = _updateForecastData();
                });
                Navigator.pop(context);
              },
            ),

            ListTile(
              title: const Text('Select via Map'),
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                ).then((value) async {
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                  
                  List<double> coords = value as List<double>; //received parameters

                  currentInfoDisplayedWithMaps = true;
                  currentInfoDisplayedWithName = false;
                  currentInfoDisplayedWithCoords = false;
                  currentInfoDisplayedWithZC = false;
                  latOut = coords[0];
                  lonOut = coords[1];

                  final weatherData = await openWeather.currentWeatherByLocation(
                  latitude: latOut,
                  longitude: lonOut,
                  weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                );

                final weatherDataForecast = await openWeather.fiveDaysWeatherForecastByLocation(
                  latitude: latOut,
                  longitude: lonOut,
                  weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                );

                 setState(() {
                  _weatherDataFuture = Future.value(weatherData);
                  _weatherDataForecastFuture = Future.value(weatherDataForecast);
                });
                
                });
              },
            )
          ],
        ),
      ),
      body: Stack(
        children: [ //2 children stacked; container then column on top of it

        //   Container(
        //   decoration: BoxDecoration(
        //     gradient: LinearGradient(
        //       begin: Alignment.topCenter,
        //       end: Alignment.bottomCenter,
        //       colors: [
        //         Color.fromARGB(255, 108, 117, 223),
        //         Color(0xFFC39BD3),
        //       ]
        //       ),
        //   ),
        // ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                begin: _animation.value,
                end: Alignment(-_animation.value.x, -_animation.value.y),
                colors: [
                Color.fromARGB(255, 108, 117, 223),
                Color(0xFFC39BD3),
              ]
              ),
          ),
              );
            }
          ),
      
      
          Column(
              children: [

                  AppBar( //the appbar is essential for the drawer to appear
                    backgroundColor: Colors.transparent, //make appbar transparent
                    elevation: 0, //remove appbar shadow
                    iconTheme: IconThemeData(
                      color: Color.fromARGB(255, 255, 191, 54),
                    ),
                    toolbarHeight: 27, //reduce the size of the appbar to give us some space
                  ),

                  if (_isSearching) ...[
                    //if the user clicked search
                    TapRegion(
                        onTapOutside: (tap){
                        setState(() {
                          _isSearching = false;
                        });
                        },
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for a city by name. Ex: Pomona',
                            border: InputBorder.none,
                          ),
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) async {
                            setState(() {
                              _isSearching = false; //hide the search bar
                            });

                            try {
                                 final weatherData = await openWeather.currentWeatherByCityName(
                                 cityName: value,
                                 weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                               );

                               final weatherDataForecast = await openWeather.fiveDaysWeatherForecastByCityName(
                                cityName: value,
                                weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                               );

                              setState(() {
                                _weatherDataFuture = Future.value(weatherData);
                                _weatherDataForecastFuture = Future.value(weatherDataForecast);
                              });
                              cityNameOut = value;
                              currentInfoDisplayedWithName = true;
                              currentInfoDisplayedWithMaps = false;
                              currentInfoDisplayedWithCoords = false;
                              currentInfoDisplayedWithZC = false;
                            } catch (error)
                            {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error),
                                      SizedBox(width: 10),
                                      Text('Error fetching data for $value'),
                                    ],
                                  ),
                                )
                              );
                            }
                          },
                        ),
                      ),
                    )
                  ],

                    if (_isSearchingZC) ...[
                    
                    TapRegion(
                      // onTapOutside: (tap){
                      //   setState(() {
                      //     _isSearchingZC = false;
                      //   });
                      // },
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            CountryListPick(
                              appBar: AppBar(
                                backgroundColor: Colors.blue,
                                title: Text('Select your country'),
                              ),
                              initialSelection: _selectedCountryCode,
                              onChanged: (CountryCode? code){
                                setState(() {
                                  _selectedCountryCode = code!.code!;
                                });
                              },
                            ),
                      
                            SizedBox(width: 10),
                      
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search for a city by zip code. Ex: 91709',
                                  border: InputBorder.none,
                                ),
                                autofocus: true,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (value) async {
                                  setState(() {
                                    _isSearchingZC = false; //hide the search bar
                                  });
                      
                                  try {
                                       final weatherData = await openWeather.currentWeatherByZipCode(
                                        zipCode: int.parse(value),
                                        countryCode: _selectedCountryCode,
                                        weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                                       );

                                       final weatherDataForecast = await openWeather.fiveDaysWeatherForecastByZipCode(
                                        zipCode: int.parse(value),
                                        countryCode: _selectedCountryCode,
                                        weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                                       );

                      
                                    setState(() {
                                      _weatherDataFuture = Future.value(weatherData);
                                      _weatherDataForecastFuture = Future.value(weatherDataForecast);
                                    });

                                    zipCodeOut = int.parse(value);
                                    currentInfoDisplayedWithName = false;
                                    currentInfoDisplayedWithMaps = false;
                                    currentInfoDisplayedWithCoords = false;
                                    currentInfoDisplayedWithZC = true;
                                  } catch (error)
                                  {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.error),
                                            SizedBox(width: 10),
                                            Text('Error fetching data for the info provided.'),
                                          ],
                                        ),
                                      )
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],

                    if (_isSearchingCoord) ...[
                    //if the user clicked search
                    TapRegion(
                        onTapOutside: (tap){
                        setState(() {
                          _isSearchingCoord = false;
                        });
                        },
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: latitudeController,
                                decoration: InputDecoration(
                                  hintText: 'Latitude',
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.next,
                                onSubmitted: (value) {
                                  FocusScope.of(context).nextFocus();
                                  },
                                onChanged: (value) {
                                  //
                                },
                              ),
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Longitude',
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.search,
                                onSubmitted: (value) async {
                                  setState(() {
                                    _isSearchingCoord = false;
                                  });

                                  try {
                                      final weatherData = await openWeather.currentWeatherByLocation(
                                        latitude: double.parse(latitudeController.text),
                                        longitude: double.parse(value),
                                        weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                                        );

                                      final weatherDataForecast = await openWeather.fiveDaysWeatherForecastByLocation(
                                        latitude: double.parse(latitudeController.text),
                                        longitude: double.parse(value),
                                        weatherUnits: (_unit == 'Imperial') ? WeatherUnits.IMPERIAL : WeatherUnits.METRIC,
                                      );

                                        setState(() {
                                          _weatherDataFuture = Future.value(weatherData);
                                          _weatherDataForecastFuture = Future.value(weatherDataForecast);
                                        });

                                        latOut = double.parse(latitudeController.text);
                                        lonOut = double.parse(value);
                                        currentInfoDisplayedWithName = false;
                                        currentInfoDisplayedWithMaps = false;
                                        currentInfoDisplayedWithCoords = true;
                                        currentInfoDisplayedWithZC = false;

                                  } catch (error)
                                  {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.error),
                                            SizedBox(width: 10),
                                            Text('Error fetching data for the info provided.'),
                                          ],
                                        ),
                                      )
                                    );
                                  }
                                },
                              )
                            )
                          ],
                        ),
                      ),
                    )
                  ],

                  Container(
                      margin: EdgeInsets.only(top: 30, bottom: 60),
                      child: Column(
                        children: [
                          Row(
                            children: [
                      
                              Expanded(
                                flex: 50,
                                child: Container(
                                  margin: EdgeInsets.only(left: 40),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 24,
                                            semanticLabel: "Location",
                                          ),

                                          SizedBox(width: 12),

                                          Expanded(
                                            flex: 60,
                                            child: Text(
                                              weatherData.name!,
                                              style: GoogleFonts.mateSc(
                                                color: Colors.black45,
                                                fontSize: 19.0,
                                                fontWeight: FontWeight.w600,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black87,
                                                    offset: Offset(1, 1),
                                                    blurRadius: 2,
                                                  )
                                                ]
                                              )
                                              ),
                                          ),
                                        ],
                                      ),

                                      
                                       
                                        Text(
                                            weatherData.temperature.currentTemperature.round().toString() + ((_unit == 'Imperial') ? '℉' : '℃'),
                                            style: GoogleFonts.montserratAlternates(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 65,
                                            ),
                                        ),

                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              'H: ${weatherData.temperature.tempMax.round().toString()}°',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700
                                              ),
                                              ),

                                            Text(
                                              "L: ${weatherData.temperature.tempMin.round().toString()}°",
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700
                                              ),
                                              ),
                                          ],
                                        ),

                                      Text(
                                        weatherShortDescription, //short description; sunny/cloudy/rain..etc
                                        style: GoogleFonts.mateSc(
                                          color: Colors.grey[800],
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                      
                              Expanded(
                                flex: 50,
                                child: _buildWeatherImage(weatherShortDescription),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  Container(
                    margin: EdgeInsets.only(left: 15),
                    child: Row(
                      children: [
                        Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(42)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.shade400,
                            offset: Offset(0, 20),
                            blurRadius: 30,
                            spreadRadius: -5
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.amberAccent.shade200,
                            Colors.amberAccent.shade400,
                            Colors.amberAccent.shade700,
                            Colors.amberAccent.shade700,
                          ],
                          stops: [
                            0.1,
                            0.3,
                            0.9,
                            1.0
                          ]
                        )
                      ),
                      child: Row(
                        children: [
                          Lottie.network('https://lottie.host/4a11b660-c65d-45fd-9abc-fcd0c2e1e98a/YPutSFhnYX.json',
                          width: 40,),
                          Text(
                                'Humidity: ${weatherData.temperature.humidity}%',
                                style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                        ],
                      ),
                        ),
                      ],
                    ),
                  ),

                    Container(
                    margin: EdgeInsets.only(right: 15, top: 12.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(42)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.shade400,
                            offset: Offset(0, 20),
                            blurRadius: 30,
                            spreadRadius: -5
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.amberAccent.shade200,
                            Colors.amberAccent.shade400,
                            Colors.amberAccent.shade700,
                            Colors.amberAccent.shade700,
                          ],
                          stops: [
                            0.1,
                            0.3,
                            0.9,
                            1.0
                          ]
                        )
                      ),
                      child: Row(
                        children: [
                          Lottie.network('https://lottie.host/817f8745-5870-4917-b6ce-3ba2def2893e/k2c7nNHqF9.json',
                          width: 40,),
                              Text(
                                  'Pressure: ${weatherData.temperature.pressure} hPa',
                                  style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w600,
                                  ),
                              ),
                        ],
                      ),
                        ),
                      ],
                    ),
                  ),

                    Container(
                    margin: EdgeInsets.only(left: 15, top: 12.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(42)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.shade400,
                            offset: Offset(0, 20),
                            blurRadius: 30,
                            spreadRadius: -5
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.amberAccent.shade200,
                            Colors.amberAccent.shade400,
                            Colors.amberAccent.shade700,
                            Colors.amberAccent.shade700,
                          ],
                          stops: [
                            0.1,
                            0.3,
                            0.9,
                            1.0
                          ]
                        )
                      ),
                      child: Row(
                        children: [
                          Lottie.network('https://lottie.host/eda1ab17-db38-4cd7-81bc-c34a5e0cf13b/mBvxa7Fqck.json',
                          width: 40,),
                              Text(
                                  'Wind Speed: ${weatherData.wind.speed}mil/h',
                                  style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w600,
                                  ),
                              ),
                        ],
                      ),
                        ),
                      ],
                    ),
                  ),

                    Container(
                    margin: EdgeInsets.only(right: 15, top: 12.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(42)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amberAccent.shade400,
                            offset: Offset(0, 20),
                            blurRadius: 30,
                            spreadRadius: -5
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.amberAccent.shade200,
                            Colors.amberAccent.shade400,
                            Colors.amberAccent.shade700,
                            Colors.amberAccent.shade700,
                          ],
                          stops: [
                            0.1,
                            0.3,
                            0.9,
                            1.0
                          ]
                        )
                      ),
                      child: Row(
                        children: [
                          Lottie.network('https://lottie.host/1b175d84-27d0-4dff-9b50-4d881372c8df/fT4S8yorJL.json',
                          width: 40,),
                              Text(
                                  'Wind Direction: ${weatherData.wind.deg}',
                                  style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w600,
                                  ),
                              ),
                        ],
                      ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.only(top: 75),
                    height: 120, // Adjust the height as needed
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: MyWeatherF.length - 1,
                      itemBuilder: (BuildContext context, int index) {

                          String innerWeatherShortDescription = '';
                          int adjustedIndex = index + 1;
                          IconData iconData = Icons.question_mark;
                          Color iconColor = Colors.black;
                          bool feather = false;
                          bool cloud = false;

                          for (var detail in MyWeatherF[adjustedIndex].details) {
                          innerWeatherShortDescription = detail.weatherShortDescription;
                          }

                          switch(innerWeatherShortDescription)
                          {
                            case "Clear":
                                iconData = Icons.sunny;
                                iconColor = Colors.yellow;
                            case "Clouds":
                              cloud = true;
                              iconData = Icons.cloud;
                              iconColor = Color.fromARGB(255, 255, 255, 255);
                              break;
                            case "Rain":
                            case "Drizzle":
                              feather = true;
                              break;
                            case "Snow":
                              iconData = Icons.snowing;
                              iconColor = Color.fromARGB(255, 5, 187, 187);
                              break;
                          }

                          Color c2 = Colors.black;
                          if (!cloud)
                          {
                            c2 = Color.fromARGB(255, 224, 228, 6);
                          } else {
                            c2 = Colors.lightBlueAccent.shade700;
                          }

                          DateTime today = DateTime.now();
                          DateTime correspondingDay = today.add(Duration(days: index + 1));
                          String dayName = DateFormat('E').format(correspondingDay);

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          width: 120, // Adjust the width as needed
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontSize: 20.0,
                                ),
                              ),
                              
                              !feather
                               ? IconShadow(
                                 Icon(
                                  iconData,
                                  color: iconColor,
                                  size: 32.0,
                                  ),
                                  shadowColor: c2,
                               )
                              :
                              FeatherIcon(
                                FeatherIcons.cloudRain,
                                size: 32.0,
                                color: Color.fromARGB(255, 23, 131, 219),
                              ),
                          
                              Text(
                                'L: ${MyWeatherF[index].minTemp.currentTemperature.round().toString()}°',
                                style: TextStyle(
                                  fontSize: 18.0,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'H: ${MyWeatherF[index].maxTemp.currentTemperature.round().toString()}°',
                                style: TextStyle(
                                  fontSize: 18.0,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
              ],
            ),
        ]
      ),
    );
        }
      } 
      );
  }
}