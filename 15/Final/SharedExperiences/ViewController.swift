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

import UIKit
import RealityKit
import ARKit
import MultipeerConnectivity

final class ViewController: UIViewController {
  // MARK: - Properties
  @IBOutlet var arView: ARView!
  @IBOutlet weak var resetButton: UIButton!
  @IBOutlet weak var linkButton: UIButton!
  @IBOutlet weak var peersButton: UIButton!
  
  private let anchorName = "Anchor for cube placement."
  private let worldTrackingConfiguration: ARWorldTrackingConfiguration = {
    let worldTrackingConfiguration = ARWorldTrackingConfiguration()
    worldTrackingConfiguration.isCollaborationEnabled = true
    worldTrackingConfiguration.environmentTexturing = .automatic
    return worldTrackingConfiguration
  }()
  
  private var sessionIDObservation: NSKeyValueObservation?
  private var multipeerSession: MultipeerSession?
  private var peerSessionMap: [MCPeerID: String] = [:]
  
  private lazy var coachingOverlayView: ARCoachingOverlayView = {
    let coachingOverlayView = ARCoachingOverlayView()
    coachingOverlayView.session = arView.session
    coachingOverlayView.delegate = self
    coachingOverlayView.goal = .tracking
    coachingOverlayView.translatesAutoresizingMaskIntoConstraints = false
    return coachingOverlayView
  }()
  
  // MARK: - Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupARView()
    setupKVO()
    setupMultipeerSession()
    setupTapGesture()
    setupCoachingOverlayView()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    resetTrackingConfiguration()
    linkButton.isHidden = true
    peersButton.isHidden = true
  }
  
  // MARK: - Tracking
  private func setupARView() {
    arView.session.delegate = self
    arView.automaticallyConfigureSession = false
  }
  
  private func resetTrackingConfiguration() {
    arView.session.run(worldTrackingConfiguration,
                       options: [.removeExistingAnchors])
  }
  
  // MARK: - Coaching Overlay View
  private func setupCoachingOverlayView() {
    arView.addSubview(coachingOverlayView)
    NSLayoutConstraint.activate([
      coachingOverlayView.leadingAnchor.constraint(
        equalTo: arView.leadingAnchor),
      coachingOverlayView.trailingAnchor.constraint(
        equalTo: arView.trailingAnchor),
      coachingOverlayView.topAnchor.constraint(
        equalTo: arView.topAnchor),
      coachingOverlayView.bottomAnchor.constraint(
        equalTo: arView.bottomAnchor)
    ])
  }
  
  // MARK: - Gesture Recognizers
  private func setupTapGesture() {
    let tapGestureRecognizer = UITapGestureRecognizer(
      target: self,
      action: #selector(didTap(withGestureRecognizer:)))
    arView.addGestureRecognizer(tapGestureRecognizer)
  }
  
  @objc func didTap(
    withGestureRecognizer recognizer: UIGestureRecognizer) {
    let tapLocation = recognizer.location(in: arView)
    let raycastResults = arView.raycast(
      from: tapLocation,
      allowing: .estimatedPlane,
      alignment: .horizontal)
    guard let firstRaycastResult = raycastResults.first else { return }
    let anchor = ARAnchor(name: anchorName,
                          transform: firstRaycastResult.worldTransform)
    arView.session.add(anchor: anchor)
  }
  
  // MARK: - Peers
  private func setupMultipeerSession() {
    multipeerSession = MultipeerSession(
      receiveData: receiveData,
      joinPeer: joinPeer,
      leavePeer: leavePeer,
      discoverPeer: discoverPeer)
  }
  
  private func discoverPeer(_ peer: MCPeerID) -> Bool {
    guard let multipeerSession = multipeerSession,
      multipeerSession.connectedPeers.count <= 1
      else { return false }
    return true
  }
  
  private func joinPeer(_ peer: MCPeerID) {
    DispatchQueue.main.async { [weak self] in
      self?.linkButton.isHidden = false
    }
    sendARSessionIDTo(peers: [peer])
  }
  
  private func leavePeer(_ peer: MCPeerID) {
    guard let sessionID = peerSessionMap[peer] else { return }
    peersButton.isHidden = true
    removeAllAnchorsFromARSessionWithID(sessionID)
    peerSessionMap.removeValue(forKey: peer)
  }
  
  private func sendARSessionIDTo(peers: [MCPeerID]) {
    let command = "ARSessionID:\(arView.session.identifier.uuidString)"
    guard let multipeerSession = multipeerSession,
      let data = command.data(using: .utf8) else { return }
    multipeerSession.sendPeersData(data, dataMode: .reliable)
  }
  
  private func removeAllAnchorsFromARSessionWithID(_ identifier: String) {
    guard let frame = arView.session.currentFrame else { return }
    frame.anchors.forEach {
      guard let sessionIdentifier = $0.sessionIdentifier,
        sessionIdentifier.uuidString == identifier else { return }
      arView.session.remove(anchor: $0)
    }
  }
  
  private func receiveData(_ data: Data, from peer: MCPeerID) {
    let sessionIDStr = "ARSessionID:"
    if let collaborationData =
      try? NSKeyedUnarchiver.unarchivedObject(
        ofClass: ARSession.CollaborationData.self,
        from: data) {
      return arView.session.update(with: collaborationData)
    }
    guard let command = String(data: data, encoding: .utf8),
      command.starts(with: sessionIDStr),
      let oldSessionID = peerSessionMap[peer] else { return }
    let newSessionID = String(
      command[command.index(command.startIndex,
                            offsetBy: sessionIDStr.count)...])
    removeAllAnchorsFromARSessionWithID(oldSessionID)
    peerSessionMap[peer] = newSessionID
  }
  
  // MARK: - KVO
  private func setupKVO() {
    sessionIDObservation = observe(
      \.arView.session.identifier,
      options: [.new]) { _, change in
        guard let newValue = change.newValue,
          let multipeerSession = self.multipeerSession
          else { return }
        print("SESSION ID: \(newValue)")
        self.sendARSessionIDTo(
          peers: multipeerSession.connectedPeers)
    }
  }
  
  // MARK: - IBActions
  @IBAction private func resetButtonDidTouchUpInside(_ sender: UIButton) {
    resetTrackingConfiguration()
  }
}

// MARK: - ARSessionDelegate
extension ViewController: ARSessionDelegate {
  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    anchors.forEach {
      if let participantAnchor = $0 as? ARParticipantAnchor {
        linkButton.isHidden = true
        peersButton.isHidden = false
        arView.scene.addAnchor(
          makeSphereAnchorEntity(from: participantAnchor))
      } else if $0.name == anchorName {
        arView.scene.addAnchor(
          makeSphereAnchorEntity(from: $0))
      }
    }
  }
  
  private func makeSphereAnchorEntity(
    from anchor: ARAnchor,
    color: UIColor = .systemRed) -> AnchorEntity {
    let sphereRadius: Float = 0.04
    let sphereEntity = ModelEntity(
      mesh: MeshResource.generateSphere(radius: sphereRadius),
      materials: [
        SimpleMaterial(
          color: color, isMetallic: true)
    ])
    sphereEntity.collision = CollisionComponent(
      shapes: [.generateSphere(radius: sphereRadius)])
    sphereEntity.position = [0, sphereRadius, 0]
    let anchorEntity = AnchorEntity(anchor: anchor)
    anchorEntity.addChild(sphereEntity)
    return anchorEntity
  }
}

// MARK: - ARCoachingOverlayViewDelegate
extension ViewController: ARCoachingOverlayViewDelegate {
  func coachingOverlayViewWillActivate(
    _ coachingOverlayView: ARCoachingOverlayView) {
    resetButton.isHidden = true
    linkButton.isHidden = true
    peersButton.isHidden = true
  }
  
  func coachingOverlayViewDidDeactivate(
    _ coachingOverlayView: ARCoachingOverlayView) {
    resetButton.isHidden = false
  }
  
  func coachingOverlayViewDidRequestSessionReset(
    _ coachingOverlayView: ARCoachingOverlayView) {
    resetTrackingConfiguration()
  }
}

// MARK: - Collaboration
extension ViewController {
  func session(
    _ session: ARSession,
    didOutputCollaborationData data: ARSession.CollaborationData) {
    guard let multipeerSession = multipeerSession,
      !multipeerSession.connectedPeers.isEmpty,
      let encodedData = try? NSKeyedArchiver.archivedData(
        withRootObject: data,
        requiringSecureCoding: true) else { return }
    multipeerSession.sendPeersData(
      encodedData,
      dataMode: data.priority == .critical
        ? .reliable
        : .unreliable)
  }
}
