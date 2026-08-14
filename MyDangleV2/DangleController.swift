import AppKit

final class DangleController {
    private var panel: NSPanel?
    private var dangleView: DangleView?

    private let panelWidth: CGFloat = 520
    private let panelHeight: CGFloat = 520

    private func makePanelIfNeeded() {
        guard panel == nil else { return }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let screenFrame = screen.frame
        let frame = NSRect(
            x: screenFrame.midX - panelWidth / 2,
            y: screenFrame.maxY - panelHeight,
            width: panelWidth,
            height: panelHeight
        )

        let p = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.level = .statusBar
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        let view = DangleView(
            frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        )

        p.contentView = view

        panel = p
        dangleView = view
    }

    func show() {
        makePanelIfNeeded()
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func push() {
        dangleView?.push()
    }

    func setRopeLength(_ length: CGFloat) {
        dangleView?.ropeLength = length
    }

    func reset() {
        dangleView?.reset()
    }
}

final class DangleView: NSView {
    var ropeLength: CGFloat = 240 {
        didSet {
            ropeLength = max(150, min(340, ropeLength))
            needsDisplay = true
        }
    }

    private var angle: CGFloat = 0.0
    private var angularVelocity: CGFloat = 0.0
    private var timer: Timer?
    private var lastTimestamp: TimeInterval = CACurrentMediaTime()
    private var dragging = false
    private var lastDragAngle: CGFloat = 0
    private var lastDragTime: TimeInterval = 0

    private lazy var charmImage: NSImage? = {
        if let url = Bundle.main.url(forResource: "bhairava_charm", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return nil
    }()

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.stepPhysics()
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    private var anchor: NSPoint {
        NSPoint(x: bounds.midX, y: 10)
    }

    private var bob: NSPoint {
        NSPoint(
            x: anchor.x + sin(angle) * ropeLength,
            y: anchor.y + cos(angle) * ropeLength
        )
    }

    private var charmSize: CGFloat {
        150
    }

    private var charmRect: NSRect {
        let b = bob
        return NSRect(
            x: b.x - charmSize / 2,
            y: b.y - charmSize / 2 + 18,
            width: charmSize,
            height: charmSize
        )
    }

    private func stepPhysics() {
        let now = CACurrentMediaTime()
        let dt = min(max(now - lastTimestamp, 0), 0.04)
        lastTimestamp = now

        guard !dragging else {
            needsDisplay = true
            return
        }

        let gravity: CGFloat = 1000
        let acceleration = -(gravity / max(ropeLength, 1)) * sin(angle)

        angularVelocity += acceleration * dt
        angularVelocity *= pow(0.992, CGFloat(dt * 60))
        angle += angularVelocity * dt

        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let a = anchor
        let b = bob
        let cRect = charmRect

        // Rope
        let ropeEnd = NSPoint(x: b.x, y: cRect.minY - 30)

        let rope = NSBezierPath()
        rope.move(to: a)
        rope.line(to: ropeEnd)
        rope.lineWidth = 3.0
        NSColor(
            calibratedRed: 0.78,
            green: 0.60,
            blue: 0.22,
            alpha: 1.0
        ).setStroke()
        rope.stroke()

        // Anchor dot
        NSColor(
            calibratedRed: 0.86,
            green: 0.67,
            blue: 0.25,
            alpha: 1.0
        ).setFill()

        NSBezierPath(
            ovalIn: NSRect(x: a.x - 4, y: a.y - 4, width: 8, height: 8)
        ).fill()

        // Beads
        let bead1 = NSRect(x: ropeEnd.x - 7, y: ropeEnd.y - 32, width: 14, height: 14)
        let bead2 = NSRect(x: ropeEnd.x - 11, y: ropeEnd.y - 12, width: 22, height: 22)
        let bead3 = NSRect(x: ropeEnd.x - 7, y: ropeEnd.y + 16, width: 14, height: 14)

        NSColor(
            calibratedRed: 0.96,
            green: 0.78,
            blue: 0.24,
            alpha: 1.0
        ).setFill()
        NSBezierPath(ovalIn: bead1).fill()

        NSColor(
            calibratedRed: 0.84,
            green: 0.31,
            blue: 0.18,
            alpha: 1.0
        ).setFill()
        NSBezierPath(ovalIn: bead2).fill()

        NSColor(
            calibratedRed: 0.96,
            green: 0.78,
            blue: 0.24,
            alpha: 1.0
        ).setFill()
        NSBezierPath(ovalIn: bead3).fill()

        // Connector ring
        let ringRect = NSRect(x: cRect.midX - 12, y: cRect.minY - 6, width: 24, height: 24)
        let ring = NSBezierPath(ovalIn: ringRect)
        ring.lineWidth = 4
        NSColor(
            calibratedRed: 0.88,
            green: 0.70,
            blue: 0.26,
            alpha: 1.0
        ).setStroke()
        ring.stroke()

        // Charm shadow + image
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.saveGState()
            ctx.setShadow(
                offset: CGSize(width: 0, height: 8),
                blur: 16,
                color: NSColor.black.withAlphaComponent(0.28).cgColor
            )

            if let charmImage {
                charmImage.draw(in: cRect)
            } else {
                let fallback = NSAttributedString(
                    string: "🧿",
                    attributes: [.font: NSFont.systemFont(ofSize: 90)]
                )
                fallback.draw(in: cRect)
            }

            ctx.restoreGState()
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return charmRect.insetBy(dx: -16, dy: -16).contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        dragging = true
        let p = convert(event.locationInWindow, from: nil)
        angle = angleForPoint(p)
        lastDragAngle = angle
        lastDragTime = CACurrentMediaTime()
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        let now = CACurrentMediaTime()
        let newAngle = angleForPoint(p)

        let dt = max(now - lastDragTime, 1.0 / 240.0)
        angularVelocity = max(min((newAngle - lastDragAngle) / dt, 9), -9)

        angle = newAngle
        lastDragAngle = newAngle
        lastDragTime = now
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        dragging = false
    }

    private func angleForPoint(_ point: NSPoint) -> CGFloat {
        let dx = point.x - anchor.x
        let dy = max(point.y - anchor.y, 1)
        return max(min(atan2(dx, dy), .pi * 0.82), -.pi * 0.82)
    }

    func push() {
        angularVelocity += CGFloat.random(in: -4.5...4.5)
    }

    func reset() {
        angle = 0
        angularVelocity = 0
        needsDisplay = true
    }
}
