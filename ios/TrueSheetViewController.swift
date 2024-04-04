//
//  Created by Jovanni Lo (@lodev09)
//  Copyright (c) 2024-present. All rights reserved.
//
//  This source code is licensed under the MIT license found in the
//  LICENSE file in the root directory of this source tree.
//

// MARK: - SizeInfo

struct SizeInfo {
  var index: Int
  var value: CGFloat
}

// MARK: - TrueSheetViewControllerDelegate

protocol TrueSheetViewControllerDelegate: AnyObject {
  func viewControllerDidChangeWidth(_ width: CGFloat)
  func viewControllerDidDismiss()
  func viewControllerSheetDidChangeSize(_ sizeInfo: SizeInfo)
  func viewControllerWillAppear()
}

// MARK: - TrueSheetViewController

class TrueSheetViewController: UIViewController, UISheetPresentationControllerDelegate {
  // MARK: - Properties

  weak var delegate: TrueSheetViewControllerDelegate?

  var blurView: UIVisualEffectView
  var lastViewWidth: CGFloat = 0
  var detentValues: [String: SizeInfo] = [:]

  var sizes: [Any] = ["medium", "large"]
  var maxHeight: CGFloat?

  var cornerRadius: CGFloat? {
    didSet {
      if #available(iOS 15.0, *) {
        sheet?.preferredCornerRadius = cornerRadius
      }
    }
  }

  var grabber = true {
    didSet {
      if #available(iOS 15.0, *) {
        sheet?.prefersGrabberVisible = grabber
      }
    }
  }

  @available(iOS 15.0, *)
  var sheet: UISheetPresentationController? {
    return sheetPresentationController
  }

  @available(iOS 15.0, *)
  var selectedSizeInfo: SizeInfo? {
    guard let rawValue = sheet?.selectedDetentIdentifier?.rawValue else {
      return nil
    }

    return detentValues[rawValue]
  }

  // MARK: - Setup

  init() {
    blurView = UIVisualEffectView()

    super.init(nibName: nil, bundle: nil)

    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.frame = view.bounds
    view.insertSubview(blurView, at: 0)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @available(iOS 15.0, *)
  func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheet: UISheetPresentationController) {
    if let rawValue = sheet.selectedDetentIdentifier?.rawValue,
       let sizeInfo = detentValues[rawValue] {
      delegate?.viewControllerSheetDidChangeSize(sizeInfo)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    delegate?.viewControllerWillAppear()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    delegate?.viewControllerDidDismiss()
  }

  /// This is called multiple times while sheet is being dragged.
  /// let's try to minimize size update by comparing last known width
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if lastViewWidth != view.frame.width {
      delegate?.viewControllerDidChangeWidth(view.bounds.width)
      lastViewWidth = view.frame.width
    }
  }

  func setBlurStyle(_ style: String?) {
    guard let style else {
      blurView.effect = nil
      return
    }

    blurView.effect = UIBlurEffect(with: style)
  }

  /// Prepares the view controller for sheet presentation
  /// Do nothing on IOS 14 and below... sad
  @available(iOS 15.0, *)
  func configureSheet(at index: Int = 0, with contentHeight: CGFloat, _ completion: (() -> Void)?) {
    guard let sheet else { return }

    detentValues = [:]

    var detents: [UISheetPresentationController.Detent] = []

    for (index, size) in sizes.enumerated() {
      let detent = detentFor(size, with: contentHeight, with: maxHeight) { id, value in
        self.detentValues[id] = SizeInfo(index: index, value: value)
      }

      detents.append(detent)
    }

    sheet.detents = detents
    sheet.prefersEdgeAttachedInCompactHeight = true
    sheet.prefersGrabberVisible = grabber
    sheet.preferredCornerRadius = cornerRadius

    sheet.delegate = self

    var identifier: UISheetPresentationController.Detent.Identifier = .medium

    if sheet.detents.indices.contains(index) {
      let detent = sheet.detents[index]
      if #available(iOS 16.0, *) {
        identifier = detent.identifier
      } else if detent == .large() {
        identifier = .large
      }
    }

    sheet.animateChanges {
      sheet.selectedDetentIdentifier = identifier
      completion?()
    }
  }
}
