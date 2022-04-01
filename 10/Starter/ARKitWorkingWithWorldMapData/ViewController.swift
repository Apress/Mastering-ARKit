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
  
  @IBOutlet weak var sceneView: ARSCNView!
  @IBOutlet weak var label: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.delegate = self
    configureLighting()
    addTapGestureToSceneView()
  }
  
  func addTapGestureToSceneView() {
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapGesture(_:)))
    sceneView.addGestureRecognizer(tapGestureRecognizer)
  }
  
  @objc func didReceiveTapGesture(_ sender: UITapGestureRecognizer) {
    let location = sender.location(in: sceneView)
    guard let hitTestResult = sceneView.hitTest(location, types: [.featurePoint, .estimatedHorizontalPlane]).first
      else { return }
    let anchor = ARAnchor(transform: hitTestResult.worldTransform)
    sceneView.session.add(anchor: anchor)
  }
  
  func generateSphereNode() -> SCNNode {
    let sphere = SCNSphere(radius: 0.05)
    let sphereNode = SCNNode()
    sphereNode.position.y += Float(sphere.radius)
    sphereNode.geometry = sphere
    return sphereNode
  }
  
  func configureLighting() {
    sceneView.autoenablesDefaultLighting = true
    sceneView.automaticallyUpdatesLighting = true
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    resetTrackingConfiguration()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }
  
  @IBAction func resetBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
    resetTrackingConfiguration()
  }
  
  @IBAction func saveBarButtonItemDidTouch(_ sender: UIBarButtonItem) {
    
  }
  
  @IBAction func loadBarButtonItemDidTouch(
    _ sender: UIBarButtonItem) {
    
  }
  
  @IBAction func visualizeButtonDidTouchUpInside(_ sender: UIButton) {
    
  }
  
  func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = [.horizontal]
    
    let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
    
    sceneView.debugOptions = [.showFeaturePoints]
    sceneView.session.run(configuration, options: options)
  }
  
  func setLabel(text: String) {
    label.text = text
  }
}


extension ViewController: ARSCNViewDelegate {
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard !(anchor is ARPlaneAnchor) else { return }
    let sphereNode = generateSphereNode()
    DispatchQueue.main.async {
      node.addChildNode(sphereNode)
    }
  }
  
}

extension float4x4 {
  var translation: SIMD3<Float> {
    let translation = self.columns.3
    return SIMD3<Float>(translation.x, translation.y, translation.z)
  }
}

extension UIColor {
  open class var transparentWhite: UIColor {
    return UIColor.white.withAlphaComponent(0.70)
  }
}
