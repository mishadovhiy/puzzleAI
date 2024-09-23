//
//  StoreKitManagerModel.swift
//  PuzzleAI
//
//  Created by Mykhailo Dovhyi on 23.09.2024.
//

import Foundation
import Combine

struct StoreKitManagerModel {
    typealias ViewModel = ModalPopupView.CointsPopupView.CointsPopupViewModel
    
    init(fetchedProducts: @escaping (_: [CointListItem]) -> Void,
         statePurchuaseSuccess: @escaping (_: Bool) -> Void,
         error: @escaping (MessageContent?) -> Void,
         loading: @escaping (Bool) -> Void,
         viewModelGet: @escaping () -> ViewModel
    ) {
        self.storeKit = .init()
        let storeKitHolder = self.storeKit
        storeKit.$error.sink {
            if let errorTitle = $0?.errorTitle {
                error(.init(title: errorTitle))
            } else {
                error(nil)
            }
        }.store(in: &cancellablesError)
        storeKit.$productsFetchCompleted.sink {
            loading($0)
        }.store(in: &cancellablesLoading)
        storeKit.purchuaseSuccessChanged = {
            let model = viewModelGet()
            if $0 {
                model.updateCointBalance(completed: {
                    statePurchuaseSuccess(false)
                })
            }
        }
        storeKit.$products.sink { product in
            fetchedProducts(product.compactMap({
                let price = storeKitHolder.priceString(product: $0) ?? "-"
                let valueFloat = Float($0.productIdentifier.stringArray(from: .decimalDigits).first ?? "") ?? 0
                let value = CointView.priceStartAmount + ((valueFloat - 1) * Float(CointView.priceMultiplyAmount))
                return .init(title: price, price: .init(value: value, id: $0.productIdentifier))}).sorted(by: {$0.price.value >= $1.price.value}))
        }.store(in: &cancellablesProducts)
        storeKit.startFetching()
    }
    
    private let storeKit:StoreKitManager

    var cancellablesProducts: Set<AnyCancellable> = []
    var fetchedProducts:[CointListItem] = []
    var cancellablesError: Set<AnyCancellable> = []
    var storeKitError:MessageContent?
    var cancellablesLoading: Set<AnyCancellable> = []
    var storeKitLoading:Bool = false

    var errorTitle:String? {
        storeKitError?.title ?? storeKit.error?.errorTitle
    }
    
    var isFailedPurchase:Bool {
        storeKit.purchaseState == .failed
    }
    
    var productFetchCompleted:Bool {
        storeKit.productsFetchCompleted && storeKitLoading
    }
    
    func buyProduct(_ key:String) {
        storeKit.buyProduct(key)
    }
}
