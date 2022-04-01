//
//  MultipeerSession.swift
//  SharedExperiences
//
//  Created by Jayven Nhan on 5/5/20.
//  Copyright © 2020 Jayven Nhan. All rights reserved.
//

import MultipeerConnectivity

final class MultipeerSession: NSObject {
  // MARK: - Value Types
  typealias PeerDataHandler = (Data, MCPeerID) -> Void
  typealias PeerMoveHandler = (MCPeerID) -> Void
  typealias PeerDiscoverHandler = (MCPeerID) -> Bool
  
  // MARK: - Properties
  static let serviceType = "ar-collab"
  private let receiveData: PeerDataHandler
  private let joinPeer: PeerMoveHandler
  private let leavePeer: PeerMoveHandler
  private let discoverPeer: PeerDiscoverHandler
  private let myPeerID = MCPeerID(
    displayName: UIDevice.current.name)
  
  private lazy var session: MCSession = {
    let session = MCSession(
      peer: myPeerID,
      securityIdentity: nil,
      encryptionPreference: .required)
    session.delegate = self
    return session
  }()
  
  private lazy var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser = {
    let nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(
      peer: myPeerID,
      discoveryInfo: nil,
      serviceType: MultipeerSession.serviceType)
    nearbyServiceAdvertiser.delegate = self
    return nearbyServiceAdvertiser
  }()
  
  private lazy var nearbyServiceBrowser: MCNearbyServiceBrowser = {
    let nearbyServiceBrowser = MCNearbyServiceBrowser(
      peer: myPeerID,
      serviceType: MultipeerSession.serviceType)
    nearbyServiceBrowser.delegate = self
    return nearbyServiceBrowser
  }()
  
  // MARK: - Computed Properties
  var connectedPeers: [MCPeerID] {
    session.connectedPeers
  }
  
  // MARK: - Initializers
  init(receiveData: @escaping PeerDataHandler,
       joinPeer: @escaping PeerMoveHandler,
       leavePeer: @escaping PeerMoveHandler,
       discoverPeer: @escaping PeerDiscoverHandler) {
    self.receiveData = receiveData
    self.joinPeer = joinPeer
    self.leavePeer = leavePeer
    self.discoverPeer = discoverPeer
    super.init()
    nearbyServiceAdvertiser.startAdvertisingPeer()
    nearbyServiceBrowser.startBrowsingForPeers()
  }
  
  // MARK: - Data Transmission
  func sendPeersData(_ data: Data, dataMode: MCSessionSendDataMode) {
    guard !connectedPeers.isEmpty else { return }
    do {
      try session.send(data, toPeers: connectedPeers,
                       with: dataMode)
    } catch {
      print(error.localizedDescription)
    }
  }
}

// MARK: - MCSessionDelegate
extension MultipeerSession: MCSessionDelegate {
  func session(
    _ session: MCSession,
    peer peerID: MCPeerID,
    didChange state: MCSessionState) {
    switch state {
    case .connected:
      joinPeer(peerID)
    case .notConnected:
      leavePeer(peerID)
    default:
      break
    }
  }
  
  func session(_ session: MCSession,
               didReceive data: Data,
               fromPeer peerID: MCPeerID) {
    receiveData(data, peerID)
  }
  
  func session(
    _ session: MCSession,
    didReceive stream: InputStream,
    withName streamName: String,
    fromPeer peerID: MCPeerID) {
  }
  
  func session(
    _ session: MCSession,
    didStartReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID, with progress: Progress) {
  }
  
  func session(
    _ session: MCSession,
    didFinishReceivingResourceWithName resourceName: String,
    fromPeer peerID: MCPeerID,
    at localURL: URL?,
    withError error: Error?) {
  }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerSession: MCNearbyServiceBrowserDelegate {
  func browser(_ browser: MCNearbyServiceBrowser,
               foundPeer peerID: MCPeerID,
               withDiscoveryInfo info: [String: String]?) {
    guard discoverPeer(peerID) else { return }
    browser.invitePeer(peerID, to: session,
                       withContext: nil,
                       timeout: 10)
  }
  
  func browser(_ browser: MCNearbyServiceBrowser,
               lostPeer peerID: MCPeerID) {
  }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                  didReceiveInvitationFromPeer peerID: MCPeerID,
                  withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    invitationHandler(true, session)
  }
}
