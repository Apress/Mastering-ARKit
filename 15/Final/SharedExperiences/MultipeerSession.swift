/// Copyright (c) 2021 Jayven Nhan
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

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
