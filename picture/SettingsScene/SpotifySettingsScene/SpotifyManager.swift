//
//  SpotifyManager.swift
//  picture
//
//  Created by Jason Goodney on 4/7/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation

protocol SpotifyManagerDelegate: class {
    func appRemoteConnecting(manager: SpotifyManager)
    func appRemoteConnected(manager: SpotifyManager)
    func appRemoteDisconnect(manager: SpotifyManager)
}

class SpotifyManager: NSObject {
    
    public weak var delegate: SpotifyManagerDelegate?
    
    private var playURI = ""
    private var playerState: SPTAppRemotePlayerState?
    public var subscribedToPlayerState = false
    
    public func isConnected() -> Bool {
        return appRemote.isConnected
    }
    
    static fileprivate let kAccessTokenKey = "access-token-key"
    
    private var accessToken = UserDefaults.standard.string(forKey: SpotifyManager.kAccessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: SpotifyManager.kAccessTokenKey)
            defaults.synchronize()
        }
    }
    
    public lazy var appRemote: SPTAppRemote = {
        let sm = SpotifyManager()
        let configuration = SPTConfiguration(clientID: Key.SpotifyApp.clientId, redirectURL: URL(string: Key.SpotifyApp.redirectUri)!)
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()
    
    private var defaultCallback: SPTAppRemoteCallback {
        get {
            return {[weak self] _, error in
                if let error = error {
//                    self?.displayError(error as NSError)
                }
            }
        }
    }
    
    var songTitle: String {
        return playerState?.track.name ?? ""
    }
    
    var songArtist: String {
        return playerState?.track.artist.name ?? ""
    }
    
    // MARK: - Methods
    public func connectToSpotify() {
        if !(appRemote.isConnected) {
            getPlayerState()
            if (!appRemote.authorizeAndPlayURI(playURI)) {
                // The Spotify app is not installed, present the user with an App Store page
//                StoreKitManager.showAppStoreInstall(from: vc)
            }
        } else if playerState == nil || playerState!.isPaused {
            startPlayback()
        } else {
            pausePlayback()
        }
    }
    
    fileprivate func startPlayback() {
        if playerState == nil {
            appRemote.playerAPI?.play("", callback: defaultCallback)
        } else {
            appRemote.playerAPI?.resume(defaultCallback)
        }
    }
    
    fileprivate func pausePlayback() {
        appRemote.playerAPI?.pause(defaultCallback)
    }

    
    public func connect() {
        delegate?.appRemoteConnecting(manager: self)
        appRemote.connect()
    }
    
    public func disconnect() {
        delegate?.appRemoteDisconnect(manager: self)
        appRemote.disconnect()
    }
    
    public func appRemoteAuthorization(from url: URL) {
        let parameters = appRemote.authorizationParameters(from: url);
        
        if let accessToken = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = accessToken
            self.accessToken = accessToken
        } else if let error = parameters?[SPTAppRemoteErrorDescriptionKey] {
//            showError(error_description);
            print(error)
        }
    }
    
    public func getPlayerState() {
        appRemote.playerAPI?.getPlayerState { (result, error) -> Void in
            guard error == nil else { return }
            
            let playerState = result as! SPTAppRemotePlayerState
            //            self.updateViewWithPlayerState(playerState)
            self.playURI = playerState.track.uri
            self.playerStateDidChange(playerState)
        }
    }
    
    func playTrackWithUri(_ uri: String) {
        
        if playerState?.track.uri == uri {
            return
        }
        if !(appRemote.isConnected) {
            if (!appRemote.authorizeAndPlayURI(uri)) {
                // The Spotify app is not installed, present the user with an App Store page
//                StoreKitManager.showAppStoreInstall(from: )
            }
        }
        
        appRemote.playerAPI?.play(uri, callback: { (callback, error) in
            if callback != nil {
                print("is playing")
                self.getPlayerState()
            }
        })
        
    }
    
    public func subscribeToPlayerState() {
        guard (!subscribedToPlayerState) else { return }
        appRemote.playerAPI!.delegate = self
        appRemote.playerAPI?.subscribe { (_, error) -> Void in
            guard error == nil else { return }
            self.subscribedToPlayerState = true
//            self.updatePlayerStateSubscriptionButtonState()
        }
    }
    
    public func unsubscribeFromPlayerState() {
        guard (subscribedToPlayerState) else { return }
        appRemote.playerAPI?.unsubscribe { (_, error) -> Void in
            guard error == nil else { return }
            self.subscribedToPlayerState = false
//            self.updatePlayerStateSubscriptionButtonState()
        }
    }
    
    // MARK: - User API
    public var subscribedToCapabilities: Bool = false
    
    fileprivate func fetchUserCapabilities() {
        appRemote.userAPI?.fetchCapabilities(callback: { (capabilities, error) in
            guard error == nil else { return }
            
            let capabilities = capabilities as! SPTAppRemoteUserCapabilities
//            self.updateViewWithCapabilities(capabilities)
        })
    }
    
    public func subscribeToCapabilityChanges() {
        guard (!subscribedToCapabilities) else { return }
        appRemote.userAPI!.delegate = self
        appRemote.userAPI?.subscribe(toCapabilityChanges: { (success, error) in
            guard error == nil else { return }
            
            self.subscribedToCapabilities = true
//            self.updateCapabilitiesSubscriptionButtonState()
        })
    }
    
    fileprivate func unsubscribeFromCapailityChanges() {
        guard (subscribedToCapabilities) else { return }
        appRemote.userAPI?.unsubscribe(toCapabilityChanges: { (success, error) in
            guard error == nil else { return }
            
            self.subscribedToCapabilities = false
//            self.updateCapabilitiesSubscriptionButtonState()
        })
    }
    
}

extension SpotifyManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        delegate?.appRemoteConnected(manager: self)
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("didFailConnectionAttemptWithError")
        delegate?.appRemoteDisconnect(manager: self)
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("didDisconnectWithError")
        delegate?.appRemoteDisconnect(manager: self)
    }
    
}

// MARK: - SPTAppRemotePlayerStateDelegate
extension SpotifyManager: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        self.playerState = playerState
//        PlayerStateController.shared.state = self.playerState
//        updateViewWithPlayerState(playerState)
    }
}

// MARK: - SPTAppRemoteUserAPIDelegate
extension SpotifyManager: SPTAppRemoteUserAPIDelegate {
    
    func userAPI(_ userAPI: SPTAppRemoteUserAPI, didReceive capabilities: SPTAppRemoteUserCapabilities) {
//        updateViewWithCapabilities(capabilities)
    }
    
}
