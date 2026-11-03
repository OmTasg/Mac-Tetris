import Foundation

final class Bag {
    private var bag: [Int] = []
    private var recentPieces: [Int] = []
    private var piecesSinceLastI: Int = 0

    init() {
        resetBag()
    }

    func grabIndex(inDangerZone: Bool = false) -> Int {
        if bag.isEmpty {
            resetBag()
        }

        // 1. I-Piece Drought Prevention: guarantee an I-bar within every 7-8 pieces
        if piecesSinceLastI >= 7, let iIndex = bag.firstIndex(of: TetrominoType.i.rawValue) {
            let chosen = bag.remove(at: iIndex)
            recordChosen(chosen)
            return chosen
        }

        // 2. Select a candidate index from the bag
        var candidateIndex = Int.random(in: 0..<bag.count)
        var candidate = bag[candidateIndex]

        // 3. S/Z Flood Prevention: never deal 3 snake pieces in a row
        let lastTwoWereSnake = recentPieces.suffix(2).count == 2 && recentPieces.suffix(2).allSatisfy {
            $0 == TetrominoType.s.rawValue || $0 == TetrominoType.z.rawValue
        }
        let candidateIsSnake = candidate == TetrominoType.s.rawValue || candidate == TetrominoType.z.rawValue

        if lastTwoWereSnake && candidateIsSnake {
            // Find any non-snake piece in the bag
            if let nonSnakeIdx = bag.firstIndex(where: { $0 != TetrominoType.s.rawValue && $0 != TetrominoType.z.rawValue }) {
                candidateIndex = nonSnakeIdx
                candidate = bag[candidateIndex]
            }
        }

        // 4. Danger zone clutch stabilizer: when near death, prefer stabilizing pieces
        if inDangerZone && candidateIsSnake && Double.random(in: 0...1) < 0.65 {
            if let stabilizerIdx = bag.firstIndex(where: {
                $0 == TetrominoType.i.rawValue || $0 == TetrominoType.t.rawValue || $0 == TetrominoType.j.rawValue || $0 == TetrominoType.l.rawValue
            }) {
                candidateIndex = stabilizerIdx
                candidate = bag[candidateIndex]
            }
        }

        let chosen = bag.remove(at: candidateIndex)
        recordChosen(chosen)
        return chosen
    }

    private func recordChosen(_ piece: Int) {
        recentPieces.append(piece)
        if recentPieces.count > 4 {
            recentPieces.removeFirst()
        }
        if piece == TetrominoType.i.rawValue {
            piecesSinceLastI = 0
        } else {
            piecesSinceLastI += 1
        }
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

