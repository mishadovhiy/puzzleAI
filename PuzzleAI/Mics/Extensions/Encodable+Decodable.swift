
import Foundation

extension Decodable {
    static func configure(_ from:Data?) -> Self? {
        guard let from else {
            return nil
        }
        do {
            let decoder = PropertyListDecoder()
            let decodedData = try decoder.decode(Self.self, from: from)
            return decodedData
        } catch {
#if DEBUG
            print("error decoding db data ", error)
#endif
            return nil
        }
    }
}

extension Encodable {
    var decode: Data? {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
            return try encoder.encode(self)
        }
        catch {
#if DEBUG
            print("error encoding db ", error)
#endif
            return nil
        }
    }
}
