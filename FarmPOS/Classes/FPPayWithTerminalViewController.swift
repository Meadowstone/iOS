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
    
    private let discoverButton = LoadableButton()
    private let connectedReaderLabel = UILabel()
    
    private var discoverCancelable: Cancelable?
    private var isDiscovering = false {
        didSet {
            handleNewDiscoveringValue()
        }
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
        discoverButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(200)
            $0.height.equalTo(32)
        }
        connectedReaderLabel.snp.makeConstraints {
            $0.centerX.equalTo(discoverButton)
            $0.bottom.equalTo(discoverButton.snp.top).offset(-16)
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
        connectedReaderLabel.text = isReaderConnected
            ? "Connected terminal: \(connectedReader?.serialNumber ?? "")"
            : ""
    }
    
}

//class AViewController: UIViewController {
//
//    var discoverCancelable: Cancelable?
//    var collectCancelable: Cancelable?
//
//    var nextActionButton = UIButton(type: .system)
//    var readerMessageLabel = UILabel()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setUpInterface()
//    }
//
//    @objc
//    func collectPayment() {
//        PaymentCardController.shared.terminal.collectPayment(
//            price: 10,
//            email: nil
//        ) { result in
//            guard case let .success(value) = result
//            else { return }
//
//            self.processPayment(value)
//        }
//    }
//
//    private func processPayment(
//        _ intent: PaymentIntent
//    ) {
//        PaymentCardController.shared.terminal.processPayment(intent) { result in
//            guard case let .success(value) = result
//            else { return }
//
//            PaymentCardController.shared.capturePaymentIntent(value) { error in
//                print(
//                    error == nil
//                        ? "Completed!"
//                        : "Error!"
//                )
//            }
//        }
//    }
//
//    func setUpInterface() {
//      readerMessageLabel.textAlignment = .center
//      readerMessageLabel.numberOfLines = 0
//
//      nextActionButton.setTitle("Connect to a reader", for: .normal)
//      nextActionButton.addTarget(self, action: #selector(discoverReaders), for: .touchUpInside)
//
//      let stackView = UIStackView(arrangedSubviews: [nextActionButton, readerMessageLabel])
//      stackView.axis = .vertical
//      stackView.translatesAutoresizingMaskIntoConstraints = false
//      view.addSubview(stackView)
//      NSLayoutConstraint.activate([
//          stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//          stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//          stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//          stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//      ])
//    }
//}
