import Foundation

struct PoolStatsResponse: Decodable {
    let status: String
    let data: PoolStatsData

    var netspaceBytes: Double? {
        data.xch.netspaceTiB?.toBytesFromTiB()
    }

    var xchPriceUSD: Double? {
        data.xch.usdt
    }
}

struct PoolStatsData: Decodable {
    let lastBlocks: [PoolBlock]
    let poolStats: PoolStats
    let xch: XCHStats
}

struct PoolBlock: Decodable, Identifiable {
    let height: Int
    let receivedHeight: Int?
    let farmer: String
    let datetime: Date

    var id: Int { height }

    enum CodingKeys: String, CodingKey {
        case height
        case receivedHeight = "received_height"
        case farmer
        case datetime
    }
}

struct PoolStats: Decodable {
    let poolSpaceTiB: Double
    let farmers: Int
    let currentFeeType: String
    let currentFee: Double
}

struct XCHStats: Decodable {
    let usdt: Double
    let peakHeight: Int
    let netspaceTiB: Double?

    enum CodingKeys: String, CodingKey {
        case usdt
        case peakHeight
        case netspaceTiB = "netspaceTiB"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        usdt = try container.decode(Double.self, forKey: .usdt)
        peakHeight = try container.decode(Int.self, forKey: .peakHeight)
        if let doubleValue = try? container.decode(Double.self, forKey: .netspaceTiB) {
            netspaceTiB = doubleValue
        } else if let stringValue = try? container.decode(String.self, forKey: .netspaceTiB) {
            netspaceTiB = Double(stringValue)
        } else {
            netspaceTiB = nil
        }
    }
}

private extension Double {
    func toBytesFromTiB() -> Double {
        self * pow(1024.0, 4)
    }
}
