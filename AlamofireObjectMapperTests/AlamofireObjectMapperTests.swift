import Foundation
import XCTest
import ObjectMapper
import Alamofire
@testable import AlamofireObjectMapper

class AlamofireObjectMapperTests: XCTestCase {
    
    let sampleURL = "https://raw.githubusercontent.com/tristanhimmelman/AlamofireObjectMapper/d8bb95982be8a11a2308e779bb9a9707ebe42ede/sample_json"
    let arrayURL = "https://raw.githubusercontent.com/tristanhimmelman/AlamofireObjectMapper/f583be1121dbc5e9b0381b3017718a70c31054f7/sample_array_json"

    func testResponseObject() {
        let expectation = self.expectation(description: "Object mapping")
        // เปลี่ยนเป็น AF.request และเช็กผลผ่าน response.result
        AF.request(sampleURL).responseObject { (response: AFDataResponse<WeatherResponse>) in
            expectation.fulfill()
            switch response.result {
            case .success(let value):
                XCTAssertNotNil(value.location)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
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

    func testResponseImmutableArray() {
        let expectation = self.expectation(description: "Immutable Array mapping")
        AF.request(arrayURL).responseArray { (response: AFDataResponse<[ImmutableForecast]>) in
            expectation.fulfill()
            XCTAssertEqual(response.value?.count, 3)
        }
        waitForExpectations(timeout: 10)
    }
}

// MARK: - Models for Test (ใส่ไว้เพื่อให้คอมไพล์ผ่าน)
class WeatherResponse: Mappable {
    var location: String?
    var threeDayForecast: [Forecast]?
    required init?(map: Map) {}
    func mapping(map: Map) {
        location <- map["location"]
        threeDayForecast <- map["three_day_forecast"]
    }
}

class Forecast: Mappable {
    var day: String?; var temperature: Int?; var conditions: String?
    required init?(map: Map) {}
    func mapping(map: Map) {
        day <- map["day"]; temperature <- map["temperature"]; conditions <- map["conditions"]
    }
}

class ImmutableForecast: ImmutableMappable {
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
