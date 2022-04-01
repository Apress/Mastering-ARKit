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
  let sphereMaterial: SCNMaterial = {
    let material = SCNMaterial()
    material.metalness.contents = 0
    material.roughness.contents = 0
    material.lightingModel = .physicallyBased
    return material
  }()
  
  var detectedHorizontalPlane = false {
    didSet {
      DispatchQueue.main.async {
        self.mainStackView.isHidden =
          !self.detectedHorizontalPlane
        self.instructionLabel.isHidden =
          self.detectedHorizontalPlane
        self.lightEstimationStackView.isHidden =
          !self.detectedHorizontalPlane
      }
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
  
  @IBAction func ambientIntensitySliderValueDidChange(_ sender: UISlider) {
    DispatchQueue.main.async {
      let ambientIntensity = sender.value
      self.ambientIntensityLabel.text = "Ambient Intensity: \(ambientIntensity)"
      
      guard !self.lightEstimationSwitch.isOn else { return }
      for lightNode in self.lightNodes {
        guard let light = lightNode.light else { continue }
        light.intensity = CGFloat(ambientIntensity)
      }
    }
  }
  
  @IBAction func ambientColorTemperatureSliderValueDidChange(_ sender: UISlider) {
    DispatchQueue.main.async {
      let ambientColorTemperature = self.ambientColorTemperatureSlider.value
      self.ambientColorTemperatureLabel.text = "Ambient Color Temperature: \(ambientColorTemperature)"
      
      guard !self.lightEstimationSwitch.isOn else { return }
      for lightNode in self.lightNodes {
        guard let light = lightNode.light else { continue }
        light.temperature = CGFloat(ambientColorTemperature)
      }
    }
  }
  
  @IBAction func lightEstimationSwitchValueDidChange(_ sender: UISwitch) {
    ambientIntensitySliderValueDidChange(
      ambientIntensitySlider)
    ambientColorTemperatureSliderValueDidChange(ambientColorTemperatureSlider)
  }
  
  @IBAction func roughnessSliderValueDidChange(_ sender: UISlider) {
    let roughness = sender.value
    DispatchQueue.main.async {
      self.roughnessLabel.text =
      "Roughness: \(roughness)"
      self.sphereMaterial
        .roughness.contents = roughness
    }
  }
  
  @IBAction func metalnessSliderValueDidChange(_ sender: UISlider) {
    let metalness = sender.value
    DispatchQueue.main.async {
      self.metalnessLabel.text =
      "Metalness: \(metalness)"
      self.sphereMaterial
        .metalness.contents = metalness
    }
  }
  
  func updateLightNodesLightEstimation() {
    DispatchQueue.main.async {
      guard self.lightEstimationSwitch.isOn,
        let lightEstimate = self.sceneView
          .session.currentFrame?.lightEstimate
        else { return }
      
      let ambientIntensity =
        lightEstimate.ambientIntensity
      let ambientColorTemperature =
        lightEstimate.ambientColorTemperature
      
      for lightNode in self.lightNodes {
        guard let light = lightNode.light else { continue }
        light.intensity = ambientIntensity
        light.temperature = ambientColorTemperature
      }
    }
  }
  
  func getSphereNode(withPosition position: SIMD3<Float>, height: Float = 0) -> SCNNode {
    let sphere = SCNSphere(radius: 0.1)
    sphere.firstMaterial = sphereMaterial
    let sphereNode = SCNNode(geometry: sphere)
    sphereNode.simdPosition = position
    sphereNode.position.y += Float(sphere.radius) + height
    
    return sphereNode
  }
  
  func getLightNode() -> SCNNode {
    let light = SCNLight()
    light.type = .omni
    light.intensity = 0
    light.temperature = 0
    
    let lightNode = SCNNode()
    lightNode.light = light
    lightNode.position = SCNVector3(0,1,0)
    
    return lightNode
  }
  
  func addLightNodeTo(_ node: SCNNode) {
    let lightNode = getLightNode()
    node.addChildNode(lightNode)
    lightNodes.append(lightNode)
  }
}

extension ViewController: ARSCNViewDelegate {
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard anchor is ARPlaneAnchor else { return }
    let sphereNode = getSphereNode(
      withPosition: node.simdWorldPosition, height: 1)
    addLightNodeTo(sphereNode)
    node.addChildNode(sphereNode)
    detectedHorizontalPlane = true
    updateLightNodesLightEstimation()
  }
}

extension float4x4 {
  var translation: SIMD3<Float> {
    let translation = columns.3
    return SIMD3(translation.x, translation.y, translation.z)
  }
}

