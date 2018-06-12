//
//  PurchaseFlowController.swift
//  Milkshakr
//
//  Created by Guilherme Rambo on 10/06/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import UIKit
import MilkshakrKit
import PassKit

protocol PurchaseFlowControllerDelegate: class {
    func purchaseFlowControllerDidPresentSuccessScreen(_ controller: PurchaseFlowController)
}

final class PurchaseFlowController: NSObject {

    weak var delegate: PurchaseFlowControllerDelegate?

    enum PurchaseError: Error {
        case applePayNotAvailable

        var localizedDescription: String {
            switch self {
            case .applePayNotAvailable:
                return NSLocalizedString("Apple Pay is not available", comment: "Error presented when a purchase fails because Apple Pay is not available")
            }
        }
    }

    weak var presenter: UIViewController?

    var products: [Product] = []

    init(from presenter: UIViewController, with products: [Product]) {
        self.presenter = presenter
        self.products = products

        super.init()
    }

    func start() {
        let request = PKPaymentRequest()

        ApplePayConfiguration.configure(request)

        let summaryItems: [PKPaymentSummaryItem] = products.map { product in
            let effectivePrice = product.discountPrice ?? product.price
            return PKPaymentSummaryItem(label: product.name, amount: NSDecimalNumber(decimal: effectivePrice))
        }

        let total: NSDecimalNumber = summaryItems.reduce(NSDecimalNumber(value: 0), { $0.adding($1.amount) })
        let totalItem = PKPaymentSummaryItem(label: "Total", amount: total, type: .final)

        request.paymentSummaryItems = summaryItems + [totalItem]

        guard let paymentController = PKPaymentAuthorizationViewController(paymentRequest: request) else {
            self.presentError(PurchaseError.applePayNotAvailable)
            return
        }

        paymentController.delegate = self

        presenter?.present(paymentController, animated: true, completion: nil)
    }

    func presentSuccessScreen() {
        // only one product is supported for now
        guard let product = products.first else { return }

        let success = PurchaseSuccessViewController(viewModel: PurchaseSuccessViewModel(product: product))

        presenter?.present(success, animated: true) { [unowned self] in
            self.delegate?.purchaseFlowControllerDidPresentSuccessScreen(self)
        }
    }

    func presentError(_ error: Error) {

    }

}

// MARK: - PKPaymentAuthorizationViewControllerDelegate

extension PurchaseFlowController: PKPaymentAuthorizationViewControllerDelegate {

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        let result = PKPaymentAuthorizationResult(status: .success, errors: nil)

        completion(result)
    }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true) { [unowned self] in
            self.presentSuccessScreen()
        }
    }

}

// MARK: - PurchaseSuccessViewControllerDelegate

extension PurchaseFlowController: PurchaseSuccessViewControllerDelegate {

    func purchaseSuccessViewControllerDidSelectAddToSiri(_ controller: PurchaseSuccessViewController) {

    }

}