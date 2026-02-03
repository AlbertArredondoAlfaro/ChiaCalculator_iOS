import XCTest
@testable import ChiaCalculator

final class ChiaCalculatorViewModelTests: XCTestCase {
    func testPlotSizeTableK32C0() {
        let size = PlotSizeTable.sizeGiB(for: .k32, compression: .c0)
        XCTAssertEqual(size, 101.4, accuracy: 0.01)
    }

    func testPlotSizeTableK32C5() {
        let size = PlotSizeTable.sizeGiB(for: .k32, compression: .c5)
        XCTAssertEqual(size, 81.3, accuracy: 0.01)
    }

    func testBlockRewardBeforeFirstHalving() {
        let reward = ChiaCalculatorViewModel.rewardForHeight(1_000_000)
        XCTAssertEqual(reward, 2.0, accuracy: 0.0001)
    }

    func testBlockRewardAfterFirstHalving() {
        let reward = ChiaCalculatorViewModel.rewardForHeight(6_000_000)
        XCTAssertEqual(reward, 1.0, accuracy: 0.0001)
    }

    func testPlotCountToBytesUsesSelectedSize() {
        let model = ChiaCalculatorViewModel()
        model.selectedKSize = .k32
        model.selectedCompression = .c5
        model.plotCount = 10
        let expectedGiB = 81.3 * 10
        let expectedBytes = expectedGiB * pow(1024.0, 3.0)
        XCTAssertEqual(model.ownedSpaceBytes, expectedBytes, accuracy: 1.0)
    }
}
