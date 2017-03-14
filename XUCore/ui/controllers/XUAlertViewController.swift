//
//  XUAlertViewController.swift
//  XUCore
//
//  Created by Charlie Monroe on 8/4/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import UIKit

/// This is a wrapper that will present a controller it gets inited with in a very
/// similar way as UIAlertController displays the .alert style - it dims the background
/// and presents the controller in the middle of the screen, even on an iPhone.
///
/// The size is determined by the controller's preferredContentSize property -
/// setting it will determine the actual size of the view.
///
/// To dismiss the alert from the code, simply use `self.dismissViewControllerAnimated(_:,completion:)`
/// assuming `self` is the `viewController` passed into the alert's init.
///
/// @note - the alert maintains a reference to self while the controller is presented
/// so you do not need to keep the reference yourself.
public final class XUAlert {

	/// The internal controller that actually displays the content.
	private lazy var _internalController: _XUAlertViewController = _XUAlertViewController(alert: self)

	/// When set to true, touching the dimmed background will dismiss the alert.
	public var canBeDismissedByTouchingOutsideOfContentView: Bool = false
	
	/// Optional completion handler. Called when the controller is being dismissed.
	public var completionHandler: (() -> Void)?
	
	/// View controller this instance was initialized with.
	public let viewController: UIViewController

	/// Designated initializer.
	public init(viewController: UIViewController) {
		self.viewController = viewController
	}

	/// You can optionally dismiss the alert using this method, but a preferred
	/// way is that you do not keep a reference to the XUAlert instance and instead
	/// call `self.dismissViewControllerAnimated(_:,completion:)` directly on
	/// your controller.
	public func dismiss() {
		self.viewController.dismiss(animated: true, completion: nil)
	}

	/// Presents the alert from controller. Presentation of the alert requires
	/// a parent controller.
	public func present(from controller: UIViewController) {
		_internalController.alert = self
		controller.present(_internalController, animated: true, completion: nil)
	}

}

/// Private class that automatically positions the content in self.
private final class _XUAlertView: UIControl {

	/// Weak alert reference.
	weak var alert: XUAlert!

	@objc private func _dismiss() {
		if self.alert.canBeDismissedByTouchingOutsideOfContentView {
			self.alert.dismiss()
		}
	}
	
	init(alert: XUAlert) {
		self.alert = alert

		super.init(frame: UIScreen.main.bounds)

		self.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
		self.addSubview(alert.viewController.view)
		
		self.addTarget(self, action: #selector(_dismiss), for: .touchUpInside)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	fileprivate override func layoutSubviews() {
		super.layoutSubviews()
		
		let view = alert.viewController.view!
		view.bounds.size = alert.viewController.preferredContentSize
		view.center = self.bounds.center
		
		let layer = view.layer
		layer.cornerRadius = 3.0
		
		layer.shadowOpacity = 0.5
		layer.shadowColor = UIColor.black.cgColor
		layer.shadowRadius = 10.0
		layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
		layer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: 3.0).cgPath
	}

}

/// Private controller that is actually displayed as the alert. It adds the alert's
/// controller as a child controller and adds its content to _XUAlertView.
private final class _XUAlertViewController: UIViewController {

	/// This needs to be strong so that the alert reference is kept alive while
	/// the controller is being presented. This does indeed create a reference
	/// cycle, but we prevent it from leaking by setting the alert property to
	/// nil in viewDidDisapear, which eventually leads to deallocation of both
	/// this controller and the XUAlert isntance.
	var alert: XUAlert!

	init(alert: XUAlert) {
		self.alert = alert

		super.init(nibName: nil, bundle: nil)

		self.view = _XUAlertView(alert: alert)
		self.addChildViewController(self.alert.viewController)

		self.providesPresentationContextTransitionStyle = true
		self.definesPresentationContext = true

		self.modalPresentationStyle = .custom
		self.transitioningDelegate = self
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	
	fileprivate override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		self.alert.completionHandler?()
		self.alert = nil
	}

}

extension _XUAlertViewController: UIViewControllerTransitioningDelegate {

	@objc private func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return _XUAlertModalTransitionAnimator()
	}

	@objc private func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return _XUAlertModalTransitionAnimator()
	}

}

private final class _XUAlertModalTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

	private func _animateDismissal(transitionContext: UIViewControllerContextTransitioning) {
		guard let source = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {
			fatalError("Transition context is missing source.")
		}
		
		UIView.animate(withDuration: 0.5, animations: {
			source.view.alpha = 0.0
		}, completion: { (finished: Bool) in
			source.view.removeFromSuperview()
			transitionContext.completeTransition(finished)
		})
	}

	private func _animatePresentation(transitionContext: UIViewControllerContextTransitioning) {
		guard let destination = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
					let destinationView = destination.view else {
			fatalError("Transition context is missing destination or destinationView.")
		}
		
		let container = transitionContext.containerView

		container.addSubview(destinationView)
		destinationView.alpha = 0.0
		
		UIView.animate(withDuration: 0.5, animations: {
			destinationView.alpha = 1.0
		}, completion: { (finished: Bool) in
			transitionContext.completeTransition(finished)
		})
	}

	@objc fileprivate func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard let destination = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
			fatalError("No destination controller!")
		}

		if destination.isBeingPresented {
			self._animatePresentation(transitionContext: transitionContext)
		} else {
			self._animateDismissal(transitionContext: transitionContext)
		}
	}

	@objc fileprivate func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 5.0
	}

}
