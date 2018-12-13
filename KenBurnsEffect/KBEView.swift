//
//  KBEView.swift
//  KenBurnsEffect
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the MIT license, see LICENSE file
//


/*
 
 An issue with using face detection in a slide show is that an image has to be processed before it can be shown.
 I chose this simple implementation just to show what needs to be done and to have it all in one placde. If you look
 at generateFaceRects and its associated functions you will see where the image processing and caching is done.
 
 Keep in mind that you can't just pass an image and have it displayed immediately. Processing a photo usually takes well
 over a second. One way to deal with this would be that while an image is being displayed, another is being processed. The trouble with
 this is that when the slide show repeats, it must process the images again. Not good for battery life. So, the best solution is probably to do
 something like I have done (very simply), which is to process and cache the images.
 
 Making a KBEViewController that will let you control things outside of the view, like changing the images to be displayed, is pretty straightforward.
 Add generateFaceRects and the associated functions to the controller and create a cache of the generated face rects. The KBEViewController will need
 to be a ImageInfoDatasource, and have the view's nextImageInfo function use that function from the delegate. And, of course, add the controller as the dataSource.

 */


import UIKit
import Vision
import ImageIO


struct ImageInfo {
    let index: Int
    let ciImageSize: CGSize
    let faceRects: [CGRect]
}

protocol ImageInfoDatasource {
    
    func nextImageInfo() -> ImageInfo?
    
}


class KBEView: UIView {

    private let imageView: UIImageView!
    private var _images: [UIImage]?
    var images: [UIImage]? {
        get { return _images }
        set { guard _images == nil,         // don't do this if _images not nil, so we don't mess up current slideshow. change this if you want to allow changing the slide show.
            newValue != nil,
            newValue!.count > 0 else {
                return
            }

            var newImages = [UIImage]()
            for image in newValue! {
                newImages.append(image)
            }
            _images = newImages

            self.generateFaceRects()
        }
    }
    private var _animationDuration = 12.0
    private var imageInfo: [ImageInfo]?
    private var currentIndex = -1
    private let initialImageDisplay = 1.5               // time to display image before animating

//    var dataSource: ImageInfoDatasource?
    var animationDuration: Double {
        get { return _animationDuration }
        set { guard newValue >= 1.00 else {
                    return
                }
            _animationDuration = newValue
            }
    }
    
    private func startEffect() {
        
        self.showNextImage()
        
    }
    
    private func nextImageInfo() -> ImageInfo? {
        
        self.currentIndex += 1
        if self.currentIndex > self.images!.count - 1  {
            self.currentIndex = 0
        }
        
        if let faceRects = self.imageInfo?.filter( {$0.index == self.currentIndex} ) {
            
            if faceRects.count > 0 {
                return faceRects.first!
                
            } else {
                self.skip()
            }
        }
        
        return nil
    }
    
    private func showNextImage() {
        
        if let currentImageInfo = self.nextImageInfo() {
            
            // _ = self.imageView.subviews.map({ $0.removeFromSuperview() })        // need this if doing debugDisplay and putting rectangles around faces
            UIView.transition(with: self.imageView,
                              duration: 2,
                              options: .transitionCrossDissolve,
                              animations: { self.imageView.image = self.images![self.currentIndex] },
                              completion: nil)
            self.imageView.transform = CGAffineTransform.identity
            
            switch currentImageInfo.faceRects.count {
            case 0:
                if currentImageInfo.ciImageSize.width > currentImageInfo.ciImageSize.height {
                    self.showLandscape()
                } else {
                    self.showPortrait()
                }
            //self.skip()
            case 1:
                self.showImageWithOneFace(imageInfo: currentImageInfo)
            //self.debugDisplay(imageInfo: currentImageInfo)
            case 2:
                self.showImageWithTwoFaces(imageInfo: currentImageInfo)
            default:
                self.showImageWithManyFaces(imageInfo: currentImageInfo)
            }
            
        }
    }

    
    //MARK: - Calculate face rect transforms and do animations
    
    private func showImageWithOneFace(imageInfo: ImageInfo) {
        let scaledRects = self.calculateScaledFaceRectsForImage(imageInfo: imageInfo)
        let scaling = self.faceRectsScaling(scaledRects: scaledRects)
        let faceRect = scaledRects.first!

        let zoomTransform = CGAffineTransform(scaleX: scaling, y: scaling)

        let horizontalTranslation: CGFloat = (self.imageView.bounds.midX - faceRect.midX) * scaling
        let verticalTranslation: CGFloat = (self.imageView.bounds.midY - faceRect.midY) * scaling
        let translateTransform = CGAffineTransform(translationX: horizontalTranslation, y: verticalTranslation)
        let panAndZoomTransform = zoomTransform.concatenating(translateTransform)
        
        let animationOptions: UIViewAnimationOptions = .curveLinear
        let keyframeAnimationOptions: UIViewKeyframeAnimationOptions = UIViewKeyframeAnimationOptions(rawValue: animationOptions.rawValue)
        UIView.animateKeyframes(withDuration: self.animationDuration, delay: self.initialImageDisplay, options: [keyframeAnimationOptions], animations:  {
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.6) {
                self.imageView.transform = panAndZoomTransform
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.3) {
                self.imageView.transform = CGAffineTransform.identity
            }
        }, completion: { completed in
            if completed {
                self.showNextImage()
            }
        })
    }
    
    private func showImageWithTwoFaces(imageInfo: ImageInfo) {
        let scaledRects = self.calculateScaledFaceRectsForImage(imageInfo: imageInfo)
        let scaling = self.faceRectsScaling(scaledRects: scaledRects)
        let faceRect = scaledRects.first!
        let faceRect2 = scaledRects.last!

        let zoomTransform = CGAffineTransform(scaleX: scaling, y: scaling)

        let horizontalTranslation: CGFloat = (self.imageView.bounds.midX - faceRect.midX) * scaling
        let verticalTranslation: CGFloat = (self.imageView.bounds.midY - faceRect.midY) * scaling
        let translateTransform = CGAffineTransform(translationX: horizontalTranslation, y: verticalTranslation)
        let panAndZoomTransform = zoomTransform.concatenating(translateTransform)
        
        let animationOptions: UIViewAnimationOptions = .curveLinear
        let keyframeAnimationOptions: UIViewKeyframeAnimationOptions = UIViewKeyframeAnimationOptions(rawValue: animationOptions.rawValue)
        UIView.animateKeyframes(withDuration: self.animationDuration, delay: self.initialImageDisplay, options: [keyframeAnimationOptions], animations:  {
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                self.imageView.transform = panAndZoomTransform
            }
            
            let secondHorizontalTranslation = (faceRect.origin.x - faceRect2.origin.x) * scaling
            var secondVerticalTranslation = (faceRect.origin.y - faceRect2.origin.y) * scaling
            if secondVerticalTranslation + verticalTranslation > self.imageView.bounds.height {
                secondVerticalTranslation = self.imageView.bounds.height - verticalTranslation
            }
            UIView.addKeyframe(withRelativeStartTime: 0.55, relativeDuration: 0.25) {
                self.imageView.transform = self.imageView.transform.concatenating(CGAffineTransform(translationX: secondHorizontalTranslation, y: secondVerticalTranslation))
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.85, relativeDuration: 0.3) {
                self.imageView.transform = CGAffineTransform.identity
            }
        }, completion: { completed in
            if completed {
                self.showNextImage()
            }
        })
    }
    
    private func showImageWithManyFaces(imageInfo: ImageInfo) {
        let scaledRects = self.calculateScaledFaceRectsForImage(imageInfo: imageInfo)
        let faceRect = scaledRects.first!
        let midFaceRectIndex = scaledRects.count / 2
        let faceRect2 = scaledRects[midFaceRectIndex]
        let faceRect3 = scaledRects.last!
        
        let scaling = self.faceRectsScaling(scaledRects: scaledRects)
        let zoomTransform = CGAffineTransform(scaleX: scaling, y: scaling)
        
        let horizontalTranslation: CGFloat = (self.imageView.bounds.midX - faceRect.midX) * scaling
        let verticalTranslation: CGFloat = CGFloat.minimum((self.imageView.bounds.midY - faceRect.midY) * scaling, self.imageView.bounds.height)
        let translateTransform = CGAffineTransform(translationX: horizontalTranslation, y: verticalTranslation)
        let panAndZoomTransform = zoomTransform.concatenating(translateTransform)
        
        let animationOptions: UIViewAnimationOptions = .curveLinear
        let keyframeAnimationOptions: UIViewKeyframeAnimationOptions = UIViewKeyframeAnimationOptions(rawValue: animationOptions.rawValue)
        UIView.animateKeyframes(withDuration: self.animationDuration, delay: self.initialImageDisplay, options: [keyframeAnimationOptions], animations:  {
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3) {
                self.imageView.transform = panAndZoomTransform
            }
            
            let secondHorizontalTranslation = (faceRect.origin.x - faceRect2.origin.x) * scaling
            var secondVerticalTranslation = (faceRect.origin.y - faceRect2.origin.y) * scaling
            if secondVerticalTranslation + verticalTranslation > self.imageView.bounds.height {
                secondVerticalTranslation = self.imageView.bounds.height - verticalTranslation
            }
            UIView.addKeyframe(withRelativeStartTime: 0.33, relativeDuration: 0.22) {
                self.imageView.transform = self.imageView.transform.concatenating(CGAffineTransform(translationX: secondHorizontalTranslation, y: secondVerticalTranslation))
            }
            
            let thirdHorizontalTranslation = (faceRect2.origin.x - faceRect3.origin.x) * scaling
            var thirdVerticalTranslation = (faceRect2.origin.y - faceRect3.origin.y) * scaling
            if thirdVerticalTranslation + secondVerticalTranslation + verticalTranslation > self.imageView.bounds.height {
                thirdVerticalTranslation = self.imageView.bounds.height - verticalTranslation - secondVerticalTranslation
            }
            UIView.addKeyframe(withRelativeStartTime: 0.58, relativeDuration: 0.22) {
                self.imageView.transform = self.imageView.transform.concatenating(CGAffineTransform(translationX: thirdHorizontalTranslation, y: thirdVerticalTranslation))
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.82, relativeDuration: 0.18) {
                self.imageView.transform = CGAffineTransform.identity
            }
        }, completion: { completed in
            if completed {
                self.showNextImage()
            }
        })
    }
    
    // didn't find any faces, and image is wider than tall, so do some horizontal panning
    private func showLandscape() {
        let scaling: CGFloat = 2.0
        let zoomTransform = CGAffineTransform(scaleX: scaling, y: scaling)
        let horizontalTranslation: CGFloat = (self.imageView.bounds.midX / 2.0) * scaling
        let verticalTranslation: CGFloat = 30.0 * scaling
        
        let translate = CGAffineTransform(translationX: horizontalTranslation, y: verticalTranslation)
        let panAndZoom = translate.concatenating(zoomTransform)
        
        let animationOptions: UIViewAnimationOptions = .curveLinear
        let keyframeAnimationOptions: UIViewKeyframeAnimationOptions = UIViewKeyframeAnimationOptions(rawValue: animationOptions.rawValue)
        UIView.animateKeyframes(withDuration: self.animationDuration, delay: 0.0, options: [keyframeAnimationOptions], animations:  {
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.38) {
                self.imageView.transform = panAndZoom
            }
            
            let secondHorizontalTranslation = (horizontalTranslation * 2.0) * scaling
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.38) {
                self.imageView.transform = self.imageView.transform.concatenating(CGAffineTransform(translationX: -secondHorizontalTranslation, y: 0))
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
                self.imageView.transform = CGAffineTransform.identity
            }
        }, completion: { completed in
            if completed {
                self.showNextImage()
            }
        })
    }
    
    // didn't find any faces, and image is taller than wide, so do some vertical panning
    private func showPortrait() {
        let scaling: CGFloat = 2.0
        let zoomTransform = CGAffineTransform(scaleX: scaling, y: scaling)
        let verticalTranslation: CGFloat = (self.imageView.bounds.midX / 3.0) * scaling
        let horizontalTranslation: CGFloat = 0.0
        
        let translate = CGAffineTransform(translationX: horizontalTranslation, y: verticalTranslation)
        let panAndZoom = translate.concatenating(zoomTransform)
        
        let animationOptions: UIViewAnimationOptions = .curveLinear
        let keyframeAnimationOptions: UIViewKeyframeAnimationOptions = UIViewKeyframeAnimationOptions(rawValue: animationOptions.rawValue)
        UIView.animateKeyframes(withDuration: self.animationDuration, delay: 0.0, options: [keyframeAnimationOptions], animations:  {
            
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.38) {
                self.imageView.transform = panAndZoom
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.38) {
                self.imageView.transform = self.imageView.transform.concatenating(CGAffineTransform(translationX: 0, y: -verticalTranslation * 1.5))
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
                self.imageView.transform = CGAffineTransform.identity
            }
        }, completion: { completed in
            if completed {
                self.showNextImage()
            }
        })
    }
    
    
    //MARK: Debugging
    
    // skips to next image after minimal delay so that you don't have to wait for normal display time
    private func skip() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25, execute: {
            self.showNextImage()
        })
    }
    
    // displays rects around faces
    private func debugDisplay(imageInfo: ImageInfo) {
        let scaledRects = self.calculateScaledFaceRectsForImage(imageInfo: imageInfo)
        
        for rect in scaledRects {
            let faceBox = UIView(frame: rect)
            
            faceBox.layer.borderWidth = 3
            faceBox.layer.borderColor = UIColor.red.cgColor
            faceBox.backgroundColor = .clear
            self.imageView!.addSubview(faceBox)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5, execute: {
            self.showNextImage()
        })
    }
    
    
    //MARK: Face detection
    
    private func generateFaceRects() {
        let serialQueue = DispatchQueue(label: "facedetection")
        self.imageInfo = [ImageInfo]()
        for (index, image) in self.images!.enumerated() {
            // detecting faces is quite slow. do them serially to make sure that the info is available when the image is displayed, in order (easy way to make sure image and image data match up).
            // this assumes that the display time is long enough to allow another image to be processed. and it really needs to be if the view is to be animated.
            serialQueue.async {
                self.addFaceRects(index: index, uiImage: image)
            }
        }
    }
    
    private func addFaceRects(index: Int, uiImage: UIImage) {

        let (imageSize, imageFaceRects) = self.detectFacesIn(uiImage: uiImage)
        
        self.imageInfo!.append( ImageInfo(index: index, ciImageSize: imageSize, faceRects: self.sortFaceRects( faceRects: imageFaceRects)) )
        if index == 0 {  //NOTE: once we've processed the first image it's usually okay to go ahead and start the slide show. But if first image is small and second is large, it's possible that this will need to be 1 to wait until the second image is processed to be safe.
            DispatchQueue.main.async {
                self.startEffect()
            }
        }
    }
    
    private func detectFacesIn(uiImage: UIImage) -> (CGSize, [CGRect]) {
        
        guard let ciImage = CIImage(image: uiImage) else {
                fatalError("can't create CIImage from UIImage")
            }
        
        // bitmaps have to be oriented "up" in order for image processing to work
        let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
        let inputImage = orientation == .up ? ciImage : ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))
        let imageSize = inputImage.extent.size
        var imageFaceRects = [CGRect]()

        let request = VNImageRequestHandler(ciImage: inputImage)
        let facesRequest = VNDetectFaceRectanglesRequest() { request, error in
            let results = request.results as! [VNFaceObservation]
            for observation in results {
                imageFaceRects.append(observation.boundingBox.scaled(to: imageSize))
            }
        }
        do {
            try request.perform([facesRequest])
        } catch {
            fatalError("can't perform request to get faces for image")
        }
        
        return (imageSize, imageFaceRects)
    }
    
    
    //MARK: Utils
    
    // takes the original CIImage rects and converts them to CGImage rects and scales to the view
    private func calculateScaledFaceRectsForImage(imageInfo: ImageInfo) -> [CGRect] {
        var scaledRects = [CGRect]()
        // rects are calculated for CIImage, convert to CGImage coordinates
        var cgImageTransform = CGAffineTransform(scaleX: 1, y: -1)
        cgImageTransform = cgImageTransform.translatedBy(x: 0, y: -imageInfo.ciImageSize.height)
        
        for faceRect in imageInfo.faceRects {
            // Apply the transform to convert the coordinates
            var faceViewBounds = faceRect.applying(cgImageTransform)
            
            // scale the calculated face rects to the view
            let viewSize = self.imageView!.bounds.size
            let scale = max(viewSize.width / imageInfo.ciImageSize.width,
                            viewSize.height / imageInfo.ciImageSize.height)
            let offsetX = (viewSize.width - imageInfo.ciImageSize.width * scale) / 2
            let offsetY = (viewSize.height - imageInfo.ciImageSize.height * scale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            
            scaledRects.append(faceViewBounds)
        }
        
        return scaledRects
    }
    
    // this adjusts the scaling (slightly) based on the size of the faces found
    private func faceRectsScaling( scaledRects: [CGRect]) -> CGFloat {
        var scaling: CGFloat = 100.0
        
        for rect in scaledRects {
            let faceArea = rect.width * rect.height
            let imageSizePercentage = faceArea / (self.imageView.frame.width * self.imageView.frame.height)
            let baseScale: CGFloat = 3.2
            let scale = (1.0 - imageSizePercentage) * baseScale
            
            if scale < scaling {
                scaling = scale
            }
        }
        
        return scaling
    }
    
    // always pan left to right, so make sure that rects are ordered that way
    private func sortFaceRects(faceRects: [CGRect]) -> [CGRect] {
        return faceRects.sorted(by: {$0.origin.x < $1.origin.x})
    }
    
    
    //MARK: Init
    override init(frame: CGRect) {
        self.imageView = UIImageView(frame: frame)
        self.imageView.contentMode = .scaleAspectFill

        super.init(frame: frame)
        self.addSubview(self.imageView)

        if let image = UIImage(named: "Ken-Burns.jpg") {            // it can take a while to analyze and show first image, so pay homage to the namesake
            self.imageView.image = image
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
