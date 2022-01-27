//
//  FPPayWithTerminalViewController.swift
//  Farm POS
//
//  Created by Luciano Polit on 26/1/22.
//  Copyright © 2022 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit
import StripeTerminal
import SnapKit

class FPPayWithTerminalViewController: UIViewController {
    
    let price: Double
    let onCompletion: () -> Void
    
    private let discoverButton = LoadableButton()
    private let connectedReaderLabel = UILabel()
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
        
        isPaying = true
        
        PaymentCardController.shared.terminal.collectPayment(
            price: price,
            email: nil
        ) { result in
            guard case let .success(value) = result
            else {
                self.isPaying = false
                return
            }

            self.processPayment(value)
        }
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
                
                Terminal.shared.connectBluetoothReader(
                    reader,
                    delegate: self,
                    connectionConfig: .init(
                        locationId: reader.locationId ?? ""
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
        PaymentCardController.shared.terminal.isReaderConnected
    }
    
    var connectedReader: Reader? {
        PaymentCardController.shared.terminal.connectedReader
    }
    
}

private extension FPPayWithTerminalViewController {
    
    func setUpView() {
        view.backgroundColor = .white
        
        view.addSubview(discoverButton)
        view.addSubview(connectedReaderLabel)
        view.addSubview(payButton)
        view.addSubview(payProcessLabel)
        discoverButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalToSuperview().offset(-60)
            $0.height.equalTo(40)
        }
        connectedReaderLabel.snp.makeConstraints {
            $0.centerX.equalTo(discoverButton.snp.centerX)
            $0.bottom.equalTo(discoverButton.snp.top).offset(-16)
        }
        payButton.snp.makeConstraints {
            $0.centerX.equalTo(discoverButton.snp.centerX)
            $0.top.equalTo(discoverButton.snp.bottom).offset(16)
            $0.width.equalTo(discoverButton.snp.width)
            $0.height.equalTo(discoverButton.snp.height)
        }
        payProcessLabel.snp.makeConstraints {
            $0.centerX.equalTo(payButton.snp.centerX)
            $0.top.equalTo(payButton.snp.bottom).offset(16)
            $0.width.equalTo(payButton.snp.width)
        }
        
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
            "Pay $\(price)",
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
        
        connectedReaderLabel.textColor = .black
        payProcessLabel.textColor = .black
        payProcessLabel.textAlignment = .center
        payProcessLabel.numberOfLines = 0
    }
    
    func handleNewDiscoveringValue() {
        discoverButton.isLoading = isDiscovering
        
        guard !isDiscovering
        else { return }
        
        discoverButton.setTitle(
            isReaderConnected
                ? "Find new terminals"
                : "Connect to terminal"
            ,
            for: .normal
        )
        payButton.isEnabled = isReaderConnected
        connectedReaderLabel.text = isReaderConnected
            ? "Connected terminal: \(connectedReader?.serialNumber ?? "")"
            : ""
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
