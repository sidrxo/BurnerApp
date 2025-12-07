//
//  ScreenshotProtect.swift
//  burner
//
//  Created by Sid Rao on 07/12/2025.
//


import SwiftUI
import UIKit

struct ScreenshotProtect<Content: View>: UIViewRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UITextField {
        let secureField = UITextField()
        secureField.isSecureTextEntry = true
        
        // This is important: it prevents the text field from grabbing focus
        // while still allowing the user to interact with buttons inside your view.
        secureField.isUserInteractionEnabled = true
        
        // Hide the cursor/selection capabilities
        secureField.tintColor = .clear
        
        // LOCATE THE SECURE LAYER
        // The secure content is hosted inside the first subview of the text field.
        if let secureContainer = secureField.subviews.first {
            secureContainer.backgroundColor = .clear
            secureContainer.isUserInteractionEnabled = true
            
            // Create a hosting controller for your SwiftUI content
            let hostingController = UIHostingController(rootView: content)
            hostingController.view.backgroundColor = .clear
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            // Add the hosting view to the secure layer
            secureContainer.addSubview(hostingController.view)
            
            // Constrain your content to fill the secure layer
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: secureContainer.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: secureContainer.bottomAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: secureContainer.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: secureContainer.trailingAnchor)
            ])
        }
        
        return secureField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        // If your state changes, the UIHostingController inside will handle the updates automatically.
    }
}