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
    
    private let discoverButton = LoadableButton()
    private let connectedReaderLabel = UILabel()
    private let payButton = LoadableButton()
    
    private var discoverCancelable: Cancelable?
    private var isDiscovering = false {
        didSet {
            handleNewDiscoveringValue()
        }
    }
    private var isPaying = false {
        didSet {
            payButton.isEnabled = !isPaying
            payButton.isLoading = isPaying
        }
    }
    
    init(
        price: Double
    ) {
        self.price = price
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
        discoverCancelable?.cancel { _ in
            self.isDiscovering = false
        }
    }
    
    override func viewWillDisappear(
        _ animated: Bool
    ) {
        super.viewWillDisappear(animated)
        discoverCancelable?.cancel { _ in
            self.isDiscovering = false
        }
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
//        self.readerMessageLabel.text = "\(readers.count) readers found"

        // Select the first reader the SDK discovers. In your app,
        // you should display the available readers to your user, then
        // connect to the reader they've selected.
        guard let selectedReader = readers.first else { return }

        // Only connect if we aren't currently connected.
        guard terminal.connectionStatus == .notConnected else { return }

        let connectionConfig = BluetoothConnectionConfiguration(
          // When connecting to a physical reader, your integration should specify either the
          // same location as the last connection (selectedReader.locationId) or a new location
          // of your user's choosing.
          //
          // Since the simulated reader is not associated with a real location, we recommend
          // specifying its existing mock location.
          locationId: selectedReader.locationId!
        )
        
        Terminal.shared.connectBluetoothReader(
            selectedReader,
            delegate: self,
            connectionConfig: connectionConfig
        ) { reader, error in
            if let reader = reader {
                print("Successfully connected to reader: \(reader)")
            } else if let error = error {
                print("connectReader failed: \(error)")
            }
        }
    }
    
}

extension FPPayWithTerminalViewController: BluetoothReaderDelegate {
    
    func reader(
        _ reader: Reader,
        didRequestReaderInput inputOptions: ReaderInputOptions = []
    ) {
//        readerMessageLabel.text = Terminal.stringFromReaderInputOptions(inputOptions)
    }
    
    func reader(
        _ reader: Reader,
        didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage
    ) {
//        readerMessageLabel.text = Terminal.stringFromReaderDisplayMessage(displayMessage)
    }
    
    func reader(
        _ reader: Reader,
        didStartInstallingUpdate update: ReaderSoftwareUpdate,
        cancelable: Cancelable?
    ) {
        // Show UI communicating that a required update has started installing
    }
    
    func reader(
        _ reader: Reader,
        didReportReaderSoftwareUpdateProgress progress: Float
    ) {
        // Update the progress of the install
    }
    
    func reader(
        _ reader: Reader,
        didFinishInstallingUpdate update: ReaderSoftwareUpdate?,
        error: Error?
    ) {
        // Report success or failure of the update
    }
    
    func reader(
        _ reader: Reader,
        didReportAvailableUpdate update: ReaderSoftwareUpdate
    ) {
        // Show UI communicating that an update is available
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
        discoverButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(200)
            $0.height.equalTo(32)
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
        payButton.setBackgroundImage(
            nil,
            for: .disabled
        )
        payButton.backgroundColor = .darkGray
        payButton.layer.cornerRadius = 4
        payButton.isEnabled = false
        
        connectedReaderLabel.textColor = .black
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
                print(
                    error == nil
                        ? "Completed!"
                        : "Error!"
                )
            }
        }
    }
    
}
