//
//  ToastManager.swift
//  DailyNews
//
//  Created on 13 November 2025.
//

import SwiftUI
import Combine


@MainActor
class ToastManager: ObservableObject {
    @Published var toast: Toast?
    
    private var cancellable: AnyCancellable?
    
    static let shared = ToastManager()
    
    private init() {}
    
    func show(toast: Toast) {
        self.toast = toast
        
        cancellable?.cancel()
        
        cancellable = Just(toast)
            .delay(for: .seconds(toast.duration), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.toast = nil
            }
    }
}
