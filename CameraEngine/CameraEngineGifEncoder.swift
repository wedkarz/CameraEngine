//
//  CameraEngineGifEncoder.swift
//  CameraEngine2
//
//  Created by Remi Robert on 11/02/16.
//  Copyright © 2016 Remi Robert. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices
import AVFoundation

public typealias blockCompletionGifEncoder = (_ success: Bool, _ url: URL?) -> (Void)

class CameraEngineGifEncoder {
    
    var blockCompletionGif: blockCompletionGifEncoder?
    
    func createGif(_ fileUrl: URL, frames: [UIImage], delayTime: Float, loopCount: Int = 0) {
        
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFLoopCount as String: loopCount
            ]]
        
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFDelayTime as String: delayTime
            ]]
        
        guard let destination = CGImageDestinationCreateWithURL(fileUrl as CFURL, kUTTypeGIF, frames.count, nil) else {
            self.blockCompletionGif?(false, nil)
            return
        }
        
        for currentFrame in frames {
            if let imageRef = currentFrame.fixOrientation().cgImage {
                CGImageDestinationAddImage(destination, imageRef, frameProperties as CFDictionary)
            }
        }
        
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
        
        if !CGImageDestinationFinalize(destination) {
            print("error fail finalize")
            self.blockCompletionGif?(false, nil)
        }
        else {
            self.blockCompletionGif?(true, fileUrl)
        }
    }
}

public extension UIImage {
    func degreesToRadians(degrees: CGFloat) -> CGFloat {
        return degrees * CGFloat(Double.pi) / 180
    }
    
    func imageRotatedByDegrees(degrees: CGFloat) -> UIImage {
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        let t = CGAffineTransform(rotationAngle: self.degreesToRadians(degrees: degrees))
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap?.translateBy(x: rotatedSize.width/2, y: rotatedSize.height/2)
        
        // Now, draw the rotated/scaled image into the context
        bitmap?.scaleBy(x: 1.0, y: -1.0)
        bitmap?.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage!
    }
    
    func fixOrientation() -> UIImage {
        if self.imageOrientation == UIImageOrientation.up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2));
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: self.size.height)
            transform = transform.rotated(by: CGFloat(-(Double.pi / 2)))
        case .up, .upMirrored:
            break
        }
        
        switch self.imageOrientation {
            
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break;
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        guard let cg = self.cgImage, let cs = cg.colorSpace,
            let ctx = CGContext(
            data: nil,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: cg.bitsPerComponent,
            bytesPerRow: 0,
            space: cs,
            bitmapInfo: UInt32(cg.bitmapInfo.rawValue)
        ) else { return UIImage() }
        
        
        ctx.concatenate(transform);
        
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            // Grr...
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: self.size.height, height: self.size.width))
        default:
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            break;
        }
        
        // And now we just create a new UIImage from the drawing context
        guard let cgimg = ctx.makeImage() else { return UIImage() }
        
        let img = UIImage(cgImage: cgimg)
        
        return img;
    }
}
