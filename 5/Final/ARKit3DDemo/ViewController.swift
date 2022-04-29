/// Copyright (c) 2022 Jayven Nhan
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureLighting()
//    addPaperPlane()
//    addCar()
    addUFO()
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
  
  func addPaperPlane(x: Float = 0, y: Float = 0, z: Float = -0.5) {
    guard let paperPlaneScene = SCNScene(named: "paperPlane.scn"), let paperPlaneNode = paperPlaneScene.rootNode.childNode(withName: "paperPlane", recursively: true) else { return }
    paperPlaneNode.position = SCNVector3(x, y, z)
    sceneView.scene.rootNode.addChildNode(paperPlaneNode)
  }
  
  func configureLighting() {
    sceneView.autoenablesDefaultLighting = true
    sceneView.automaticallyUpdatesLighting = true
  }
  
  func addCar(x: Float = 0, y: Float = 0, z: Float = -0.5) {
    guard let carScene = SCNScene(named: "car.dae") else { return }
    let carNode = SCNNode()
    let carSceneChildNodes = carScene.rootNode.childNodes
    for childNode in carSceneChildNodes {
      carNode.addChildNode(childNode)
    }
    carNode.position = SCNVector3(x, y, z)
    carNode.scale = SCNVector3(0.5, 0.5, 0.5)
    sceneView.scene.rootNode.addChildNode(carNode)
  }
  
  func addUFO(x: Float = 0, y: Float = -0.5, z: Float = -1) {
    guard let ufoURL = Bundle.main.url(
      forResource: "ufo", withExtension: "usdz"),
      let ufoNode = SCNReferenceNode(url: ufoURL) else { return }
    ufoNode.position = SCNVector3(x, y, z)
    ufoNode.load()
    sceneView.scene.rootNode.addChildNode(ufoNode)
  }
    
}
