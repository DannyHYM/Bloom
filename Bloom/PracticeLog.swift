import SwiftData
import Foundation

@Model
class PracticeLog {
    var date: Date
    var courseTitle: String
    var setsCompleted: Int
    
    init(date: Date = .now, courseTitle: String, setsCompleted: Int) {
        self.date = date
        self.courseTitle = courseTitle
        self.setsCompleted = setsCompleted
    }
}
