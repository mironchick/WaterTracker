// WaterPersonView.swift
import SwiftUI

struct WaterPersonView: View {
    let progress: Double // 0.0 ... 1.0
    
    @State private var animatedProgress: Double = 0.0
    
    private let containerHeight: CGFloat = 200
    private let containerWidth: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Человек
            personShape
                .frame(width: containerWidth, height: containerHeight)
            
            // Уровень воды
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: containerHeight * animatedProgress)
                .mask(alignment: .bottom) {
                    Rectangle()
                        .frame(height: containerHeight * animatedProgress)
                }
                .animation(.easeInOut(duration: 0.5), value: animatedProgress)
            
            // Процент над водой
            if animatedProgress > 0 {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .offset(y: -20)
            }
        }
        .frame(width: containerWidth, height: containerHeight)
        .clipped()
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
    }
    
    private var personShape: some View {
        GeometryReader { geometry in
            Path { path in
                let w = geometry.size.width
                let h = geometry.size.height
                
                // Голова
                path.addEllipse(in: CGRect(x: w * 0.3, y: h * 0.05, width: w * 0.4, height: w * 0.4))
                
                // Туловище
                path.move(to: CGPoint(x: w * 0.5, y: w * 0.45))
                path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.7))
                
                // Руки
                path.move(to: CGPoint(x: w * 0.5, y: h * 0.5))
                path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.45))
                path.move(to: CGPoint(x: w * 0.5, y: h * 0.5))
                path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.45))
                
                // Ноги
                path.move(to: CGPoint(x: w * 0.5, y: h * 0.7))
                path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.9))
                path.move(to: CGPoint(x: w * 0.5, y: h * 0.7))
                path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.9))
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
            .fill(Color.clear)
        }
    }
}

#Preview {
    VStack {
        WaterPersonView(progress: 1.0)
        WaterPersonView(progress: 0.6)
        WaterPersonView(progress: 0.0)
    }
}
