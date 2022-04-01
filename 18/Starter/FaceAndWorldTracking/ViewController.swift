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

  private let worldTrackingConfiguration = ARWorldTrackingConfiguration()
  private var isSurfaceFound = false
  private let steelHead: Face.SteelHead
  private var isPlayingSound = false
  private var mouthEntity: Entity
  private var mouthEntityTransformOrigin: Transform

  // MARK: - Initializers
  required init?(coder: NSCoder) {
    guard let steelHead = try? Face.loadSteelHead(),
      let mouthEntity = steelHead.findEntity(named: "mouth") else {
      fatalError("Unable to load completely load Face.Smiley components.")
    }
    mouthEntityTransformOrigin = mouthEntity.transform
    self.steelHead = steelHead
    self.mouthEntity = mouthEntity
    super.init(coder: coder)
  }

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
  private func setupSmileyFaceActionHandlers() {
    steelHead.actions.bearSoundHasEnded.onAction = {
      [weak self] _ in
      self?.isPlayingSound = false
    }
  }
  private func updateSteelHead(from faceAnchor: ARFaceAnchor) {
    let blendShapes = faceAnchor.blendShapes
    if let jawOpen = blendShapes[.jawOpen] {
      mouthEntity.transform.translation.z =
        mouthEntityTransformOrigin.translation.z +
        jawOpen.floatValue * 0.05
      if !isPlayingSound,
        jawOpen.floatValue >= 0.5 {
        isPlayingSound = true
        steelHead.notifications.playBearSound.post()
      }
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
    for case let faceAnchor as ARFaceAnchor in anchors {
      let anchorEntity = AnchorEntity(anchor: faceAnchor)
      anchorEntity.addChild(steelHead)
      arView.scene.addAnchor(anchorEntity)
    }
  }

  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    for case let faceAnchor as ARFaceAnchor in anchors {
      updateSteelHead(from: faceAnchor)
    }
  }
}
