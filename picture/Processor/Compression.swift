//
//  Compression.swift
//  picture
//
//  Created by Jason Goodney on 1/15/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

struct BinarySize {
    static let MB: Double = 1048576
}

struct Compression {
    static let videoBitrate = 1024 * 4800
    static let videoQuality = AVAssetExportPreset1280x720
    static let photoQuality: CGFloat = 0.75
    static let thumbnailQuality: CGFloat = 0.1
}

class Compressor {
    static func compressVideo(inputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".MP4")
        
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: Compression.videoQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
            try? FileManager.default.removeItem(at: outputURL)
        }
    }
    
    var assetWriter:AVAssetWriter?
    var assetReader:AVAssetReader?
    let bitrate:NSNumber = NSNumber(value: Compression.videoBitrate)
    
    func compressFile(urlToCompress: URL, outputURL: URL, completion:@escaping (URL)->Void){
        //video file to make the asset
        
        var audioFinished = false
        var videoFinished = false
        
        
        
        let asset = AVAsset(url: urlToCompress);
        
        //create asset reader
        do{
            assetReader = try AVAssetReader(asset: asset)
        } catch{
            assetReader = nil
        }
        
        guard let reader = assetReader else{
            fatalError("Could not initalize asset reader probably failed its try catch")
        }
        
        let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first!
        let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first!
        
        let videoReaderSettings: [String:Any] =  [kCVPixelBufferPixelFormatTypeKey as String!:kCVPixelFormatType_32ARGB ]
        
        // ADJUST BIT RATE OF VIDEO HERE
        
        let videoSettings:[String:Any] = [
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey:self.bitrate],
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoHeightKey: videoTrack.naturalSize.height,
            AVVideoWidthKey: videoTrack.naturalSize.width
        ]
        
        
        let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
        let assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
        
        
        if reader.canAdd(assetReaderVideoOutput){
            reader.add(assetReaderVideoOutput)
        }else{
            fatalError("Couldn't add video output reader")
        }
        
        if reader.canAdd(assetReaderAudioOutput){
            reader.add(assetReaderAudioOutput)
        }else{
            fatalError("Couldn't add audio output reader")
        }
        
        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        videoInput.transform = videoTrack.preferredTransform
        //we need to add samples to the video input
        
        let videoInputQueue = DispatchQueue(label: "videoQueue")
        let audioInputQueue = DispatchQueue(label: "audioQueue")
        
        do{
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
        }catch{
            assetWriter = nil
        }
        guard let writer = assetWriter else{
            fatalError("assetWriter was nil")
        }
        
        writer.shouldOptimizeForNetworkUse = true
        writer.add(videoInput)
        writer.add(audioInput)
        
        
        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: .zero)
        
        
        let closeWriter:()->Void = {
            if (audioFinished && videoFinished){
                self.assetWriter?.finishWriting(completionHandler: {
                    
                    self.checkFileSize(sizeUrl: (self.assetWriter?.outputURL)!, message: "The file size of the compressed file is: ")
                    
                    completion((self.assetWriter?.outputURL)!)
                    
                })
                
                self.assetReader?.cancelReading()
                
            }
        }
        
        
        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
            while(audioInput.isReadyForMoreMediaData){
                let sample = assetReaderAudioOutput.copyNextSampleBuffer()
                if (sample != nil){
                    audioInput.append(sample!)
                }else{
                    audioInput.markAsFinished()
                    DispatchQueue.main.async {
                        audioFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
        
        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
            //request data here
            
            while(videoInput.isReadyForMoreMediaData){
                let sample = assetReaderVideoOutput.copyNextSampleBuffer()
                if (sample != nil){
                    videoInput.append(sample!)
                }else{
                    videoInput.markAsFinished()
                    DispatchQueue.main.async {
                        videoFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
            
        }
        
        
    }
    
    private func checkFileSize(sizeUrl: URL, message:String){
        let data = NSData(contentsOf: sizeUrl)!
        print(message, (Double(data.length) / 1048576.0), " mb")
    }
}

struct VideoResolution {
    
    static var size = CGSize()
    
    static var width: CGFloat {
        return size.width
    }
    static var height: CGFloat {
        return size.height
    }
}

//  Created by Diego Perini, TestFairy
//  License: Public Domain

import AVFoundation
import AssetsLibrary
import Foundation
import QuartzCore
import UIKit

// Global Queue for All Compressions
fileprivate let compressQueue = DispatchQueue(label: "compressQueue", qos: .background)

// Angle Conversion Utility
extension Int {
    fileprivate var degreesToRadiansCGFloat: CGFloat { return CGFloat(Double(self) * Double.pi / 180) }
}

// Compression Interruption Wrapper
class CancelableCompression {
    var cancel = false
}

// Compression Error Messages
struct CompressionError: LocalizedError {
    let title: String
    let code: Int
    
    init(title: String = "Compression Error", code: Int = -1) {
        self.title = title
        self.code = code
    }
}

// Compression Transformation Configuration
enum CompressionTransform {
    case keepSame
    case fixForBackCamera
    case fixForFrontCamera
}

// Compression Encode Parameters
struct CompressionConfig {
    let videoBitrate: Int
    let videomaxKeyFrameInterval: Int
    let avVideoProfileLevel: String
    let audioSampleRate: Int
    let audioBitrate: Int
    
    static let defaultConfig = CompressionConfig(
        videoBitrate: Compression.videoBitrate,
        videomaxKeyFrameInterval: 30,
        avVideoProfileLevel: AVVideoProfileLevelH264High41,
        audioSampleRate: 22050,
        audioBitrate: 180000
    )
}

// Video Size
typealias CompressionSize = (width: Int, height: Int)

// Compression Operation (just call this)
func compressh264VideoInBackground(videoToCompress: URL, destinationPath: URL, size: CompressionSize?, compressionTransform: CompressionTransform, compressionConfig: CompressionConfig, completionHandler: @escaping (URL)->(), errorHandler: @escaping (Error)->(), cancelHandler: @escaping ()->()) -> CancelableCompression {
    
    // Globals to store during compression
    class CompressionContext {
        var cgContext: CGContext?
        var pxbuffer: CVPixelBuffer?
        let colorSpace = CGColorSpaceCreateDeviceRGB()
    }
    
    // Draw Single Video Frame in Memory (will be used to loop for each video frame)
    func getCVPixelBuffer(_ i: CGImage?, compressionContext: CompressionContext) -> CVPixelBuffer? {
        // Allocate Temporary Pixel Buffer to Store Drawn Image
        weak var image = i!
        let imageWidth = image!.width
        let imageHeight = image!.height
        
        let attributes : [AnyHashable: Any] = [
            kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
            kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
        ]
        
        if compressionContext.pxbuffer == nil {
            CVPixelBufferCreate(kCFAllocatorSystemDefault,
                                imageWidth,
                                imageHeight,
                                kCVPixelFormatType_32ARGB,
                                attributes as CFDictionary?,
                                &compressionContext.pxbuffer)
        }
        
        // Draw Frame to Newly Allocated Buffer
        if let _pxbuffer = compressionContext.pxbuffer {
            let flags = CVPixelBufferLockFlags(rawValue: 0)
            CVPixelBufferLockBaseAddress(_pxbuffer, flags)
            let pxdata = CVPixelBufferGetBaseAddress(_pxbuffer)
            
            if compressionContext.cgContext == nil {
                compressionContext.cgContext = CGContext(data: pxdata,
                                                         width: imageWidth,
                                                         height: imageHeight,
                                                         bitsPerComponent: 8,
                                                         bytesPerRow: CVPixelBufferGetBytesPerRow(_pxbuffer),
                                                         space: compressionContext.colorSpace,
                                                         bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            }
            
            if let _context = compressionContext.cgContext, let image = image {
                _context.draw(image, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
            }
            else {
                CVPixelBufferUnlockBaseAddress(_pxbuffer, flags);
                return nil
            }
            
            CVPixelBufferUnlockBaseAddress(_pxbuffer, flags);
            return _pxbuffer;
        }
        
        return nil
    }
    
    // Asset, Output File
    let avAsset = AVURLAsset(url: videoToCompress)
    let filePath = destinationPath
    
    do {
        // Reader and Writer
        let writer = try AVAssetWriter(outputURL: filePath, fileType: AVFileType.mp4)
        let reader = try AVAssetReader(asset: avAsset)
        
        // Tracks
        let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).first!
        let audioTrack = avAsset.tracks(withMediaType: AVMediaType.audio).first!
        
        // Video Output Configuration
        let videoCompressionProps: Dictionary<String, Any> = [
            AVVideoAverageBitRateKey : compressionConfig.videoBitrate,
            AVVideoMaxKeyFrameIntervalKey : compressionConfig.videomaxKeyFrameInterval,
            AVVideoProfileLevelKey : compressionConfig.avVideoProfileLevel
        ]
        
        let videoOutputSettings: Dictionary<String, Any> = [
            AVVideoWidthKey : size == nil ? videoTrack.naturalSize.width : size!.width,
            AVVideoHeightKey : size == nil ? videoTrack.naturalSize.height : size!.height,
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoCompressionPropertiesKey : videoCompressionProps
        ]
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        let sourcePixelBufferAttributesDictionary: Dictionary<String, Any> = [
            String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32RGBA),
            String(kCVPixelFormatOpenGLESCompatibility) : kCFBooleanTrue
        ]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        
        videoInput.performsMultiPassEncodingIfSupported = true
        guard writer.canAdd(videoInput) else {
            errorHandler(CompressionError(title: "Cannot add video input"))
            return CancelableCompression()
        }
        writer.add(videoInput)
        
        // Audio Output Configuration
        var acl = AudioChannelLayout()
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
        acl.mChannelBitmap = AudioChannelBitmap(rawValue: UInt32(0))
        acl.mNumberChannelDescriptions = UInt32(0)
        
        let acll = MemoryLayout<AudioChannelLayout>.size
        let audioOutputSettings: Dictionary<String, Any> = [
            AVFormatIDKey : UInt(kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey : UInt(2),
            AVSampleRateKey : compressionConfig.audioSampleRate,
            AVEncoderBitRateKey : compressionConfig.audioBitrate,
            AVChannelLayoutKey : NSData(bytes:&acl, length: acll)
        ]
        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
        audioInput.expectsMediaDataInRealTime = false
        
        guard writer.canAdd(audioInput) else {
            errorHandler(CompressionError(title: "Cannot add audio input"))
            return CancelableCompression()
        }
        writer.add(audioInput)
        
        // Video Input Configuration
        let videoOptions: Dictionary<String, Any> = [
            kCVPixelBufferPixelFormatTypeKey as String : UInt(kCVPixelFormatType_422YpCbCr8_yuvs),
            kCVPixelBufferIOSurfacePropertiesKey as String : [:]
        ]
        let readerVideoTrackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoOptions)
        
        readerVideoTrackOutput.alwaysCopiesSampleData = true
        
        guard reader.canAdd(readerVideoTrackOutput) else {
            errorHandler(CompressionError(title: "Cannot add video output"))
            return CancelableCompression()
        }
        reader.add(readerVideoTrackOutput)
        
        // Audio Input Configuration
        let decompressionAudioSettings: Dictionary<String, Any> = [
            AVFormatIDKey: UInt(kAudioFormatLinearPCM)
        ]
        let readerAudioTrackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: decompressionAudioSettings)
        
        readerAudioTrackOutput.alwaysCopiesSampleData = true
        
        guard reader.canAdd(readerAudioTrackOutput) else {
            errorHandler(CompressionError(title: "Cannot add video output"))
            return CancelableCompression()
        }
        reader.add(readerAudioTrackOutput)
        
        // Orientation Fix for Videos Taken by Device Camera
        var appliedTransform: CGAffineTransform
        switch compressionTransform {
        case .fixForFrontCamera:
            appliedTransform = CGAffineTransform(rotationAngle: 90.degreesToRadiansCGFloat).scaledBy(x:-1.0, y:1.0)
        case .fixForBackCamera:
            appliedTransform = CGAffineTransform(rotationAngle: 270.degreesToRadiansCGFloat)
        case .keepSame:
            appliedTransform = CGAffineTransform.identity
        }
        
        // Begin Compression
        reader.timeRange = CMTimeRangeMake(start: .zero, duration: avAsset.duration)
        writer.shouldOptimizeForNetworkUse = true
        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        // Compress in Background
        let cancelable = CancelableCompression()
        compressQueue.async {
            // Allocate OpenGL Context to Draw and Transform Video Frames
            let glContext = EAGLContext(api: .openGLES2)!
            let context = CIContext(eaglContext: glContext)
            let compressionContext = CompressionContext()
            
            // Loop Video Frames
            var frameCount = 0
            var videoDone = false
            var audioDone = false
            
            while !videoDone || !audioDone {
                // Check for Writer Errors (out of storage etc.)
                if writer.status == AVAssetWriter.Status.failed {
                    reader.cancelReading()
                    writer.cancelWriting()
                    compressionContext.pxbuffer = nil
                    compressionContext.cgContext = nil
                    
                    if let e = writer.error {
                        errorHandler(e)
                        return
                    }
                }
                
                // Check for Reader Errors (source file corruption etc.)
                if reader.status == AVAssetReader.Status.failed {
                    reader.cancelReading()
                    writer.cancelWriting()
                    compressionContext.pxbuffer = nil
                    compressionContext.cgContext = nil
                    
                    if let e = reader.error {
                        errorHandler(e)
                        return
                    }
                }
                
                // Check for Cancel
                if cancelable.cancel {
                    reader.cancelReading()
                    writer.cancelWriting()
                    compressionContext.pxbuffer = nil
                    compressionContext.cgContext = nil
                    cancelHandler()
                    return
                }
                
                // Check if enough data is ready for encoding a single frame
                if videoInput.isReadyForMoreMediaData {
                    // Copy a single frame from source to destination with applied transforms
                    if let vBuffer = readerVideoTrackOutput.copyNextSampleBuffer(), CMSampleBufferDataIsReady(vBuffer) {
                        frameCount += 1
                        print("Encoding frame: ", frameCount)
                        
                        autoreleasepool {
                            let presentationTime = CMSampleBufferGetPresentationTimeStamp(vBuffer)
                            let pixelBuffer = CMSampleBufferGetImageBuffer(vBuffer)!
                            
                            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:0))
                            
                            let transformedFrame = CIImage(cvPixelBuffer: pixelBuffer).transformed(by: appliedTransform)
                            let frameImage = context.createCGImage(transformedFrame, from: transformedFrame.extent)
                            let frameBuffer = getCVPixelBuffer(frameImage, compressionContext: compressionContext)
                            
                            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
                            
                            _ = pixelBufferAdaptor.append(frameBuffer!, withPresentationTime: presentationTime)
                        }
                    } else {
                        // Video source is depleted, mark as finished
                        if !videoDone {
                            videoInput.markAsFinished()
                        }
                        videoDone = true
                    }
                }
                
                if audioInput.isReadyForMoreMediaData {
                    // Copy a single audio sample from source to destination
                    if let aBuffer = readerAudioTrackOutput.copyNextSampleBuffer(), CMSampleBufferDataIsReady(aBuffer) {
                        _ = audioInput.append(aBuffer)
                    } else {
                        // Audio source is depleted, mark as finished
                        if !audioDone {
                            audioInput.markAsFinished()
                        }
                        audioDone = true
                    }
                }
                
                // Let background thread rest for a while
                Thread.sleep(forTimeInterval: 0.001)
            }
            
            // Write everything to output file
            writer.finishWriting(completionHandler: {
                compressionContext.pxbuffer = nil
                compressionContext.cgContext = nil
                completionHandler(filePath)
            })
        }
        
        // Return a cancel wrapper for users to let them interrupt the compression
        return cancelable
    } catch {
        // Error During Reader or Writer Creation
        errorHandler(error)
        return CancelableCompression()
    }
}
