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
import Vision

final class ViewController: UIViewController {
  // MARK: - IBOutlets
  @IBOutlet var sceneView: ARSCNView!
  @IBOutlet weak var label: UILabel!
  
  // MARK: - Properties
  private let worldTrackingConfiguration: ARWorldTrackingConfiguration = {
    let worldTrackingConfiguration = ARWorldTrackingConfiguration()
    worldTrackingConfiguration.planeDetection = .horizontal
    return worldTrackingConfiguration
  }()
  
  private let anchorName = "toyRobotAnchor"
  private let toyRobotNode: SCNReferenceNode = {
    let resourceName = "toy_robot_vintage"
    guard let url = Bundle.main.url(
      forResource: resourceName, withExtension: "usdz"),
      let referenceNode = SCNReferenceNode(url: url)
      else { fatalError("Failed to load \(resourceName).") }
    referenceNode.load()
    return referenceNode
  }()
  
  private var isToyRobotAdded = false
  private var isAnimating = false
  
  private var cvPixelBuffer: CVPixelBuffer?
  private lazy var visionCoreMLRequest: VNCoreMLRequest = {
    do {
      let mlModel = try MLModel(contentsOf: Gesture.urlOfModelInThisBundle)
      let visionModel = try VNCoreMLModel(for: mlModel)
      let request = VNCoreMLRequest(model: visionModel) { request, error in
        self.handleObservationClassification(request: request, error: error)
      }
      request.imageCropAndScaleOption = .centerCrop
      return request
    } catch {
      fatalError("Error: \(error.localizedDescription)")
    }
  }()

  // MARK: - Computed Properties
  private var requestHandler: VNImageRequestHandler? {
    guard let pixelBuffer = cvPixelBuffer,
      let orientation = CGImagePropertyOrientation(
        rawValue: UInt32(UIDevice.current.orientation.rawValue))
      else { return nil }
    return VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                 orientation: orientation)
  }
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupSceneView()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    resetTrackingConfiguration()
  }
  
  // MARK: - Tracking
  private func setupSceneView() {
    sceneView.session.delegate = self
    sceneView.automaticallyUpdatesLighting = true
  }
  
  private func resetTrackingConfiguration() {
    sceneView.session.run(worldTrackingConfiguration,
                       options: [.removeExistingAnchors])
  }
  
  // MARK: - Frame Classification
  private func handleObservationClassification(
    request: VNRequest, error: Error?) {
    guard let observations = request.results
      as? [VNClassificationObservation],
      let observation = observations.first(
        where: { $0.confidence > 0.8 })
      else { return }
    let identifier = observation.identifier
    let confidence = observation.confidence
    var text = "Show your hand."
    if identifier.lowercased().contains("five") {
      self.moveToyRobot(isForward: true)
      text = "\(confidence) open hand."
    } else if identifier.lowercased().contains("fist") {
      self.moveToyRobot(isForward: false)
      text = "\(confidence) closed fist."
    }
    DispatchQueue.main.async {
      self.label.text = text
    }
  }
  
  private func classifyFrame(_ frame: ARFrame) {
    cvPixelBuffer = frame.capturedImage
    DispatchQueue.global(qos: .background).async { [weak self] in
      guard let self = self else { return }
      do {
        defer {
          self.cvPixelBuffer = nil
        }
        try self.requestHandler?.perform(
          [self.visionCoreMLRequest])
      } catch {
        print("Error:", error.localizedDescription)
      }
    }
  }
  
  // MARK: - Toy Robot
  private func moveToyRobot(isForward: Bool) {
    guard !isAnimating else { return }
    isAnimating = true
    let z: CGFloat = isForward ? 0.05 : -0.03
    let moveAction = SCNAction.moveBy(
      x: 0, y: 0, z: z, duration: 1)
    toyRobotNode.runAction(moveAction) {
      self.isAnimating = false
    }
  }
}

// MARK: - ARSessionDelegate
extension ViewController: ARSessionDelegate {
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    guard cvPixelBuffer == nil else { return }
    classifyFrame(frame)
  }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
  func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
    for anchor in anchors {
      guard !isToyRobotAdded, anchor is ARPlaneAnchor else { continue }
      isToyRobotAdded = true
      label.isHidden = false
      toyRobotNode.simdTransform = anchor.transform
      DispatchQueue.main.async {
        self.sceneView.scene.rootNode.addChildNode(
          self.toyRobotNode)
      }
    }
  }
}
