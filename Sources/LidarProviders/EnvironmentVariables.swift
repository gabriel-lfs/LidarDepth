/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A utility singleton class that holds a single MTLDevice for the app.
*/

import Foundation
import Metal

public class EnvironmentVariables {
    public static let shared: EnvironmentVariables = {
       let instance = EnvironmentVariables()
        return instance
    }()
    public let metalDevice: MTLDevice
    public let dispatchQueue: DispatchQueue
    
    private init() {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("Error creating metal device")
        }
        self.dispatchQueue = DispatchQueue(label:"con",attributes:.concurrent)
        self.metalDevice = metalDevice
    }
}

