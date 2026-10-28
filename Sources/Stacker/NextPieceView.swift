import SwiftUI

struct NextPieceView: View {
    let shapeIndex: Int

    var body: some View {
        let piece = TetrominoType(rawValue: shapeIndex) ?? .t
        let matrix = piece.defaultMatrix
        let color = piece.color
        let miniCell: CGFloat = 8.0

        HStack(spacing: 6) {
            Text("NEXT")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            // Mini grid for preview
            VStack(spacing: 1) {
                ForEach(0..<matrix.count, id: \.self) { y in
                    HStack(spacing: 1) {
                        ForEach(0..<matrix[y].count, id: \.self) { x in
                            if matrix[y][x] != 0 {
                                Rectangle()
                                    .fill(color)
                                    .frame(width: miniCell, height: miniCell)
                            } else {
                                Color.clear
                                    .frame(width: miniCell, height: miniCell)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        )
    }
}
