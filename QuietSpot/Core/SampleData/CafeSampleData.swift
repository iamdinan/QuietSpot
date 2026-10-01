import Foundation

enum CafeSampleData {
    static let cafes: [CafeSnapshot] = [
        CafeSnapshot(name: "The Glass House", area: "Colombo 07", description: "A light-filled café with leafy surroundings and window-side seating. Stop by for coffee, pastries, or a leisurely catch-up.", imageName: "CafeGlassHouse", latitude: 6.906, longitude: 79.864, isFavorite: true, updateOrder: 2, noiseLevel: .quiet, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "5 min ago"),
        CafeSnapshot(name: "Common Grounds", area: "Colombo 03", description: "Warm timber finishes and shared tables give this café a welcoming feel. Enjoy an espresso or settle in with a light bite.", imageName: "CafeCommonGrounds", latitude: 6.9102, longitude: 79.851, isFavorite: true, updateOrder: 4, noiseLevel: .moderate, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "18 min ago"),
        CafeSnapshot(name: "The Coffee Stop", area: "Colombo 05", description: "An urban café with exposed brick and a spacious communal table. A casual stop for coffee and conversation.", imageName: "CafeCoffeeStop", latitude: 6.8915, longitude: 79.873, isFavorite: false, updateOrder: 1, noiseLevel: .loud, wifi: "Spotty Wi‑Fi", outlets: "Outlets full", crowd: "Crowded", updatedAt: "2 min ago"),
        CafeSnapshot(name: "Kopi Kade", area: "Colombo 04", description: "A cozy café with rattan seating and a courtyard-inspired setting. Take a break over a freshly brewed coffee.", imageName: "CafeKopiKade", latitude: 6.883, longitude: 79.858, isFavorite: true, updateOrder: 3, noiseLevel: .quiet, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "12 min ago"),
        CafeSnapshot(name: "Whight & Co.", area: "Colombo 07", description: "A café with warm interiors and terrace seating. Enjoy a coffee and a pastry while watching the afternoon unfold.", imageName: "CafeWhightCo", latitude: 6.915, longitude: 79.867, isFavorite: false, updateOrder: 5, noiseLevel: .moderate, wifi: "Strong Wi‑Fi", outlets: "Outlets full", crowd: "Crowded", updatedAt: "2 hrs ago")
    ]
}
