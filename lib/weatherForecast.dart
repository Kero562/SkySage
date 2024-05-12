import 'package:intl/intl.dart';
import 'package:open_weather_client/models/coordinates.dart';
import 'package:open_weather_client/models/details.dart';
import 'package:open_weather_client/models/temperature.dart';
import 'package:open_weather_client/models/wind.dart';
import 'package:open_weather_client/open_weather.dart';

class myWeatherForecast {
  final String date;
  final Coordinates? coords;
  final List<Details> details;
  final String? name;
  final Temperature maxTemp;
  final Temperature minTemp;
  final Wind wind;

  myWeatherForecast({
    required this.date,
    required this.coords,
    required this.details,
    required this.name,
    required this.maxTemp,
    required this.minTemp,
    required this.wind,
  });

  static List<myWeatherForecast> aggregate(WeatherForecastData weatherFData) {
    Map<String, List<myWeatherForecast>> groupedForecasts = {};

    for (var forecast in weatherFData.forecastData) {
      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(forecast.date * 1000);
      String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);

      myWeatherForecast myForecast = myWeatherForecast(
        date: formattedDate,
        coords: forecast.coordinates,
        details: forecast.details,
        name: forecast.name,
        maxTemp: forecast.temperature,
        minTemp: forecast.temperature,
        wind: forecast.wind,
      );

      if (!groupedForecasts.containsKey(formattedDate)) {
        groupedForecasts[formattedDate] = [myForecast];
      } else {
        groupedForecasts[formattedDate]!.add(myForecast);
      }
    }

    List<myWeatherForecast> aggregatedForecasts = [];
    groupedForecasts.forEach((date, forecasts) {
      Temperature minTemp = forecasts[0].minTemp;
      Temperature maxTemp = forecasts[0].maxTemp;

      for (var forecast in forecasts) {
        if (forecast.minTemp.currentTemperature < minTemp.currentTemperature) {
          minTemp = forecast.minTemp;
        }
        if (forecast.maxTemp.currentTemperature > maxTemp.currentTemperature) {
          maxTemp = forecast.maxTemp;
        }
      }

      myWeatherForecast dailyForecast = myWeatherForecast(
        date: date,
        coords: forecasts[0].coords,
        details: forecasts[0].details,
        name: forecasts[0].name,
        minTemp: minTemp,
        maxTemp: maxTemp,
        wind: forecasts[0].wind,
      );

      aggregatedForecasts.add(dailyForecast);
    });

    return aggregatedForecasts;
  }
}