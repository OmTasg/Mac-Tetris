import Foundation

final class Bag {
    private var bag: [Int] = []

    init() {
        resetBag()
    }

    func grabIndex() -> Int {
        if bag.isEmpty {
            resetBag()
        }
        let randomIndex = Int.random(in: 0..<bag.count)
        return bag.remove(at: randomIndex)
    }

    private func resetBag() {
        bag = Array(0..<TetrominoType.allCases.count)
    }

    // For state persistence:
    func getRemainingBag() -> [Int] {
        return bag
    }

    func setBag(_ newBag: [Int]) {
        self.bag = newBag.isEmpty ? Array(0..<TetrominoType.allCases.count) : newBag
    }
}

