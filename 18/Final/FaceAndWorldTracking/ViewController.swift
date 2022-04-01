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

final class ViewController: UIViewController {
  // MARK: - Properties
  @IBOutlet var arView: ARView!
  @IBOutlet weak var resetButton: UIButton!
  private var isSurfaceFound = false

  private let worldTrackingConfiguration: ARWorldTrackingConfiguration = {
    guard ARWorldTrackingConfiguration.supportsUserFaceTracking else {
      fatalError("Application requires support for user face tracking.")
    }
    let worldTrackingConfiguration = ARWorldTrackingConfiguration()
    worldTrackingConfiguration.userFaceTrackingEnabled = true
    return worldTrackingConfiguration
  }()

  private var steelHead: SteelHead?

  // MARK: - Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupARView()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    resetTrackingConfiguration()
  }

  // MARK: - Tracking
  private func setupARView() {
    arView.automaticallyConfigureSession = false
    arView.renderOptions.insert(.disableMotionBlur)
    arView.session.delegate = self
  }

  private func resetTrackingConfiguration() {
    arView.session.run(worldTrackingConfiguration,
                       options: [.removeExistingAnchors, .resetTracking])
  }

  // MARK: - Entity
  private func addSteelHeadToCamera() {
    let cameraEntity = AnchorEntity(.camera)
    let steelHead = SteelHead()
    cameraEntity.addChild(steelHead)
    steelHead.position.z = -1
    self.steelHead = steelHead
    arView.scene.addAnchor(cameraEntity)
  }

  // MARK: - IBActions
  @IBAction private func resetButtonDidTouchUpInside(_ sender: UIButton) {
    resetTrackingConfiguration()
  }
}

// MARK: - ARSessionDelegate
extension ViewController: ARSessionDelegate {
  func session(_ session: ARSession,
               didUpdate anchors: [ARAnchor]) {
    for case let faceAnchor as ARFaceAnchor in anchors {
      steelHead?.updateSteelHead(from: faceAnchor)
    }
  }

  func session(_ session: ARSession,
               didUpdate frame: ARFrame) {
    if steelHead == nil,
      case .normal = frame.camera.trackingState {
      addSteelHeadToCamera()
    }
  }
}
