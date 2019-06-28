//
//  ViewController.swift
//  VideoTriming
//
//  Created by CTPLMac7 on 02/01/19.
//  Copyright © 2019 CTPLMac7. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMedia
import AssetsLibrary
import Photos

class ViewController: UIViewController {
    
    var isPlaying = true
    var isSliderEnd = true
    var playbackTimeCheckerTimer: Timer! = nil
    let playerObserver: Any? = nil
    
    let exportSession: AVAssetExportSession! = nil
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var asset: AVAsset!
    
    var url:NSURL! = nil
    var startTime: CGFloat = 0.0
    var stopTime: CGFloat  = 0.0
    var thumbTime: CMTime!
    var thumbtimeSeconds: Int!
    
    var videoPlaybackPosition: CGFloat = 0.0
    var cache:NSCache<AnyObject, AnyObject>!
    var timeSlider: TimeSlider! = nil
    
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var frameContainerView: UIView!
    @IBOutlet weak var imageFrameView: UIView!
    
    var initialCenter = CGPoint()
    
    var startTimestr = ""
    var endTimestr = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadViews()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        if let assets = asset
        {
        thumbTime = asset.duration
        thumbtimeSeconds      = Int(CMTimeGetSeconds(thumbTime))
        
        self.viewAfterVideoIsPicked()
        
        let item:AVPlayerItem = AVPlayerItem(asset: asset)
        player                = AVPlayer(playerItem: item)
        playerLayer           = AVPlayerLayer(player: player)
        playerLayer.frame     = videoPlayerView.bounds
        
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        player.actionAtItemEnd   = AVPlayer.ActionAtItemEnd.none
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapOnvideoPlayerView))
        self.videoPlayerView.addGestureRecognizer(tap)
        self.tapOnvideoPlayerView(tap: tap)
        
        videoPlayerView.layer.addSublayer(playerLayer)
        player.play()
            
        NotificationCenter.default.addObserver(self, selector: #selector(reachTheEndOfTheVideo(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
            
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        player!.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: timeScale),
            queue: DispatchQueue.main
            )
        { (CMTime) -> Void in
            if self.player!.currentItem?.status == .readyToPlay {
                let time = CMTimeGetSeconds(self.player!.currentTime());
                self.timeSlider.barValue = ( time / CMTimeGetSeconds(self.thumbTime) ) * 100.0;
            }
        }
            
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    @objc func reachTheEndOfTheVideo(_ notification: Notification) {
        player?.pause()
        player?.seek(to: CMTime.zero)
        player?.play()
    }
    
    @IBAction func scaleView(_ sender: UIPinchGestureRecognizer) {
        guard sender.view != nil else { return }
        
        if sender.state == .began || sender.state == .changed {
            sender.view?.transform = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale))!
            sender.scale = 1.0
        }
    }
    
    @IBAction func moveView(_ sender: UIPanGestureRecognizer) {
        
        guard sender.view != nil else {return}
        let piece = sender.view!
        // Get the changes in the X and Y directions relative to
        // the superview's coordinate space.
        let translation = sender.translation(in: piece.superview)
        if sender.state == .began {
            // Save the view's original position.
            self.initialCenter = piece.center
        }
        // Update the position for the .began, .changed, and .ended states
        if sender.state != .cancelled {
            // Add the X and Y translation to the view's original position.
            let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            piece.center = newCenter
        }
        else {
            // On cancellation, return the piece to its original location.
            piece.center = initialCenter
        }
    }
    
    //Loading Views
    func loadViews()
    {
        //Whole layout view
        
        saveButton.layer.cornerRadius   = 5.0
        
        //Hiding buttons and view on load
        saveButton.isHidden         = false
        frameContainerView.isHidden = true
        
        
        imageFrameView.layer.cornerRadius = 5.0
        imageFrameView.layer.borderWidth  = 1.0
        imageFrameView.layer.borderColor  = UIColor.white.cgColor
        imageFrameView.layer.masksToBounds = true
        
        player = AVPlayer()
        
        
        //Allocating NsCahe for temp storage
        self.cache = NSCache()
        
    }
    
}

//Subclass of VideoMainViewController
extension ViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    
    func viewAfterVideoIsPicked()
    {
        //Rmoving player if alredy exists
        if(playerLayer != nil)
        {
            playerLayer.removeFromSuperlayer()
        }
        
        self.createImageFrames()
        
        //unhide buttons and view after video selection
        saveButton.isHidden         = false
        frameContainerView.isHidden = false
        
        
        isSliderEnd = true
        startTimestr = "\(0.0)"
        endTimestr   = "\(thumbtimeSeconds!)"
        self.createrangSlider()
        
        
        //        if let timeObserverToken = timeObserverToken {
        //            player.removeTimeObserver(timeObserverToken)
        //            self.timeObserverToken = nil
        //        }
    }
    
    //Tap action on video player
    @objc func tapOnvideoPlayerView(tap: UITapGestureRecognizer)
    {
        if isPlaying
        {
            self.player.play()
        }
        else
        {
            self.player.pause()
        }
        isPlaying = !isPlaying
    }
    
    func createThumbnailOfVideoFromRemoteUrl(url: String) -> UIImage? {
        let asset = AVAsset(url: URL(string: url)!)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        //Can set this to improve performance if target size is known before hand
        //assetImgGenerate.maximumSize = CGSize(width,height)
        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            return thumbnail
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    //MARK: CreatingFrameImages
    func createImageFrames()
    {
        //creating assets
        let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter    = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore   = CMTime.zero;
        assetImgGenerate.appliesPreferredTrackTransform = true
        
        let numThumb:CGFloat = 10.0
        let lenThumb:CGFloat = self.imageFrameView.frame.width/numThumb
        
        let assetDur: CMTime = asset.duration
        let assetTime = CGFloat(assetDur.value) / CGFloat(assetDur.timescale)
        let timeThumb:CGFloat = assetTime/numThumb
        
        var startTime:CGFloat = 0.0
        var startXPosition:CGFloat = 0.0
        
        for _ in 0...Int(numThumb)-1
        {
            let imageButton = UIButton()
            imageButton.frame = CGRect(x: CGFloat(startXPosition), y: CGFloat(0),
                                       width: lenThumb, height: CGFloat(self.imageFrameView.frame.height))
            do {
                let timeScale = Int32(assetTime)
                let time:CMTime = CMTimeMakeWithSeconds(Float64(startTime), preferredTimescale: timeScale)
                let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                let image = UIImage(cgImage: img)
                imageButton.setImage(image, for: .normal)
            }
            catch
                _ as NSError
            {
                print("Image generation failed with error (error)")
            }
            
            startXPosition = startXPosition + lenThumb
            startTime = startTime + timeThumb
            imageButton.isUserInteractionEnabled = false
            imageFrameView.addSubview(imageButton)
        }
        
    }
    
    //Create range slider
    func createrangSlider()
    {
        //Remove slider if already present
        let subViews = self.frameContainerView.subviews
        for subview in subViews{
            if subview.tag == 1000 {
                subview.removeFromSuperview()
            }
        }
        
        timeSlider = TimeSlider(frame: frameContainerView.bounds)
        frameContainerView.addSubview(timeSlider)
        timeSlider.tag = 1000
        
        //Range slider action
        timeSlider.addTarget(self, action: #selector(ViewController.timeSliderValueChanged(_:)), for: .valueChanged)
        
        let time = DispatchTime.now() + Double(Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.timeSlider.trackHighlightTintColor = UIColor.clear
            self.timeSlider.curvaceousness = 1.0
        }
        
    }
    
    //MARK: timeSlider Delegate
    @objc func timeSliderValueChanged(_ timeSlider: TimeSlider) {
        self.player.pause()
        self.seekVideo(toPos: CGFloat(timeSlider.barValue)/100.0 * CGFloat(CMTimeGetSeconds(thumbTime)))
    }
    
    //Seek video when slide
    func seekVideo(toPos pos: CGFloat) {
        self.videoPlaybackPosition = pos
        let time: CMTime = CMTimeMakeWithSeconds(Float64(self.videoPlaybackPosition), preferredTimescale: self.player.currentTime().timescale)
        self.player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        
        if(pos == CGFloat(thumbtimeSeconds))
        {
            self.player.pause()
        }
    }
    
    //Save Video to Photos Library
    func saveToCameraRoll(URL: NSURL!) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL as URL)
        }) { saved, error in
            if saved {
                let alertController = UIAlertController(title: "Cropped video was saved successfully", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }}}
}

