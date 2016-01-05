//
//  ViewController.swift
//  QRcodeSample
//
//  Created by joinhov on 16/1/5.
//  Copyright © 2016年 lance. All rights reserved.
//

import UIKit
import AVFoundation

// private let borderWidth:CGFloat =
/// 扫码
class ViewController: UIViewController {
    
    var session:AVCaptureSession!;
    
    var animImageView:UIImageView!;
    var keyAnimation:CAKeyframeAnimation?;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupMaskView();
        self.setupPreviewView();
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
        self.beginScanning();
        self.startAnimation();
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
        
        self.session.stopRunning();
        self.stopAnimation();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        
    }

    // 添加预览遮罩
    func setupMaskView() {
        let maskView = UIView();
        //maskView.backgroundColor = UIColor.redColor();
        
        let size = previewSize();
        let bottomSize = self.view.height * 0.2;
        
        // 计算出离顶边的距离
        let borderWidth = (self.view.height * 0.8 - size.height) / 2.0 + bottomSize;
        // 计算出边框宽度
        maskView.layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7).CGColor;
        maskView.layer.borderWidth = borderWidth;// 预留底部工具栏
        
        NSLog("borderWidth: %f", self.view.height * 0.8 - size.height);
        NSLog("origin.x: %f", maskView.frame.origin.y);
        // 计算出内容尺寸
        maskView.frame = CGRectMake(0, 0, size.width + borderWidth * 2, size.height + borderWidth * 2);
        maskView.center = CGPointMake(self.view.center.x, self.view.center.y - bottomSize / 2.0);
        
        NSLog("origin.x: %f", maskView.frame.origin.y);
        
        self.view.addSubview(maskView);
    }
    
    // 添加扫描动画视图
    func setupPreviewView() {
        let size = previewSize();
        let originX = (self.view.width - size.width) / 2;
        let originY = (self.view.height * 0.8 - size.height) / 2;
        let previewView = UIView();
        previewView.clipsToBounds = true;
        previewView.frame = CGRectMake(originX, originY, size.width, size.height);
        
        self.view.addSubview(previewView);
        
        self.animImageView = UIImageView();
        // 起始位置看不见
        self.animImageView.frame = CGRectMake(0, -size.height, size.width, size.height);
        self.animImageView.image = UIImage(named: "scan_net");
        
        previewView.addSubview(self.animImageView);
        
        let cornerSize:CGFloat = 18;
        let cornerImage = UIImage(named: "scan_corner");
        let topLeft = UIButton(type: .Custom);
        topLeft.frame = CGRectMake(0, 0, cornerSize, cornerSize);
        topLeft.setImage(cornerImage, forState: UIControlState.Normal);
        
        let topRight = UIButton(type: .Custom);
        topRight.frame = CGRectMake(previewView.width - cornerSize, 0, cornerSize, cornerSize);
        topRight.setImage(cornerImage, forState: UIControlState.Normal);
        
        let bottomLeft = UIButton(type: .Custom);
        bottomLeft.frame = CGRectMake(0, previewView.height - cornerSize, cornerSize, cornerSize);
        bottomLeft.setImage(cornerImage, forState: UIControlState.Normal);
        
        let bottomRight = UIButton(type: .Custom);
        bottomRight.frame = CGRectMake(previewView.width - cornerSize, previewView.height - cornerSize, cornerSize, cornerSize);
        bottomRight.setImage(cornerImage, forState: UIControlState.Normal);
        
        topLeft.transform = CGAffineTransformIdentity;
        topRight.transform = CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0));
        bottomLeft.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI / 2.0));
        bottomRight.transform = CGAffineTransformMakeRotation(CGFloat(M_PI));
        
        // 添加4个角
        previewView.addSubview(topLeft);
        previewView.addSubview(topRight);
        previewView.addSubview(bottomLeft);
        previewView.addSubview(bottomRight);
    }
    
    // 设置扫描动画
    func startAnimation() {
        if self.animImageView == nil {
            return;
        }
        
        let size = previewSize();
        
        self.animImageView.layer.removeAllAnimations();
        
        // 控制Y轴上的循环运动
        let keyAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y");
        
        keyAnimation.values = [0, size.height];
        keyAnimation.keyTimes = [0.0, 1.0];
        keyAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut);
        keyAnimation.duration = 1.0;
        keyAnimation.repeatCount = 10000;
        
        self.animImageView.layer.addAnimation(keyAnimation, forKey: nil);
    }
    
    func stopAnimation() {
        if self.animImageView == nil {
            return;
        }
        
        self.animImageView.layer.removeAllAnimations();
    }
    
    /// 获取扫描区域
    func previewSize() ->CGSize {
        
        let width = self.view.width * 0.8;
        
        return CGSizeMake(width, width);
    }
    
    func beginScanning() {
        
        /// 获取默认的后置摄像头
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo);
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: device);
            
            let output = AVCaptureMetadataOutput();
            // 指定预览区域中敢兴趣的区域来扫描
            output.rectOfInterest = CGRectMake(0.1, 0, 0.9, 1);
            output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue());
            
            
            self.session = AVCaptureSession();
            self.session.sessionPreset = AVCaptureSessionPresetHigh;
            self.session.addInput(deviceInput);
            self.session.addOutput(output);
            
            // 设置扫码支持的格式，二维码和条码兼容 --- 这个地方需要先添加后设置，否则易出错
            output.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
            
            // 设置预览区域
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.session);
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            previewLayer.frame = self.view.bounds;
            
            self.view.layer.insertSublayer(previewLayer, atIndex: 0);
            
            self.session.startRunning();
            
        }catch let error as NSError {
            NSLog("error: %@", error.description);
        }
        
    }

}

extension ViewController:AVCaptureMetadataOutputObjectsDelegate
{
    /// 扫描后的回调
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        if metadataObjects == nil && metadataObjects.count == 0 {
            return;
        }
        
        self.session.stopRunning();
        
        // AVMetadataMachineReadableCodeObject
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject;
        
        UIAlertView(title: "扫描结果", message: metadataObj.stringValue!, delegate: self, cancelButtonTitle: "OK").show();
        
    }
    
}

extension ViewController:UIAlertViewDelegate {
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        self.session.startRunning();
        
    }
    
}

