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
  
  let fadeDuration: TimeInterval = 0.3
  let rotateDuration: TimeInterval = 3
  let waitDuration: TimeInterval = 0.5
  
  lazy var fadeAndSpinAction: SCNAction = {
    return .sequence([
      .fadeIn(duration: fadeDuration),
      .rotateBy(x: 0, y: 0, z: CGFloat.pi * 360 / 180, duration: rotateDuration),
      .wait(duration: waitDuration),
      .fadeOut(duration: fadeDuration)
    ])
  }()
  
  lazy var fadeAction: SCNAction = {
    return .sequence([
      .fadeOpacity(by: 0.8, duration: fadeDuration),
      .wait(duration: waitDuration),
      .fadeOut(duration: fadeDuration)
    ])
  }()
  
  lazy var treeNode: SCNNode = {
    guard let scene = SCNScene(named: "tree.scn"),
      let node = scene.rootNode.childNode(withName: "tree", recursively: false) else { return SCNNode() }
    let scaleFactor = 0.005
    node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
    node.eulerAngles.x = -.pi / 2
    return node
  }()
  
  lazy var bookNode: SCNNode = {
    guard let scene = SCNScene(named: "book.scn"),
      let node = scene.rootNode.childNode(withName: "book", recursively: false) else { return SCNNode() }
    let scaleFactor  = 0.1
    node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
    return node
  }()
  
  lazy var mountainNode: SCNNode = {
    guard let scene = SCNScene(named: "mountain.scn"),
      let node = scene.rootNode.childNode(withName: "mountain", recursively: false) else { return SCNNode() }
    let scaleFactor  = 0.25
    node.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
    node.eulerAngles.x += -.pi / 2
    return node
  }()
  
  var catReferenceImages: Set<ARReferenceImage> = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneView.delegate = self
    configureLighting()
    
    guard let catImageUrl = URL(
      string: "https://bit.ly/2XB83sl")
      else { return }
    downloadImageWithURL(catImageUrl)
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
  
  @IBAction func resetButtonDidTouch(_ sender: UIBarButtonItem) {
    resetTrackingConfiguration()
  }
  
  func resetTrackingConfiguration() {
    guard let referenceImages = ARReferenceImage
      .referenceImages(inGroupNamed: "AR Resources",
                       bundle: nil)
      else { return }
    let configuration = ARWorldTrackingConfiguration()
    let detectionImages = referenceImages.union(
      catReferenceImages)
    configuration.detectionImages = detectionImages
    print("DETECTION IMAGES:", detectionImages)
    let options: ARSession.RunOptions =
      [.resetTracking, .removeExistingAnchors]
    sceneView.session.run(configuration, options: options)
    DispatchQueue.main.async {
      self.label.text = "Move camera around to detect images"
    }
  }
  
  func downloadImageWithURL(_ url: URL) {
    URLSession.shared.dataTask(with: url) {
      (data, response, error) in
      if let error = error {
        print("Error:", error.localizedDescription)
        return
      }
      guard let data = data,
        let image = UIImage(data: data)
        else { return }
      self.makeReferenceImageFromImage(image)
    }.resume()
  }
  
  func makeReferenceImageFromImage(_ image: UIImage) {
    guard let cgImage = image.cgImage else { return }
    let referenceImage = ARReferenceImage(
      cgImage, orientation: .up,
      physicalWidth: CGFloat(
        cgImage.width / 1000))
    referenceImage.name = "Cat"
    catReferenceImages.insert(referenceImage)
    debugPrint("Did insert cat reference image.")
    resetTrackingConfiguration()
  }
}

extension ViewController: ARSCNViewDelegate {
  
  func renderer(_ renderer: SCNSceneRenderer,
                didAdd node: SCNNode,
                for anchor: ARAnchor) {
    print("NEW ANCHOR")
    DispatchQueue.main.async {
      guard let imageAnchor = anchor as? ARImageAnchor,
        let imageName = imageAnchor.referenceImage.name else { return }
      let overlayNode = self.getNode(
        withImageName: imageName)
      overlayNode.opacity = 0
      overlayNode.position.y = 0.2
      overlayNode.runAction(self.fadeAndSpinAction)
      node.addChildNode(overlayNode)
      
      self.label.text = "Image detected: \"\(imageName)\""
    }
  }
  
  func getPlaneNode(withReferenceImage image: ARReferenceImage) -> SCNNode {
    let plane = SCNPlane(width: image.physicalSize.width,
                         height: image.physicalSize.height)
    let node = SCNNode(geometry: plane)
    return node
  }
  
  func getNode(withImageName name: String) -> SCNNode {
    var node = SCNNode()
    switch name {
    case "Book":
      node = bookNode
    case "Snow Mountain":
      node = mountainNode
    case "Trees In the Dark":
      node = treeNode
    default:
      break
    }
    return node
  }
  
}
