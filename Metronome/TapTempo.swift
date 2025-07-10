

import UIKit

class TapTempo {
    private var taps: [NSDate] = []
    private var intervals: [Int] = []
    
    func resetTaps() {
        taps.removeAll()
        intervals.removeAll()
    }
    
    func addTap(maxTaps: Int) -> Double? {
        let thisTap = NSDate()
        
        if taps.count >= maxTaps {
            taps.remove(at: 0) // once we reach number of taps to average then pop oldest
            taps.append(thisTap)
            if taps.count > 1 {
                intervals.remove(at: 0)
                intervals.append(Int(round(1000000 * thisTap.timeIntervalSince(taps[taps.count - 2] as Date))))
            }
        } else {
            taps.append(thisTap)
            if taps.count > 1 {
                intervals.append(Int(round(1000000 * thisTap.timeIntervalSince(taps[taps.count - 2] as Date))))
            }
        }
        
        if intervals.count < 1 { return nil}
        
        let intervalAverage = Double(intervals.reduce(0, +)) / Double(intervals.count)
        let newReturnInterval = 60 / (intervalAverage / 1000000.0)
        return newReturnInterval
        
    }
}
