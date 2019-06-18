//
//  ViewController.swift
//  HapticTest
//
//  Created by Linus Akerlund on 2019-06-17.
//  Copyright © 2019 Puterman. All rights reserved.
//

import UIKit
import CoreHaptics

class ViewController: UIViewController {

    @IBOutlet var hapticButton: UIControl!

    var hapticEngine: CHHapticEngine?
    var hapticPlayer: CHHapticPatternPlayer?
    var continuousHapticPlayer: CHHapticPatternPlayer?

    var lastPoint: CGPoint?

    let hapticDict = [
        CHHapticPattern.Key.pattern: [
            [CHHapticPattern.Key.event: [
                CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticTransient,
                CHHapticPattern.Key.time: 0.001,
                CHHapticPattern.Key.eventDuration: 1.0]
            ]
        ]
    ]

    let continuousHapticDict = [
        CHHapticPattern.Key.pattern: [
            [CHHapticPattern.Key.event: [
                CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticContinuous,
                CHHapticPattern.Key.time: 0.001,
                CHHapticPattern.Key.eventDuration: 1000]
            ]
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            hapticEngine = try CHHapticEngine()
        } catch let error {
            print("error: \(error.localizedDescription)")
        }

        hapticEngine?.start(completionHandler: { (error) in
            if error != nil {
                print("Error starting haptic engine")
            }
        })

        guard let pattern = try? CHHapticPattern(dictionary: hapticDict) else {
            print("Failed to initialize pattern")
            return
        }
        guard let player = try? hapticEngine?.makePlayer(with: pattern) else {
            print("Failed to create player")
            return
        }
        self.hapticPlayer = player

        guard let continuousPattern = try? CHHapticPattern(dictionary: continuousHapticDict) else {
            print("Failed to initialize continuous pattern")
            return
        }
        guard let continuousPlayer = try? hapticEngine?.makePlayer(with: continuousPattern) else {
            print("Failed to create player for continuous pattern")
            return
        }
        self.continuousHapticPlayer = continuousPlayer

//        hapticButton.addTarget(self, action: #selector(dragInside), for: .touchDragInside)

//        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(recognizer:)))
//        view.addGestureRecognizer(panRecognizer)
    }

    @objc
    private func pan(recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: view)

        if recognizer.state == .began {
            lastPoint = nil
            print("STARTING")
            try? continuousHapticPlayer?.start(atTime: 0)
        } else if recognizer.state == .ended {
            print("STOPPING")
            try? continuousHapticPlayer?.stop(atTime: 0)
        }

        if lastPoint != nil {
            let xDistance = abs(lastPoint!.x - point.x)
            let yDistance = abs(lastPoint!.y - point.y)
            let distance = sqrt(xDistance * xDistance + yDistance * yDistance)
//            print("distance: \(distance)")

            let value = Float(distance) / Float(10.0)
            print("value: \(value)")
            let parameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: value, relativeTime: 0)
            try? continuousHapticPlayer?.sendParameters([parameter], atTime: 0)
        }

        lastPoint = point
    }

    @objc
    private func dragInside() {
        print("dragInside")
        playHaptic()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    func playHaptic() {
        do {
            try hapticPlayer?.start(atTime: 0)
        } catch let error {
            print("hapticPlayer start failed: \(error.localizedDescription)")
        }
    }

}

