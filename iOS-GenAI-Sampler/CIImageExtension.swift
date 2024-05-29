//
//  CIImageExtension.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/20.
//

import CoreImage

extension CIImage {
    // TODO: リファクタ
    func resized(to maxSize: CGFloat) -> CIImage {
        let currentSize = extent.size
        let aspectRatio = CGFloat(currentSize.width) / CGFloat(currentSize.height)

        var newWidth: CGFloat
        var newHeight: CGFloat

        if currentSize.width > currentSize.height {
            // 幅が高さより大きい場合
            newWidth = min(CGFloat(currentSize.width), maxSize)
            newHeight = newWidth / aspectRatio
        } else {
            // 高さが幅より大きい（または同じ）場合
            newHeight = min(CGFloat(currentSize.height), maxSize)
            newWidth = newHeight * aspectRatio
        }
        let newSize = CGSize(width: newWidth, height: newHeight)
        let scale = min(newSize.width / extent.width, newSize.height / extent.height)
        return transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    // TODO: リファクタ
    func resizedByShortestSide(to maxSize: CGFloat) -> CIImage {
        let currentSize = extent.size
        let aspectRatio = CGFloat(currentSize.width) / CGFloat(currentSize.height)

        var newWidth: CGFloat
        var newHeight: CGFloat

        if currentSize.width < currentSize.height {
            newWidth = min(CGFloat(currentSize.width), maxSize)
            newHeight = newWidth / aspectRatio
        } else {
            newHeight = min(CGFloat(currentSize.height), maxSize)
            newWidth = newHeight * aspectRatio
        }
        let newSize = CGSize(width: newWidth, height: newHeight)
        let scale = min(newSize.width / extent.width, newSize.height / extent.height)
        return transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    func cropped(to maxSize: CGFloat) -> CIImage {
        let center = CGPoint(x: extent.midX, y: extent.midY)
        let cropRect = CGRect(x: center.x - maxSize / 2, y: center.y - maxSize / 2, width: maxSize, height: maxSize)
        return cropped(to: cropRect)
    }
}
