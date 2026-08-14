import Cocoa

final class DangleController {
    private let settings: AppSettings
    private var panel: NSPanel?
    private var dangleView: DangleView?
    private var pointerTimer: Timer?

    private let panelWidth: CGFloat = 680
    private let panelHeight: CGFloat = 650

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
        let centerX = sf.minX + sf.width * settings.anchorFraction

        var x = centerX - panelWidth / 2
        x = max(sf.minX, min(x, sf.maxX - panelWidth))

        return NSRect(
            x: x,
            y: sf.maxY - panelHeight,
            width: panelWidth,
            height: panelHeight
        )
    }

    private func makePanelIfNeeded() {
        guard panel == nil, let screen = targetScreen() else { return }

        let p = NSPanel(
            contentRect: frameForScreen(screen),
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
            frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
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
            timeInterval: 1.0 / 30.0,
            repeats: true
        ) { [weak self] _ in
            self?.updateMousePassthrough()
        }

        pointerTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func updateMousePassthrough() {
        guard let panel, let view = dangleView else { return }

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
        dangleView?.needsDisplay = true
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
        panel.setFrame(frameForScreen(screen), display: true)
    }
}

final class DangleView: NSView {
    var ropeLength: CGFloat
    var charmSize: CGFloat
    var selectedCharm: String

    private var angle: CGFloat = 0
    private var angularVelocity: CGFloat = 0
    private var timer: Timer?
    private var lastTime: TimeInterval = CACurrentMediaTime()

    private(set) var isDragging = false
    private var previousAngle: CGFloat = 0
    private var previousTime: TimeInterval = 0

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

        let animationTimer = Timer(
            timeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            self?.step()
        }

        timer = animationTimer
        RunLoop.main.add(animationTimer, forMode: .common)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    private var anchor: NSPoint {
        NSPoint(x: bounds.midX, y: 5)
    }

    private var direction: CGVector {
        CGVector(dx: sin(angle), dy: cos(angle))
    }

    private func point(_ distance: CGFloat) -> NSPoint {
        NSPoint(
            x: anchor.x + direction.dx * distance,
            y: anchor.y + direction.dy * distance
        )
    }

    private var connector: NSPoint {
        point(ropeLength)
    }

    private var actualSize: CGFloat {
        selectedCharm == "lemon_chilli" ? charmSize * 1.35 : charmSize
    }

    private var charmRect: NSRect {
        let center = connector

        return NSRect(
            x: center.x - actualSize / 2,
            y: center.y,
            width: actualSize,
            height: actualSize
        )
    }

    var interactiveRect: NSRect {
        charmRect.insetBy(dx: -22, dy: -22)
    }

    private func step() {
        let now = CACurrentMediaTime()
        let dt = min(max(now - lastTime, 0), 0.04)
        lastTime = now

        guard !isDragging else {
            needsDisplay = true
            return
        }

        let acceleration = -(1120 / max(ropeLength, 90)) * sin(angle)
        angularVelocity += acceleration * dt
        angularVelocity *= 0.992
        angle += angularVelocity * dt

        if abs(angle) < 0.0002 && abs(angularVelocity) < 0.0002 {
            angle = 0
            angularVelocity = 0
        }

        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawRope()

        if selectedCharm == "bhairava" {
            drawBeads()
        }

        drawCharm()
    }

    private func ropePath() -> NSBezierPath {
        let start = anchor
        let end = connector
        let perpendicular = CGVector(dx: -direction.dy, dy: direction.dx)
        let curve = max(-12, min(12, angularVelocity * 2.8))

        let control1 = NSPoint(
            x: start.x + (end.x - start.x) * 0.34 + perpendicular.dx * curve,
            y: start.y + (end.y - start.y) * 0.34 + perpendicular.dy * curve
        )

        let control2 = NSPoint(
            x: start.x + (end.x - start.x) * 0.72 + perpendicular.dx * curve * 0.45,
            y: start.y + (end.y - start.y) * 0.72 + perpendicular.dy * curve * 0.45
        )

        let path = NSBezierPath()
        path.move(to: start)
        path.curve(to: end, controlPoint1: control1, controlPoint2: control2)
        return path
    }

    private func drawRope() {
        let path = ropePath()
        path.lineCapStyle = .round

        path.lineWidth = 4.2
        NSColor(
            calibratedRed: 0.37,
            green: 0.23,
            blue: 0.07,
            alpha: 0.95
        ).setStroke()
        path.stroke()

        path.lineWidth = 2.7
        NSColor(
            calibratedRed: 0.82,
            green: 0.58,
            blue: 0.16,
            alpha: 1.0
        ).setStroke()
        path.stroke()

        path.lineWidth = 0.8
        NSColor(
            calibratedRed: 1.0,
            green: 0.86,
            blue: 0.43,
            alpha: 0.92
        ).setStroke()
        path.stroke()
    }

    private func drawBead(
        at center: NSPoint,
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
            calibratedRed: 0.42,
            green: 0.23,
            blue: 0.05,
            alpha: 1.0
        ).setFill()
        NSBezierPath(ovalIn: rect).fill()

        fill.setFill()
        NSBezierPath(ovalIn: rect.insetBy(dx: 1.5, dy: 1.5)).fill()
    }

    private func drawBeads() {
        drawBead(
            at: point(ropeLength - 43),
            radius: 6,
            fill: .systemYellow
        )
        drawBead(
            at: point(ropeLength - 26),
            radius: 9,
            fill: .systemRed
        )
        drawBead(
            at: point(ropeLength - 8),
            radius: 6,
            fill: .systemYellow
        )
    }

    private func drawCharm() {
        guard let image = images[selectedCharm] else { return }

        NSGraphicsContext.saveGraphicsState()

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.32)
        shadow.shadowBlurRadius = 13
        shadow.shadowOffset = NSSize(width: 0, height: -6)
        shadow.set()

        image.draw(
            in: charmRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high]
        )

        NSGraphicsContext.restoreGraphicsState()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        interactiveRect.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        isDragging = true

        let point = convert(event.locationInWindow, from: nil)
        angle = angleFor(point)
        previousAngle = angle
        previousTime = CACurrentMediaTime()
        angularVelocity = 0
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let now = CACurrentMediaTime()
        let newAngle = angleFor(point)
        let dt = max(now - previousTime, 1.0 / 240.0)

        angularVelocity = max(
            -8.5,
            min(8.5, (newAngle - previousAngle) / dt)
        )

        angle = newAngle
        previousAngle = newAngle
        previousTime = now
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }

    private func angleFor(_ point: NSPoint) -> CGFloat {
        let dx = point.x - anchor.x
        let dy = max(point.y - anchor.y, 1)

        return max(
            -.pi * 0.78,
            min(.pi * 0.78, atan2(dx, dy))
        )
    }

    func push() {
        let sign: CGFloat = Bool.random() ? 1 : -1
        angularVelocity += sign * CGFloat.random(in: 2.4 ... 4.1)
    }

    func resetPhysics() {
        angle = 0
        angularVelocity = 0
        isDragging = false
        needsDisplay = true
    }
}
