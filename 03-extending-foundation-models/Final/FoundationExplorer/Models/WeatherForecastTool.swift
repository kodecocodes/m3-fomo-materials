/// Copyright (c) 2025 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import MapKit
import OpenMeteoSdk
import FoundationModels

struct WeatherForecastTool: Tool {
    let name = "weatherLookup"
  let description = "Get the forecast temperatures and precipitation for the location provided as an argument."
  
  @Generable
  struct Arguments {
    @Guide(description: "The name of the location to get the forecast for.")
    var location: String
  }
  
  // 1
  func call(arguments: Arguments) async throws -> WeatherForecast? {
    // 2
    var weatherForecast: WeatherForecast? = nil

    // 3
    if let coordinates = await getCoordinatesFor(arguments.location) {
      weatherForecast = try? await getForecastFor(coordinates: coordinates)
    }

    // 4
    return weatherForecast
  }
  
  func getCoordinatesFor(_ name: String) async -> CLLocationCoordinate2D? {
    if let request = MKGeocodingRequest(addressString: name) {
      do {
        let mapitems = try await request.mapItems
        if let mapItem = mapitems.first {
          let coordinates = mapItem.location.coordinate
          return coordinates
        }
      } catch {
        print("Error doing city lookup: \(error.localizedDescription)")
        return nil
      }
    }
    return nil
  }

  func getForecastFor(coordinates: CLLocationCoordinate2D) async throws -> WeatherForecast {

    //  Make sure the URL contains '&format=flatbuffers'
    let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(coordinates.latitude)&longitude=\(coordinates.longitude)&hourly=temperature_2m,precipitation_probability&wind_speed_unit=mph&temperature_unit=fahrenheit&precipitation_unit=inch&format=flatbuffers")!

    let responses = try await WeatherApiResponse.fetch(url: url)

    struct WeatherData {
      let hourly: Hourly

      struct Hourly {
        let time: [Date]
        let temperature2m: [Float]
        let precipitationProbability: [Float]
      }
    }

    // Process first location. Add a for-loop for multiple locations or weather models
    let response = responses[0]

    // Attributes for timezone and location
    let latitude = response.latitude
    let longitude = response.longitude
    let elevation = response.elevation
    let utcOffsetSeconds = response.utcOffsetSeconds

    print("\nCoordinates: \(latitude)°N \(longitude)°E")
    print("Elevation: \(elevation)m asl")
    print("Timezone difference to GMT+0: \(utcOffsetSeconds)s")

    let hourly = response.hourly!

    // Note: The order of weather variables in the URL query and the 'at' indices below need to match!
    let data = WeatherData(
      hourly: .init(
        time: hourly.getDateTime(offset: utcOffsetSeconds),
        temperature2m: hourly.variables(at: 0)!.values,
        precipitationProbability: hourly.variables(at: 1)!.values,
      ),
    )

    // Timezone '.gmt' is deliberately used.
    // By adding 'utcOffsetSeconds' before, local-time is inferred
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = .gmt
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

    var weatherForecast = WeatherForecast(
      forecasts: [ForecastElements]()
    )

    var count: Int = 0
    for (i, date) in data.hourly.time.enumerated() {
      let forecast = ForecastElements(
        time: dateFormatter.string(from: date),
        temperature: data.hourly.temperature2m[i],
        precipitationProbability: data.hourly.precipitationProbability[i]
      )
      if count < 48 {
        weatherForecast.forecasts.append(forecast)
      }
      count += 1
    }

    return weatherForecast
  }
}
