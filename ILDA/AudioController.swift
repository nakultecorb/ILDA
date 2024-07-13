//
//  AudioController.swift
//  Melody
//
//  Created by Nakul Sharma on 19/06/24.
//
import AVFoundation
enum VolumeFlow{
    case up, down
}

class AudioController {
    private var audioEngine: AVAudioEngine
    private var leftPlayerNode: AVAudioPlayerNode
    private var rightPlayerNode: AVAudioPlayerNode
    private var leftMixerNode: AVAudioMixerNode
    private var rightMixerNode: AVAudioMixerNode
    private var audioFile: AVAudioFile?
    
    var max: Double = 0.7
    var min: Double = 0.3
    
    var volumeFlow: VolumeFlow = .down
    var stepValue: Double = 0.1
    
    var left: Double = 0.7
    var right: Double = 0.3
    
    var frequency:Double = 1.0
    
    var timer: Timer?
    
    var isLooping: Bool = false
    init() {
        audioEngine = AVAudioEngine()
        leftPlayerNode = AVAudioPlayerNode()
        rightPlayerNode = AVAudioPlayerNode()
        leftMixerNode = AVAudioMixerNode()
        rightMixerNode = AVAudioMixerNode()

        // Attach nodes to the audio engine
        audioEngine.attach(leftPlayerNode)
        audioEngine.attach(rightPlayerNode)
        audioEngine.attach(leftMixerNode)
        audioEngine.attach(rightMixerNode)

        // Connect nodes
        audioEngine.connect(leftPlayerNode, to: leftMixerNode, format: nil)
        audioEngine.connect(leftMixerNode, to: audioEngine.mainMixerNode, format: nil)
        audioEngine.connect(rightPlayerNode, to: rightMixerNode, format: nil)
        audioEngine.connect(rightMixerNode, to: audioEngine.mainMixerNode, format: nil)
    }
    
    func loadAudioFile(_ audioFileName: String){
        // Load the audio file
        if let url = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") {
            do {
                audioFile = try AVAudioFile(forReading: url)
            } catch {
                print("Error loading audio file: \(error.localizedDescription)")
            }
        }
    }
    
    func playTone() {
        scheduleFileLeftNode()
        scheduleFileRightNode()
        volumeFlow = .down
        do {
            try audioEngine.start()
            leftPlayerNode.play()
            rightPlayerNode.play()
            leftPlayerNode.volume = 1.0
            leftMixerNode.outputVolume = 1.0
            rightPlayerNode.volume = 1.0
            rightMixerNode.outputVolume = 1.0
            leftMixerNode.pan = -1
            leftPlayerNode.pan = -1
            rightMixerNode.pan = 1
            rightPlayerNode.pan = 1
            isLooping = true
        }
        catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
        
        setVolume(leftVolume: left, rightVolume: right)
        resetTimer(self.frequency)
    }
    
    func scheduleFileLeftNode() {
        guard let audioFile = self.audioFile else{ return }
        leftPlayerNode.scheduleFile(audioFile, at: nil) {
            if self.isLooping{
                DispatchQueue.main.async {
                    print("Repeat loaded left Node")
                    self.scheduleFileLeftNode()
                }
            }
        }
    }
    
    func scheduleFileRightNode() {
        guard let audioFile = self.audioFile else{ return }
        rightPlayerNode.scheduleFile(audioFile, at: nil) {
            if self.isLooping{
                DispatchQueue.main.async {
                    print("Repeat loaded right node")
                    self.scheduleFileRightNode()
                }
            }
        }
    }
    
    func stopTone(){
        isLooping = false
        leftPlayerNode.stop()
        rightPlayerNode.stop()
        stopTimer()
        volumeFlow = .down
    }
    
    func pauseTone(){
        leftPlayerNode.pause()
        rightPlayerNode.pause()
        stopTimer()
    }
    func resumeTone(){
        leftPlayerNode.play()
        rightPlayerNode.play()
        resetTimer(self.frequency)
    }
    
    func setFrequency(_ frequency: Double){
        self.frequency = frequency
        resetTimer(frequency)
    }
    
    private func stopTimer(){
        timer?.invalidate()
        timer = nil
    }
    
    func pauseTimer(){
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer(_ frequency: Double){
        let diff = (max - min)/stepValue
        let ffFreq = frequency*diff
        if ffFreq == 0{return}
        let timerFrequency = 1/(ffFreq)
        print("timerFrequency: \(timerFrequency)")
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: timerFrequency, target: self, selector: #selector(self.timerHandler), userInfo: nil, repeats: true)
    }
    
    func setMinMaxIntensity(_ min: Double, max: Double, isPlaying: Bool = false){
        
        self.min = min
        self.max = max
        
        if isPlaying{
            resetTimer(self.frequency)
        }
        
    }
    
    private func setVolume(leftVolume: Double? = nil, rightVolume: Double? = nil) {
        if let leftVolume = leftVolume {
            leftPlayerNode.volume = Float(leftVolume)
            leftMixerNode.outputVolume = Float(leftVolume)
            leftMixerNode.pan = (0 - Float(leftVolume))
            leftPlayerNode.pan = (0 - Float(leftVolume))
        }
        
        if let rightVolume = rightVolume {
            rightPlayerNode.volume = Float(rightVolume)
            rightMixerNode.outputVolume = Float(rightVolume)
            rightMixerNode.pan = Float(rightVolume)
            rightPlayerNode.pan = Float(rightVolume)
        }
    }

    func forceSetTheVolumeFlow(){
        if left < min || right > max{
            volumeFlow = .up
        }
        else if left > max || right < min{
            volumeFlow = .down
        }
    }
    
    @objc func timerHandler(){
        if volumeFlow == .down{ // down flow
            left = Swift.max(min, (left-stepValue)) // -= stepValue
            right = Swift.min(max, right+stepValue) //+= stepValue
            setVolume(leftVolume: left, rightVolume: right)
            if left == min && right == max{
                volumeFlow = .up
            }
        }
        else{
//            left += stepValue
//            right -= stepValue
            left = Swift.min(max, (left+stepValue))
            right = Swift.max(min, right-stepValue)
            setVolume(leftVolume: left, rightVolume: right)
            if left >= max || right <= min{
                volumeFlow = .down
            }
        }
        
        print("left:  \(String(format: "%0.1f", left)) right: \(String(format: "%0.1f", right)) volume flow : \(volumeFlow), min: \(String(format: "%0.1f", min)) max: \(String(format: "%0.1f", max))")
    }
    
    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
    }
}
