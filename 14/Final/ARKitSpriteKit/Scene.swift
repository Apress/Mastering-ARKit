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

import SpriteKit
import ARKit

protocol SceneGestureDelegate: AnyObject {
  func didTouchObjectNode()
}

// TODO: Subclass it as ARSKView
final class Scene: SKScene {
  
  private var initialTimeInterval: TimeInterval = 0
  
  private let sequenceAction: SKAction = {
    .sequence([.playSoundFileNamed("Horse.mp3", waitForCompletion: false),
               .fadeOut(withDuration: 0.3),
               .removeFromParent()])
  }()
  
  var isGameOver = false
  
  weak var gestureDelegate: SceneGestureDelegate?
  
  // TODO: Add anchor on a scheduled timer
  override func update(_ currentTime: TimeInterval) {
    guard !isGameOver,
      currentTime > initialTimeInterval else { return }
    initialTimeInterval = currentTime + TimeInterval(Float.random(in: 1...2))
    addRandomPositionAnchor()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    // TODO: Configure touch action
    guard let sceneView = view as? ARSKView,
      let currentFrame = sceneView.session.currentFrame,
      let touch = touches.first else { return }
    let touchLocation = touch.location(in: self)
    guard let node = nodes(at: touchLocation).first else {
      return addAnchorToSceneView(sceneView, in: currentFrame)
    }
    gestureDelegate?.didTouchObjectNode()
    node.run(sequenceAction)
  }
  
  // TODO: Add method
  private func addAnchorToSceneView(_ sceneView: ARSKView, in frame: ARFrame) {
    var translation = matrix_identity_float4x4
    translation.columns.3.z = -0.2
    let transform = simd_mul(frame.camera.transform,
                             translation)
    
    let anchor = ARAnchor(transform: transform)
    sceneView.session.add(anchor: anchor)
  }
  
  // TODO: Add an anchor randomly around you
  private func addRandomPositionAnchor() {
    guard let sceneView = self.view as? ARSKView else { return }
    
    // Make rotation between 0 and 360 degrees for the x-axis
    let xAngle: Float = .fullCircle * .random(in: 0...1)
    let xRotation = simd_float4x4(SCNMatrix4MakeRotation(xAngle, 1, 0, 0))
    // Make rotation between 0 and 360 degrees for the y-axis
    let yAngle: Float = .fullCircle * .random(in: 0...1)
    let yRotation = simd_float4x4(SCNMatrix4MakeRotation(yAngle, 0, 1, 0))
    
    // Combine the x and y rotations into a single matrix
    let rotation = simd_mul(xRotation, yRotation)
    
    // Make a translation matrix in the z axis to be between 1 and 2 meters
    var translation = matrix_identity_float4x4
    translation.columns.3.z = -1 - .random(in: 0...1)
    
    // Combine the rotation matrix with the translation matrix to create the anchor's final transformation matrix.
    let transform = simd_mul(rotation, translation)
    
    // Initialize an anchor using the final transformation matrix.
    let anchor = ARAnchor(transform: transform)
    
    // Add the anchor onto the session.
    sceneView.session.add(anchor: anchor)
  }
  
}

// TODO: Add extension
fileprivate extension Float {
  static var fullCircle: Float {
    return .pi * 2
  }
}
