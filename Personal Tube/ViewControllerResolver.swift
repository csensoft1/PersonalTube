//
//  ViewControllerResolver.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct ViewControllerResolver: UIViewControllerRepresentable {
    let onResolve: (UIViewController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        ResolverVC(onResolve: onResolve)
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    final class ResolverVC: UIViewController {
        let onResolve: (UIViewController) -> Void
        init(onResolve: @escaping (UIViewController) -> Void) {
            self.onResolve = onResolve
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onResolve(self)
        }
    }
}
