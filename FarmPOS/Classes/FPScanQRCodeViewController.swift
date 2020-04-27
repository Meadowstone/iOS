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
        
        var captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        if isPad {
            preferredContentSize = CGSize(width: 640.0, height: 468.0);
            let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            for device in videoDevices as! [AVCaptureDevice] {
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
        
        let videoInput: AVCaptureDeviceInput! = try? AVCaptureDeviceInput(device: captureDevice)
        if videoInput == nil {
            FPAlertManager.showMessage("Video input unavailable", withTitle: "Error")
        } else {
            captureSession.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        var metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        if !shouldScanQROnly {
            metadataObjectTypes = [AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code]
        }
        metadataOutput.metadataObjectTypes = metadataObjectTypes
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        if !shouldScanQROnly && isPad {
            if UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeLeft {
                previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            } else {
                previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            }
        }
        
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        for metadataObject in metadataObjects as! [AVMetadataObject] {
            if let readableObj = metadataObject as? AVMetadataMachineReadableCodeObject {
                captureSession.stopRunning()
                if !gotCode {
                    gotCode = true
                    codeScannedBlock(readableObj.stringValue)
                }
            }
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        if !shouldScanQROnly && isPad {
            if UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeLeft {
                previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            } else {
                previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            }
        }
    }
}
