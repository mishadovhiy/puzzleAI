//
//  AdPresenterRepresentable.swift
//  PuzzleAI
//
//  Created by Mykhailo Dovhyi on 05.05.2025.
//
#if os(iOS)
import SwiftUI
import UIKit

import GoogleMobileAds

struct AdPresenterRepresentable:UIViewControllerRepresentable {
    var dismissed:()->()

    func makeUIViewController(context: Context) -> AdPresenterViewController {
        let vc = AdPresenterViewController()
        vc.dismissed = {
            dismissed()
        }
        return vc
    }
    func updateUIViewController(_ uiViewController: AdPresenterViewController, context: Context) {
        
    }
}

class AdPresenterViewController: UIViewController, FullScreenContentDelegate {
    var dismissed:(()->())?
    private var bannerShowCompletion:((_ presented:Bool)->())?
    var interstitial: FullScreenPresentingAd?
    private var adNotReceved = true
    var bannerWatchedFull = false
    override func viewDidLoad() {
        super.viewDidLoad()
        presentFullScreenAd {
            
        }
    }
    
    func presentFullScreenAd(okCompletion:@escaping()->()) {
        toggleFullScreenAd(loaded: { delegate in
        
            self.interstitial = delegate
            self.interstitial?.fullScreenContentDelegate = self
        }, closed: { presented in
            print("ok")
            okCompletion()
        })
    }
    
    func toggleFullScreenAd(loaded:@escaping(FullScreenPresentingAd?)->(), closed:@escaping(_ presented:Bool)->()) {
        bannerCanShow() { show in
            if show {
                self.bannerShowCompletion = closed
                self.presentFullScreen(loaded: loaded)
                
            } else {
                closed(false)
            }
        }
    }
    
    private func presentFullScreen(loaded:@escaping(FullScreenPresentingAd?)->()) {
        //        rootVC = vc
        let id = Keys.admob.rawValue
        InterstitialAd.load(with: id, request: Request()) { ad, error in
            loaded(ad)
            if error != nil {
                print(error ?? "-", "bannerror")
                self.bannerShowCompletion?(true)
                self.dismiss(animated: true)
            }
            ad?.present(from: self)
        }
    }
    
    /// checks last showed time and other properties
    func bannerCanShow(completion:@escaping(_ show:Bool)->()) {
        if #available(iOS 13.0, *) {
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func adWillPresentFullScreenContent(_ ad: any FullScreenPresentingAd) {
        bannerWatchedFull = false
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        self.dismiss(animated: true) {
            self.dismissed?()
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissed?()
        dismissed = nil
        super.dismiss(animated: flag, completion: completion)

    }
    
    func adWillDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        print("oksfddsafdsdfs")
        self.dismiss(animated: true)
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {

    }
    

}
#endif
