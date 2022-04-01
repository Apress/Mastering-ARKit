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
  private var panPosition: simd_float4x4?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addBox()
    addTapGestureToSceneView()
    addPanGestureToSceneView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let configuration = ARWorldTrackingConfiguration()
    sceneView.session.run(configuration)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sceneView.session.pause()
  }
  
  func addBox(x: Float = 0, y: Float = 0, z: Float = -0.2) {
    let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
    
    let boxNode = SCNNode()
    boxNode.geometry = box
    boxNode.position = SCNVector3(x, y, z)
    
    sceneView.scene.rootNode.addChildNode(boxNode)
  }
  
  func addTapGestureToSceneView() {
    let tapGestureRecognizer = UITapGestureRecognizer(
      target: self, action: #selector(ViewController.didTap(withGestureRecognizer:)))
    sceneView.addGestureRecognizer(tapGestureRecognizer)
  }
  
  func addPanGestureToSceneView() {
    let panGestureRecognizer = UIPanGestureRecognizer(
      target: self, action: #selector(didPan(withGestureRecognizer:)))
    sceneView.addGestureRecognizer(panGestureRecognizer)
  }
  
  @objc func didTap(withGestureRecognizer recognizer: UITapGestureRecognizer) {
    let tapLocation = recognizer.location(in: sceneView)
    let hitTestResults = sceneView.hitTest(tapLocation)
    
    guard let node = hitTestResults.first?.node else {
      let hitTestResultsWithFeaturePoints = sceneView.hitTest(tapLocation, types: .featurePoint)
      if let hitTestResultWithFeaturePoints = hitTestResultsWithFeaturePoints.first {
        let translation = hitTestResultWithFeaturePoints.worldTransform.translation
        addBox(x: translation.x, y: translation.y, z: translation.z)
      }
      return
    }
    
    node.removeFromParentNode()
  }
  
  @objc func didPan(withGestureRecognizer recognizer: UIPanGestureRecognizer) {
    switch recognizer.state {
    case .began:
      print("Pan Began")
    case .changed:
      print("Pan Changed")
      let tapLocation = recognizer.location(in: sceneView)
      let hitTestResults = sceneView.hitTest(tapLocation)
      guard let node = hitTestResults.first?.node,
        let hitTestResultWithFeaturePoints = sceneView.hitTest(
          tapLocation, types: .featurePoint).first else { return }
      let worldTransform = SCNMatrix4(
        hitTestResultWithFeaturePoints.worldTransform)
      node.setWorldTransform(worldTransform)
    case .ended:
      print("Pan Ended")
    default:
      break
    }
  }
}

extension float4x4 {
  var translation: SIMD3<Float> {
    let translation = self.columns.3
    return SIMD3<Float>(translation.x, translation.y, translation.z)
  }
}

