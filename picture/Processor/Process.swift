//
//  Process.swift
//  picture
//
//  Created by Jason Goodney on 2/5/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import AVFoundation

class Process {
    
    func addOverlay(url: URL, image: UIImage, completion: @escaping (URL?) -> Void) {

        let videoWidth: CGFloat = VideoResolution.width
        let videoHeight: CGFloat = VideoResolution.height
        
        let height: CGFloat = videoHeight
        let width = videoWidth
    
        let size = CGSize(width: width, height: height)
        let placement = Placement.custom(x: 0, y: 0, size: size)
        
        let config = MergeConfiguration.init(frameRate: 30, directory: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0], quality: .high, placement: placement)
        
        let merge = Merge(config: config)
        let asset = AVAsset(url: url)
        
        merge.overlayVideo(video: asset, overlayImage: image, completion: { (url) in
            completion(url)
        }) { (progress) in
            print("Overlay progress: \(progress * 100)%")
        }
    }
    
    func addOverlay(url: URL, inView view: UIView, caption: UITextView? = nil, completion: @escaping (URL?) -> Void) {
        guard let captionTextView = caption else {
            print("No caption 🤷‍♂️")
            return
        }
        let videoWidth: CGFloat = VideoResolution.width
        let videoHeight: CGFloat = VideoResolution.height
        
        let height: CGFloat = 36 * (videoHeight / view.frame.height)
        let width = videoWidth
        let y: CGFloat = videoHeight - (captionTextView.center.y * (videoHeight / view.frame.height))
        
        let size = CGSize(width: width, height: height)
        let placement = Placement.custom(x: 0, y: y, size: size)
        
        let config = MergeConfiguration.init(frameRate: 30, directory: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0], quality: .high, placement: placement)
        
        let merge = Merge(config: config)
        let asset = AVAsset(url: url)
        
        merge.overlayVideo(video: asset, overlayImage: captionTextView.asImage(), completion: { (url) in
            completion(url)
        }) { (progress) in
            print("Overlay progress: \(progress.rounded())%")
        }
    }
    
    func videoWithCompression(url: URL, inView view: UIView, image: UIImage? = nil, completion: @escaping (Data?, Error?) -> Void) {
        
        let compressor = Compressor()
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".MP4")
        
        
        if let image = image {
            
            let videoWidth: CGFloat = VideoResolution.width
            let videoHeight: CGFloat = VideoResolution.height
        
            let height: CGFloat = videoHeight
            let width = videoWidth
            
            let size = CGSize(width: width, height: height)
            let placement = Placement.custom(x: 0, y: 0, size: size)
            
            let config = MergeConfiguration.init(frameRate: 30, directory: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0], quality: .high, placement: placement)
            
            let merge = Merge(config: config)
            let asset = AVAsset(url: url)
            
            let thumbnail = generateThumbnail(for: asset)
 
            let thumbnailData = image.jpegData(compressionQuality: Compression.thumbnailQuality)
            
            merge.overlayVideo(video: asset, overlayImage: image, completion: { (url) in
                guard let url = url else { return }
                
                let videoData = try! Data(contentsOf: url)
                print("File size before compression: \(Double(videoData.count / 1048576)) mb")
                
                compressor.compressFile(urlToCompress: url, outputURL: outputURL) { (url) in
                    do {
                        guard let mediaData = try? Data(contentsOf: url) else { return }
                        print("File size after compression: \(Double(mediaData.count / 1048576)) mb")
                        completion(mediaData, nil)
                        
                    } catch let error {
                        print("🎅🏻\nThere was an error in \(#function): \(error)\n\n\(error.localizedDescription)\n🎄")
                        completion(nil, error)
                    }
                }
                
            }) { (progress) in
                print("Overlay progress: \(progress.rounded())%")
            }
        } else {
            let videoData = try! Data(contentsOf: url)
            print("File size before compression: \(Double(videoData.count / 1048576)) mb")
            
            
           // DispatchQueue.main.async {
                
                compressor.compressFile(urlToCompress: url, outputURL: outputURL) { (url) in
                    do {
                        guard let mediaData = try? Data(contentsOf: url) else { return }
                        print("File size after compression: \(Double(mediaData.count / 1048576)) mb")
                        completion(mediaData, nil)
                        
                    } catch let error {
                        print("🎅🏻\nThere was an error in \(#function): \(error)\n\n\(error.localizedDescription)\n🎄")
                        completion(nil, error)
                    }
                }
            //}
            
//            Compressor.compressVideo(inputURL: url, handler: { (exportSession) in
//                guard let session = exportSession else {
//                    return
//                }
//
//                switch session.status {
//                case .unknown:
//
//                    break
//                case .waiting:
//                    break
//                case .exporting:
//                    break
//                case .completed:
//                    do {
//                        guard let mediaData = try? Data(contentsOf: session.outputURL!) else { return }
//                        print("File size after compression: \(Double(mediaData.count / 1048576)) mb")
//                        completion(mediaData, nil)
//
//                    } catch let error {
//                        print("🎅🏻\nThere was an error in \(#function): \(error)\n\n\(error.localizedDescription)\n🎄")
//                        completion(nil, error)
//                    }
//
//                case .failed:
//                    break
//                case .cancelled:
//                    break
//                }
//            })
        }
    }
    
    private func generateThumbnail(for asset: AVAsset) -> UIImage? {
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let timestamp = CMTime(seconds: 0, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
}
