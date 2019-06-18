//
//  AudioBuffer.swift
//  bastechno
//
//  Created by Linus Akerlund on 2019-03-06.
//  Copyright © 2019 Puterman. All rights reserved.
//

import Foundation

class AudioBuffer {
    // 2 channels (stereo), 16-bit signed integers, but we use int32 for overflow handling
    // FIXME: This one should be private, and we should define setters and getters for the individual samples.
    // That way, you can't screw around with the number of samples.
    var samples : ([Int32], [Int32])

    init(sample: UnsafePointer<Int16>, sampleCount: UInt32) {
        var channel1 : [Int32] = []
        var channel2 : [Int32] = []

        for i in 0..<sampleCount {
            channel1.append(Int32(sample[Int(i) * 2]))
            channel2.append(Int32(sample[Int(i) * 2] + 1))
        }

        samples.0 = channel1
        samples.1 = channel2
    }

    init(sampleCount: Int) {
        samples.0 = [Int32](repeating: 0, count: sampleCount)
        samples.1 = [Int32](repeating: 0, count: sampleCount)
    }

    func sampleBufferUnsafePointer() -> UnsafePointer<Int16> {
        let sampleCount = samples.0.count
        let outBuffer = UnsafeMutablePointer<Int16>.allocate(capacity: sampleCount * 2)

        guard let samples0max = samples.0.max(),
            let samples1max = samples.1.max(),
            let samples0min = samples.0.min(),
            let samples1min = samples.1.min()
            else {
                fatalError()
        }
        let maxValue = max(samples0max, samples1max)
        let minValue = min(samples0min, samples1min)
        var divisor = Int32(1)
        if maxValue > Int16.max {
            divisor = Int32(ceil(Double(maxValue) / Double(Int16.max)))
        }
        if minValue < Int16.min {
            let divisor0 = Int32(ceil(Double(minValue) / Double(Int16.min)))
            divisor = max(divisor, divisor0)
        }

        for i in 0..<sampleCount {
            outBuffer[i * 2] = Int16(samples.0[i] / divisor)
            outBuffer[i * 2 + 1] = Int16(samples.1[i] / divisor)
        }

        return UnsafePointer<Int16>(outBuffer)
    }

    func sampleCount() -> Int {
        return samples.0.count
    }
}
