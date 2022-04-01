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
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addTapGestureToSceneView()
    configureLighting()
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
    
    sceneView.session.run(configuration)
    
    sceneView.delegate = self
    sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
  }
  
  func configureLighting() {
    sceneView.autoenablesDefaultLighting = true
    sceneView.automaticallyUpdatesLighting = true
  }
  
  @objc func addObjectToSceneView(
    withGestureRecognizer recognizer: UITapGestureRecognizer) {
    let tapLocation = recognizer.location(in: sceneView)
    switch segmentedControl.selectedSegmentIndex {
    case 0:
      addShipToSceneView(location: tapLocation)
    case 1:
      addBoatToSceneView(location: tapLocation)
    default:
      break
    }
  }
  
  func addShipToSceneView(location: CGPoint) {
    let hitTestResults = sceneView.hitTest(
      location, types: .existingPlaneUsingExtent)
    guard let hitTestResult = hitTestResults.first
      else { return }
    let translation = hitTestResult.worldTransform.translation
    let x = translation.x
    let y = translation.y
    let z = translation.z
    
    guard let shipScene = SCNScene(named: "ship.scn"),
      let shipNode = shipScene.rootNode.childNode(
        withName: "ship", recursively: false)
      else { return }
    
    shipNode.position = SCNVector3(x,y,z)
    sceneView.scene.rootNode.addChildNode(shipNode)
  }
  
  func addBoatToSceneView(location: CGPoint) {
    guard let raycastQuery = sceneView.raycastQuery(
      from: location,
      allowing: .existingPlaneInfinite,
      alignment: .any),
      let raycastResult = sceneView.session.raycast(
        raycastQuery).first else { return }
    guard let boatURL = Bundle.main.url(
      forResource: "boat", withExtension: "usdz"),
      let boatReferenceNode = SCNReferenceNode(
        url: boatURL) else { return }
    boatReferenceNode.load()
    boatReferenceNode.simdPosition =
      raycastResult.worldTransform.translation
    sceneView.scene.rootNode.addChildNode(boatReferenceNode)
  }
  
  func addTapGestureToSceneView() {
    let tapGestureRecognizer = UITapGestureRecognizer(
      target: self,
      action: #selector(ViewController.addObjectToSceneView(
        withGestureRecognizer:)))
    sceneView.addGestureRecognizer(tapGestureRecognizer)
  }
}

extension float4x4 {
  var translation: SIMD3<Float> {
    let translation = columns.3
    return SIMD3(translation.x, translation.y, translation.z)
  }
}

extension UIColor {
  open class var transparentLightBlue: UIColor {
    return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
  }
}

extension ViewController: ARSCNViewDelegate {
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    // 1
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    // 2
    let width = CGFloat(planeAnchor.extent.x)
    let height = CGFloat(planeAnchor.extent.z)
    let plane = SCNPlane(width: width, height: height)
    
    // 3
    plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
    
    // 4
    let planeNode = SCNNode(geometry: plane)
    
    // 5
    let x = CGFloat(planeAnchor.center.x)
    let y = CGFloat(planeAnchor.center.y)
    let z = CGFloat(planeAnchor.center.z)
    planeNode.position = SCNVector3(x,y,z)
    planeNode.eulerAngles.x = -.pi / 2
    
    // 6
    node.addChildNode(planeNode)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    // 1
    guard let planeAnchor = anchor as?  ARPlaneAnchor,
      let planeNode = node.childNodes.first,
      let plane = planeNode.geometry as? SCNPlane
      else { return }
    
    // 2
    let width = CGFloat(planeAnchor.extent.x)
    let height = CGFloat(planeAnchor.extent.z)
    plane.width = width
    plane.height = height
    
    // 3
    let x = CGFloat(planeAnchor.center.x)
    let y = CGFloat(planeAnchor.center.y)
    let z = CGFloat(planeAnchor.center.z)
    planeNode.position = SCNVector3(x, y, z)
  }
}
