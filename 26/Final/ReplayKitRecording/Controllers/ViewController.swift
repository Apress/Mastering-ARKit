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
import RealityKit
import ReplayKit

final class ViewController: UIViewController {
  // MARK: - IBOutlets
  @IBOutlet var arView: ARView!
  @IBOutlet weak var recordButton: UIButton!

  // MARK: - Stored Properties
  private let worldTrackingConfiguration = ARWorldTrackingConfiguration()
  private let screenRecorder = RPScreenRecorder.shared()

  // MARK: - View Life Cycle
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    resetTrackingConfiguration()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    arView.session.pause()
  }

  // MARK: - Tracking
  private func resetTrackingConfiguration() {
    arView.debugOptions = [.showFeaturePoints]
    arView.session.run(worldTrackingConfiguration)
  }

  // MARK: - Screen Recording
  private func startScreenRecording() {
    guard screenRecorder.isAvailable else { return }
    recordButton.setTitle("Stop", for: .normal)
    screenRecorder.startRecording { (error) in
      if let error = error {
        print("Error:", error.localizedDescription)
        return
      }
    }
  }

  private func stopScreenRecording() {
    recordButton.setTitle("Record", for: .normal)
    screenRecorder.stopRecording { [unowned self] (previewController, error) in
      guard let previewController = previewController else { return }
      previewController.modalPresentationStyle = .fullScreen
      previewController.previewControllerDelegate = self
      self.present(previewController, animated: true)
    }
  }

  // MARK: - IBAction
  @IBAction func recordButtonDidTap(_ sender: UIButton) {
    if screenRecorder.isRecording {
      stopScreenRecording()
      return
    }
    startScreenRecording()
  }
}

// MARK: - RPPreviewViewControllerDelegate
extension ViewController: RPPreviewViewControllerDelegate {
  func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
    previewController.dismiss(animated: true)
  }
}
