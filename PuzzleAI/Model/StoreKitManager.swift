
import Foundation
import StoreKit
import Combine

final class StoreKitManager:NSObject, ObservableObject {
    private var productIdentifiers: [String] {
        Array(1..<6).compactMap({"Coin\($0)"})
    }
    
    @Published var products: [SKProduct] = [] {
        didSet {
            productsFetchCompleted = true
        }
    }
    
    @Published var purchaseState: SKPaymentTransactionState? {
        didSet {
            switch purchaseState {
            case .failed, .restored, .purchased:
                self.completePurchuasing()
            default: break
            }
        }
    }
    
    @Published var error:StoreKitError? {
        didSet {
            if error != nil {
                productsFetchCompleted = true
            }
#if DEBUG
            print(error?.errorDescription ?? "-", " \(#file) \(#line) ", error?.errorTitle ?? "-")
#endif
        }
    }
    
    @Published var productsFetchCompleted:Bool = false {
        didSet {
            if !productsFetchCompleted {
                self.error = nil
            }
        }
    }

    @Published var purchuaseSuccess:Bool = false {
        didSet {
            productsFetchCompleted = true
            purchuaseSuccessChanged?(purchuaseSuccess)
        }
    }
    var purchuaseSuccessChanged:((Bool)->())? = nil

    override init() {
        super.init()
    }
    func toAppReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    private var isPurchuaseRequestCompletedSCS:Bool {
        self.purchaseState == .purchased || self.purchaseState == .restored
    }
    
    func startFetching() {
        print("startfetchingproducts")
        SKPaymentQueue.default().add(self)
        self.fetchProducts()
    }
    
    func buyProduct(_ productID: String?) {
        guard let purchaseQueue: SKPayment = self.products.filter({
            productID == $0.productIdentifier
        }).compactMap({
            .init(product: $0)
        }).first else {
#if DEBUG
            print("error fetching products")
#endif
            DispatchQueue.main.async {
                self.completePurchuasing()
            }
            return
        }
        self.productsFetchCompleted = false
        SKPaymentQueue.default().add(purchaseQueue)
    }
    
    private func fetchProducts() {
        DispatchQueue.main.async {
            self.productsFetchCompleted = false
            DispatchQueue(label: "storekit", qos: .userInitiated).async {
                let request = SKProductsRequest(productIdentifiers: Set(self.productIdentifiers))
                request.delegate = self
                request.start()
            }
        }
    }
    

    
    private func completePurchuasing() {
        if isPurchuaseRequestCompletedSCS {
            self.purchuaseSuccess = true
        }
        self.productsFetchCompleted = true
    }
}

extension StoreKitManager:SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            if response.products.isEmpty {
                self.error = .init(error: NSError(domain: "Products not found", code: -2), type: .fetchProduct)
            }
            self.products = response.products.sorted(by: {$0.productIdentifier >= $1.productIdentifier})
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: any Error) {
        DispatchQueue.main.async {
            self.error = .init(error: error, type: .fetchProduct)
        }
    }
}

extension StoreKitManager:SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            DispatchQueue.main.async {
                self.purchaseState = transaction.transactionState
            }
            switch transaction.transactionState {
            case .failed, .restored, .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
    
    func priceString(product:SKProduct) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price)
    }
}

// MARK: Data Model
extension StoreKitManager {
    struct StoreKitError {
        let error:Error
        let type:Type
        var isTemporary = false
        
        enum `Type` {
            case buyProduct
            case fetchProduct
        }
        
        var errorTitle:String? {
            switch type {
            case .buyProduct:
                return "Error purchuasing product"
            case .fetchProduct:
                return "Error fetching products"
            }
        }
        
        var errorDescription:String? {
            return error.localizedDescription
        }
    }
}

