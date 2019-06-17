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

    @IBOutlet var buttonView: UIView!

    var hapticEngine: CHHapticEngine?
    var hapticPlayer: CHHapticPatternPlayer?

    let hapticDict = [
        CHHapticPattern.Key.pattern: [
            [CHHapticPattern.Key.event: [
                CHHapticPattern.Key.eventType: CHHapticEvent.EventType.hapticContinuous,
                CHHapticPattern.Key.time: 0.001,
                CHHapticPattern.Key.eventDuration: 1.0]
            ]
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

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


    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        do {
            try hapticPlayer?.start(atTime: 5.0)
        } catch let error {
            print("hapticPlayer start failed: \(error.localizedDescription)")
        }
    }

}

