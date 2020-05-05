//
//  FPScanQRCodeViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/13/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import AVFoundation

class FPScanQRCodeViewController: FPRotationViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var gotCode: Bool = false
    var shouldScanQROnly = true
    var codeScannedBlock: ((_ code: String) -> Void)!
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    class func scanQRCodeViewControllerForQRCodes(_ forQRCodes: Bool, completion: @escaping (String) -> Void) -> FPScanQRCodeViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPScanQRCodeViewController") as! FPScanQRCodeViewController
        vc.shouldScanQROnly = forQRCodes
        vc.codeScannedBlock = completion
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if shouldScanQROnly {
            navigationItem.title = "Scan QR Code"
        } else {
            navigationItem.title = "Scan barcode"
        }
        
        captureSession = AVCaptureSession()
        
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        
        var captureDevice = AVCaptureDevice.default(for: .video)
        
        if isPad {
            preferredContentSize = CGSize(width: 640.0, height: 468.0);
            let videoDevices = AVCaptureDevice.devices(for: .video)
            for device in videoDevices {
                if shouldScanQROnly {
                    if device.position == .front {
                        captureDevice = device
                        break
                    }
                } else {
                    if device.position == .back {
                        captureDevice = device
                        break
                    }
                }
            }
            
        }
        
        let videoInput = captureDevice.flatMap { try? AVCaptureDeviceInput(device: $0) }
        if let videoInput = videoInput {
            captureSession.addInput(videoInput)
        } else {
            FPAlertManager.showMessage("Video input unavailable", withTitle: "Error")
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        var metadataObjectTypes: [AVMetadataObject.ObjectType] = [.qr]
        if !shouldScanQROnly {
            metadataObjectTypes = [.upce, .code39, .code39Mod43, .ean13, .ean8, .code93, .code128]
        }
        metadataOutput.metadataObjectTypes = metadataObjectTypes
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        if !shouldScanQROnly && isPad {
            if UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeLeft {
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            } else {
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            }
        }
        
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    
    func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for metadataObject in metadataObjects {
            if let readableObj = metadataObject as? AVMetadataMachineReadableCodeObject,
                let readableObjStringValue = readableObj.stringValue
            {
                captureSession.stopRunning()
                if !gotCode {
                    gotCode = true
                    codeScannedBlock(readableObjStringValue)
                }
            }
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        if !shouldScanQROnly && isPad {
            if UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeLeft {
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            } else {
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            }
        }
    }
}
