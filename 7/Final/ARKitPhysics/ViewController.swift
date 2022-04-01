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
  
  enum CollisionBody: Int {
    case plane = 1
    case rocket = 2
  }
  
  @IBOutlet weak var sceneView: ARSCNView!
  
  var planeNodes = [SCNNode]()
  
  // TODO: Declare rocketship node name constant
  let rocketshipNodeName = "rocketship"
  var isFirstRocketLanded = true
  
  // TODO: Initialize an empty array of type SCNNode
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addTapGestureToSceneView()
    configureLighting()
    addSwipeGesturesToSceneView()
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
    sceneView.scene.physicsWorld.contactDelegate = self
    sceneView.debugOptions = [.showPhysicsShapes]
  }
  
  func configureLighting() {
    sceneView.autoenablesDefaultLighting = true
    sceneView.automaticallyUpdatesLighting = true
  }
  
  func addTapGestureToSceneView() {
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addRocketshipToSceneView(withGestureRecognizer:)))
    sceneView.addGestureRecognizer(tapGestureRecognizer)
  }
  
  // TODO: Create add swipe gestures to scene view method
  func addSwipeGesturesToSceneView() {
    let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.applyForceToRocketship(withGestureRecognizer:)))
    swipeUpGestureRecognizer.direction = .up
    sceneView.addGestureRecognizer(swipeUpGestureRecognizer)
    
    let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.launchRocketship(withGestureRecognizer:)))
    swipeDownGestureRecognizer.direction = .down
    sceneView.addGestureRecognizer(swipeDownGestureRecognizer)
  }
  
  @objc func addRocketshipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
    let tapLocation = recognizer.location(in: sceneView)
    let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
    guard let hitTestResult = hitTestResults.first else { return }
    
    let translation = hitTestResult.worldTransform.translation
    let x = translation.x
    let y = translation.y + 0.1
    let z = translation.z
    
    guard let rocketshipScene = SCNScene(named: "rocketship.scn"),
      let rocketshipNode = rocketshipScene.rootNode.childNode(withName: "rocketship", recursively: false)
      else { return }
    
    rocketshipNode.position = SCNVector3(x,y,z)
    
    // TODO: Attach physics body to rocketship node
    let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
    rocketshipNode.physicsBody = physicsBody
    rocketshipNode.name = rocketshipNodeName
    setRocketCollisionBitmask(onNode: rocketshipNode)
    
    sceneView.scene.rootNode.addChildNode(rocketshipNode)
  }
  
  // TODO: Create get rocketship node from swipe location method
  func getRocketshipNode(from swipeLocation: CGPoint) -> SCNNode? {
    let hitTestResults = sceneView.hitTest(swipeLocation)
    guard let parentNode = hitTestResults.first?.node.parent,
      parentNode.name == rocketshipNodeName
      else { return nil }
    return parentNode
  }
  
  // TODO: Create apply force to rocketship method
  @objc func applyForceToRocketship(withGestureRecognizer recognizer: UIGestureRecognizer) {
    // 1
    guard recognizer.state == .ended else { return }
    // 2
    let swipeLocation = recognizer.location(in: sceneView)
    // 3
    guard let rocketshipNode = getRocketshipNode(from: swipeLocation),
      let physicsBody = rocketshipNode.physicsBody
      else { return }
    // 4
    let direction = SCNVector3(0, 3, 0)
    physicsBody.applyForce(direction, asImpulse: true)
  }
  
  // TODO: Create launch rocketship method
  @objc func launchRocketship(withGestureRecognizer recognizer: UIGestureRecognizer) {
    // 1
    guard recognizer.state == .ended else { return }
    // 2
    let swipeLocation = recognizer.location(in: sceneView)
    guard let rocketshipNode = getRocketshipNode(from: swipeLocation),
      let physicsBody = rocketshipNode.physicsBody,
      let reactorParticleSystem = SCNParticleSystem(named: "reactor", inDirectory: nil),
      let engineNode = rocketshipNode.childNode(withName: "node2", recursively: false)
      else { return }
    // 3
    physicsBody.isAffectedByGravity = false
    physicsBody.damping = 0
    // 4
    reactorParticleSystem.colliderNodes = planeNodes
    // 5
    engineNode.addParticleSystem(reactorParticleSystem)
    // 6
    let action = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 3)
    action.timingMode = .easeInEaseOut
    rocketshipNode.runAction(action)
  }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    let width = CGFloat(planeAnchor.extent.x)
    let height = CGFloat(planeAnchor.extent.z)
    let plane = SCNPlane(width: width, height: height)
    plane.materials.first?.diffuse.contents = UIColor.transparentWhite
    
    var planeNode = SCNNode(geometry: plane)
    let x = CGFloat(planeAnchor.center.x)
    let y = CGFloat(planeAnchor.center.y)
    let z = CGFloat(planeAnchor.center.z)
    planeNode.position = SCNVector3(x,y,z)
    planeNode.eulerAngles.x = -.pi / 2
    
    // TODO: Update plane node
    update(&planeNode, withGeometry: plane, type: .static)
    setPlaneCollisionBitmask(onNode: planeNode)
    
    node.addChildNode(planeNode)
    
    // TODO: Append plane node to plane nodes array if appropriate
    planeNodes.append(planeNode)
  }
  
  // TODO: Remove plane node from plane nodes array if appropriate
  func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    guard anchor is ARPlaneAnchor,
      let planeNode = node.childNodes.first
      else { return }
    planeNodes = planeNodes.filter { $0 != planeNode }
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as?  ARPlaneAnchor,
      var planeNode = node.childNodes.first,
      let plane = planeNode.geometry as? SCNPlane
      else { return }
    
    let width = CGFloat(planeAnchor.extent.x)
    let height = CGFloat(planeAnchor.extent.z)
    plane.width = width
    plane.height = height
    
    let x = CGFloat(planeAnchor.center.x)
    let y = CGFloat(planeAnchor.center.y)
    let z = CGFloat(planeAnchor.center.z)
    
    planeNode.position = SCNVector3(x, y, z)
    update(&planeNode, withGeometry: plane, type: .static)
  }
  
  // TODO: Create update plane node method
  func update(_ node: inout SCNNode, withGeometry geometry: SCNGeometry, type: SCNPhysicsBodyType) {
    let shape = SCNPhysicsShape(geometry: geometry, options: nil)
    let physicsBody = SCNPhysicsBody(type: type, shape: shape)
    node.physicsBody = physicsBody
    setPlaneCollisionBitmask(onNode: node)
  }
}

// MARK: - SCNPhysicsContactDelegate
extension ViewController: SCNPhysicsContactDelegate {
  func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
    guard (contact.nodeA.physicsBody?.categoryBitMask == CollisionBody.plane.rawValue
      && contact.nodeB.physicsBody?.categoryBitMask == CollisionBody.rocket.rawValue)
      || (contact.nodeA.physicsBody?.categoryBitMask == CollisionBody.rocket.rawValue
        && contact.nodeB.physicsBody?.categoryBitMask == CollisionBody.plane.rawValue)
      else { return }
    guard isFirstRocketLanded else { return }
    isFirstRocketLanded = false
    for planeNode in planeNodes {
      planeNode.geometry?.firstMaterial?.diffuse.contents =
        UIColor.transparentOrange
    }
  }
    
  func setRocketCollisionBitmask(onNode node: SCNNode) {
    node.physicsBody?.categoryBitMask = CollisionBody.rocket.rawValue
    node.physicsBody?.collisionBitMask = CollisionBody.plane.rawValue
    node.physicsBody?.contactTestBitMask = CollisionBody.plane.rawValue
  }
  
  func setPlaneCollisionBitmask(onNode node: SCNNode) {
    node.physicsBody?.categoryBitMask = CollisionBody.plane.rawValue
    node.physicsBody?.collisionBitMask = CollisionBody.rocket.rawValue
    node.physicsBody?.contactTestBitMask = CollisionBody.rocket.rawValue
  }
}
