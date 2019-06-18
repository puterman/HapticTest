//
//  Copyright © 2019 Puterman. All rights reserved.
//

import AudioToolbox

func loadFile(url: URL) -> AudioBuffer? {
    var _audioFile: AudioFileID?
    let result = AudioFileOpenURL(url as CFURL, .readPermission, 0, &_audioFile)
    guard let audioFile = _audioFile else {
        print("audioFile is nil")
        return nil
    }

    defer {
        AudioFileClose(audioFile)
    }

    // Get properties
    var outData = AudioStreamBasicDescription()
    var outDataSize: UInt32 = 0
    AudioFileGetPropertyInfo(audioFile, kAudioFilePropertyDataFormat, &outDataSize, nil)

    AudioFileGetProperty(audioFile, kAudioFilePropertyDataFormat, &outDataSize, &outData)

    // Read audio data in packets
    let chunkSize = Int(outData.mBytesPerPacket) * 4096 * 1024
    let outBuffer = UnsafeMutableRawPointer.allocate(byteCount: chunkSize, alignment: 1)
    var readByteCount: UInt32 = UInt32(chunkSize)
    AudioFileReadBytes(audioFile, false, 0, &readByteCount, outBuffer)

    let outBufferInt16Pointer = outBuffer.bindMemory(to: Int16.self, capacity: Int(readByteCount / 2))

    return AudioBuffer(sample: outBufferInt16Pointer, sampleCount: readByteCount / (2 * 2))
}

func saveFile(url: URL, audioBuffer: AudioBuffer) {
    let samples = audioBuffer.sampleBufferUnsafePointer()

    var audioStreamDescription = AudioStreamBasicDescription(mSampleRate: 44100,
                                                             mFormatID: kAudioFormatLinearPCM,
                                                             mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
                                                             mBytesPerPacket: 4,
                                                             mFramesPerPacket: 1,
                                                             mBytesPerFrame: 4,
                                                             mChannelsPerFrame: 2,
                                                             mBitsPerChannel: 16,
                                                             mReserved: 0)

    var _outAudioFile: AudioFileID?
    AudioFileCreateWithURL(url as CFURL, kAudioFileWAVEType, &audioStreamDescription, [.eraseFile], &_outAudioFile)

    guard let outAudioFile = _outAudioFile else {
        print("outAudioFile is nil")
        return
    }

    var writeByteCount = UInt32(audioBuffer.sampleCount() * 2 * 2)
    AudioFileWriteBytes(outAudioFile, false, 0, &writeByteCount, samples)

    AudioFileClose(outAudioFile)
}
