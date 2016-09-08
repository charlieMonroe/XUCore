//
//  XUProgressWindowController.swift
//  XUCore
//
//  Created by Charlie Monroe on 12/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

@objc public protocol XUProgressableOperationDelegate {
	
	/// This method must be called when the operation is complete. It forces
	/// the window to close.
	func progressableOperationDidFinish(_ operation: XUProgressableOperation)

	/// This method must be called when the operation progress changes. It forces
	/// the window to update.
	func progressableOperationDidUpdateProgress(_ operation: XUProgressableOperation)

	
}

/// Your operation should conform to this protocol.
@objc public protocol XUProgressableOperation {
	
	/// Name of the action. E.g. "Converting XYZ..."
	var currentActionName: String { get }
	
	/// The current step.
	var currentStep: Int { get }
	
	/// Delegate.
	weak var delegate: XUProgressableOperationDelegate? { get set }
	
	/// Return the total number of steps.
	var numberOfSteps: Int { get }
	
	
	/// Called when the user cancels the action. After actually cancelling the
	/// operation, you must call the delegate's progressableOperationDidFinish(_),
	/// which actually dismisses the dialog.
	func cancel()
	
}

/// This is a window controller for a window with a progress bar and a Cancel 
/// button. It can be easily re-used.
open class XUOperationProgressWindowController: NSWindowController, XUProgressableOperationDelegate {
	
	@IBOutlet open fileprivate(set) weak var currentActionNameLabel: NSTextField!
	@IBOutlet open fileprivate(set) weak var currentProgressLabel: NSTextField!
	@IBOutlet open fileprivate(set) weak var progressIndicator: NSProgressIndicator!
	
	/// The operation.
	open fileprivate(set) var operation: XUProgressableOperation!
	
	/// By default true. If true, shows the textual progress such as 12/100.
	open var showsTextualProgress: Bool = true {
		didSet {
			self.currentProgressLabel?.isHidden = !self.showsTextualProgress
		}
	}
	
	@IBAction open func cancel(_ sender: AnyObject?) {
		self.operation.cancel()
	}
	
	
	open class func operationProgressWindowControllerWithOperation(_ operation: XUProgressableOperation) -> XUOperationProgressWindowController {
		let controller = XUOperationProgressWindowController(windowNibName: "XUOperationProgressWindowController")
		controller.operation = operation
		operation.delegate = controller
		return controller
	}
	
	
	fileprivate func _update() {
		self.currentActionNameLabel.stringValue = self.operation.currentActionName
		self.progressIndicator.minValue = 0.0
		self.progressIndicator.maxValue = Double(self.operation.numberOfSteps)
		self.progressIndicator.doubleValue = Double(self.operation.currentStep)
		
		self.currentProgressLabel.stringValue = "\(self.operation.currentStep)/\(self.operation.numberOfSteps)"
	}
	
	open func progressableOperationDidFinish(_ operation: XUProgressableOperation) {
		XU_PERFORM_BLOCK_ON_MAIN_THREAD { () -> Void in
			self.window?.orderOut(nil)
		}
	}
	
	open func progressableOperationDidUpdateProgress(_ operation: XUProgressableOperation) {
		XU_PERFORM_BLOCK_ON_MAIN_THREAD {
			self._update()
		}
	}
	
    open override func windowDidLoad() {
        super.windowDidLoad()

		self._update()
    }
    
}
