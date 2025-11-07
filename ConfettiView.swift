// ConfettiView.swift
import SwiftUI

struct ConfettiView: View {
    @State private var particles = [ConfettiParticle]()
    let colors: [Color] = [.blue, .cyan, .green, .yellow, .pink, .orange, .purple, .white]
    let shapes: [ConfettiShape] = [.circle, .star, .heart, .drop]
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                ConfettiShapeView(shape: particle.shape, color: particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            generateParticles()
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) {
                particles.removeAll()
            }
        }
    }
    
    private func generateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        particles = (0..<250).map { _ in
            let shape = shapes.randomElement()!
            let color = colors.randomElement()!
            let size = CGFloat.random(in: 6...18)
            
            // Начинаем сверху экрана
            let startX = CGFloat.random(in: -50...screenWidth + 50)
            let startY = -50.0
            
            // Падаем вниз, но с разбросом по X
            let endX = startX + CGFloat.random(in: -100...100)
            let endY = screenHeight + 100
            
            return ConfettiParticle(
                id: UUID(),
                shape: shape,
                color: color,
                size: size,
                startPosition: CGPoint(x: startX, y: startY),
                endPosition: CGPoint(x: endX, y: endY),
                rotation: CGFloat.random(in: 0...360),
                endRotation: CGFloat.random(in: 360...1080), // 1-3 оборота
                scale: CGFloat.random(in: 0.7...1.3),
                endScale: CGFloat.random(in: 0.7...1.3),
                opacity: 1.0
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: CGFloat.random(in: 2.5...4.0))) {
                for i in particles.indices {
                    particles[i].position = particles[i].endPosition
                    particles[i].rotation = particles[i].endRotation
                    // Масштаб и прозрачность остаются почти как есть
                    particles[i].opacity = 0
                }
            }
        }
    }
}

// Модель частицы
struct ConfettiParticle {
    let id: UUID
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    let startPosition: CGPoint
    let endPosition: CGPoint
    var rotation: CGFloat
    let endRotation: CGFloat
    let scale: CGFloat
    let endScale: CGFloat
    var opacity: Double
    var position: CGPoint
    
    init(
        id: UUID,
        shape: ConfettiShape,
        color: Color,
        size: CGFloat,
        startPosition: CGPoint,
        endPosition: CGPoint,
        rotation: CGFloat,
        endRotation: CGFloat,
        scale: CGFloat,
        endScale: CGFloat,
        opacity: Double
    ) {
        self.id = id
        self.shape = shape
        self.color = color
        self.size = size
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.rotation = rotation
        self.endRotation = endRotation
        self.scale = scale
        self.endScale = endScale
        self.opacity = opacity
        self.position = startPosition
    }
}

// Типы фигур
enum ConfettiShape {
    case circle, star, heart, drop
}

// Отображение фигуры
struct ConfettiShapeView: View {
    let shape: ConfettiShape
    let color: Color
    
    var body: some View {
        switch shape {
        case .circle:
            Circle()
                .fill(color)
        case .star:
            StarShape()
                .fill(color)
        case .heart:
            HeartShape()
                .fill(color)
        case .drop:
            WaterDropShape()
                .fill(color)
        }
    }
}

// Звёздочка
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5
            let isOuter = i % 2 == 0
            let currentRadius = isOuter ? radius : radius * 0.4
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * currentRadius,
                y: center.y + CGFloat(sin(angle)) * currentRadius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// Сердечко
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scale = min(rect.width, rect.height) / 40
        let points = [
            CGPoint(x: 20, y: 10),
            CGPoint(x: 30, y: 0),
            CGPoint(x: 40, y: 10),
            CGPoint(x: 30, y: 30),
            CGPoint(x: 20, y: 40),
            CGPoint(x: 10, y: 30),
            CGPoint(x: 0, y: 10),
            CGPoint(x: 10, y: 0),
        ].map { CGPoint(x: rect.midX + ($0.x - 20) * scale, y: rect.midY + ($0.y - 20) * scale) }
        
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        path.closeSubpath()
        return path
    }
}

// Капля воды
struct WaterDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let centerX = rect.midX
        let centerY = rect.midY
        
        path.move(to: CGPoint(x: centerX, y: centerY - height / 2))
        path.addQuadCurve(
            to: CGPoint(x: centerX + width / 2, y: centerY),
            control: CGPoint(x: centerX + width / 2, y: centerY - height / 2)
        )
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: centerY + height / 2),
            control: CGPoint(x: centerX + width / 2, y: centerY + height / 2)
        )
        path.addQuadCurve(
            to: CGPoint(x: centerX - width / 2, y: centerY),
            control: CGPoint(x: centerX - width / 2, y: centerY + height / 2)
        )
        path.addQuadCurve(
            to: CGPoint(x: centerX, y: centerY - height / 2),
            control: CGPoint(x: centerX - width / 2, y: centerY - height / 2)
        )
        path.closeSubpath()
        return path
    }
}
