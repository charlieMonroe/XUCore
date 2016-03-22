//
//  XULineView.swift
//  XUCore
//
//  Created by Charlie Monroe on 12/23/15.
//  Copyright © 2015 Charlie Monroe Software. All rights reserved.
//

import Foundation

/// Draws a line at the top of the view.
@IBDesignable public class XULineView: UIView {

	/// By default, the line is drawn at the top of the view for horizontal
	/// and at the left of the view for vertical lines. This option allows the
	/// line to be drawn at the bottom, or right side instead.
	@IBInspectable public var alternateAlignment: Bool = false {
		didSet {
			self.setNeedsDisplay()
		}
	}

	/// Color of the line.
	@IBInspectable public var lineColor: UIColor = UIColor.clearColor() {
		didSet {
			self.setNeedsDisplay()
		}
	}

	/// Width of the line.
	@IBInspectable public var lineWidth: CGFloat = 0.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}

	public override func awakeFromNib() {
		super.awakeFromNib()

		self.opaque = false
	}

	public override func drawRect(rect: CGRect) {
		self.lineColor.set()

		let bounds = self.bounds
		if bounds.size.width > bounds.size.height {
			if self.alternateAlignment {
				UIRectFill(CGRectMake(0.0, bounds.size.height - self.lineWidth, bounds.size.width, self.lineWidth))
			} else {
				UIRectFill(CGRect(x: 0.0, y: 0.0, width: bounds.size.width, height: self.lineWidth))
			}
		} else {
			// Horizontal line
			if self.alternateAlignment {
				UIRectFill(CGRectMake(bounds.size.width - self.lineWidth, 0.0, self.lineWidth, bounds.size.height))
			} else {
				UIRectFill(CGRect(x: 0.0, y: 0.0, width: self.lineWidth, height: bounds.size.height))
			}
		}
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.opaque = false
		self.backgroundColor = nil
	}

	public required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
		
		self.opaque = false
		self.backgroundColor = nil
	}

}


