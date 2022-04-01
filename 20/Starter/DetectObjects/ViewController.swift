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
import RealityKit
import ARKit

final class ViewController: UIViewController {
  // MARK: - Properties
  @IBOutlet var arView: ARView!
  @IBOutlet var label: UILabel!
  @IBOutlet var resetButton: UIButton!

  private let anchorName = "Object anchor."
  private let originBoundingBoxSize: SIMD3<Float> = SIMD3(0.13, 0.2, 0.13)
  private lazy var coachingOverlayView: ARCoachingOverlayView = {
    let coachingOverlayView = ARCoachingOverlayView()
    coachingOverlayView.session = arView.session
    coachingOverlayView.delegate = self
    coachingOverlayView.goal = .tracking
    coachingOverlayView.translatesAutoresizingMaskIntoConstraints = false
    return coachingOverlayView
  }()

  private let worldTrackingConfiguration: ARWorldTrackingConfiguration = {
    let worldTrackingConfiguration = ARWorldTrackingConfiguration()
    worldTrackingConfiguration.planeDetection = .horizontal
    return worldTrackingConfiguration
  }()

  // MARK: - Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupARView()
    setupCoachingOverlayView()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    resetTrackingConfiguration()
  }

  // MARK: - Coaching Overlay View
  private func setupCoachingOverlayView() {
    arView.addSubview(coachingOverlayView)
    NSLayoutConstraint.activate([
      coachingOverlayView.leadingAnchor.constraint(
        equalTo: arView.leadingAnchor),
      coachingOverlayView.trailingAnchor.constraint(
        equalTo: arView.trailingAnchor),
      coachingOverlayView.topAnchor.constraint(
        equalTo: arView.topAnchor),
      coachingOverlayView.bottomAnchor.constraint(
        equalTo: arView.bottomAnchor)
    ])
  }

  // MARK: - Tracking
  private func setupARView() {
    arView.session.delegate = self
  }

  // MARK: - Object Entity Factory

  // MARK: - AR Detections
  private func resetTrackingConfiguration() {
    arView.debugOptions = [.showFeaturePoints]
    arView.session.run(worldTrackingConfiguration,
                       options: [.removeExistingAnchors, .resetTracking])
  }

  private func runObjectScanningConfiguration() {
    guard let configuration = arView.session.configuration as? ARObjectScanningConfiguration else { return }
    arView.session.run(configuration, options: [.resetTracking])
  }

  // MARK: - IBActions
  @IBAction private func resetButtonDidTouchUpInside(_ sender: UIButton) {
    resetTrackingConfiguration()
  }

  @IBAction func stopButtonDidTouchUpInside(_ sender: UIButton) {
    guard let configuration = arView.session.configuration
      as? ARObjectScanningConfiguration else { return }
    configuration.planeDetection = []
    arView.session.run(configuration, options: [])
  }
}

// MARK: - ARSessionDelegate
extension ViewController: ARSessionDelegate {

}

// MARK: - ARCoachingOverlayViewDelegate
extension ViewController: ARCoachingOverlayViewDelegate {
  func coachingOverlayViewWillActivate(
    _ coachingOverlayView: ARCoachingOverlayView) {
    resetButton.isHidden = true
    label.isHidden = true
  }

  func coachingOverlayViewDidDeactivate(
    _ coachingOverlayView: ARCoachingOverlayView) {
    resetButton.isHidden = false
    label.isHidden = false
  }

  func coachingOverlayViewDidRequestSessionReset(
    _ coachingOverlayView: ARCoachingOverlayView) {
    resetTrackingConfiguration()
  }
}

extension UIColor {
  class var customOrange: UIColor {
    UIColor(named: "CustomOrange")!
  }
}
