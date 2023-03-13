//
//  FPPayWithTerminalViewController.swift
//  Farm POS
//
//  Created by Luciano Polit on 26/1/22.
//  Copyright © 2022 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit
import Stripe
import StripeTerminal
import SnapKit
import MBProgressHUD

class FPPayWithTerminalViewController: UIViewController {
    
    let price: Double
    let onCompletion: () -> Void
    
    private let discoverButton = LoadableButton()
    private let connectedReaderLabel = UILabel()
    private let emailTextField = UITextField()
    private let emailExplanationLabel = UILabel()
    private let payButton = LoadableButton()
    private let payProcessLabel = UILabel()
    
    private var discoverCancelable: Cancelable?
    private var updateCancelable: Cancelable?
    private var isDiscovering = false {
        didSet {
            handleNewDiscoveringValue()
        }
    }
    private var isConnecting = false
    private var isPaying = false {
        didSet {
            discoverButton.isEnabled = !isPaying
            payButton.isEnabled = !isPaying
            payButton.isLoading = isPaying
            payButton.isHidden = isPaying
        }
    }
    private weak var readersViewController: FPPayWithTerminalListViewController?
    private var ignoreDiscoverCancelable = false
    
    init(
        price: Double,
        onCompletion: @escaping () -> Void
    ) {
        self.price = price
        self.onCompletion = onCompletion
        super.init(
            nibName: nil,
            bundle: nil
        )
    }
    
    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        handleNewDiscoveringValue()
    }
    
    override func viewWillAppear(
        _ animated: Bool
    ) {
        super.viewWillAppear(animated)
        
        guard !ignoreDiscoverCancelable
        else {
            ignoreDiscoverCancelable = false
            return
        }
        
        discoverCancelable?.cancel { _ in
            self.isDiscovering = false
        }
        updateCancelable?.cancel { _ in }
    }
    
    override func viewWillDisappear(
        _ animated: Bool
    ) {
        super.viewWillDisappear(animated)
        
        guard !ignoreDiscoverCancelable
        else {
            ignoreDiscoverCancelable = false
            return
        }
        
        discoverCancelable?.cancel { _ in
            self.isDiscovering = false
        }
        updateCancelable?.cancel { _ in }
    }
    
}

extension FPPayWithTerminalViewController {
    
    @objc
    func actionDiscover() {
        emailTextField.resignFirstResponder()
        
        if isReaderConnected {
            isDiscovering = true
            PaymentCardController.shared.terminal.disconnectReader { _ in
                self.isDiscovering = false
                self.actionDiscover()
            }
        } else {
            isDiscovering = true
            discoverCancelable = PaymentCardController.shared.terminal.discoverReaders(
                delegate: self
            ) { error in
                self.isDiscovering = false
                self.discoverCancelable = nil
                if let error = error {
                    print("discoverReaders failed: \(error)")
                } else {
                    print("discoverReaders succeeded")
                }
            }
        }
    }
    
    @objc
    func actionPay() {
        guard isReaderConnected
        else { return }
        
        emailTextField.resignFirstResponder()
        
        isPaying = true
        
        #if Devbuild
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Processing payment..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            hud?.hide(false)
            self?.isPaying = false
            self?.payProcessLabel.text = "Payment completed!"
            self?.onCompletion()
        }
        #else
        payProcessLabel.text = "Terminal: Swipe / Insert / Tap"
        
        PaymentCardController.shared.terminal.collectPayment(
            price: price,
            email: emailTextField.text?.isEmpty == true
                ? nil
                : emailTextField.text
        ) { result in
            guard case let .success(value) = result
            else {
                self.isPaying = false
                return
            }

            self.processPayment(value)
        }
        #endif
    }
    
}

extension FPPayWithTerminalViewController: DiscoveryDelegate {
    
    func terminal(
        _ terminal: Terminal,
        didUpdateDiscoveredReaders readers: [Reader]
    ) {
        guard terminal.connectionStatus == .notConnected,
              isDiscovering,
              !isConnecting
        else { return }
        
        if readersViewController == nil {
            let vc = FPPayWithTerminalListViewController(
                options: readers
            ) { reader in
                self.isConnecting = true
                self.ignoreDiscoverCancelable = true
                
                self.navigationController?.popViewController(
                    animated: true
                )
                
                let completion = {
                    Terminal.shared.connectBluetoothReader(
                        reader,
                        delegate: self,
                        connectionConfig: .init(
                            locationId: $0
                        )
                    ) { reader, error in
                        self.isConnecting = false
                        if let reader = reader {
                            print("Successfully connected to reader: \(reader)")
                        } else if let error = error {
                            print("connectReader failed: \(error)")
                        }
                    }
                }
                
                if let locationId = reader.locationId, !locationId.isEmpty {
                    completion(locationId)
                } else {
                    PaymentCardController.shared.terminal.readLocation { location in
                        switch location {
                        case .success(let value):
                            completion(value)
                        case .failure(let error):
                            print("location error: \(error)")
                        }
                    }
                }
            }
            
            ignoreDiscoverCancelable = true
            
            navigationController?.pushViewController(
                vc,
                animated: true
            )
            
            readersViewController = vc
        } else {
            readersViewController?.options = readers
        }
    }
    
}

extension FPPayWithTerminalViewController: BluetoothReaderDelegate {
    
    func reader(
        _ reader: Reader,
        didRequestReaderInput inputOptions: ReaderInputOptions = []
    ) {
        payProcessLabel.text = "Terminal: " + Terminal.stringFromReaderInputOptions(inputOptions)
    }
    
    func reader(
        _ reader: Reader,
        didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage
    ) {
        payProcessLabel.text = "Terminal: " +  Terminal.stringFromReaderDisplayMessage(displayMessage)
    }
    
    func reader(
        _ reader: Reader,
        didStartInstallingUpdate update: ReaderSoftwareUpdate,
        cancelable: Cancelable?
    ) {
        updateCancelable = cancelable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.payProcessLabel.text = "Terminal: Installing updates, hold on please!"
            self.isPaying = true
        }
    }
    
    func reader(
        _ reader: Reader,
        didReportReaderSoftwareUpdateProgress progress: Float
    ) { }
    
    func reader(
        _ reader: Reader,
        didFinishInstallingUpdate update: ReaderSoftwareUpdate?,
        error: Error?
    ) {
        payProcessLabel.text = "Installation completed, you can continue with the payment now."
        isPaying = false
    }
    
    func reader(
        _ reader: Reader,
        didReportAvailableUpdate update: ReaderSoftwareUpdate
    ) {
        Terminal.shared.installAvailableUpdate()
    }
    
}

private extension FPPayWithTerminalViewController {
    
    var isReaderConnected: Bool {
        #if Devbuild
        true
        #else
        PaymentCardController.shared.terminal.isReaderConnected
        #endif
    }
    
    var connectedReader: Reader? {
        PaymentCardController.shared.terminal.connectedReader
    }
    
}

private extension FPPayWithTerminalViewController {
    
    func setUpView() {
        view.backgroundColor = .white
        
        view.addSubview(connectedReaderLabel)
        view.addSubview(discoverButton)
        view.addSubview(emailTextField)
        view.addSubview(emailExplanationLabel)
        view.addSubview(payButton)
        view.addSubview(payProcessLabel)
        connectedReaderLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(16)
        }
        discoverButton.snp.makeConstraints {
            $0.top.equalTo(connectedReaderLabel.snp.bottom).offset(16)
            $0.centerX.equalTo(connectedReaderLabel.snp.centerX)
            $0.width.equalToSuperview().offset(-60)
            $0.height.equalTo(40)
        }
        emailTextField.snp.makeConstraints {
            $0.centerX.equalTo(discoverButton.snp.centerX)
            $0.top.equalTo(discoverButton.snp.bottom).offset(16)
            $0.width.equalTo(discoverButton.snp.width)
            $0.height.equalTo(44)
        }
        emailExplanationLabel.snp.makeConstraints {
            $0.centerX.equalTo(emailTextField.snp.centerX)
            $0.top.equalTo(emailTextField.snp.bottom).offset(16)
            $0.width.equalTo(emailTextField.snp.width)
        }
        payButton.snp.makeConstraints {
            $0.centerX.equalTo(emailExplanationLabel.snp.centerX)
            $0.top.equalTo(emailExplanationLabel.snp.bottom).offset(16)
            $0.width.equalTo(emailTextField.snp.width)
            $0.height.equalTo(discoverButton.snp.height)
        }
        payProcessLabel.snp.makeConstraints {
            $0.centerX.equalTo(payButton.snp.centerX)
            $0.top.equalTo(payButton.snp.bottom).offset(16)
            $0.width.equalTo(payButton.snp.width)
        }
        
        connectedReaderLabel.textColor = .black
        
        discoverButton.addTarget(
            self,
            action: #selector(actionDiscover),
            for: .touchUpInside
        )
        discoverButton.setTitleColor(
            .white,
            for: .normal
        )
        discoverButton.setBackgroundImage(
            UIImage(named: "green_btn"),
            for: .normal
        )
        discoverButton.layer.cornerRadius = 4
        
        payButton.addTarget(
            self,
            action: #selector(actionPay),
            for: .touchUpInside
        )
        payButton.setTitle(
            "Pay $\(FPCurrencyFormatter.printableCurrency(price))",
            for: .normal
        )
        payButton.setTitleColor(
            .white,
            for: .normal
        )
        payButton.setBackgroundImage(
            UIImage(named: "green_btn"),
            for: .normal
        )
        payButton.layer.cornerRadius = 4
        payButton.isEnabled = false
        
        payProcessLabel.textColor = .black
        payProcessLabel.textAlignment = .center
        payProcessLabel.numberOfLines = 0
        payProcessLabel.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        
        let toCopyColors = STPPaymentCardTextField()
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.keyboardType = .emailAddress
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "E-mail",
            attributes: [
                .font : UIFont(name: "HelveticaNeue-Light", size: 20)!,
                .foregroundColor : FPColorPaymentFlowPlaceholder
            ]
        )
        emailTextField.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        emailTextField.layer.cornerRadius = toCopyColors.cornerRadius
        emailTextField.layer.borderColor = toCopyColors.borderColor?.cgColor
        emailTextField.layer.borderWidth = toCopyColors.borderWidth
        emailTextField.layer.sublayerTransform = CATransform3DMakeTranslation(12, 0, 0)
        
        emailExplanationLabel.text = "If you fill out your e-mail, we'll send you a receipt for this purchase."
        emailExplanationLabel.numberOfLines = 0
        emailExplanationLabel.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        emailExplanationLabel.textColor = FPColorPaymentFlowMessage
        
        guard let customer = FPCustomer.activeCustomer() else { return }
        emailTextField.text = customer.email
    }
    
    func handleNewDiscoveringValue() {
        discoverButton.isLoading = isDiscovering
        
        guard !isDiscovering
        else { return }
        
        discoverButton.setTitle(
            isReaderConnected
                ? "Connected"
                : "Connect to terminal"
            ,
            for: .normal
        )
        payButton.isEnabled = isReaderConnected
        
        #if Devbuild
        connectedReaderLabel.text = "Connected terminal: DEV"
        #else
        connectedReaderLabel.text = isReaderConnected
            ? "Connected terminal: \(connectedReader?.serialNumber ?? "")"
            : ""
        #endif
        
        payProcessLabel.text = ""
    }
    
}

private extension FPPayWithTerminalViewController {
    
    func processPayment(
        _ intent: PaymentIntent
    ) {
        PaymentCardController.shared.terminal.processPayment(intent) { result in
            guard case let .success(value) = result
            else {
                self.isPaying = false
                return
            }

            PaymentCardController.shared.capturePaymentIntent(value) { error in
                self.isPaying = false
                self.payProcessLabel.text = error == nil
                    ? "Payment completed!"
                    : "Error!"
                if error == nil {
                    self.onCompletion()
                }
            }
        }
    }
    
}
