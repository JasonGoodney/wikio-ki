//
//  VideoProcessor.swift
//  picture
//
//  Created by Jason Goodney on 12/17/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import AVKit

struct VideoProcessor: MediaProcessable {
    
    func addOverlay(_ overlay: UIView, to videoURL: URL, size: CGSize) -> URL {
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let overlayLayer = CALayer()
        overlayLayer.addSublayer(overlay.layer)
        overlayLayer.frame = frame
        overlayLayer.masksToBounds = true
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        
        parentLayer.frame = frame
        videoLayer.frame = frame
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        let composition = AVMutableComposition()
        let videoComposition = processesVideoComposition(from: videoURL)
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = videoComposition
        
        
        let newVideoURL = urlOfPlayerItem(playerItem)!
        
        return newVideoURL
    }
    
    private func processesVideoComposition(from videoURL: URL) -> AVMutableVideoComposition {
        let videoAsset = AVAsset(url: videoURL)
        let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first!
        let mixComposition = AVMutableComposition()
        let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        do {
            try videoTrack?.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: videoAsset.duration), of: videoAssetTrack, at: CMTime.zero)
        } catch let error {
            print("🎅🏻\nThere was an error in \(#function): \(error)\n\n\(error.localizedDescription)\n🎄")
        }
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        let videoInstructionLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoAssetTrack)
        videoInstructionLayer.setTransform(videoAssetTrack.preferredTransform, at: .zero)
        videoInstructionLayer.setOpacity(0.0, at: videoAsset.duration)
        mainInstruction.layerInstructions = [videoInstructionLayer]
        let mainCompositionInstruction = AVMutableVideoComposition()
        let naturalSize = videoAssetTrack.naturalSize
        mainCompositionInstruction.renderSize = CGSize(width: naturalSize.width, height: naturalSize.height)
        mainCompositionInstruction.instructions = [mainInstruction]

        return mainCompositionInstruction
    }
    
    private func urlOfPlayerItem(_ playerItem : AVPlayerItem) -> URL? {
        return ((playerItem.asset) as? AVURLAsset)?.url
    }
}
