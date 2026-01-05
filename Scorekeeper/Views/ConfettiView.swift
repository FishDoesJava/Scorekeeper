import SwiftUI

#if canImport(UIKit)
import UIKit

struct ConfettiView: UIViewRepresentable {
    @Binding var isActive: Bool
    var colors: [UIColor] {
        let names = ["Accent", "Primary", "Secondary", "AccentColor"]
        let fallbacks: [UIColor] = [.systemPink, .systemBlue, .systemGreen, .systemOrange]
        return zip(names, fallbacks).compactMap { (name, fb) in
            UIColor(named: name) ?? fb
        }
    }

    static var particleImage: UIImage {
        let size = CGSize(width: 14, height: 14)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 3)
            UIColor.white.setFill()
            path.fill()
        }
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard isActive else { return }

        // Prevent multiple emitters stacking
        if uiView.layer.sublayers?.contains(where: { $0.name == "confetti_emitter" }) == true {
            DispatchQueue.main.async { isActive = false }
            return
        }

        let emitter = CAEmitterLayer()
        emitter.name = "confetti_emitter"
        emitter.emitterPosition = CGPoint(x: uiView.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: uiView.bounds.size.width, height: 1)

        var cells: [CAEmitterCell] = []
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 6.0
            cell.velocity = 200
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 3
            cell.spinRange = 3
            cell.scale = 0.06
            cell.scaleRange = 0.02
            cell.color = color.cgColor
            cell.contents = Self.particleImage.cgImage
            cells.append(cell)
        }

        emitter.emitterCells = cells
        uiView.layer.addSublayer(emitter)

        // Stop emitting after a short burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            emitter.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                emitter.removeFromSuperlayer()
            }
        }

        // Reset the binding so view can be triggered again
        DispatchQueue.main.async { isActive = false }
    }
}

#else

struct ConfettiView: View {
    @Binding var isActive: Bool
    var body: some View { EmptyView() }
}

#endif
