import Foundation
import Alamofire
import ObjectMapper

// MARK: - Serializers
public struct ObjectMapperSerializer<T: BaseMappable>: ResponseSerializer {
    public let keyPath: String?
    public let object: T?
    public let context: MapContext?

    public init(keyPath: String?, object: T? = nil, context: MapContext? = nil) {
        self.keyPath = keyPath
        self.object = object
        self.context = context
    }

    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        if let error = error { throw error }
        let jsonObject = DataRequest.processResponse(data: data, keyPath: keyPath)

        if let object = object {
            _ = Mapper<T>(context: context, shouldIncludeNilValues: false).map(JSONObject: jsonObject as? [String: Any], toObject: object)
            return object
        } else if let parsedObject = Mapper<T>(context: context, shouldIncludeNilValues: false).map(JSONObject: jsonObject as? [String: Any]) {
            return parsedObject
        }

        throw AFError.responseSerializationFailed(reason: .decodingFailed(error: NSError(domain: "AlamofireObjectMapper", code: 2, userInfo: [NSLocalizedDescriptionKey: "ObjectMapper failed to serialize response."])))
    }
}

public struct ObjectMapperArraySerializer<T: BaseMappable>: ResponseSerializer {
    public let keyPath: String?
    public let context: MapContext?

    public init(keyPath: String?, context: MapContext? = nil) {
        self.keyPath = keyPath
        self.context = context
    }

    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [T] {
        if let error = error { throw error }
        let jsonObject = DataRequest.processResponse(data: data, keyPath: keyPath)

        if let parsedObject = Mapper<T>(context: context, shouldIncludeNilValues: false).mapArray(JSONObject: jsonObject as? [[String: Any]]) {
            return parsedObject
        }

        throw AFError.responseSerializationFailed(reason: .decodingFailed(error: NSError(domain: "AlamofireObjectMapper", code: 2, userInfo: [NSLocalizedDescriptionKey: "ObjectMapper failed to serialize array response."])))
    }
}

// MARK: - Immutable Serializers
public struct ObjectMapperImmutableSerializer<T: ImmutableMappable>: ResponseSerializer {
    public let keyPath: String?
    public let context: MapContext?

    public init(keyPath: String?, context: MapContext? = nil) {
        self.keyPath = keyPath
        self.context = context
    }

    public func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> T {
        if let error = error { throw error }
        let jsonObject = DataRequest.processResponse(data: data, keyPath: keyPath)

        if let json = jsonObject as? [String: Any], let parsedObject = try? Mapper<T>(context: context).map(JSONObject: json) {
            return parsedObject
        }

        throw AFError.responseSerializationFailed(reason: .decodingFailed(error: NSError(domain: "AlamofireObjectMapper", code: 2, userInfo: [NSLocalizedDescriptionKey: "ImmutableMapper failed to serialize response."])))
    }
}

// MARK: - DataRequest Extension
extension DataRequest {
    internal static func processResponse(data: Data?, keyPath: String?) -> Any? {
        guard let data = data else { return nil }
        let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
        if let keyPath = keyPath, !keyPath.isEmpty {
            return (result as AnyObject).value(forKeyPath: keyPath)
        }
        return result
    }

    @discardableResult
    public func responseObject<T: BaseMappable>(queue: DispatchQueue = .main, keyPath: String? = nil, mapToObject object: T? = nil, context: MapContext? = nil, completionHandler: @escaping (AFDataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: ObjectMapperSerializer(keyPath: keyPath, object: object, context: context), completionHandler: completionHandler)
    }

    @discardableResult
    public func responseArray<T: BaseMappable>(queue: DispatchQueue = .main, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (AFDataResponse<[T]>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: ObjectMapperArraySerializer(keyPath: keyPath, context: context), completionHandler: completionHandler)
    }

    @discardableResult
    public func responseObject<T: ImmutableMappable>(queue: DispatchQueue = .main, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (AFDataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: ObjectMapperImmutableSerializer(keyPath: keyPath, context: context), completionHandler: completionHandler)
    }
}
