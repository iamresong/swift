//
//  ContentView.swift
//  Paywall
//
//  Created by Kseniia Zaitseva on 3. 7. 2025..
//

import SwiftUI
import StoreKit

/// Enum to list all IAP screenshot assets used in the marketing section
enum IAPImage: String, CaseIterable {
    case one = "IAP1"
    case two = "IAP2"
    case three = "IAP3"
    case four = "IAP4"
    case five = "IAP5"
    case six = "IAP6"
    case seven = "IAP7"
    case eight = "IAP8"
    case nine = "IAP9"
    case ten = "IAP10"
}

struct ContentView: View {
    /// Tracks whether loading of IAP products is complete
    @State private var isLoadingCompleted: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            /// The main StoreKit subscription view with our marketing content
            SubscriptionStoreView(productIDs: Self.productIDs, marketingContent: {
                CustomMarketingView()
            })
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStorePickerItemBackground(.ultraThinMaterial)
            
            /// Shows restore purchases button, hides default policy button
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.hidden, for: .policies)
            
            /// Handles start of purchase flow
            .onInAppPurchaseStart { product in
                print("Show Loading Screen")
                print("Purchasing \(product.displayName)")
            }
            
            /// Handles completion of purchase flow (success, pending, cancelled, or error)
            .onInAppPurchaseCompletion { product, result in
                switch result {
                case .success(let result):
                    switch result {
                    case .success(_): print("Purchase succeeded and should verify receipt")
                    case .pending: print("Purchase pending")
                    case .userCancelled: print("User cancelled purchase")
                    @unknown default:
                        fatalError()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
                
                print("Hide Loading Screen")
            }
            
            /// Checks subscription status and prints if user is subscribed
            .subscriptionStatusTask(for: "445DECC7") {
                if let result = $0.value {
                    let premiumUser = result.filter({ $0.state == .subscribed }).isEmpty
                    print("User Subscribed = \(premiumUser)")
                }
            }
            
            /// Terms and privacy links
            HStack(spacing: 3) {
                Link("Terms of Service", destination: URL(string: "https://www.apple.com/")!)
                Text("And")
                Link("Privacy Policy", destination: URL(string: "https://www.apple.com/")!)
            }
            .font(.caption)
            .padding(.bottom, 10)
        }
        /// Makes the paywall fill the entire screen
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        /// Controls loading fade-in
        .opacity(isLoadingCompleted ? 1 : 0)
        
        /// Adds blurred background image
        .background(BackdropView())
        
        /// Shows loading spinner until data is ready
        .overlay {
            if !isLoadingCompleted {
                ProgressView()
                    .font(.largeTitle)
            }
        }
        
        /// Smooth transition when loading completes
        .animation(.easeInOut(duration: 0.35), value: isLoadingCompleted)
        
        /// Loads IAP products and sets loading complete flag
        .storeProductsTask(for: Self.productIDs) { @MainActor collection in
            if let products = collection.products, products.count == Self.productIDs.count {
                try? await Task.sleep(for: .seconds(0.1))
                isLoadingCompleted = true
            }
        }
        
        /// Forces dark mode and white tint
        .environment(\.colorScheme, .dark)
        .tint(.white)
    }
    
    /// The list of subscription product IDs
    static var productIDs: [String] {
        return ["pro_weekly", "pro_monthly", "pro_yearly"]
    }
    
    /// Blurred full-screen background with dark overlay
    @ViewBuilder
    func BackdropView() -> some View {
        GeometryReader {
            let size = $0.size
            
            Image("IAP6")
                .resizable()
                .scaledToFill()
                .frame(width: size.width * 2, height: size.height * 2)
                .blur(radius: 70, opaque: true)
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.5))
                }
                .clipped()
                .ignoresSafeArea()
        }
    }
    
    /// Marketing section with stacked screenshots and promo text
    @ViewBuilder
    func CustomMarketingView() -> some View {
        VStack(spacing: 15) {
            /// Rotated vertical stacks of app screenshots
            HStack(spacing: 25) {
                ScreenshotsView([.one, .two, .eight], offset: -200)
                ScreenshotsView([.four, .six, .five], offset: -350)
                ScreenshotsView([.eight, .seven, .nine], offset: -250)
                    .overlay(alignment: .trailing) {
                        ScreenshotsView([.four, .ten, .one], offset: -150)
                            .visualEffect { content, proxy in content
                                    .offset(x: proxy.size.width + 25)
                            }
                    }
            }
            .frame(maxHeight: .infinity)
            .offset(x:20)
            .mask {
                /// Fades screenshots into transparent gradient at the bottom
                LinearGradient(colors: [
                    .white,
                    .white.opacity(0.9),
                    .white.opacity(0.7),
                    .white.opacity(0.4),
                    .clear
                ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .padding(.bottom, -40)
            }
            
            /// Title, subtitle, and description text for the paywall
            VStack(spacing: 6) {
                Text("Location Tracker")
                    .font(.title3)
                
                Text("Unlock Premium")
                    .font(.largeTitle.bold())
                
                Text("Stay connected and keep your family safe. Unlock unlimited device tracking, custom zones and alerts.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.white)
            .padding(.top, 15)
            .padding(.bottom, 10)
            .padding(.horizontal, 15)
        }
    }
    
    /// Single rotated vertical scroll of screenshots with manual offset
    @ViewBuilder
    func ScreenshotsView(_ content: [IAPImage], offset: CGFloat) -> some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                ForEach(content.indices, id: \.self) { index in
                    Image(content[index].rawValue)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .offset(y: offset)
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .rotationEffect(.init(degrees: -30), anchor: .bottom)
        .scrollClipDisabled()
    }
}

#Preview {
    ContentView()
}
