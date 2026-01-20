import UIKit

extension UIWindowScene {
    var keyWindow: UIWindow? {
        return self.windows.first(where: { $0.isKeyWindow })
    }
}

func topMostViewController(from root: UIViewController?) -> UIViewController? {
    guard let root = root else { return nil }
    if let presented = root.presentedViewController {
        return topMostViewController(from: presented)
    }
    if let nav = root as? UINavigationController {
        return topMostViewController(from: nav.visibleViewController)
    }
    if let tab = root as? UITabBarController {
        return topMostViewController(from: tab.selectedViewController)
    }
    return root
}

func currentTopViewController() -> UIViewController? {
    guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive }),
          let root = scene.keyWindow?.rootViewController else {
        return nil
    }
    return topMostViewController(from: root)
}
