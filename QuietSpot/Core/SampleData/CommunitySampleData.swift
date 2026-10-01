import Foundation

enum CommunitySampleData {
    static let insights: [CafeInsight] = [
        CafeInsight(cafeID: CafeSampleData.cafes[0].id, authorName: "Nethmi", text: "The window-side seats are lovely for a morning coffee. I went early and found a peaceful corner to read.", createdAt: .now.addingTimeInterval(-900)),
        CafeInsight(cafeID: CafeSampleData.cafes[3].id, authorName: "Ravi", text: "Really enjoyed the courtyard atmosphere here. A nice spot to take a break between errands.", createdAt: .now.addingTimeInterval(-3600)),
        CafeInsight(cafeID: CafeSampleData.cafes[1].id, authorName: "Amaya", text: "The shared tables worked well for catching up with a friend. I'd come back for another espresso.", createdAt: .now.addingTimeInterval(-7200)),
        CafeInsight(cafeID: CafeSampleData.cafes[4].id, authorName: "Dilan", text: "Had a coffee and pastry on the terrace this afternoon. I liked having an outdoor seating option.", createdAt: .now.addingTimeInterval(-14400))
    ]
}
