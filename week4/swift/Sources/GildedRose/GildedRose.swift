// MARK: - Item Type Constants
fileprivate enum ItemType: String {
    case agedBrie = "Aged Brie"
    case backstage = "Backstage passes to a TAFKAL80ETC concert"
    case sulfuras = "Sulfuras, Hand of Ragnaros"
    case conjured = "Conjured Mana Cake" // for future extension
    case normal

    static func type(for name: String) -> ItemType {
        switch name {
        case ItemType.agedBrie.rawValue: return .agedBrie
        case ItemType.backstage.rawValue: return .backstage
        case ItemType.sulfuras.rawValue: return .sulfuras
        case ItemType.conjured.rawValue: return .conjured
        default: return .normal
        }
    }
}

fileprivate let maxQuality = 50
fileprivate let minQuality = 0

// MARK: - UpdatableItem Protocol
fileprivate protocol UpdatableItem {
    var item: Item { get }
    func updateQuality()
}

// MARK: - Item Wrappers
fileprivate class NormalItemWrapper: UpdatableItem {
    let item: Item
    init(item: Item) { self.item = item }
    func updateQuality() {
        if item.quality > minQuality { item.quality -= 1 }
        item.sellIn -= 1
        if item.sellIn < 0, item.quality > minQuality { item.quality -= 1 }
    }
}

fileprivate class AgedBrieWrapper: UpdatableItem {
    let item: Item
    init(item: Item) { self.item = item }
    func updateQuality() {
        if item.quality < maxQuality { item.quality += 1 }
        item.sellIn -= 1
        if item.sellIn < 0, item.quality < maxQuality { item.quality += 1 }
    }
}

fileprivate class BackstagePassWrapper: UpdatableItem {
    let item: Item
    init(item: Item) { self.item = item }
    func updateQuality() {
        if item.quality < maxQuality { item.quality += 1 }
        if item.sellIn < 11, item.quality < maxQuality { item.quality += 1 }
        if item.sellIn < 6, item.quality < maxQuality { item.quality += 1 }
        item.sellIn -= 1
        if item.sellIn < 0 { item.quality = 0 }
    }
}

fileprivate class SulfurasWrapper: UpdatableItem {
    let item: Item
    init(item: Item) { self.item = item }
    func updateQuality() {
        // Legendary: do nothing
    }
}

// MARK: - Factory
fileprivate func makeUpdatableItem(from item: Item) -> UpdatableItem {
    switch ItemType.type(for: item.name) {
    case .agedBrie: return AgedBrieWrapper(item: item)
    case .backstage: return BackstagePassWrapper(item: item)
    case .sulfuras: return SulfurasWrapper(item: item)
    default: return NormalItemWrapper(item: item)
    }
}

// MARK: - GildedRose
public class GildedRose {
    public var items: [Item]
    private var updatableItems: [UpdatableItem]

    public init(items: [Item]) {
        self.items = items
        self.updatableItems = items.map { makeUpdatableItem(from: $0) }
    }

    public func updateQuality() {
        for updatable in updatableItems {
            updatable.updateQuality()
        }
    }
}
