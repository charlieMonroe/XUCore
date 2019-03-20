//
//  XUProgressWindowController.swift
//  XUCore
//
//  Created by Charlie Monroe on 12/10/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Cocoa

public protocol XUProgressableOperationDelegate: AnyObject {
	
	/// This method must be called when the operation is complete. It forces
	/// the window to close.
	func progressableOperationDidFinish(_ operation: XUProgressableOperation)

	/// This method must be called when the operation progress changes. It forces
	/// the window to update.
	func progressableOperationDidUpdateProgress(_ operation: XUProgressableOperation)

	
}

/// Your operation should conform to this protocol.
public protocol XUProgressableOperation: AnyObject {
	
	/// Name of the action. E.g. "Converting XYZ..."
	var currentActionName: String { get }
	
	/// The current step.
	var currentStep: Int { get }
	
	/// Delegate. You can call it from any thread.
	var delegate: XUProgressableOperationDelegate? { get set }
	
	/// Return the total number of steps.
	var numberOfSteps: Int { get }
	
	
	/// Called when the user cancels the action. After actually cancelling the
	/// operation, you must call the delegate's progressableOperationDidFinish(_),
	/// which actually dismisses the dialog.
	func cancel()
	
}

/// This is a window controller for a window with a progress bar and a Cancel 
/// button. It can be easily re-used.
public final class XUOperationProgressWindowController: NSWindowController, XUProgressableOperationDelegate {
	
	@IBOutlet public private(set) weak var currentActionNameLabel: NSTextField!
	@IBOutlet public private(set) weak var currentProgressLabel: NSTextField!
	@IBOutlet public private(set) weak var progressIndicator: NSProgressIndicator!
	
	/// The operation.
	public private(set) var operation: XUProgressableOperation!
	
	/// By default true. If true, shows the textual progress such as 12/100.
	public var showsTextualProgress: Bool = true {
		didSet {
			self.currentProgressLabel?.isHidden = !self.showsTextualProgress
		}
	}
	
	@IBAction public func cancel(_ sender: AnyObject?) {
		self.operation.cancel()
	}
	
	
	public class func operationProgressWindowController(with operation: XUProgressableOperation) -> XUOperationProgressWindowController {
		let controller = XUOperationProgressWindowController(windowNibName: "XUOperationProgressWindowController")
		controller.operation = operation
		operation.delegate = controller
		return controller
	}
	
	
	private func _update() {
		if !self.isWindowLoaded {
			self.loadWindow()
		}
		
		self.currentActionNameLabel.stringValue = self.operation.currentActionName
		self.progressIndicator.minValue = 0.0
		self.progressIndicator.maxValue = Double(self.operation.numberOfSteps)
		self.progressIndicator.doubleValue = Double(self.operation.currentStep)
		
		self.currentProgressLabel.stringValue = "\(self.operation.currentStep)/\(self.operation.numberOfSteps)"
	}
	
	public func progressableOperationDidFinish(_ operation: XUProgressableOperation) {
		DispatchQueue.main.syncOrNow {
			if self.window!.isSheet {
				self.window!.sheetParent?.endSheet(self.window!)
			}
			self.window!.close()
		}
	}
	
	public func progressableOperationDidUpdateProgress(_ operation: XUProgressableOperation) {
		DispatchQueue.main.syncOrNow {
			self._update()
		}
	}
	
    public override func windowDidLoad() {
        super.windowDidLoad()

		self._update()
    }
    
}
