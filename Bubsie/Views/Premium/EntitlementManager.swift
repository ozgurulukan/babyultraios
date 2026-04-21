//
//  EntitlementManager.swift
//  Bubsie
//
//  Created by Ozgur Ulukan on 18/07/24.
//

import SwiftUI

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "com.Bubsie")
    
    @AppStorage("hasPro", store: userDefaults)
    var hasPro: Bool = false 
}
