//
//  APIErrorResponse.swift
//  NetwatchViewer
//
//  Created by Codex on 2026/06/06.
//

import Foundation

struct APIErrorResponse: Decodable {
    let error: APIErrorDetail

    enum CodingKeys: String, CodingKey {
        case error
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let detail = try? container.decode(APIErrorDetail.self, forKey: .error) {
            error = detail
            return
        }

        if let message = try? container.decode(String.self, forKey: .error) {
            error = APIErrorDetail(code: nil, message: message, param: nil, min: nil, max: nil)
            return
        }

        throw DecodingError.dataCorruptedError(forKey: .error, in: container, debugDescription: "Unsupported API error response.")
    }
}

struct APIErrorDetail: Decodable {
    let code: String?
    let message: String
    let param: String?
    let min: Double?
    let max: Double?
}
