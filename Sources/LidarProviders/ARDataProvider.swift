/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A utility class that provides processed depth information.
*/

import SceneKit
import MetalKit
import SceneKit.ModelIO
import ARKit
import SwiftUI
import RealityKit

public final class ARProvider: ARDataReceiver {

    // Set the original depth size.
    let origDepthWidth = 256
    let origDepthHeight = 192
    
    public let arReceiver: ARReceiver
    public var lastArData: ARData?
    public var arView: ARView
    
    #if DEBUG
    public var debugData: DepthData? = nil
    #endif
    
    public init() {
        self.arView = ARView()
        self.arReceiver = ARReceiver(arSession: self.arView.session)
        arReceiver.delegate = self
    }
    
    // Start or resume the stream from ARKit.
    public func start() {
        arReceiver.start()
    }
    
    // Pause the stream from ARKit.
    public func pause() {
        arReceiver.pause()
    }
    
    #if DEBUG
    public func switchCaptureMetrics() {
        debugData?.capturingMetrics.toggle()
    }
    #endif
    
    
    public func createModel() -> SCNScene {
        arReceiver.createModel()
    }
    
    // Save a reference to the current AR data and process it.
    func onNewARData(arData: ARData) {
        lastArData = arData
        #if DEBUG
        if !(debugData?.capturingMetrics ?? false) {
            return
        }
        if let depthMap = arData.depthMap {
            DispatchQueue.main.async {
                self.debugData?.updateOffsets(depthMap: depthMap)
                self.debugData?.updateMetrics()
            }
        }
        #endif
    }
}

