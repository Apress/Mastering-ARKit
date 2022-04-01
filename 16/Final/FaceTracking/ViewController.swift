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
  
  private var jawAnchor: ARAnchor?
  private var leftEyeAnchor: ARAnchor?
  private var rightEyeAnchor: ARAnchor?
  private var isPlayingSound = false
  private var isPlayingEyebrowsAnimation = false
  
  private var leftEyeEntity: Entity
  private var rightEyeEntity: Entity
  private var mouthEntity: Entity
  
  private var leftEyeAnchorEntity: AnchorEntity?
  private var rightEyeAnchorEntity: AnchorEntity?
  
  private var leftEyeModelEntity: ModelEntity?
  private var rightEyeModelEntity: ModelEntity?
  
  private let steelHead: Face.SteelHead
  private var mouthEntityTransformOrigin: Transform
  
  private let anchorName = "Anchor for cube placement."
  private let faceTrackingConfiguration: ARFaceTrackingConfiguration = {
    let faceTrackingConfiguration = ARFaceTrackingConfiguration()
    faceTrackingConfiguration.isLightEstimationEnabled = true
    return faceTrackingConfiguration
  }()
  
  // MARK: - Initializers
  required init?(coder: NSCoder) {
    guard let smileyFace = try? Face.loadSteelHead(),
      let leftEyeEntity = smileyFace.findEntity(named: "leftEye"),
      let rightEyeEntity = smileyFace.findEntity(named: "rightEye"),
      let mouthEntity = smileyFace.findEntity(named: "mouth") else {
      fatalError("Unable to load completely load Face.Smiley components.")
    }
    mouthEntityTransformOrigin = mouthEntity.transform
    self.steelHead = smileyFace
    self.leftEyeEntity = leftEyeEntity
    self.rightEyeEntity = rightEyeEntity
    self.mouthEntity = mouthEntity
    super.init(coder: coder)
  }
  
  // MARK: - Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupARView()
    setupSmileyFaceActionHandlers()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    resetTrackingConfiguration()
  }
  
  // MARK: - Tracking
  private func setupARView() {
    arView.session.delegate = self
  }
  
  private func resetTrackingConfiguration() {
    arView.session.run(faceTrackingConfiguration,
                       options: [.removeExistingAnchors, .resetTracking])
  }
  
  // MARK: - Anchor Entity
  private func makeEyeballAnchorEntity(
    from anchor: ARFaceAnchor,
    isLeftEye: Bool = true) -> AnchorEntity {
    let sphereRadius: Float = 0.04
    let sphereEntity = makeSphereModelEntity(radius: sphereRadius)
    sphereEntity.setTransformMatrix(
      isLeftEye ? anchor.leftEyeTransform : anchor.rightEyeTransform,
      relativeTo: nil)
    let boxEntity = makeBoxModelEntity(size: 0.03)
    boxEntity.position.z = sphereRadius
    sphereEntity.addChild(boxEntity)
    if isLeftEye {
      leftEyeModelEntity = sphereEntity
    } else {
      rightEyeModelEntity = sphereEntity
    }
    let anchorEntity = AnchorEntity(anchor: anchor)
    anchorEntity.addChild(sphereEntity)
    return anchorEntity
  }
  
  // MARK: - Model Entity
  private func makeSphereModelEntity(
    radius: Float,
    color: UIColor = .customOrange) -> ModelEntity {
    let sphereEntity = ModelEntity(
      mesh: MeshResource.generateSphere(radius: radius),
      materials: [
        SimpleMaterial(
          color: color, isMetallic: false)
    ])
    return sphereEntity
  }
  
  // MARK: - Smiley Face
  private func setupSmileyFaceActionHandlers() {
    steelHead.actions.bearSoundHasEnded.onAction = {
      [weak self] _ in
      self?.isPlayingSound = false
    }
    steelHead.actions.jiggleHatHasEnded.onAction = {
      [weak self] _ in
      self?.isPlayingEyebrowsAnimation = false
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

  private func makeBoxModelEntity(size: Float) -> ModelEntity {
    let boxEntity = ModelEntity(
      mesh: MeshResource.generateBox(size: size),
      materials: [SimpleMaterial(
        color: .white, isMetallic: false)
    ])
    return boxEntity
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
    if !isPlayingEyebrowsAnimation,
      let browOuterLeft = blendShapes[.browOuterUpLeft],
      browOuterLeft.floatValue >= 0.5,
      let browOuterRight = blendShapes[.browOuterUpRight],
      browOuterRight.floatValue >= 0.5 {
      isPlayingEyebrowsAnimation = true
      steelHead.notifications.jiggleHat.post()
    }
  }
}

extension UIColor {
  static let customOrange = UIColor(named: "CustomOrange")!
}
