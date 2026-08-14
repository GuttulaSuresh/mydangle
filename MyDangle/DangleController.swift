import Cocoa

final class DangleController {
    private let settings: AppSettings
    private var panel: NSPanel?
    private var dangleView: DangleView?
    private var pointerTimer: Timer?

    // Wider/taller than v1.4 so a long rope can move naturally without clipping.
    private let panelWidth: CGFloat = 900
    private let panelHeight: CGFloat = 740

    init(settings: AppSettings) {
        self.settings = settings

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        pointerTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screenChanged() {
        updatePanelFrame()
    }

    private func targetScreen() -> NSScreen? {
        NSScreen.main ?? NSScreen.screens.first
    }

    private func frameForScreen(_ screen: NSScreen) -> NSRect {
        let sf = screen.frame
        let width = min(panelWidth, sf.width)
        let height = min(panelHeight, sf.height)

        let centerX = sf.minX + sf.width * settings.anchorFraction
        var x = centerX - width / 2
        x = max(sf.minX, min(x, sf.maxX - width))

        return NSRect(
            x: x,
            y: sf.maxY - height,
            width: width,
            height: height
        )
    }

    private func makePanelIfNeeded() {
        guard panel == nil, let screen = targetScreen() else { return }

        let frame = frameForScreen(screen)
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
        p.acceptsMouseMovedEvents = true
        p.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        let view = DangleView(
            frame: NSRect(origin: .zero, size: frame.size),
            settings: settings
        )
        view.autoresizingMask = [.width, .height]

        p.contentView = view
        panel = p
        dangleView = view

        startPointerTracking()
    }

    private func startPointerTracking() {
        pointerTimer?.invalidate()

        let timer = Timer(
            timeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            self?.updateMousePassthrough()
        }

        pointerTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func updateMousePassthrough() {
        guard let panel, let view = dangleView else { return }

        // Once a drag begins, keep receiving the entire mouse gesture even if
        // the pointer briefly outruns the charm.
        if view.isDragging {
            panel.ignoresMouseEvents = false
            return
        }

        let windowRect = view.convert(view.interactiveRect, to: nil)
        let screenRect = panel.convertToScreen(windowRect)
        panel.ignoresMouseEvents = !screenRect.contains(NSEvent.mouseLocation)
    }

    func show() {
        settings.isVisible = true
        settings.save()
        makePanelIfNeeded()
        updatePanelFrame()
        panel?.orderFrontRegardless()
    }

    func hide() {
        settings.isVisible = false
        settings.save()
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

    func setCharm(_ value: String) {
        settings.selectedCharm = value
        settings.save()
        dangleView?.selectedCharm = value
        dangleView?.needsDisplay = true
    }

    func setRopeLength(_ value: CGFloat) {
        settings.ropeLength = value
        settings.save()
        dangleView?.ropeLength = value
    }

    func setCharmSize(_ value: CGFloat) {
        settings.charmSize = value
        settings.save()
        dangleView?.charmSize = value
        dangleView?.needsDisplay = true
    }

    func setPosition(_ value: CGFloat) {
        settings.anchorFraction = max(0.10, min(value, 0.90))
        settings.save()
        updatePanelFrame()
    }

    func reset() {
        settings.reset()
        dangleView?.ropeLength = settings.ropeLength
        dangleView?.charmSize = settings.charmSize
        dangleView?.selectedCharm = settings.selectedCharm
        dangleView?.resetPhysics()
        updatePanelFrame()
        show()
    }

    private func updatePanelFrame() {
        guard let panel, let screen = targetScreen() else { return }

        let newFrame = frameForScreen(screen)
        panel.setFrame(newFrame, display: true)

        if let view = dangleView {
            view.frame = NSRect(origin: .zero, size: newFrame.size)
        }
    }
}


// MARK: - Segmented rope physics

final class DangleView: NSView {
    private struct RopeNode {
        var position: CGPoint
        var previous: CGPoint
    }

    var ropeLength: CGFloat {
        didSet {
            ropeLength = max(140, min(340, ropeLength))
            rebuildRope()
        }
    }

    var charmSize: CGFloat
    var selectedCharm: String

    private let segmentCount = 18
    private let constraintIterations = 10
    private var nodes: [RopeNode] = []

    private var animationTimer: Timer?
    private var lastTime: TimeInterval = CACurrentMediaTime()
    private var lastPhysicsStep: CGFloat = 1.0 / 60.0

    private(set) var isDragging = false
    private var dragTarget: CGPoint?
    private var pointerVelocity = CGVector(dx: 0, dy: 0)
    private var previousPointerPoint = CGPoint.zero
    private var previousPointerTime: TimeInterval = 0

    private lazy var images: [String: NSImage] = {
        var result: [String: NSImage] = [:]

        if let url = Bundle.main.url(
            forResource: "bhairava_charm",
            withExtension: "png"
        ), let image = NSImage(contentsOf: url) {
            result["bhairava"] = image
        }

        if let url = Bundle.main.url(
            forResource: "lemon_chilli_charm",
            withExtension: "png"
        ), let image = NSImage(contentsOf: url) {
            result["lemon_chilli"] = image
        }

        return result
    }()

    override var isFlipped: Bool { true }

    init(frame: NSRect, settings: AppSettings) {
        ropeLength = settings.ropeLength
        charmSize = settings.charmSize
        selectedCharm = settings.selectedCharm

        super.init(frame: frame)

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        rebuildRope()

        // A 120 Hz update request produces noticeably smoother pointer-follow
        // behavior on ProMotion Macs while still using elapsed-time physics.
        let timer = Timer(
            timeInterval: 1.0 / 120.0,
            repeats: true
        ) { [weak self] _ in
            self?.step()
        }

        animationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        animationTimer?.invalidate()
    }

    private var anchor: CGPoint {
        CGPoint(x: bounds.midX, y: 5)
    }

    private var segmentLength: CGFloat {
        ropeLength / CGFloat(segmentCount)
    }

    private var connector: CGPoint {
        nodes.last?.position ?? CGPoint(x: anchor.x, y: anchor.y + ropeLength)
    }

    private var actualSize: CGFloat {
        selectedCharm == "lemon_chilli" ? charmSize * 1.35 : charmSize
    }

    private var charmRect: NSRect {
        let c = connector

        return NSRect(
            x: c.x - actualSize / 2,
            y: c.y - 5,
            width: actualSize,
            height: actualSize
        )
    }

    var interactiveRect: NSRect {
        charmRect.insetBy(dx: -28, dy: -28)
    }

    private func rebuildRope() {
        guard bounds.width > 0 else { return }

        let a = anchor
        nodes.removeAll(keepingCapacity: true)

        for index in 0...segmentCount {
            let fraction = CGFloat(index) / CGFloat(segmentCount)
            let p = CGPoint(
                x: a.x,
                y: a.y + ropeLength * fraction
            )
            nodes.append(RopeNode(position: p, previous: p))
        }

        pointerVelocity = CGVector(dx: 0, dy: 0)
        dragTarget = nil
        isDragging = false
        needsDisplay = true
    }

    private func step() {
        let now = CACurrentMediaTime()
        var elapsed = CGFloat(now - lastTime)
        lastTime = now

        // Ignore large debugger/app-switch stalls.
        elapsed = max(1.0 / 240.0, min(elapsed, 1.0 / 24.0))

        // Substep long frames so constraints remain stable.
        let targetSubstep: CGFloat = 1.0 / 120.0
        let substeps = max(1, Int(ceil(elapsed / targetSubstep)))
        let dt = elapsed / CGFloat(substeps)
        lastPhysicsStep = dt

        for _ in 0..<substeps {
            simulate(dt: dt)
        }

        needsDisplay = true
    }

    private func simulate(dt: CGFloat) {
        guard nodes.count == segmentCount + 1 else {
            rebuildRope()
            return
        }

        let gravity: CGFloat = 1550
        let verletDamping: CGFloat = pow(0.996, dt * 120.0)

        // The anchor is fixed to the top of the panel.
        nodes[0].position = anchor
        nodes[0].previous = anchor

        for index in 1..<nodes.count {
            var node = nodes[index]

            let vx = (node.position.x - node.previous.x) * verletDamping
            let vy = (node.position.y - node.previous.y) * verletDamping

            var accelerationX: CGFloat = 0
            var accelerationY: CGFloat = gravity

            // Treat the charm as a heavier mass than the cord itself.
            if index == nodes.count - 1 {
                accelerationY *= 1.15

                if isDragging, let target = dragTarget {
                    // Spring + damper: the mouse PULLS the weighted charm rather
                    // than teleporting it. This is the core v1.5 interaction.
                    let springK: CGFloat = 150
                    let dragDamping: CGFloat = 15

                    let velocityPerSecondX = vx / max(dt, 0.001)
                    let velocityPerSecondY = vy / max(dt, 0.001)

                    accelerationX +=
                        (target.x - node.position.x) * springK
                        - velocityPerSecondX * dragDamping

                    accelerationY +=
                        (target.y - node.position.y) * springK
                        - velocityPerSecondY * dragDamping
                }
            }

            node.previous = node.position
            node.position.x += vx + accelerationX * dt * dt
            node.position.y += vy + accelerationY * dt * dt

            nodes[index] = node
        }

        solveConstraints()
    }

    private func inverseMass(for index: Int) -> CGFloat {
        if index == 0 {
            return 0
        }

        // Lower inverse mass = heavier. The endpoint represents the charm.
        if index == nodes.count - 1 {
            return 0.28
        }

        // The bottom few cord points carry more of the charm's load.
        if index >= nodes.count - 4 {
            return 0.72
        }

        return 1.0
    }

    private func solveConstraints() {
        guard nodes.count >= 2 else { return }

        for _ in 0..<constraintIterations {
            nodes[0].position = anchor

            for index in 0..<(nodes.count - 1) {
                var first = nodes[index]
                var second = nodes[index + 1]

                let dx = second.position.x - first.position.x
                let dy = second.position.y - first.position.y
                let distance = max(sqrt(dx * dx + dy * dy), 0.0001)

                let error = (distance - segmentLength) / distance
                let correctionX = dx * error
                let correctionY = dy * error

                let w1 = inverseMass(for: index)
                let w2 = inverseMass(for: index + 1)
                let totalWeight = w1 + w2

                if totalWeight > 0 {
                    first.position.x += correctionX * (w1 / totalWeight)
                    first.position.y += correctionY * (w1 / totalWeight)

                    second.position.x -= correctionX * (w2 / totalWeight)
                    second.position.y -= correctionY * (w2 / totalWeight)
                }

                nodes[index] = first
                nodes[index + 1] = second
            }

            nodes[0].position = anchor
        }
    }


    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard nodes.count > 1 else { return }

        drawRope()

        if selectedCharm == "bhairava" {
            drawBeads()
        }

        drawCharm()
    }

    private func smoothRopePath() -> NSBezierPath {
        let points = nodes.map(\.position)
        let path = NSBezierPath()

        guard points.count >= 2 else { return path }

        path.move(to: points[0])

        for index in 0..<(points.count - 1) {
            let p0 = index > 0 ? points[index - 1] : points[index]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = index + 2 < points.count ? points[index + 2] : p2

            let cp1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6.0,
                y: p1.y + (p2.y - p0.y) / 6.0
            )

            let cp2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6.0,
                y: p2.y - (p3.y - p1.y) / 6.0
            )

            path.curve(
                to: p2,
                controlPoint1: cp1,
                controlPoint2: cp2
            )
        }

        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        return path
    }

    private func drawRope() {
        let path = smoothRopePath()

        NSGraphicsContext.saveGraphicsState()

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow.shadowBlurRadius = 3.5
        shadow.shadowOffset = NSSize(width: 1.2, height: -1.5)
        shadow.set()

        // Deep fiber/shadow edge.
        path.lineWidth = 5.2
        NSColor(
            calibratedRed: 0.28,
            green: 0.17,
            blue: 0.055,
            alpha: 0.92
        ).setStroke()
        path.stroke()

        NSGraphicsContext.restoreGraphicsState()

        // Main warm-gold fiber.
        path.lineWidth = 3.55
        NSColor(
            calibratedRed: 0.70,
            green: 0.45,
            blue: 0.11,
            alpha: 1.0
        ).setStroke()
        path.stroke()

        // Sunlit strand running through the cord.
        path.lineWidth = 1.25
        NSColor(
            calibratedRed: 0.98,
            green: 0.78,
            blue: 0.30,
            alpha: 0.92
        ).setStroke()
        path.stroke()

        drawFiberBands()
        drawAnchorKnot()
    }

    private func drawFiberBands() {
        // Tiny angled bands give the rope a subtle twisted/braided appearance.
        guard nodes.count > 4 else { return }

        for index in stride(from: 2, to: nodes.count - 2, by: 2) {
            let p = nodes[index]
            let before = nodes[index - 1].position
            let after = nodes[index + 1].position

            let dx = after.x - before.x
            let dy = after.y - before.y
            let length = max(sqrt(dx * dx + dy * dy), 0.001)

            let perpendicularX = -dy / length
            let perpendicularY = dx / length

            let half: CGFloat = 2.1
            let band = NSBezierPath()
            band.move(
                to: CGPoint(
                    x: p.position.x - perpendicularX * half,
                    y: p.position.y - perpendicularY * half
                )
            )
            band.line(
                to: CGPoint(
                    x: p.position.x + perpendicularX * half,
                    y: p.position.y + perpendicularY * half
                )
            )
            band.lineWidth = 0.75
            band.lineCapStyle = .round

            NSColor(
                calibratedRed: 0.34,
                green: 0.20,
                blue: 0.06,
                alpha: 0.48
            ).setStroke()
            band.stroke()
        }
    }

    private func drawAnchorKnot() {
        let center = nodes[0].position

        let outer = NSBezierPath(
            ovalIn: NSRect(
                x: center.x - 5.0,
                y: center.y - 2.0,
                width: 10.0,
                height: 8.0
            )
        )
        NSColor(
            calibratedRed: 0.35,
            green: 0.21,
            blue: 0.06,
            alpha: 1.0
        ).setFill()
        outer.fill()

        let inner = NSBezierPath(
            ovalIn: NSRect(
                x: center.x - 3.2,
                y: center.y - 1.0,
                width: 6.4,
                height: 5.0
            )
        )
        NSColor(
            calibratedRed: 0.86,
            green: 0.60,
            blue: 0.18,
            alpha: 1.0
        ).setFill()
        inner.fill()
    }

    private func drawBeads() {
        guard nodes.count >= 5 else { return }

        let indexes = [
            nodes.count - 5,
            nodes.count - 3,
            nodes.count - 2
        ]

        drawBead(
            at: nodes[indexes[0]].position,
            radius: 5.8,
            fill: NSColor(
                calibratedRed: 0.94,
                green: 0.70,
                blue: 0.18,
                alpha: 1
            )
        )

        drawBead(
            at: nodes[indexes[1]].position,
            radius: 8.5,
            fill: NSColor(
                calibratedRed: 0.82,
                green: 0.14,
                blue: 0.08,
                alpha: 1
            )
        )

        drawBead(
            at: nodes[indexes[2]].position,
            radius: 5.9,
            fill: NSColor(
                calibratedRed: 0.94,
                green: 0.70,
                blue: 0.18,
                alpha: 1
            )
        )
    }

    private func drawBead(
        at center: CGPoint,
        radius: CGFloat,
        fill: NSColor
    ) {
        let rect = NSRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        NSColor(
            calibratedRed: 0.32,
            green: 0.17,
            blue: 0.035,
            alpha: 0.95
        ).setFill()
        NSBezierPath(ovalIn: rect).fill()

        fill.setFill()
        NSBezierPath(
            ovalIn: rect.insetBy(dx: 1.35, dy: 1.35)
        ).fill()

        NSColor.white.withAlphaComponent(0.60).setFill()
        NSBezierPath(
            ovalIn: NSRect(
                x: center.x - radius * 0.48,
                y: center.y - radius * 0.50,
                width: radius * 0.52,
                height: radius * 0.52
            )
        ).fill()
    }

    private func currentCharmTilt() -> CGFloat {
        guard nodes.count >= 2 else { return 0 }

        let last = nodes[nodes.count - 1]
        let before = nodes[nodes.count - 2].position

        let dx = last.position.x - before.x
        let dy = max(last.position.y - before.y, 0.001)
        let ropeAngle = atan2(dx, dy)

        let velocityX =
            (last.position.x - last.previous.x)
            / max(lastPhysicsStep, 0.001)

        let inertialTilt = max(
            -0.15,
            min(0.15, velocityX / 2200.0)
        )

        return max(
            -0.28,
            min(0.28, ropeAngle * 0.16 + inertialTilt)
        )
    }

    private func drawCharm() {
        let rect = charmRect
        let image = images[selectedCharm]

        NSGraphicsContext.saveGraphicsState()

        let context = NSGraphicsContext.current?.cgContext
        let pivot = CGPoint(
            x: rect.midX,
            y: rect.minY + actualSize * 0.08
        )

        if let context {
            context.translateBy(x: pivot.x, y: pivot.y)
            context.rotate(by: currentCharmTilt())
            context.translateBy(x: -pivot.x, y: -pivot.y)
        }

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = 15
        shadow.shadowOffset = NSSize(width: 0, height: -7)
        shadow.set()

        if let image {
            image.draw(
                in: rect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.high]
            )
        } else {
            let fallback = NSAttributedString(
                string: "🧿",
                attributes: [
                    .font: NSFont.systemFont(
                        ofSize: actualSize * 0.60
                    )
                ]
            )
            fallback.draw(in: rect)
        }

        NSGraphicsContext.restoreGraphicsState()
    }


    // MARK: - Mouse interaction

    override func hitTest(_ point: NSPoint) -> NSView? {
        interactiveRect.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        isDragging = true
        dragTarget = point
        pointerVelocity = CGVector(dx: 0, dy: 0)
        previousPointerPoint = point
        previousPointerTime = CACurrentMediaTime()
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let now = CACurrentMediaTime()
        let dt = max(CGFloat(now - previousPointerTime), 1.0 / 240.0)

        let rawVelocity = CGVector(
            dx: (point.x - previousPointerPoint.x) / dt,
            dy: (point.y - previousPointerPoint.y) / dt
        )

        // Low-pass pointer velocity so release momentum feels physical instead
        // of reacting to one noisy mouse sample.
        pointerVelocity = CGVector(
            dx: pointerVelocity.dx * 0.55 + rawVelocity.dx * 0.45,
            dy: pointerVelocity.dy * 0.55 + rawVelocity.dy * 0.45
        )
        pointerVelocity = limitedVelocity(pointerVelocity, maxSpeed: 2800)

        dragTarget = point
        previousPointerPoint = point
        previousPointerTime = now
    }

    override func mouseUp(with event: NSEvent) {
        transferPointerMomentum()
        isDragging = false
        dragTarget = nil
    }

    private func limitedVelocity(
        _ velocity: CGVector,
        maxSpeed: CGFloat
    ) -> CGVector {
        let speed = sqrt(
            velocity.dx * velocity.dx
            + velocity.dy * velocity.dy
        )

        guard speed > maxSpeed, speed > 0 else {
            return velocity
        }

        let scale = maxSpeed / speed
        return CGVector(
            dx: velocity.dx * scale,
            dy: velocity.dy * scale
        )
    }

    private func transferPointerMomentum() {
        guard !nodes.isEmpty else { return }

        let lastIndex = nodes.count - 1
        var end = nodes[lastIndex]

        let currentDisplacement = CGVector(
            dx: end.position.x - end.previous.x,
            dy: end.position.y - end.previous.y
        )

        let frameEquivalent: CGFloat = 1.0 / 60.0
        let pointerDisplacement = CGVector(
            dx: pointerVelocity.dx * frameEquivalent * 0.48,
            dy: pointerVelocity.dy * frameEquivalent * 0.48
        )

        let combined = CGVector(
            dx: currentDisplacement.dx * 0.38 + pointerDisplacement.dx,
            dy: currentDisplacement.dy * 0.38 + pointerDisplacement.dy
        )

        end.previous = CGPoint(
            x: end.position.x - combined.dx,
            y: end.position.y - combined.dy
        )

        nodes[lastIndex] = end
        pointerVelocity = CGVector(dx: 0, dy: 0)
    }

    func push() {
        guard !nodes.isEmpty else { return }

        let lastIndex = nodes.count - 1
        var end = nodes[lastIndex]
        let direction: CGFloat = Bool.random() ? 1 : -1
        let impulse = CGFloat.random(in: 9.0...14.0)

        end.previous.x = end.position.x - direction * impulse
        end.previous.y = end.position.y + 1.0
        nodes[lastIndex] = end
    }

    func resetPhysics() {
        rebuildRope()
    }
}
