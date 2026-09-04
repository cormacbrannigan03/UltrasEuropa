import Foundation

/// Thin, pure JSON-decoding helper shared by the bundled-content catalogs.
/// Takes raw `Data` (no `Bundle` dependency) so it's directly unit-testable
/// on any platform, including Linux.
public enum ContentDecoding {
    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}
