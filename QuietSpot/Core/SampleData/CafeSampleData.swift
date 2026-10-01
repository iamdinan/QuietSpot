import Foundation

enum CafeSampleData {
    static let cafes: [CafeSnapshot] = [
        CafeSnapshot(name: "The Glass House", area: "Colombo 07", imageName: "CafeGlassHouse", isFavorite: true, updateOrder: 2, noiseLevel: .quiet, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "5 min ago"),
        CafeSnapshot(name: "Common Grounds", area: "Colombo 03", imageName: "CafeCommonGrounds", isFavorite: true, updateOrder: 4, noiseLevel: .moderate, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "18 min ago"),
        CafeSnapshot(name: "The Coffee Stop", area: "Colombo 05", imageName: "CafeCoffeeStop", isFavorite: false, updateOrder: 1, noiseLevel: .loud, wifi: "Spotty Wi‑Fi", outlets: "Outlets full", crowd: "Crowded", updatedAt: "2 min ago"),
        CafeSnapshot(name: "Kopi Kade", area: "Colombo 04", imageName: "CafeKopiKade", isFavorite: true, updateOrder: 3, noiseLevel: .quiet, wifi: "Strong Wi‑Fi", outlets: "Outlets free", crowd: "Uncrowded", updatedAt: "12 min ago"),
        CafeSnapshot(name: "Whight & Co.", area: "Colombo 07", imageName: "CafeWhightCo", isFavorite: false, updateOrder: 5, noiseLevel: .moderate, wifi: "Strong Wi‑Fi", outlets: "Outlets full", crowd: "Crowded", updatedAt: "2 hrs ago")
    ]
}
