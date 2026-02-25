import Foundation
import XCTest
import ObjectMapper
import Alamofire
@testable import AlamofireObjectMapper

class AlamofireObjectMapperTests: XCTestCase {
    
    let sampleURL = "https://raw.githubusercontent.com/tristanhimmelman/AlamofireObjectMapper/d8bb95982be8a11a2308e779bb9a9707ebe42ede/sample_json"
    let keypathURL = "https://raw.githubusercontent.com/tristanhimmelman/AlamofireObjectMapper/2ee8f34d21e8febfdefb2b3a403f18a43818d70a/sample_keypath_json"
    let nestedKeypathURL = "https://raw.githubusercontent.com/tristanhimmelman/AlamofireObjectMapper/97231a04e6e4970612efcc0b7e0c125a83e3de6e/sample_keypath_json"
    let arrayURL = "https://raw.githubusercontent.com/tristanhimmelman/AlamofireObjectMapper/f583be1121dbc5e9b0381b3017718a70c31054f7/sample_array_json"

    func testResponseObject() {
        let expectation = self.expectation(description: "Object mapping")
        AF.request(sampleURL).responseObject { (response: AFDataResponse<WeatherResponse>) in
            expectation.fulfill()
            XCTAssertNotNil(response.value?.location)
            XCTAssertNotNil(response.value?.threeDayForecast)
        }
        waitForExpectations(timeout: 10)
    }

    func testResponseObjectMapToObject() {
        let expectation = self.expectation(description: "Map to existing object")
        let weatherResponse = WeatherResponse()
        weatherResponse.date = Date()
        
        AF.request(sampleURL).responseObject(mapToObject: weatherResponse) { (response: AFDataResponse<WeatherResponse>) in
            expectation.fulfill()
            XCTAssertNotNil(response.value?.date)
            XCTAssertNotNil(response.value?.location)
        }
        waitForExpectations(timeout: 10)
    }

    func testResponseObjectWithKeyPath() {
        let expectation = self.expectation(description: "KeyPath mapping")
        AF.request(keypathURL).responseObject(keyPath: "data") { (response: AFDataResponse<WeatherResponse>) in
            expectation.fulfill()
            XCTAssertNotNil(response.value?.location)
        }
        waitForExpectations(timeout: 10)
    }

    func testResponseObjectWithNestedKeyPath() {
        let expectation = self.expectation(description: "Nested KeyPath")
        AF.request(nestedKeypathURL).responseObject(keyPath: "response.data") { (response: AFDataResponse<WeatherResponse>) in
            expectation.fulfill()
            XCTAssertNotNil(response.value?.location)
        }
        waitForExpectations(timeout: 10)
    }

    func testResponseArray() {
        let expectation = self.expectation(description: "Array mapping")
        AF.request(arrayURL).responseArray { (response: AFDataResponse<[Forecast]>) in
            expectation.fulfill()
            XCTAssertEqual(response.value?.count, 3)
        }
        waitForExpectations(timeout: 10)
    }

    func testArrayResponseArrayWithKeyPath() {
        let expectation = self.expectation(description: "Array KeyPath")
        AF.request(sampleURL).responseArray(keyPath: "three_day_forecast") { (response: AFDataResponse<[Forecast]>) in
            expectation.fulfill()
            XCTAssertNotNil(response.value)
        }
        waitForExpectations(timeout: 10)
    }

    func testResponseImmutableObject() {
        let expectation = self.expectation(description: "Immutable Object")
        AF.request(sampleURL).responseObject { (response: AFDataResponse<WeatherResponseImmutable>) in
            expectation.fulfill()
            XCTAssertNotNil(response.value?.location)
        }
        waitForExpectations(timeout: 10)
    }

    func testResponseImmutableArray() {
        let expectation = self.expectation(description: "Immutable Array")
        AF.request(arrayURL).responseArray { (response: AFDataResponse<[ImmutableForecast]>) in
            expectation.fulfill()
            XCTAssertEqual(response.value?.count, 3)
        }
        waitForExpectations(timeout: 10)
    }
}

// MARK: - Models (ครบตามต้นฉบับของคุณ)

class WeatherResponse: Mappable {
    var location: String?; var threeDayForecast: [Forecast]?; var date: Date?
    init(){}
    required init?(map: Map){}
    func mapping(map: Map) {
        location <- map["location"]
        threeDayForecast <- map["three_day_forecast"]
    }
}

class Forecast: Mappable {
    var day: String?; var temperature: Int?; var conditions: String?
    required init?(map: Map){}
    func mapping(map: Map) {
        day <- map["day"]; temperature <- map["temperature"]; conditions <- map["conditions"]
    }
}

struct WeatherResponseImmutable: ImmutableMappable {
    let location: String; var threeDayForecast: [Forecast]; var date: Date?
    init(map: Map) throws {
        location = try map.value("location")
        threeDayForecast = try map.value("three_day_forecast")
    }
    func mapping(map: Map) {
        location >>> map["location"]; threeDayForecast >>> map["three_day_forecast"]
    }
}

struct ImmutableForecast: ImmutableMappable {
    let day: String; let temperature: Int; let conditions: String
    required init(map: Map) throws {
        day = try map.value("day")
        temperature = try map.value("temperature")
        conditions = try map.value("conditions")
    }
    func mapping(map: Map) {
        day >>> map["day"]; temperature >>> map["temperature"]; conditions >>> map["conditions"]
    }
}
