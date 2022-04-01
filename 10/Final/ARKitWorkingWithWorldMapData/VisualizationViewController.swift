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

final class VisualizationViewController: UIViewController {
  // MARK: - Properties
  private let worldMap: ARWorldMap
  private let sceneView = SCNView()
  private let scene = SCNScene()
  
  private let cameraNode: SCNNode = {
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(
      x: 0, y: 0, z: 10)
    return cameraNode
  }()
  
  private let omniLightNode: SCNNode = {
    let lightNode = SCNNode()
    lightNode.light = SCNLight()
    lightNode.light?.type = .omni
    lightNode.position = SCNVector3(
      x: 0, y: 10, z: 10)
    return lightNode
  }()
  
  private let sphereNode: SCNNode = {
    let sphere = SCNSphere(radius: 0.01)
    let material = SCNMaterial()
    material.metalness.contents = 0
    material.roughness.contents = 0
    material.lightingModel = .blinn
    sphere.firstMaterial?.diffuse.contents =
      UIColor.systemYellow
    let sphereNode = SCNNode(geometry: sphere)
    return sphereNode
  }()
  
  // MARK: - Initializers
  init(worldMap: ARWorldMap) {
    self.worldMap = worldMap
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    let leftBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .cancel,
      target: self,
      action: #selector(leftbarButtonItemDidTap(_:)))
    navigationItem.leftBarButtonItem = leftBarButtonItem
    setupSceneView()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    visualizeWorldMap()
  }
  
  // MARK: - Action
  @objc private func leftbarButtonItemDidTap(_ sender: UIBarButtonItem) {
    DispatchQueue.main.async {
      self.dismiss(
        animated: true, completion: nil)
    }
  }
  
  // MARK: - Business Logic
  private func setupSceneView() {
    sceneView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(sceneView)
    NSLayoutConstraint.activate(
      [sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
       sceneView.rightAnchor.constraint(equalTo: view.rightAnchor),
       sceneView.topAnchor.constraint(equalTo: view.topAnchor),
       sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor)]
    )
    scene.rootNode.addChildNode(omniLightNode)
    scene.rootNode.addChildNode(cameraNode)
    sceneView.scene = scene
    sceneView.autoenablesDefaultLighting = true
    sceneView.allowsCameraControl = true
    sceneView.backgroundColor = .systemBackground
  }
  
  private func visualizeWorldMap() {
    for point in worldMap.rawFeaturePoints.points {
      sphereNode.position = SCNVector3(
        point.x, point.y, point.z)
      sceneView.scene?.rootNode.addChildNode(
        sphereNode.clone())
    }
  }
}
