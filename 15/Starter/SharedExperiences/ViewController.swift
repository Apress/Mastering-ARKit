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
    linkButton.isHidden = true
    peersButton.isHidden = true
  }
  
  // MARK: - Tracking
  private func setupARView() {
    arView.session.delegate = self
    arView.automaticallyConfigureSession = false
  }
  
  private func resetTrackingConfiguration() {
  }
  
  // MARK: - Coaching Overlay View
  private func setupCoachingOverlayView() {
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
  }
  
  // MARK: - Peers
  private func setupMultipeerSession() {
  }
  
  private func discoverPeer(_ peer: MCPeerID) -> Bool {
    return true
  }
  
  private func joinPeer(_ peer: MCPeerID) {
  }
  
  private func leavePeer(_ peer: MCPeerID) {
  }
  
  private func sendARSessionIDTo(peers: [MCPeerID]) {
  }
  
  private func removeAllAnchorsFromARSessionWithID(_ identifier: String) {
  }
  
  private func receiveData(_ data: Data, from peer: MCPeerID) {
  }
  
  // MARK: - KVO
  private func setupKVO() {
  }
  
  // MARK: - IBActions
  @IBAction private func resetButtonDidTouchUpInside(_ sender: UIButton) {
    resetTrackingConfiguration()
  }
}

// MARK: - ARCoachingOverlayViewDelegate

// MARK: - ARSessionDelegate
extension ViewController: ARSessionDelegate {
  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
  }
}

// MARK: - Collaboration
