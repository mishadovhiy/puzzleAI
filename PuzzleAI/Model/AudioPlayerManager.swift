//
//  AudioPlayerManager.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import AVFoundation

final class AudioPlayerManager {
    var audioPlayer: AVAudioPlayer?
    var canPlay:Bool = true
    
    deinit {
//        audioPlayer?.stop()
//        audioPlayer = nil
    }
    
    convenience init(type:BundleAudio) {
        self.init(audioName: type.rawValue, isRepeated: type.repeated, valuem: type.valuem)
    }
    
    init(audioName:String, isRepeated:Bool, valuem:Float) {
//        if let soundUrl = Bundle.main.url(forResource: audioName, withExtension: "mp3") {
//            do {
//                audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
//                if isRepeated {
//                    audioPlayer?.numberOfLoops =  -1
//                }
//                audioPlayer?.prepareToPlay()
//                audioPlayer?.volume = valuem
//            } catch {
//#if DEBUG
//                print("Error loading audio file: \(error.localizedDescription)")
//#endif
//            }
//        }
    }

    func play() {
        if canPlay {
//            self.audioPlayer!.play()
        }
    }
    
    func stop() {
//        self.audioPlayer!.stop()
    }
}

extension AudioPlayerManager {
    enum BundleAudio:String {
        case gameMusic, puzzleDrop, puzzleError
        var repeated:Bool {
            return switch self {
            case .gameMusic:true
            default:false
            }
        }
        var valuem:Float {
            if repeated {
                return 1
            } else {
                return 0.2
            }
        }
    }
}
