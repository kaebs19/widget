//
//  StoreManager.swift
//  Widgets
//
//  StoreKit 2: جلب المنتجين (شهري وسنوي)، الشراء، الاستعادة، ومتابعة التجديد والإلغاء.
//

import StoreKit
import SwiftUI

@MainActor @Observable
final class StoreManager {
    private(set) var products: [Product] = []
    private(set) var isActive = Premium.isActive
    /// المنتج المشترك فيه حالياً، لعرض «خطتك الحالية»
    private(set) var activeProductID: String?
    /// السنوي فيه أسبوع مجاني لمن لم يجرّبه
    private(set) var trialEligible = false
    private(set) var isLoading = false
    var errorMessage: String?

    private var updates: Task<Void, Never>?

    init() {
        // التجديد والإلغاء والشراء من جهاز آخر يصل هنا ولو كان التطبيق مفتوحاً
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await self?.refreshStatus()
            }
        }
    }

    var monthly: Product? { products.first { $0.id == Premium.monthlyID } }
    var yearly: Product? { products.first { $0.id == Premium.yearlyID } }

    func load() async {
        if products.isEmpty {
            isLoading = true
            do {
                products = try await Product.products(for: Premium.productIDs)
                    .sorted { $0.price > $1.price }
            } catch {
                errorMessage = L10n.text("تعذّر جلب الأسعار. تحقق من الاتصال وحاول مرة أخرى.")
            }
            isLoading = false
        }
        if let yearly, let subscription = yearly.subscription {
            let eligible = await subscription.isEligibleForIntroOffer
            trialEligible = subscription.introductoryOffer != nil && eligible
        }
        await refreshStatus()
    }

    func refreshStatus() async {
        isActive = await Premium.refresh()
        var current: String?
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, Premium.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                current = transaction.productID
            }
        }
        activeProductID = current
    }

    /// يرجع true إذا تم الاشتراك
    func purchase(_ product: Product) async -> Bool {
        errorMessage = nil
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = L10n.text("تعذّر التحقق من عملية الشراء.")
                    return false
                }
                await transaction.finish()
                await refreshStatus()
                return isActive
            case .pending:
                errorMessage = L10n.text("الشراء بانتظار الموافقة، وسيُفتح الاشتراك تلقائياً عند اعتماده.")
                return false
            case .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = L10n.text("تعذّر إتمام الشراء. حاول مرة أخرى.")
            return false
        }
    }

    func restore() async {
        errorMessage = nil
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = L10n.text("تعذّرت استعادة المشتريات.")
        }
        await refreshStatus()
        if !isActive && errorMessage == nil {
            errorMessage = L10n.text("لا يوجد اشتراك سارٍ على حساب Apple هذا.")
        }
    }
}
