//
//  UIViewExtension.swift
//  QRcodeSample
//
//  Created by joinhov on 16/1/5.
//  Copyright © 2016年 lance. All rights reserved.
//

import UIKit

extension UIView {
    
    var width:CGFloat {
        get {
            return self.frame.size.width;
        }
    }
    
    var height:CGFloat {
        get {
            return self.frame.size.height;
        }
    }
    
    var x:CGFloat {
        get {
            return self.frame.origin.x;
        }
        
        set {
            var temp = self.frame;
            temp.origin.x = newValue;
            self.frame = temp;
        }
    }
    
    var y:CGFloat {
        get {
            return self.frame.origin.y;
        }
        set {
            var temp = self.frame;
            temp.origin.y = newValue;
            self.frame = temp;
        }
    }
    
}