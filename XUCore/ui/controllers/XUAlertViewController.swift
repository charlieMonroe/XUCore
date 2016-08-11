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
		self.viewController.dismissViewControllerAnimated(true, completion: nil)
	}

	/// Presents the alert from controller. Presentation of the alert requires
	/// a parent controller.
	public func presentFromController(controller: UIViewController) {
		_internalController.alert = self
		controller.presentViewController(_internalController, animated: true, completion: nil)
	}

}

/// Private class that automatically positions the content in self.
private final class _XUAlertView: UIControl {

	/// Weak alert reference.
	weak var alert: XUAlert!

	@objc private func _dismiss() {
		self.alert.dismiss()
	}
	
	init(alert: XUAlert) {
		self.alert = alert

		super.init(frame: UIScreen.mainScreen().bounds)

		self.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
		self.addSubview(alert.viewController.view)
		
		self.addTarget(self, action: #selector(_dismiss), forControlEvents: .TouchUpInside)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private override func layoutSubviews() {
		super.layoutSubviews()

		let view = alert.viewController.view
		view.bounds.size = alert.viewController.preferredContentSize
		view.center = self.bounds.center

		view.layer.cornerRadius = 3.0
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

		self.modalPresentationStyle = .Custom
		self.transitioningDelegate = self
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)

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
		guard let source = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) else {
			fatalError("Transition context is missing source.")
		}
		
		UIView.animateWithDuration(0.5, animations: {
			source.view.alpha = 0.0
		}, completion: { (finished: Bool) in
			source.view.removeFromSuperview()
			transitionContext.completeTransition(finished)
		})
	}

	private func _animatePresentation(transitionContext: UIViewControllerContextTransitioning) {
		guard let destination = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
				  container = transitionContext.containerView() else {
			fatalError("Transition context is missing destination or containerView.")
		}

		let destinationView = destination.view

		container.addSubview(destinationView)
		destinationView.alpha = 0.0
		
		UIView.animateWithDuration(0.5, animations: {
			destinationView.alpha = 1.0
		}, completion: { (finished: Bool) in
			transitionContext.completeTransition(finished)
		})
	}

	@objc private func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
		guard let destination = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
			fatalError("No destination controller!")
		}

		if destination.isBeingPresented() {
			self._animatePresentation(transitionContext)
		} else {
			self._animateDismissal(transitionContext)
		}
	}

	@objc private func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
		return 5.0
	}

}
