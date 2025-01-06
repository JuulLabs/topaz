import Observation
import SwiftUI

@MainActor
@Observable
public final class PullDrawerModel: NSObject {
    @ObservationIgnored
    private var kvoStore: [NSKeyValueObservation] = []

    /// The status drives the rendered view state
    public enum Status {
        case exposed, open, closed
    }
    public private(set) var status: Status = .closed

    /// The visibility drives the internal logic tracking the drawer opening progress
    private enum Visibility {
        case hidden, visible, stretched
    }
    private var visibiltiy: Visibility = .hidden

    /// The speed/gearing of the user input
    private let ratio: CGFloat

    /// A notching value for the pull distance below which nothing happens
    private let activationDistance: CGFloat

    /// A notching value for the pull distance to trigger the extended pull action
    private let stretchActivationDistance: CGFloat

    /// The current open distance in points
    private var openedDistance: CGFloat = 0

    /// The (static) total view height
    public let drawerHeight: CGFloat

    /// The amount of the view showing during the pull-to-reveal stage
    public var drawerMaskHeight: CGFloat {
        min(drawerHeight, openedDistance)
    }

    public var disabled: Bool = false {
        didSet {
            if disabled {
                status = .closed
                visibiltiy = .hidden
                openedDistance = 0
            }
        }
    }

    /// Triggered when the user keeps pulling down beyond where it is already opened
    public var onExtendedPull: () -> Void = {}

    public init(
        height: CGFloat = 40,
        ratio: CGFloat = 2.0,
        activationDistance: CGFloat = 12
    ) {
        self.drawerHeight = height
        self.ratio = ratio
        self.activationDistance = activationDistance
        self.stretchActivationDistance = activationDistance * 1.7
        super.init()
    }

    deinit {
        kvoStore.forEach { $0.invalidate() }
        kvoStore.removeAll()
    }

    public func close() {
        self.openedDistance = 0
        self.status = .closed
        self.visibiltiy = .hidden
    }

    // Note this can be replaced with onScrollPhaseChange/onScrollGeometryChange when targeting iOS18
    func observe(scrollView: UIScrollView) {
        kvoStore.forEach { $0.invalidate() }
        kvoStore.removeAll()
        let offsetObservation = scrollView.observe(\.contentOffset, options: .new) { scrollView, change in
            guard let offset = change.newValue?.y else { return }
            Task { @MainActor [weak self, scrollView] in
                // Note these tasks are fired asynchronously on the offset change, which means
                // the order they run is non-deterministic. The logic needs to be robust to that fact.
                self?.updateOffset(offset: offset, scrollView: scrollView)
            }
        }
        kvoStore.append(offsetObservation)
    }

    private func updateOffset(offset: CGFloat, scrollView: UIScrollView) {
        guard !disabled else { return }

        let gearedPullOffset = floor((-scrollView.adjustedContentInset.top - offset) / ratio)
        guard status != .open else {
            triggerAutomaticScrollToCloseIfConditionsMet(at: gearedPullOffset)
            return
        }

        let distance = max(0, gearedPullOffset - activationDistance)
        updateStatusForDistance(distance: distance)
        updateVisibilityForDistance(distance: distance)

        // Scrollview changes constantly - only update if things change to avoid triggering observation re-rendering:
        let newOpenedDistance = min(distance, drawerHeight)
        if newOpenedDistance != openedDistance {
            openedDistance = newOpenedDistance
        }

        // Do this last because the extended pull action may cause other updates
        triggerOpenActionIfConditionsMet(scrollView: scrollView)
    }

    private func triggerAutomaticScrollToCloseIfConditionsMet(at offset: CGFloat) {
        if offset + drawerHeight <= activationDistance {
            withAnimation(.smooth.speed(0.7)) { close() }
        }
    }

    private func triggerOpenActionIfConditionsMet(scrollView: UIScrollView) {
        if visibiltiy != .hidden && status != .open && !scrollView.isDragging {
            status = .open
            if visibiltiy == .stretched {
                onExtendedPull()
            }
        }
    }

    private func updateVisibilityForDistance(distance: CGFloat) {
        if distance >= (drawerHeight + stretchActivationDistance) {
            if visibiltiy == .visible {
                visibiltiy = .stretched
                playImpactForVisibility(visibility: .stretched)
            }
        } else if distance >= drawerHeight {
            if visibiltiy == .hidden {
                visibiltiy = .visible
                playImpactForVisibility(visibility: .visible)
            }
        } else if distance < (drawerHeight - activationDistance) && visibiltiy != .hidden {
            visibiltiy = .hidden
        }
    }

    private func updateStatusForDistance(distance: CGFloat) {
        if distance > 0 {
            if self.status == .closed {
                self.status = .exposed
            }
        } else {
            if self.status == .exposed {
                self.status = .closed
            }
        }
    }

    private func playImpactForVisibility(visibility: Visibility) {
        switch visibility {
        case .visible:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
        case .stretched:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.8)
        case .hidden:
            break
        }
    }
}
