//
//  XUCertificateView.swift
//  XUCore
//
//  Created by Charlie Monroe on 11/23/16.
//  Copyright © 2016 Charlie Monroe Software. All rights reserved.
//

import Cocoa
import SecurityInterface.SFCertificatePanel
import XUCore

public protocol XUCertificateViewDelegate: AnyObject {
	
	/// This informs the delegate that the view did load a certificate. This is
	/// not called upon setting the certificateData property manually, only as
	/// a result of user action.
	func certificateView(_ certificateView: XUCertificateView, didLoadCertificate certificate: SecCertificate)
	
	/// This informs the delegate that the certificate view failed to parse the
	/// certificate data.
	func certificateView(didFailToLoadCertificate certificateView: XUCertificateView, withError error: XUCertificateView.CertificateError)
	
}

/// This view allows you to view and load a certificate from data. Currently not
/// fully functional.
public class XUCertificateView: NSView {
	
	public enum CertificateError: Error {
		
		/// Data cannot be read from the file.
		case couldNotReadData
		
		/// SecCertificateCreateWithData returns nil.
		case couldNotParseData
		
	}
	
	
	private var _data: Data?
	
	private lazy var _selectButton: NSButton = {
		let button = NSButton()
		button.title = XULocalizedString("Select...", inBundle: .core)
		button.target = self
		button.action = #selector(_selectCertificate)
		return button
	}()
	
	/// The certificate.
	public var certificate: SecCertificate?
	
	/// Certificate data. You can set and retrieve data from here.
	public var certificateData: Data? {
		get {
			return _data
		}
		set {
			_data = newValue
			
			self.needsDisplay = true
			self._loadCertificateFromData(notifyDelegate: false)
		}
	}
	
	/// Delegate.
	public weak var delegate: XUCertificateViewDelegate?
	
	
	private func _loadCertificateFromData(notifyDelegate: Bool) {
		self.certificate = nil
		
		guard let data = self.certificateData else {
			return
		}
		
		guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
			_data = nil // We're clearing the data if it can't be read.
			
			if notifyDelegate {
				self.delegate?.certificateView(didFailToLoadCertificate: self, withError: .couldNotParseData)
			}
			return
		}
		
		self.certificate = certificate
		
		if notifyDelegate {
			self.delegate?.certificateView(self, didLoadCertificate: certificate)
		}
	}
	
	@objc private func _selectCertificate() {
		let openPanel = NSOpenPanel()
		openPanel.allowedFileTypes = ["cert"]
		openPanel.beginSheetModal(for: self.window!, completionHandler: { (response) in
			if response == .cancel {
				return
			}
			
			let url = openPanel.url!
			guard let data = try? Data(contentsOf: url) else {
				self.delegate?.certificateView(didFailToLoadCertificate: self, withError: .couldNotReadData)
				return
			}
			
			self._data = data
			self.needsDisplay = true
			self._loadCertificateFromData(notifyDelegate: true)
		})
	}
	
	public override func draw(_ dirtyRect: NSRect) {
		
	}
	
	public override func mouseDown(with event: NSEvent) {
		if let certificate = self.certificate, event.clickCount == 2 {
			SFCertificatePanel.shared().runModal(forCertificates: [certificate], showGroup: true)
		}
	}
	
	
}
