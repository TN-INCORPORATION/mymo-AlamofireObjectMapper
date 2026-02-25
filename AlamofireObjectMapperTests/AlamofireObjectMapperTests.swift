import Foundation
import XCTest
import ObjectMapper
import Alamofire
@testable import AlamofireObjectMapper

class AlamofireObjectMapperTests: XCTestCase {
    
    let sampleURL = "https://raw.githubusercontent.com/tristanhimmelman/AlamofireObjectMapper/d8bb95982be8a11a2308e779bb9a9707ebe42ede/sample_json"
    
    func testResponseObject() {
        let expectation = self.expectation(description: "Get object")

        // เปลี่ยนจาก Alamofire.request เป็น AF.request และ DataResponse เป็น AFDataResponse
        AF.request(sampleURL, method: .get).responseObject { (response: AFDataResponse<WeatherResponse>) in
            expectation.fulfill()
            
            switch response.result {
            case .success(let mappedObject):
                XCTAssertNotNil(mappedObject.location)
                XCTAssertNotNil(mappedObject.threeDayForecast)
            case .failure(let error):
                XCTFail("Request failed with error: \(error)")
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testResponseArray() {
        let arrayURL = "https://raw.githubusercontent.com/tristanhimmelman/AlamofireObjectMapper/f583be1121dbc5e9b0381b3017718a70c31054f7/sample_array_json"
        let expectation = self.expectation(description: "Get array")

        AF.request(arrayURL, method: .get).responseArray { (response: AFDataResponse<[Forecast]>) in
            expectation.fulfill()
            
            if case .success(let mappedArray) = response.result {
                XCTAssertTrue(mappedArray.count == 3)
            } else {
                XCTFail("Parsing failed")
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testResponseImmutableObject() {
        let expectation = self.expectation(description: "Get immutable object")

        AF.request(sampleURL, method: .get).responseObject { (response: AFDataResponse<WeatherResponseImmutable>) in
            expectation.fulfill()
            
            if let mappedObject = response.value {
                XCTAssertNotNil(mappedObject.location)
                XCTAssertFalse(mappedObject.threeDayForecast.isEmpty)
            } else {
                XCTFail("Immutable mapping failed")
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}

// MARK: - Models (ตัวอย่าง)
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
    var day: String?
    var temperature: Int?
    var conditions: String?
    
    required init?(map: Map) {}
    func mapping(map: Map) {
        day <- map["day"]
        temperature <- map["temperature"]
        conditions <- map["conditions"]
    }
}

struct WeatherResponseImmutable: ImmutableMappable {
    let location: String
    let threeDayForecast: [Forecast]
    
    init(map: Map) throws {
        location = try map.value("location")
        threeDayForecast = try map.value("three_day_forecast")
    }
}
