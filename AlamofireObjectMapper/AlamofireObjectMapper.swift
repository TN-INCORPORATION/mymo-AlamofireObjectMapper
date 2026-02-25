import Foundation
import Alamofire
import ObjectMapper

extension DataRequest {
    
    enum ErrorCode: Int {
        case noData = 1
        case dataSerializationFailed = 2
    }
    
    internal static func processResponse(request: URLRequest?, response: HTTPURLResponse?, data: Data?, keyPath: String?) -> Any? {
        if let data = data, let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
            if let keyPath = keyPath, !keyPath.isEmpty {
                return (result as AnyObject).value(forKeyPath: keyPath)
            }
            return result
        }
        return nil
    }
    
    internal static func newError(_ code: ErrorCode, failureReason: String) -> NSError {
        let errorDomain = "com.alamofireobjectmapper.error"
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
    }

    // MARK: - BaseMappable Serializers
    
    public static func ObjectMapperSerializer<T: BaseMappable>(_ keyPath: String?, mapToObject object: T? = nil, context: MapContext? = nil) -> DataResponseSerializer<T> {
        return DataResponseSerializer { request, response, data, error in
            if let error = error { return .failure(error) }
            let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
            
            if let object = object {
                _ = Mapper<T>(context: context, shouldIncludeNilValues: false).map(JSONObject: JSONObject as? [String: Any], toObject: object)
                return .success(object)
            } else if let parsedObject = Mapper<T>(context: context, shouldIncludeNilValues: false).map(JSONObject: JSONObject as? [String: Any]) {
                return .success(parsedObject)
            }
            return .failure(newError(.dataSerializationFailed, failureReason: "ObjectMapper failed to serialize response."))
        }
    }
    
    public static func ObjectMapperArraySerializer<T: BaseMappable>(_ keyPath: String?, context: MapContext? = nil) -> DataResponseSerializer<[T]> {
        return DataResponseSerializer { request, response, data, error in
            if let error = error { return .failure(error) }
            let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
            
            if let parsedObject = Mapper<T>(context: context, shouldIncludeNilValues: false).mapArray(JSONObject: JSONObject as? [[String: Any]]) {
                return .success(parsedObject)
            }
            return .failure(newError(.dataSerializationFailed, failureReason: "ObjectMapper failed to serialize response."))
        }
    }

    // MARK: - ImmutableMappable Serializers
    
    public static func ObjectMapperImmutableSerializer<T: ImmutableMappable>(_ keyPath: String?, context: MapContext? = nil) -> DataResponseSerializer<T> {
        return DataResponseSerializer { request, response, data, error in
            if let error = error { return .failure(error) }
            let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
            
            if let JSONObject = JSONObject, let parsedObject = try? Mapper<T>(context: context, shouldIncludeNilValues: false).map(JSONObject: JSONObject as? [String: Any]) as T {
                return .success(parsedObject)
            }
            return .failure(newError(.dataSerializationFailed, failureReason: "ObjectMapper failed to serialize response."))
        }
    }
    
    public static func ObjectMapperImmutableArraySerializer<T: ImmutableMappable>(_ keyPath: String?, context: MapContext? = nil) -> DataResponseSerializer<[T]> {
        return DataResponseSerializer { request, response, data, error in
            if let error = error { return .failure(error) }
            if let JSONObject = processResponse(request: request, response: response, data: data, keyPath: keyPath),
               let parsedObject = try? Mapper<T>(context: context, shouldIncludeNilValues: false).mapArray(JSONObject: JSONObject as? [[String: Any]]) as [T] {
                return .success(parsedObject)
            }
            return .failure(newError(.dataSerializationFailed, failureReason: "ObjectMapper failed to serialize response."))
        }
    }

    // MARK: - Handlers
    
    @discardableResult
    public func responseObject<T: BaseMappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, mapToObject object: T? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperSerializer(keyPath, mapToObject: object, context: context), completionHandler: completionHandler)
    }
    
    @discardableResult
    public func responseArray<T: BaseMappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperArraySerializer(keyPath, context: context), completionHandler: completionHandler)
    }

    @discardableResult
    public func responseObject<T: ImmutableMappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperImmutableSerializer(keyPath, context: context), completionHandler: completionHandler)
    }
    
    @discardableResult
    public func responseArray<T: ImmutableMappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperImmutableArraySerializer(keyPath, context: context), completionHandler: completionHandler)
    }
}
