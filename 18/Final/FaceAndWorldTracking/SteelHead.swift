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

import ARKit
import RealityKit

fileprivate enum NotificationKey: String {
  case trigger = "RealityKit.NotificationTrigger"
  case action = "RealityKit.NotifyAction"
}

fileprivate extension Notification.Name {
  static let notificationTrigger = Notification.Name(NotificationKey.trigger.rawValue)
  static let notifyAction = Notification.Name(NotificationKey.action.rawValue)
}

final class SteelHead: Entity {
  // MARK: - Value Type
  class NotificationTrigger {
    private let identifier: String
    private weak var rootEntity: Entity?

    fileprivate init(identifier: String, root: Entity?) {
      self.identifier = identifier
      self.rootEntity = root
    }

    func post() {
      guard let scene = rootEntity?.scene else { return }
      let userInfo: [AnyHashable: Any] = [
        "\(NotificationKey.trigger.rawValue).Scene": scene,
        "\(NotificationKey.trigger.rawValue).Identifier": identifier
      ]
      notificationCenter.post(
        name: .notificationTrigger,
        object: self,
        userInfo: userInfo)
    }
  }

  class NotifyAction {
    private let identifier: String
    private weak var root: Entity?
    var onAction: ((Entity) -> Void)?

    fileprivate init(identifier: String, root: Entity?) {
      self.identifier = identifier
      self.root = root
      notificationCenter.addObserver(
        self,
        selector: #selector(actionDidFire(notification:)),
        name: .notifyAction,
        object: nil)
    }

    deinit {
      notificationCenter.removeObserver(self)
    }

    @objc private func actionDidFire(notification: Notification) {
      guard let onAction = onAction,
        let userInfo = notification.userInfo,
        let scene = userInfo["\(NotificationKey.action.rawValue).Scene"] as? Scene,
        root?.scene == scene,
        let identifier = userInfo["\(NotificationKey.action.rawValue).Identifier"] as? String,
        identifier == self.identifier,
        let entity = userInfo["\(NotificationKey.action.rawValue).Entity"] as? Entity else { return }
      onAction(entity)
    }
  }

  // MARK: - Properties
  private static let notificationCenter = NotificationCenter.default
  private let leftEyeEntity: Entity
  private let rightEyeEntity: Entity
  private let mouthEntity: Entity
  private let mouthEntityTransformOrigin: Transform
  private var isPlayingSound = false
  private(set) lazy var playBearSoundTrigger = NotificationTrigger(identifier: "playBearSound", root: self)
  private(set) lazy var bearSoundHasEndedAction = NotifyAction(identifier: "bearSoundHasEnded", root: self)

  // MARK: - Initializers
required init() {
  guard let steelHead = try? Entity.load(named: "SteelHead"),
    let leftEyeEntity = steelHead.findEntity(named: "leftEye"),
    let rightEyeEntity = steelHead.findEntity(named: "rightEye"),
    let mouthEntity = steelHead.findEntity(named: "mouth") else {
      fatalError()
  }
  self.leftEyeEntity = leftEyeEntity
  self.rightEyeEntity = rightEyeEntity
  self.mouthEntity = mouthEntity
  mouthEntityTransformOrigin = mouthEntity.transform
  super.init()
  addChild(steelHead)
  setupActionHandlers()
}

  // MARK: - Overheads
  private func setupActionHandlers() {
    bearSoundHasEndedAction.onAction = { [weak self] _ in
      self?.isPlayingSound = false
    }
  }

  // MARK: - Update Face Anchor
  func updateSteelHead(from faceAnchor: ARFaceAnchor) {
    let blendShapes = faceAnchor.blendShapes
    if let jawOpen = blendShapes[.jawOpen] {
      mouthEntity.transform.translation.z =
        mouthEntityTransformOrigin.translation.z +
        jawOpen.floatValue * 0.05
      if !isPlayingSound,
        jawOpen.floatValue >= 0.5 {
        isPlayingSound = true
        playBearSoundTrigger.post()
      }
    }
    if let zPosition = getFaceZPositionRelativeToFaceAnchor(faceAnchor) {
      position.z = zPosition
    }
  }
  // MARK: - Helper
  private func getFaceZPositionRelativeToFaceAnchor(_ faceAnchor: ARFaceAnchor) -> Float? {
    guard let parent = parent else { return nil }
    let cameraPosition = parent.transform.matrix.columns.3
    let faceAnchorPosition = faceAnchor.transform.columns.3
    let zPosition = cameraPosition - faceAnchorPosition
    return zPosition.z
  }
}
