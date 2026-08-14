import Cocoa

final class DangleView: NSView {
    private let settings: AppSettings

    // Simple physical pendulum.
    private var angle: CGFloat = 0.0
    private var angularVelocity: CGFloat = 0.0
    private var lastTime: TimeInterval = CACurrentMediaTime()
    private var timer: Timer?

    private var dragging = false
    private var previousDragPoint: NSPoint = .zero
    private var previousDragTime: TimeInterval = 0

    var onRequestPanelMove: ((CGFloat) -> Void)?

    init(frame: NSRect, settings: AppSettings) {
        self.settings = settings
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    override var isFlipped: Bool { true }

    private var anchor: NSPoint {
        NSPoint(x: bounds.midX, y: 12)
    }

    private var bobCenter: NSPoint {
        let l = settings.ropeLength
        return NSPoint(
            x: anchor.x + sin(angle) * l,
            y: anchor.y + cos(angle) * l
        )
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let dt = min(max(now - lastTime, 0), 1.0 / 20.0)
        lastTime = now

        guard !dragging else {
            needsDisplay = true
            return
        }

        let length = max(settings.ropeLength, 40)
        let angularAcceleration = -(settings.gravity / length) * sin(angle)
        angularVelocity += angularAcceleration * dt
        angularVelocity *= pow(settings.damping, CGFloat(dt * 60.0))
        angle += angularVelocity * dt

        if abs(angle) < 0.0005 && abs(angularVelocity) < 0.0005 {
            angle = 0
            angularVelocity = 0
        }

        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let a = anchor
        let b = bobCenter

        // Rope
        let rope = NSBezierPath()
        rope.move(to: a)
        rope.line(to: b)
        rope.lineWidth = 2.2
        NSColor.labelColor.withAlphaComponent(0.72).setStroke()
        rope.stroke()

        // Small anchor cap
        let capRect = NSRect(x: a.x - 4, y: a.y - 4, width: 8, height: 8)
        NSColor.labelColor.withAlphaComponent(0.85).setFill()
        NSBezierPath(ovalIn: capRect).fill()

        // Charm shadow / hit area
        let s = settings.charmSize
        let charmRect = NSRect(x: b.x - s/2, y: b.y - s/2, width: s, height: s)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: s * 0.82),
            .paragraphStyle: paragraph
        ]

        let str = NSAttributedString(string: settings.charm, attributes: attrs)
        let textSize = str.size()
        let textRect = NSRect(
            x: b.x - textSize.width / 2,
            y: b.y - textSize.height / 2 - 2,
            width: textSize.width,
            height: textSize.height
        )
        str.draw(in: textRect)

        // Invisible charmRect intentionally retained conceptually for hit testing.
        _ = charmRect
    }

    private func isNearInteractiveArea(_ p: NSPoint) -> Bool {
        let b = bobCenter
        let r = max(settings.charmSize * 0.72, 34)
        let dx = p.x - b.x
        let dy = p.y - b.y
        if dx*dx + dy*dy <= r*r { return true }

        // Also let the user grab the anchor area to move the dangle horizontally.
        let ax = p.x - anchor.x
        let ay = p.y - anchor.y
        return ax*ax + ay*ay <= 18*18
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        isNearInteractiveArea(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)

        let ax = p.x - anchor.x
        let ay = p.y - anchor.y
        if ax*ax + ay*ay <= 18*18 {
            // Anchor dragging is handled in mouseDragged.
            dragging = false
            previousDragPoint = p
            previousDragTime = CACurrentMediaTime()
            return
        }

        dragging = true
        previousDragPoint = p
        previousDragTime = CACurrentMediaTime()
        updateAngle(to: p)
    }

    override func mouseDragged(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)

        // If drag started near anchor, move panel.
        let prevAx = previousDragPoint.x - anchor.x
        let prevAy = previousDragPoint.y - anchor.y
        if !dragging && prevAx*prevAx + prevAy*prevAy <= 24*24 {
            let dx = p.x - previousDragPoint.x
            onRequestPanelMove?(dx)
            previousDragPoint = p
            return
        }

        let now = CACurrentMediaTime()
        let oldAngle = angle
        updateAngle(to: p)
        let dt = max(now - previousDragTime, 1.0 / 240.0)
        angularVelocity = (angle - oldAngle) / dt
        angularVelocity = max(min(angularVelocity, 8.0), -8.0)

        previousDragPoint = p
        previousDragTime = now
    }

    override func mouseUp(with event: NSEvent) {
        dragging = false
    }

    private func updateAngle(to point: NSPoint) {
        let dx = point.x - anchor.x
        let dy = max(point.y - anchor.y, 1)
        angle = atan2(dx, dy)

        // Keep it visually sane.
        angle = max(min(angle, .pi * 0.80), -.pi * 0.80)
        needsDisplay = true
    }

    func kick() {
        angularVelocity += CGFloat.random(in: -3.5...3.5)
    }

    func resetPhysics() {
        angle = 0
        angularVelocity = 0
        needsDisplay = true
    }
}
