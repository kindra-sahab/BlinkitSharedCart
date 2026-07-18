//
//  ConfettiView.swift
//  BlinkitSharedCart
//
//  Lightweight confetti burst driven by a trigger. Overlay it on any view.
//

import SwiftUI

struct ConfettiView: View {
    let trigger: Bool
    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiShape(kind: piece.kind)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                        .opacity(piece.opacity)
                }
            }
            .onChange(of: trigger) { _, newValue in
                if newValue { burst(in: geo.size) }
            }
            .onAppear { if trigger { burst(in: geo.size) } }
        }
        .allowsHitTesting(false)
    }

    private func burst(in size: CGSize) {
        let colors: [Color] = [Palette.brand, Palette.accent, Palette.violet, Palette.pink,
                               Color(hex: 0x2D9CDB), Color(hex: 0x16B8A6)]
        var new: [ConfettiPiece] = []
        for _ in 0..<70 {
            new.append(ConfettiPiece(
                x: size.width / 2 + CGFloat.random(in: -40...40),
                y: size.height * 0.35,
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement()!,
                rotation: .random(in: 0...360),
                opacity: 1,
                kind: ConfettiShape.Kind.allCases.randomElement()!
            ))
        }
        pieces = new
        // Animate each piece falling outward.
        for i in pieces.indices {
            let dx = CGFloat.random(in: -size.width/2...size.width/2)
            let dy = size.height * CGFloat.random(in: 0.4...0.95)
            withAnimation(.easeOut(duration: Double.random(in: 1.6...2.6))) {
                pieces[i].x += dx
                pieces[i].y += dy
                pieces[i].rotation += Double.random(in: 180...720)
                pieces[i].opacity = 0
            }
        }
        Task {
            try? await Task.sleep(for: .seconds(2.8))
            pieces = []
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
    var opacity: Double
    var kind: ConfettiShape.Kind
}

private struct ConfettiShape: Shape {
    enum Kind: CaseIterable { case rect, circle, triangle }
    let kind: Kind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .rect: return Path(roundedRect: rect, cornerRadius: 1.5)
        case .circle: return Path(ellipseIn: rect)
        case .triangle:
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
            return p
        }
    }
}
