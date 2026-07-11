import SwiftUI

class CoinCounter: ObservableObject {
    @AppStorage("coins") private var _coins = 0
    public var coins: Int {
        get { _coins }
        set {
            objectWillChange.send()
            _coins = newValue
        }
    }

    func useCoin() {
        coins -= 1
    }
}