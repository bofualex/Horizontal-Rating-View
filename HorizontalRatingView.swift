// HorizontalRatingView.swift
//
// Copyright (c) 2017 Alex Bofu
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
import UIKit

protocol RatingViewDelegate: class {
    func ratingViewChanged()
}

@IBDesignable
final class HorizontalRatingView: UIView {
    
    fileprivate var emptyImageViews: [UIImageView] = []
    fileprivate var fullImageViews: [UIImageView] = []
    
    weak var delegate: RatingViewDelegate?
    var imageContentMode: UIViewContentMode = UIViewContentMode.scaleAspectFit
    
    @IBInspectable open var minImageSize: CGSize = CGSize(width: 5.0, height: 5.0)
    @IBInspectable open var editable: Bool = true
    @IBInspectable open var halfRatings: Bool = false
    @IBInspectable open var floatRatings: Bool = false
    
    @IBInspectable open var emptyImage: UIImage? {
        didSet {
            for imageView in emptyImageViews {
                imageView.image = emptyImage
            }
            refresh()
        }
    }
    
    @IBInspectable open var fullImage: UIImage? {
        didSet {
            for imageView in fullImageViews {
                imageView.image = fullImage
            }
            refresh()
        }
    }
    
    @IBInspectable open var minRating: Int  = 0 {
        didSet {
            if rating < Float(minRating) {
                rating = Float(minRating)
                refresh()
            }
        }
    }
    
    @IBInspectable open var maxRating: Int = 5 {
        didSet {
            if maxRating != oldValue {
                removeImageViews()
                initImageViews()
                
                setNeedsLayout()
                refresh()
            }
        }
    }
    
    @IBInspectable open var rating: Float = 0 {
        didSet {
            if rating != oldValue {
                delegate?.ratingViewChanged()
                refresh()
            }
        }
    }
    
    //MARK: - memory management
    required override public init(frame: CGRect) {
        super.init(frame: frame)
        initImageViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initImageViews()
    }
    
    //MARK: - private
    fileprivate func initImageViews() {
        guard emptyImageViews.isEmpty && fullImageViews.isEmpty else { return }
        
        for _ in 0..<maxRating {
            let emptyImageView = UIImageView()
            emptyImageView.contentMode = imageContentMode
            emptyImageView.image = emptyImage
            emptyImageViews.append(emptyImageView)
            addSubview(emptyImageView)
            
            let fullImageView = UIImageView()
            fullImageView.contentMode = imageContentMode
            fullImageView.image = fullImage
            fullImageViews.append(fullImageView)
            addSubview(fullImageView)
        }
    }
    
    fileprivate func removeImageViews() {
        subviews.forEach({ ($0 as! UIImageView).removeFromSuperview() })
        emptyImageViews.removeAll(keepingCapacity: false)
        fullImageViews.removeAll(keepingCapacity: false)
    }
    
    fileprivate func refresh() {
        for i in 0..<fullImageViews.count {
            let imageView = fullImageViews[i]
            
            if rating >= Float(i+1) {
                imageView.layer.mask = nil
                imageView.isHidden = false
            } else if rating > Float(i) && rating < Float(i+1) {
                let maskLayer = CALayer()
                maskLayer.frame = CGRect(x: 0, y: 0, width: CGFloat(rating-Float(i))*imageView.frame.size.width, height: imageView.frame.size.height)
                maskLayer.backgroundColor = UIColor.black.cgColor
                imageView.layer.mask = maskLayer
                imageView.isHidden = false
            } else {
                imageView.layer.mask = nil
                imageView.isHidden = true
            }
        }
    }
    
    fileprivate func sizeForImage(_ image: UIImage, inSize size: CGSize) -> CGSize {
        let imageRatio = image.size.width / image.size.height
        let viewRatio = size.width / size.height
        
        let scale = imageRatio < viewRatio ? size.height / image.size.height : size.width / image.size.width
        let width = scale * image.size.width
        let height = scale * image.size.height
        
        return imageRatio < viewRatio ? CGSize(width: width, height: size.height) : CGSize(width: size.width, height: height)
    }
    
    fileprivate func updateLocation(_ touch: UITouch) {
        guard editable else { return }
        
        let touchLocation = touch.location(in: self)
        var newRating: Float = 0
        
        for i in stride(from: (maxRating-1), through: 0, by: -1) {
            let imageView = emptyImageViews[i]
            
            guard touchLocation.x > imageView.frame.origin.x else {
                continue
            }
            
            let newLocation = imageView.convert(touchLocation, from: self)
            
            if imageView.point(inside: newLocation, with: nil) && (floatRatings || halfRatings) {
                let decimalNum = Float(newLocation.x / imageView.frame.size.width)
                newRating = Float(i) + decimalNum
                
                if halfRatings {
                    newRating = Float(i) + (decimalNum > 0.75 ? 1 : (decimalNum > 0.25 ? 0.5 : 0))
                }
            } else {
                newRating = Float(i) + 1.0
            }
            
            break
        }
        
        if rating == 1 && newRating == 1 {
            newRating = 0
        }
        
        rating = newRating < Float(minRating) ? Float(minRating) : newRating
    }
    
    // MARK: - override methods
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        guard let emptyImage = emptyImage else { return }
        
        let desiredImageWidth = frame.size.width / CGFloat(emptyImageViews.count)
        let maxImageWidth = max(minImageSize.width, desiredImageWidth)
        let maxImageHeight = max(minImageSize.height, frame.size.height)
        let imageViewSize = sizeForImage(emptyImage, inSize: CGSize(width: maxImageWidth, height: maxImageHeight))
        let imageXOffset = (frame.size.width - (imageViewSize.width * CGFloat(emptyImageViews.count))) /
            CGFloat((emptyImageViews.count - 1))
        
        for i in 0..<maxRating {
            let imageFrame = CGRect(x: i == 0 ? 0 : CGFloat(i) * (imageXOffset + imageViewSize.width), y: 0, width: imageViewSize.width, height: imageViewSize.height)
            
            var imageView = emptyImageViews[i]
            imageView.frame = imageFrame
            
            imageView = fullImageViews[i]
            imageView.frame = imageFrame
        }
        
        refresh()
    }
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        updateLocation(touch)
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        updateLocation(touch)
    }
}
