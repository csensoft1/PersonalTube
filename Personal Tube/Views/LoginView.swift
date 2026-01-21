//
//  LoginView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var presentingVC: UIViewController?

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign in to personalize your YouTube profiles")
                .multilineTextAlignment(.center)

            Button("Sign in with Google") {
                guard let vc = presentingVC else { return }
                auth.signIn(presentingVC: vc)
            }
            .buttonStyle(.borderedProminent)
            .disabled(presentingVC == nil)
        }
        .padding()
        .background(
            ViewControllerResolver { vc in
                presentingVC = vc
            }
        )
    }
}
