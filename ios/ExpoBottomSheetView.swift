import ExpoModulesCore
import React.RCTScrollView

class ExpoBottomSheetView: ExpoView, RCTInvalidating, ExpoBottomSheetViewControllerDelegate {
  // MARK: - React properties

  // Events
  @objc var onDismiss: RCTDirectEventBlock?
  @objc var onPresent: RCTDirectEventBlock?
  @objc var onSizeChange: RCTDirectEventBlock?

  // MARK: - Private properties

  private var isPresented = false
  private var activeIndex: Int?
  private var touchHandler: RCTTouchHandler
  private var bottomSheetController: ExpoBottomSheetViewController

  // MARK: - Content properties

  private var containerView: UIView?

  private var contentView: UIView?
  private var footerView: UIView?

  // Reference the bottom constraint to adjust during keyboard event
  private var footerViewBottomConstraint: NSLayoutConstraint?

  // Reference height constraint during content updates
  private var footerViewHeightConstraint: NSLayoutConstraint?

  private var rctScrollView: RCTScrollView?

  // MARK: - Setup
  
  required init(appContext: AppContext? = nil) {
    bottomSheetController = ExpoBottomSheetViewController()
    touchHandler = RCTTouchHandler(bridge: appContext?.reactBridge)

    super.init(appContext: appContext)
    
    bottomSheetController.delegate = self
  }

  override func insertReactSubview(_ subview: UIView!, at index: Int) {
    super.insertReactSubview(subview, at: index)

    guard containerView == nil else {
      log.error("Sheet can only have one content view.")
      return
    }

    bottomSheetController.view.addSubview(subview)

    containerView = subview
    touchHandler.attach(to: containerView)
  }

  override func removeReactSubview(_ subview: UIView!) {
    guard subview == containerView else {
      log.error("Cannot remove view other than sheet view")
      return
    }

    super.removeReactSubview(subview)

    touchHandler.detach(from: subview)

    containerView = nil
    contentView = nil
    footerView = nil
  }

  override func didUpdateReactSubviews() {
    // Do nothing, as subviews are managed by `insertReactSubview`
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if let containerView, contentView == nil {
      contentView = containerView.subviews[0]
      footerView = containerView.subviews[1]

      containerView.pinTo(view: bottomSheetController.view, constraints: nil)

      // Set footer constraints
      if let footerView {
        footerView.pinTo(view: bottomSheetController.view, from: [.left, .right, .bottom], with: 0) { constraints in
          self.footerViewBottomConstraint = constraints.bottom
          self.footerViewHeightConstraint = constraints.height
        }
      }

      // Update content containers
      setupScrollable()
    }
  }

  // MARK: - ViewController delegate

  func viewControllerKeyboardWillHide() {
    guard let footerViewBottomConstraint else { return }

    footerViewBottomConstraint.constant = 0

    UIView.animate(withDuration: 0.3) {
      self.bottomSheetController.view.layoutIfNeeded()
    }
  }

  func viewControllerKeyboardWillShow(_ keyboardHeight: CGFloat) {
    guard let footerViewBottomConstraint else { return }

    footerViewBottomConstraint.constant = -keyboardHeight

    UIView.animate(withDuration: 0.3) {
      self.bottomSheetController.view.layoutIfNeeded()
    }
  }

  func viewControllerDidChangeWidth(_ width: CGFloat) {
    guard let containerView else { return }

    let size = CGSize(width: width, height: containerView.bounds.height)
    appContext?.reactBridge?.uiManager.setSize(size, for: containerView)
  }

  func viewControllerWillAppear() {
    setupScrollable()
  }

  func viewControllerDidDismiss() {
    isPresented = false
    activeIndex = nil

    onDismiss?(nil)
  }

  func viewControllerSheetDidChangeSize(_ sizeInfo: SizeInfo) {
    if sizeInfo.index != activeIndex {
      activeIndex = sizeInfo.index
      onSizeChange?(sizeInfoData(from: sizeInfo))
    }
  }

  func invalidate() {
    bottomSheetController.dismiss(animated: true)
  }

  // MARK: - Prop setters

  @objc
  func setDismissible(_ dismissible: Bool) {
    bottomSheetController.isModalInPresentation = !dismissible
  }

  @objc
  func setMaxHeight(_ height: NSNumber) {
    bottomSheetController.maxHeight = CGFloat(height.floatValue)
    configurePresentedSheet()
  }

  @objc
  func setContentHeight(_ height: NSNumber) {
    // Exclude bottom safe area for consistency with a Scrollable content
    let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    let bottomInset = window?.safeAreaInsets.bottom ?? 0

    bottomSheetController.contentHeight = CGFloat(height.floatValue) - bottomInset
    configurePresentedSheet()
  }

  @objc
  func setFooterHeight(_ height: NSNumber) {
    guard let footerView, let footerViewHeightConstraint else {
      return
    }

    bottomSheetController.footerHeight = CGFloat(height.floatValue)

    if footerView.subviews.first != nil {
      containerView?.bringSubviewToFront(footerView)
      footerViewHeightConstraint.constant = bottomSheetController.footerHeight
    } else {
      containerView?.sendSubviewToBack(footerView)
      footerViewHeightConstraint.constant = 0
    }

    configurePresentedSheet()
  }

  @objc
  func setSizes(_ sizes: [Any]) {
    bottomSheetController.sizes = Array(sizes.prefix(3))
    configurePresentedSheet()
  }

  @objc
  func setBlurTint(_ tint: NSString?) {
    guard let tint else {
      bottomSheetController.blurView.effect = nil
      return
    }

    bottomSheetController.blurView.effect = UIBlurEffect(with: tint as String)
  }

  @objc
  func setCornerRadius(_ radius: NSNumber?) {
    var cornerRadius: CGFloat?
    if let radius {
      cornerRadius = CGFloat(radius.floatValue)
    }

    bottomSheetController.cornerRadius = cornerRadius
    if #available(iOS 15.0, *) {
      withPresentedSheet { sheet in
        sheet.preferredCornerRadius = bottomSheetController.cornerRadius
      }
    }
  }

  @objc
  func setGrabber(_ visible: Bool) {
    bottomSheetController.grabber = visible
    if #available(iOS 15.0, *) {
      withPresentedSheet { sheet in
        sheet.prefersGrabberVisible = visible
      }
    }
  }

  @objc
  func setDimmed(_ dimmed: Bool) {
    bottomSheetController.dimmed = dimmed

    if #available(iOS 15.0, *) {
      withPresentedSheet { sheet in
        bottomSheetController.setupDimmedBackground(for: sheet)
      }
    }
  }

  @objc
  func setDimmedIndex(_ index: NSNumber) {
    bottomSheetController.dimmedIndex = index as? Int

    if #available(iOS 15.0, *) {
      withPresentedSheet { sheet in
        bottomSheetController.setupDimmedBackground(for: sheet)
      }
    }
  }

  @objc
  func setScrollableHandle(_ tag: NSNumber?) {
    let view = appContext?.reactBridge?.uiManager.view(forReactTag: tag) as? RCTScrollView
    rctScrollView = view
  }

  // MARK: - Methods

  private func sizeInfoData(from sizeInfo: SizeInfo?) -> [String: Any] {
    guard let sizeInfo else {
      return ["index": 0, "value": 0.0]
    }

    return ["index": sizeInfo.index, "value": sizeInfo.value]
  }

  /// Use to customize some properties of the Sheet without fully reconfiguring.
  @available(iOS 15.0, *)
  func withPresentedSheet(completion: (UISheetPresentationController) -> Void) {
    guard isPresented, let sheet = bottomSheetController.sheetPresentationController else {
      return
    }

    sheet.animateChanges {
      completion(sheet)
    }
  }

  /// Fully reconfigure the sheet. Use during size prop changes.
  func configurePresentedSheet() {
    if isPresented {
      bottomSheetController.configureSheet(at: activeIndex ?? 0, nil)
    }
  }

  func setupScrollable() {
    guard let contentView, let containerView else { return }

    // Add constraints to fix weirdness and support ScrollView
    if let rctScrollView {
      contentView.pinTo(view: containerView, constraints: nil)
      rctScrollView.pinTo(view: contentView, constraints: nil)
    }
  }

  func dismiss(promise: Promise) {
    guard isPresented else {
      promise.resolve(nil)
      return
    }

    bottomSheetController.dismiss(animated: true) {
      promise.resolve(nil)
    }
  }

  func present(at index: Int, promise: Promise) {
    let rvc = reactViewController()

    guard let rvc else {
      promise.reject("TODO", "No react view controller present.")
      return
    }

    guard bottomSheetController.sizes.indices.contains(index) else {
      promise.reject("TODO", "Size at \(index) is not configured.")
      return
    }

    bottomSheetController.configureSheet(at: index) { sizeInfo in
      // Trigger onSizeChange event when size is changed while presenting
      if self.isPresented {
        self.viewControllerSheetDidChangeSize(sizeInfo)
        promise.resolve(nil)
      } else {
        // Keep track of the active index
        self.activeIndex = index

        rvc.present(self.bottomSheetController, animated: true) {
          self.isPresented = true

          let data = self.sizeInfoData(from: sizeInfo)
          self.onPresent?(data)
          promise.resolve(nil)
        }
      }
    }
  }
}
