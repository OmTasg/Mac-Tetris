import SwiftUI

struct NextPieceView: View {
    let shapeIndex: Int

    var body: some View {
        let piece = TetrominoType(rawValue: shapeIndex) ?? .t
        let matrix = piece.previewMatrix
        let color = piece.color
        let miniCell: CGFloat = 6.0
        let miniSpacing: CGFloat = 1.5

        HStack(spacing: 7) {
            Text("NEXT")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
                .padding(.leading, 8)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 14)

            // Centered preview display area with consistent breathing room
            ZStack {
                VStack(spacing: miniSpacing) {
                    ForEach(0..<matrix.count, id: \.self) { r in
                        HStack(spacing: miniSpacing) {
                            ForEach(0..<matrix[r].count, id: \.self) { c in
                                if matrix[r][c] != 0 {
                                    RoundedRectangle(cornerRadius: 1.5)
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
            .frame(width: 30, height: 18)
            .padding(.trailing, 8)
        }
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                )
        )
    }
}
