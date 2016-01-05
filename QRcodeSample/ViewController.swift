//
//  ViewController.swift
//  QRcodeSample
//
//  Created by joinhov on 16/1/5.
//  Copyright © 2016年 lance. All rights reserved.
//

import UIKit
import AVFoundation

/// 扫码
class ViewController: UIViewController {
    
    var qrcodeControl:QRCodeViewController!;
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.qrcodeControl = QRCodeViewController();
        self.qrcodeControl.attachToViewController(self, delegate: self);
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
        self.qrcodeControl.startRunning();
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
        
        self.qrcodeControl.stopRunning();
    }


}

extension ViewController:QRCodeViewControllerDelegate {
    
    func qrcode(controller:QRCodeViewController, result:String) {
        self.qrcodeControl.stopRunning();
        
        UIAlertView(title: "扫描结果", message: result, delegate: self, cancelButtonTitle: "OK").show();
    }
    
}

extension ViewController:UIAlertViewDelegate {
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        self.qrcodeControl.startRunning();
        
    }
    
}

