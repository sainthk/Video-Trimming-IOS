//
//  TimeSlider.swift
//  VideoTriming
//
//  Created by seankim on 6/28/19.
//  Copyright © 2019 CTPLMac7. All rights reserved.
//

import UIKit
import QuartzCore

class TimeSliderTrackLayer: CALayer {
    weak var TimeSlider: TimeSlider?
    
    override func draw(in ctx: CGContext) {
        guard let slider = TimeSlider else {
            return
        }
        
        // Clip
        let cornerRadius = bounds.height * slider.curvaceousness / 2.0
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        ctx.addPath(path.cgPath)
        
        // Fill the track
        ctx.setFillColor(slider.trackTintColor.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
    }
}

class TimeSliderThumbLayer: CALayer {
    
    var highlighted: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    weak var TimeSlider: TimeSlider?
    
    var strokeColor: UIColor = UIColor.gray {
        didSet {
            setNeedsDisplay()
        }
    }
    var lineWidth: CGFloat = 0.5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(in ctx: CGContext) {
        guard let slider = TimeSlider else {
            return
        }
        
        let thumbFrame = bounds.insetBy(dx: 2.0, dy: 2.0)
        let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
        let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)
        
        // Fill
        ctx.setFillColor(slider.thumbTintColor.cgColor)
        ctx.addPath(thumbPath.cgPath)
        ctx.fillPath()
        
        // Outline
        ctx.setStrokeColor(strokeColor.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.addPath(thumbPath.cgPath)
        ctx.strokePath()
        
        if highlighted {
            ctx.setFillColor(UIColor(white: 0.0, alpha: 0.1).cgColor)
            ctx.addPath(thumbPath.cgPath)
            ctx.fillPath()
        }
    }
}

@IBDesignable
class TimeSlider: UIControl {
    
    @IBInspectable var minimumValue: Double = 0.0 {
        willSet(newValue) {
            assert(newValue < maximumValue, "TimeSlider: minimumValue should be lower than maximumValue")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable var maximumValue: Double = 100 {
        willSet(newValue) {
            assert(newValue > minimumValue, "TimeSlider: maximumValue should be greater than minimumValue")
        }
        didSet {
            updateLayerFrames()
        }
    }
    
    @IBInspectable var barValue: Double = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }
    
    var gapBetweenThumbs: Double {
        return 0.6 * Double(thumbWidth) * (maximumValue - minimumValue) / Double(bounds.width)
    }
    
    @IBInspectable var trackTintColor: UIColor = UIColor.clear {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable var trackHighlightTintColor: UIColor = UIColor.clear {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable var thumbTintColor: UIColor = UIColor.white {
        didSet {
            thumbLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable var thumbBorderColor: UIColor = UIColor.gray {
        didSet {
            thumbLayer.strokeColor = thumbBorderColor
        }
    }
    
    @IBInspectable var thumbBorderWidth: CGFloat = 0.5 {
        didSet {
            thumbLayer.lineWidth = thumbBorderWidth
        }
    }
    
    @IBInspectable var curvaceousness: CGFloat = 1.0 {
        didSet {
            if curvaceousness < 0.0 {
                curvaceousness = 0.0
            }
            
            if curvaceousness > 1.0 {
                curvaceousness = 1.0
            }
            
            trackLayer.setNeedsDisplay()
            thumbLayer.setNeedsDisplay()
        }
    }
    
    fileprivate var previouslocation = CGPoint()
    fileprivate let trackLayer = TimeSliderTrackLayer()
    fileprivate let thumbLayer = TimeSliderThumbLayer()
    fileprivate var thumbWidth: CGFloat = 13
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeLayers()
    }
    
    override func layoutSublayers(of: CALayer) {
        super.layoutSublayers(of:layer)
        updateLayerFrames()
    }
    
    fileprivate func initializeLayers() {
        layer.backgroundColor = UIColor.clear.cgColor
        
        trackLayer.TimeSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)
        
        thumbLayer.TimeSlider = self
        thumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(thumbLayer)
    }
    
    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        trackLayer.frame = bounds.insetBy(dx: 0.0, dy: bounds.height/3)
        trackLayer.setNeedsDisplay()
        
        let thumbCenter = CGFloat(positionForValue(barValue))
        thumbLayer.frame = CGRect(x: thumbCenter - thumbWidth/2.0, y: -5.0, width: thumbWidth, height: 50)
        thumbLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func positionForValue(_ value: Double) -> Double {
        return Double(bounds.width - thumbWidth) * (value - minimumValue) /
            (maximumValue - minimumValue) + Double(thumbWidth/2.0)
    }
    
    func boundValue(_ value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        return min(max(value, lowerValue), upperValue)
    }
    
    
    // MARK: - Touches
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previouslocation = touch.location(in: self)
        
        // Hit test the thumb layers
        if thumbLayer.frame.contains(previouslocation) {
            thumbLayer.highlighted = true
        }
        
        return thumbLayer.highlighted
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        
        // Determine by how much the user has dragged
        let deltaLocation = Double(location.x - previouslocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - bounds.height)
        
        previouslocation = location
        
        // Update the values
        if thumbLayer.highlighted {
            barValue = boundValue(barValue + deltaValue, toLowerValue: minimumValue, upperValue: maximumValue - gapBetweenThumbs)
        }
        
        sendActions(for: .valueChanged)
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        thumbLayer.highlighted = false
    }
}
