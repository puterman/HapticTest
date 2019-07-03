import UIKit
import CoreHaptics

class LineViewController: UIViewController {

    @IBOutlet var line: UIView!
    var lastYPos: CGFloat?
    var hapticEngine: CHHapticEngine?
    var patternPlayer: CHHapticPatternPlayer?


    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarItem.title = "Line"

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

        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0, duration: 0.01)

        guard let pattern = try? CHHapticPattern(events: [event], parameterCurves: []) else {
            print("Error creating pattern")
            return
        }

        guard let patternPlayer = try? hapticEngine?.makePlayer(with: pattern) else {
            print("Error creating pattern")
            return
        }
        self.patternPlayer = patternPlayer

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(recognizer:)))
        view.addGestureRecognizer(panRecognizer)
    }

    @objc
    private func pan(recognizer: UIGestureRecognizer) {
        let y = line.frame.origin.y
        let yPos = recognizer.location(in: view).y

        if recognizer.state == .began {

            lastYPos = yPos
        } else if recognizer.state == .ended {

            lastYPos = nil
        } else if recognizer.state == .changed {
            guard let lastY = lastYPos else {
                return
            }
            if (yPos < y && lastY >= y) || (yPos > y && lastY <= y) {
                do {
                    try patternPlayer?.start(atTime: 0)
                } catch let error {
                    print("Error playing pattern: \(error.localizedDescription)")
                }

                line.backgroundColor = .yellow
                UIView.animate(withDuration: 0.5) {
                    self.line.backgroundColor = .black
                }
            }

            lastYPos = yPos
        }
    }
}
