import Foundation

struct Filter: Codable {
    let name: String
    let parameters: [String: Float]?
}

struct Scene: Codable {
    let label: String
    let leftFilters: [Filter]
    let rightFilters: [Filter]
}

struct Filters: Codable {
    let scenes: [Scene]
}

extension Scene {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        label = try values.decode(String.self, forKey: .label)

        // Custom decoding for the filters
        let leftFiltersArray = try values.decode([[String: [String: Float]]].self, forKey: .leftFilters)
        let rightFiltersArray = try values.decode([[String: [String: Float]]].self, forKey: .rightFilters)

        leftFilters = leftFiltersArray.flatMap { dict -> Filter? in
            guard let key = dict.keys.first, let params = dict[key] else { return nil }
            return Filter(name: key, parameters: params)
        }

        rightFilters = rightFiltersArray.flatMap { dict -> Filter? in
            guard let key = dict.keys.first, let params = dict[key] else { return nil }
            return Filter(name: key, parameters: params)
        }
    }
}
