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

import SwiftUI
import ARKit
import RealityKit

final class CustomARView: ARView {
  // 1
  let label: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  // 2
  var didTapView: ((_ sender: UITapGestureRecognizer) -> Void)?
  // 3
  @objc required dynamic init(frame frameRect: CGRect) {
    super.init(frame: frameRect)
    commonInit()
  }
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }
  convenience init() {
    self.init(frame: .zero)
    commonInit()
  }
  private func commonInit() {
    // 1
    addSubview(label)
    NSLayoutConstraint.activate(
      [
        label.topAnchor.constraint(equalTo: topAnchor),
        label.leadingAnchor.constraint(equalTo: leadingAnchor),
        label.trailingAnchor.constraint(equalTo: trailingAnchor),
        label.bottomAnchor.constraint(equalTo: bottomAnchor)
      ]
    )
    // 2
    registerTapGesture()
  }
  // 1
  private func registerTapGesture() {
    let tapGesture = UITapGestureRecognizer(
      target: self,
      action: #selector(didRegisterTap(_:)))
    addGestureRecognizer(tapGesture)
  }
  // 2
  @objc private func didRegisterTap(_ sender: UITapGestureRecognizer) {
    guard let didTapView = didTapView else { return }
    didTapView(sender)
  }
}
