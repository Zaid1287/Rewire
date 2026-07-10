import UIKit

/// The custom NavHeader hides the system nav bar, which disables the
/// interactive pop (edge-swipe back) gesture. Re-enable it whenever there's
/// something to pop.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
