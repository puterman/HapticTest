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
    var ahapData: Data?


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

        guard let wav = loadWav() else {
            print("Error loading wav")
            return
        }
        let meanBuffer = downsampledMono(for: wav, rate: 10)

        guard let url = Bundle.main.url(forResource: "test", withExtension: "ahap"),
            let ahapData = try? Data.init(contentsOf: url) else {
            print("Error loading ahap data")
            return
        }
        self.ahapData = ahapData

//        hapticButton.addTarget(self, action: #selector(dragInside), for: .touchDragInside)

//        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(recognizer:)))
//        view.addGestureRecognizer(panRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        view.addGestureRecognizer(tapRecognizer)
    }

    @objc
    private func tapped() {
        playAhap()
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

    func playAhap() {
        do {
            try hapticEngine?.playPattern(from: ahapData!)
        } catch let error {
            print("Failed to play haptic from ahap: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio to AHAP experiment
    func loadWav() -> AudioBuffer? {
        guard let url = Bundle.main.url(forResource: "drums16", withExtension: "wav"),
            let audioBuffer = loadFile(url: url) else {
                print("Error loading wav")
                return nil
        }

        return audioBuffer
    }

    func downsampledMono(for audioBuffer: AudioBuffer, rate: Int) -> [Float] {
        var outputBuffer = [Float]()
        let samplesPerDownsampledSample = Int(44100.0 / Double(rate))
        let outputSampleCount = Int(Double(audioBuffer.sampleCount()) / Double(samplesPerDownsampledSample))


        for i in 0..<Int(outputSampleCount) {
            var sample: Int32 = 0
            var count: Int = 0
            for j in 0..<Int(samplesPerDownsampledSample) {
                let s = audioBuffer.samples.0[i * samplesPerDownsampledSample + j]
                if s > 0 {
                    sample += s
                    count += 1
                }
            }
            let meanSample = Float(sample) / Float(count)
            outputBuffer.append(meanSample / Float(0x8000))
        }

        var minValue = outputBuffer[0]
        var maxValue = outputBuffer[0]

        for val in outputBuffer {
            minValue = min(minValue, val)
            maxValue = max(maxValue, val)
        }

        let range = maxValue - minValue

        for i in 0..<outputBuffer.count {
            let val = outputBuffer[i]
            outputBuffer[i] = (val - minValue) * (1.0 / range)
        }

        return outputBuffer
    }
}

