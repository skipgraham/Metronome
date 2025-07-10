

import UIKit
import SwiftySound
import AVFoundation

class ViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var wheelImage: UIImageView!
    @IBOutlet weak var wheelBaseImage: UIImageView!
    @IBOutlet weak var tempoLabel: UILabel!
    @IBOutlet weak var wheelContainerView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var tapButton: UIButton!
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var timeSignatureButton: UIButton!
    @IBOutlet weak var tempoNameLabel: UILabel!
    
    
    var rotation: CGFloat = 0.0
    var lastAngle: CGFloat = 0 // previous angle on spinner
    var currentAngle: CGFloat = 0 // current angle on spinner
    var referenceAngle: CGFloat = 0 // angle used as reference to know when to change tempo in UI
    var tempo: Int = 80
    var timer = BPMTimer(bpm: 80)
    var tapTempo = TapTempo()
    var tempoDifferential: CGFloat = 15 // differential set for when tempo increment advances or declines  (10-20)
    var playing: Bool = false
    var beatsPerMeasure: Int = 4
    var beat: Int = 0
    var note: Int = 1
    
    var tapTimer: Timer?
    var timeLeft = 4
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.style
    }
    var style: UIStatusBarStyle = .default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timer.delegate = self
        updateTempoUI(tempo: tempo)
        self.style = .lightContent
        setNeedsStatusBarAppearanceUpdate()
        let pan = UIPanGestureRecognizer(target: self, action:#selector(self.pan))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        self.view.addGestureRecognizer(pan)
    }
    
    override func viewWillDisappear(_ animated: Bool) { //invalidate timer when closing
        super.viewWillDisappear(animated)
        timer.stop()
        tapTimer?.invalidate()
    }
    
    func playMetronomeSound() {
        tempoLabel.textColor = .white
        tempoLabel.blink()
        timer.bpm = Double(tempo * note)
        beat += 1
        if beat == 1 {
            Sound.play(url: getSoundURL(name: "tick-up"))
        } else {
            Sound.play(url: getSoundURL(name: "tick"))
        }
        if beat >= beatsPerMeasure * note {
            beat = 0
        }
    }
    
    func getSoundURL(name: String) -> URL {
        return Bundle.main.url(forResource: name, withExtension: "aac")!
    }
    
    func wheelHaptic(type: Int) {
        let haptic = UIImpactFeedbackGenerator(style: type == 1 ? .light : .heavy)
        haptic.impactOccurred()
    }
    
    func tempoColorChange(wheelMoving: Bool) {
        tempoLabel.textColor = wheelMoving ? UIColor.cyan : UIColor.lightGray
    }
    
    func tempoName(bpm: Int) -> String {
        switch bpm {
        case 30...40:
            return "Grave"
        case 41...60:
            return "Largo"
        case 61...66:
            return "Larghetto"
        case 67...76:
            return "Adagio"
        case 77...108:
            return "Andante"
        case 109...120:
            return "Moderato"
        case 121...156:
            return "Allegro"
        case 157...176:
            return "Vivace"
        case 177...200:
            return "Presto"
        case 201...250:
            return "Prestissimo"
        default:
            return ""
        }
    }
    
    func setTimeSignatureButton() {
        switch beatsPerMeasure {
        case 2:
            timeSignatureButton.setImage(UIImage(named: "button-time-2-4"), for: .normal)
        case 3:
            timeSignatureButton.setImage(UIImage(named: "button-time-3-4"), for: .normal)
        case 4:
            timeSignatureButton.setImage(UIImage(named: "button-time-4-4"), for: .normal)
        case 5:
            timeSignatureButton.setImage(UIImage(named: "button-time-5-4"), for: .normal)
        case 6:
            timeSignatureButton.setImage(UIImage(named: "button-time-6-4"), for: .normal)
        default:
            timeSignatureButton.setImage(UIImage(named: "button-time-4-4"), for: .normal)
        }
        
    }
    
    func setNoteButton() {
        switch note {
        case 1:
            noteButton.setImage(UIImage(named: "button-note-single"), for: .normal)
        case 2:
            noteButton.setImage(UIImage(named: "button-note-double"), for: .normal)
        case 3:
            noteButton.setImage(UIImage(named: "button-note-triplet"), for: .normal)
        default:
            noteButton.setImage(UIImage(named: "button-note-single"), for: .normal)
        }
    }
    
    func updateTempoUI(tempo: Int) {
        tempoLabel.text = String(tempo)
        tempoNameLabel.text = tempoName(bpm: tempo)
    }

    func angle(from location: CGPoint) -> CGFloat {
        let deltaY = location.y - wheelContainerView.center.y
        let deltaX = location.x - view.center.x
        let angle = atan2(deltaY, deltaX) * 180 / .pi
        return angle < 0 ? abs(angle) : 360 - angle
    }
    
    fileprivate let rotateAnimation = CABasicAnimation()
    func rotate(to: CGFloat, duration: Double = 0) {
        rotateAnimation.fromValue = to
        rotateAnimation.toValue = to
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = 0
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.fillMode = CAMediaTimingFillMode.forwards
        rotateAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        wheelImage.layer.add(rotateAnimation, forKey: "transform.rotation.z")
    }
    
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }
    
    fileprivate var startRotationAngle: CGFloat = 0
    @objc func pan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        let center = CGPoint(x: gesture.view!.bounds.size.width / 2.0, y: wheelContainerView.frame.minY + (wheelContainerView.frame.height / 2))
//        let center = CGPoint(x: gesture.view!.bounds.size.width / 2.0, y: gesture.view!.bounds.size.height / 2.0)
        if sqrt(CGPointDistanceSquared(from: center, to: location)) <= wheelImage.frame.width / 2 {
            wheelBaseImage.image = UIImage(named: "wheel-base-teal")
            tempoColorChange(wheelMoving: true)
            lastAngle = currentAngle
            let gestureRotation = CGFloat(angle(from: location)) - startRotationAngle
            switch gesture.state {
            case .began:
                startRotationAngle = angle(from: location)
                lastAngle = startRotationAngle
                referenceAngle = startRotationAngle
            case .changed:
                rotate(to: rotation - (gestureRotation).degreesToRadians)
                currentAngle = angle(from: location)
                updateTempo(currentAngle: currentAngle, lastAngle: lastAngle)
            case .ended:
                rotation -= gestureRotation.degreesToRadians
                wheelBaseImage.image = UIImage(named: "wheel-base-gray")
                tempoColorChange(wheelMoving: false)
                lastAngle = angle(from: location)
            default :
                break
            }
        } else {
            wheelBaseImage.image = UIImage(named: "wheel-base-gray")
        }

    }
    
    @objc func onTimerFires()
    {
        timeLeft -= 1
        
        if timeLeft <= 0 {
            tapTimer?.invalidate()
            timeLeft = 4
            tapTempo.resetTaps()
        }
    }
    
    func resetTimer() {
        tapTimer?.invalidate()
        tapTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(onTimerFires), userInfo: nil, repeats: true)
    }
    
    func updateTempo(currentAngle: CGFloat, lastAngle: CGFloat) {
        var clockwiseZero: Bool = false
        var counterClockwiseZero: Bool = false
        clockwiseZero = lastAngle - currentAngle < -350
        counterClockwiseZero = lastAngle - currentAngle > 350
        if currentAngle > lastAngle && !clockwiseZero { // moving ccw
            if currentAngle - referenceAngle > tempoDifferential || currentAngle - referenceAngle < 0 - tempoDifferential {
                if tempo > 30 {
                    tempo -= 1
                    updateTempoUI(tempo: tempo)
                }
                referenceAngle = lastAngle
                wheelHaptic(type: tempo > 30 ? 1 : 2)
            }
        } else if lastAngle > currentAngle && !counterClockwiseZero { // moving cw
            if referenceAngle - currentAngle > tempoDifferential || referenceAngle - currentAngle < 0 - tempoDifferential {
                if tempo < 250 {
                    tempo += 1
                    referenceAngle = lastAngle
                    updateTempoUI(tempo: tempo)
                }
                referenceAngle = lastAngle
                wheelHaptic(type: tempo < 250 ? 1 : 2)

            }
        }
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        if playing {
            playButton.setImage(UIImage(named: "button-start"), for: .normal)
            playing = false
            beat = 0
            tempoLabel.textColor = .lightGray
            tempoLabel.alpha = 1.0
            timer.stop()
        } else {
            playMetronomeSound()
            playButton.setImage(UIImage(named: "button-stop"), for: .normal)
            playing = true
            timer.start()
        }
    }
    
    @IBAction func tapButtonPressed(_ sender: Any) {
        let newTempo = tapTempo.addTap(maxTaps: 3) // have to add 1 to the actual UI value to have enough intervals to calculate
        if let tappedTempo = newTempo {
            print(tappedTempo)
            if tappedTempo > 250 {
                tempo = 250
            } else if tappedTempo < 30 {
                tempo = 30
            } else {
                tempo = Int(tappedTempo)
            }
            updateTempoUI(tempo: tempo)
        }        
        resetTimer()
    }
    
    @IBAction func noteButtonPressed(_ sender: Any) {
        note = note < 3 ? note + 1 : 1
        setNoteButton()
    }
    
    @IBAction func timeSignatureButtonPressed(_ sender: Any) {
        beatsPerMeasure = beatsPerMeasure < 6 ? beatsPerMeasure + 1 : 2
        setTimeSignatureButton()
    }
    @IBAction func minusButtonPressed(_ sender: Any) {
        if tempo > 30 {
            tempo -= 1
            updateTempoUI(tempo: tempo)
        }
    }
    
    @IBAction func plusButtonPressed(_ sender: Any) {
        if tempo < 250 {
            tempo += 1
            updateTempoUI(tempo: tempo)
        }
    }
    
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension ViewController: BPMTimerDelegate {
    func bpmTimerTicked() {
        playMetronomeSound()
    }
}

extension UIView {
    func blink() {
        self.alpha = 1.0
        UIView.animate(withDuration: 0.7, delay: 0.0, options: [.curveLinear], animations: {self.alpha = 0.15}, completion: nil)
    }
}
