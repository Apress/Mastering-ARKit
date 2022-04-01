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
import ARKit
import RealityKit

final class ViewController: UIViewController {
  // MARK: - Value Types
  typealias JointAnchorTuple = (anchorEntity: AnchorEntity,
                                modelEntity: ModelEntity)

  enum ShoulderRaiseStage: String {
    case raised, finished
  }

  // MARK: - IBOutlets
  @IBOutlet var arView: ARView!
  @IBOutlet weak var shoulderRaiseStageLabel: UILabel!
  @IBOutlet weak var repetitionLabel: UILabel!

  // MARK: - Stored Properties
  private var repetition = 0 {
    didSet {
      repetitionLabel.text = "Repetition: \(repetition)"
    }
  }
  private var shoulderRaiseStage: ShoulderRaiseStage = .finished {
    didSet {
      shoulderRaiseStageLabel.text = "Should Raise Stage: \(shoulderRaiseStage.rawValue.capitalized)"
    }
  }
  private let maximumYDistanceMargin: Float = 0.05

  private let bodyTrackingConfiguration = ARBodyTrackingConfiguration()
  private var bodyTrackedEntity: BodyTrackedEntity?

  private let rootAnchorEntity = AnchorEntity()
  private let leftShoulderAnchorEntity = AnchorEntity()
  private let rightShoulderAnchorEntity = AnchorEntity()
  private let leftHandAnchorEntity = AnchorEntity()
  private let rightHandAnchorEntity = AnchorEntity()

  private let rootModelEntity = makeBoxModelEntity()
  private let leftShoulderModelEntity = makeBallModelEntity(color: .systemBlue)
  private let rightShoulderModelEntity = makeBallModelEntity(color: .systemBlue)
  private let leftHandModelEntity = makeBallModelEntity()
  private let rightHandModelEntity = makeBallModelEntity()

  // MARK: - Computed Properties
  private var jointAnchorSphereMap: [
    ARSkeleton.JointName: JointAnchorTuple
    ] {
    [
      .root: (rootAnchorEntity, rootModelEntity),
      .leftShoulder: (leftShoulderAnchorEntity, leftShoulderModelEntity),
      .leftHand: (leftHandAnchorEntity, leftHandModelEntity),
      .rightShoulder: (rightShoulderAnchorEntity, rightShoulderModelEntity),
      .rightHand: (rightHandAnchorEntity, rightHandModelEntity)
    ]
  }

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    arView.session.delegate = self
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    resetTrackingConfiguration()
    loadRiggedModelAsync()
  }

  // MARK: - Tracking
  private func resetTrackingConfiguration() {
    guard ARBodyTrackingConfiguration.isSupported else {
      fatalError("Device doesn't support ARBodyTrackingConfiguration.")
    }
    arView.session.run(bodyTrackingConfiguration)
  }

  // MARK: - Body Tracked Entity
  private func loadRiggedModelAsync() {
    do {
      // 1
      let robotBodyTrackedEntity = try Entity.loadBodyTracked(
        named: "robot")
      // 2
      robotBodyTrackedEntity.scale = [1, 1, 1]
      // 3
      bodyTrackedEntity = robotBodyTrackedEntity
      // 4
      let bodyAnchorEntity = AnchorEntity(.body)
      bodyAnchorEntity.addChild(robotBodyTrackedEntity)
      // 5
      arView.scene.addAnchor(bodyAnchorEntity)
    } catch {
      // 6
      print("Error:", error.localizedDescription)
    }
  }

  // MARK: - Model Entity Factory
  private static func makeBallModelEntity(
    color: UIColor = .customOrange) -> ModelEntity {
    let sphereMesh = MeshResource.generateSphere(
      radius: 0.06)
    let simpleMaterial = SimpleMaterial(
      color: color,
      isMetallic: false)
    let modelEntity = ModelEntity(
      mesh: sphereMesh,
      materials: [simpleMaterial])
    return modelEntity
  }

  private static func makeBoxModelEntity() -> ModelEntity {
    let boxMesh = MeshResource.generateBox(width: 0.3, height: 0.02, depth: 0.2)
    let simpleMaterial = SimpleMaterial(
      color: .black,
      isMetallic: false)
    let modelEntity = ModelEntity(
      mesh: boxMesh,
      materials: [simpleMaterial])
    return modelEntity
  }
}

// MARK: - ARSessionDelegate
extension ViewController: ARSessionDelegate {
  func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    for anchor in anchors {
      guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
      jointAnchorSphereMap.forEach { jointName, jointAnchorTuple in
        updateJointPosition(bodyAnchor: bodyAnchor,
                            jointName: jointName,
                            jointAnchorTuple: jointAnchorTuple)
      }
      guard
        let lhsUpperDifference = yDifferenceBetweenJoints(
          .leftShoulder, .leftHand, relativeToBodyAnchor: bodyAnchor),
        let rhsUpperDifference = yDifferenceBetweenJoints(
          .rightShoulder, .rightHand, relativeToBodyAnchor: bodyAnchor),
        let lhsLowerDifference = yDifferenceBetweenJoints(
          .root, .leftHand, relativeToBodyAnchor: bodyAnchor),
        let rhsLowerDifference = yDifferenceBetweenJoints(
          .root, .rightHand, relativeToBodyAnchor: bodyAnchor)
      else { continue }
      if shoulderRaiseStage == .finished,
         lhsUpperDifference <= maximumYDistanceMargin,
         rhsUpperDifference <= maximumYDistanceMargin {
        shoulderRaiseStage = .raised
      } else if shoulderRaiseStage == .raised,
                lhsLowerDifference <= maximumYDistanceMargin,
                rhsLowerDifference <= maximumYDistanceMargin {
        shoulderRaiseStage = .finished
        repetition += 1
      }
    }
  }

  private func updateJointPosition(
    bodyAnchor: ARBodyAnchor,
    jointName: ARSkeleton.JointName,
    jointAnchorTuple: JointAnchorTuple) {
    guard let transform = bodyAnchor.skeleton.modelTransform(
            for: jointName) else { return }
    let position = simd_make_float3(transform.columns.3)
    let jointAnchorEntity = jointAnchorTuple.anchorEntity
    jointAnchorEntity.position = position
    guard jointAnchorEntity.parent == nil else { return }
    let modelEntity = jointAnchorTuple.modelEntity
    jointAnchorEntity.addChild(modelEntity)
    bodyTrackedEntity?.addChild(jointAnchorEntity)
  }

  private func yDifferenceBetweenJoints(
    _ lhs: ARSkeleton.JointName,
    _ rhs: ARSkeleton.JointName,
    relativeToBodyAnchor bodyAnchor: ARBodyAnchor) -> Float? {
    guard
      let lhsTransform = bodyAnchor.skeleton.modelTransform(for: lhs),
      let rhsTransform = bodyAnchor.skeleton.modelTransform(for: rhs)
    else { return nil }
    let bodyAnchorYPosition = bodyAnchor.transform.columns.3
    let lhsPosition = simd_make_float3(bodyAnchorYPosition) +
      simd_make_float3(lhsTransform.columns.3)
    let rhsPosition = simd_make_float3(bodyAnchorYPosition) +
      simd_make_float3(rhsTransform.columns.3)
    let yDifference = abs(lhsPosition.y - rhsPosition.y)
    return yDifference
  }
}

