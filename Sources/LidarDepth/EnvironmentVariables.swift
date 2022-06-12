/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A utility singleton class that holds a single MTLDevice for the app.
*/

import Foundation
import Metal

class EnvironmentVariables {
    static let shared: EnvironmentVariables = {
       let instance = EnvironmentVariables()
        return instance
    }()
    let metalDevice: MTLDevice
    let dispatchQueue: DispatchQueue
    
    private init() {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Error creating metal device")
        }
        self.dispatchQueue = DispatchQueue(label:"con",attributes:.concurrent)
        self.metalDevice = metalDevice
    }
}

