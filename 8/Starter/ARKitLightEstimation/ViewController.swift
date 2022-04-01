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

class ViewController: UIViewController {
  // MARK: - IBOutlets
  @IBOutlet weak var sceneView: ARSCNView!
  @IBOutlet weak var instructionLabel: UILabel!
  
  @IBOutlet weak var mainStackView: UIStackView!
  @IBOutlet weak var lightEstimationStackView: UIStackView!
  
  @IBOutlet weak var ambientIntensityLabel: UILabel!
  @IBOutlet weak var ambientColorTemperatureLabel: UILabel!
  
  @IBOutlet weak var roughnessLabel: UILabel!
  @IBOutlet weak var metalnessLabel: UILabel!
  
  @IBOutlet weak var ambientIntensitySlider: UISlider!
  @IBOutlet weak var ambientColorTemperatureSlider: UISlider!
  
  @IBOutlet weak var lightEstimationSwitch: UISwitch!
  
  // MARK: - Properties
  var lightNodes = [SCNNode]()
  var sphereNodes = [SCNNode]()
  
  var detectedHorizontalPlane = false {
    didSet {
      
    }
  }
  
  private var ballProbeAnchor: AREnvironmentProbeAnchor?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addTapGesture()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setUpSceneView()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }
  
  func setUpSceneView() {
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
    configuration.environmentTexturing = .automatic
    sceneView.debugOptions = [.showFeaturePoints]
    sceneView.session.run(configuration,
                          options: [.removeExistingAnchors])
    sceneView.delegate = self
  }
  
  private func addTapGesture() {
    let tapGestureRecognizer = UITapGestureRecognizer(
      target: self, action: #selector(didRegisterTapGestureRecognizer(_:)))
    sceneView.addGestureRecognizer(tapGestureRecognizer)
  }
  
  @objc func didRegisterTapGestureRecognizer(
    _ recognizer: UITapGestureRecognizer) {
    let tapLocation = recognizer.location(in: sceneView)
    guard let raycastQuery = sceneView.raycastQuery(
    from: tapLocation,
    allowing: .estimatedPlane,
    alignment: .any),
    let raycastResult = sceneView.session.raycast(
      raycastQuery).first else { return }
    let sphereNode = getSphereNode(
      withPosition: raycastResult.worldTransform.translation)
    addLightNodeTo(sphereNode)
    sceneView.scene.rootNode.addChildNode(sphereNode)
  }
  
  func getSphereNode(withPosition position: SIMD3<Float>,
                     height: Float = 0) -> SCNNode {
    SCNNode()
  }
  
  func getLightNode() -> SCNNode {
    SCNNode()
  }
  
  func addLightNodeTo(_ node: SCNNode) {
    
  }
  
  @IBAction func ambientIntensitySliderValueDidChange(_ sender: UISlider) {
    
  }
  
  @IBAction func ambientColorTemperatureSliderValueDidChange(_ sender: UISlider) {
    
  }
  
  @IBAction func lightEstimationSwitchValueDidChange(_ sender: UISwitch) {
    
  }
  
  @IBAction func roughnessSliderValueDidChange(_ sender: UISlider) {
    
  }
  
  @IBAction func metalnessSliderValueDidChange(_ sender: UISlider) {
    
  }
}

extension ViewController: ARSCNViewDelegate {
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard anchor is ARPlaneAnchor else { return }
        guard anchor is ARPlaneAnchor else { return }
    let sphereNode = getSphereNode(
      withPosition: node.simdWorldPosition, height: 1)
    addLightNodeTo(sphereNode)
    node.addChildNode(sphereNode)
    detectedHorizontalPlane = true
  }
}

extension float4x4 {
  var translation: SIMD3<Float> {
    let translation = columns.3
    return SIMD3(translation.x, translation.y, translation.z)
  }
}
