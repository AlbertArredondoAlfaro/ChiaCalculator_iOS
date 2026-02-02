import Foundation
import Observation

@Observable
final class ChiaCalculatorViewModel {
    var plotCount: Int = 10 {
        didSet {
            if plotCount < 1 { plotCount = 1 }
        }
    }
    var selectedKSize: KSize = .k32
    var selectedCompression: CompressionLevel = .c0
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var lastUpdated: Date?

    private(set) var netspaceBytes: Double?
    private(set) var xchPriceUSD: Double?
    private(set) var peakHeight: Int?

    // Constants
    let blocksPerDay: Double = 4608
    private let baseReward: Double = 2.0

    private let statsURL = URL(string: "https://spacefarmers.io/api/pool/stats")!

    @MainActor
    func loadIfNeeded() async {
        guard lastUpdated == nil else { return }
        await refresh(showSpinner: true)
    }

    @MainActor
    func refresh(showSpinner: Bool = false) async {
        errorMessage = nil
        if showSpinner { isLoading = true }
        isRefreshing = true
        let start = Date()

        do {
            let (data, response) = try await URLSession.shared.data(from: statsURL)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(PoolStatsResponse.self, from: data)

            guard decoded.status.uppercased() == "OK" else {
                throw URLError(.badServerResponse)
            }

            guard let netspace = decoded.netspaceBytes else {
                throw URLError(.cannotParseResponse)
            }

            netspaceBytes = netspace
            xchPriceUSD = decoded.xchPriceUSD
            peakHeight = decoded.data.xch.peakHeight
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

        let elapsed = Date().timeIntervalSince(start)
        let minimum = 0.6
        if elapsed < minimum {
            let nanos = UInt64((minimum - elapsed) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
        }

        isLoading = false
        isRefreshing = false
    }

    var ownedSpaceBytes: Double {
        plotCountToBytes(plotCount)
    }

    var ownedSpacePercent: Double? {
        guard let netspaceBytes, netspaceBytes > 0 else { return nil }
        return ownedSpaceBytes / netspaceBytes
    }

    var expectedWinsPerDay: Double? {
        guard let ratio = ownedSpacePercent else { return nil }
        return ratio * blocksPerDay
    }

    var rewardPerBlock: Double? {
        guard let height = peakHeight else { return nil }
        return rewardForHeight(height)
    }

    var expectedTimeToWinDays: Double? {
        guard let winsPerDay = expectedWinsPerDay, winsPerDay > 0 else { return nil }
        return 1.0 / winsPerDay
    }

    var earningsDailyXCH: Double? {
        guard let winsPerDay = expectedWinsPerDay, let reward = rewardPerBlock else { return nil }
        return winsPerDay * reward
    }

    var earningsHourlyXCH: Double? {
        guard let daily = earningsDailyXCH else { return nil }
        return daily / 24.0
    }

    var earningsMonthlyXCH: Double? {
        guard let daily = earningsDailyXCH else { return nil }
        return daily * 30.0
    }

    func earningsUSD(_ xch: Double?) -> Double? {
        guard let xch, let price = xchPriceUSD else { return nil }
        return xch * price
    }

    func chanceToWin(hours: Double) -> Double? {
        guard let ratio = ownedSpacePercent else { return nil }
        let expectedBlocks = ratio * blocksPerDay * (hours / 24.0)
        return 1.0 - Foundation.exp(-expectedBlocks)
    }

    func plotCountToBytes(_ plots: Int) -> Double {
        let gibToBytes = pow(1024.0, 3.0)
        return Double(plots) * plotSizeGiB * gibToBytes
    }

    var plotSizeGiB: Double {
        PlotSizeTable.sizeGiB(for: selectedKSize, compression: selectedCompression)
    }

    private func rewardForHeight(_ height: Int) -> Double {
        let firstHalving = 5_045_760
        let secondHalving = 10_091_520
        let thirdHalving = 15_137_280
        let fourthHalving = 20_183_040

        switch height {
        case ..<firstHalving:
            return baseReward
        case firstHalving..<secondHalving:
            return baseReward / 2.0
        case secondHalving..<thirdHalving:
            return baseReward / 4.0
        case thirdHalving..<fourthHalving:
            return baseReward / 8.0
        default:
            return baseReward / 16.0
        }
    }
}

enum KSize: Int, CaseIterable, Identifiable {
    case k32 = 32
    case k33 = 33
    case k34 = 34

    var id: Int { rawValue }
    var label: String { "k=\(rawValue)" }
}

enum CompressionLevel: Int, CaseIterable, Identifiable {
    case c0 = 0
    case c1 = 1
    case c2 = 2
    case c3 = 3
    case c4 = 4
    case c5 = 5
    case c6 = 6
    case c7 = 7
    case c9 = 9

    var id: Int { rawValue }
    var label: String { "C\(rawValue)" }
}

enum PlotSizeTable {
    // Source: https://docs.chia.net/chia-blockchain/resources/k-sizes/
    static let sizesGiB: [KSize: [CompressionLevel: Double]] = [
        .k32: [.c0: 101.4, .c1: 87.5, .c2: 86.0, .c3: 84.5, .c4: 82.9, .c5: 81.3, .c6: 79.6, .c7: 78.0, .c9: 75.2],
        .k33: [.c0: 208.8, .c1: 179.6, .c2: 176.6, .c3: 173.4, .c4: 170.2, .c5: 167.0, .c6: 163.8, .c7: 160.6, .c9: 154.1],
        .k34: [.c0: 429.9, .c1: 368.2, .c2: 362.1, .c3: 355.9, .c4: 349.4, .c5: 343.0, .c6: 336.6, .c7: 330.2, .c9: 315.5]
    ]

    static func sizeGiB(for kSize: KSize, compression: CompressionLevel) -> Double {
        sizesGiB[kSize]?[compression] ?? 101.4
    }
}
