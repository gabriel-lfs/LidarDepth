import Foundation
import SwiftUI
import RealityKit
import LidarProviders


//- Tag: ARDepthView
public struct ARDepthView: UIViewRepresentable {
    public var arProvider: ARProvider
    #if DEBUG
    @EnvironmentObject public var debugData: LidarProviders.DepthData
    #endif
    
    public init(arProvider: ARProvider) {
        self.arProvider = arProvider
    }
    
    public func makeCoordinator() -> ARReceiver {
        #if DEBUG
        arProvider.debugData = debugData
        #endif
        
        return arProvider.arReceiver
    }
    
    public func makeUIView(context: UIViewRepresentableContext<ARDepthView>) -> ARView {
        let arView = arProvider.arView
        
        arView.session.delegate = context.coordinator
        
        arView.environment.sceneUnderstanding.options = []
        // Turn on occlusion from the scene reconstruction's mesh.
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        // Turn on physics for the scene reconstruction's mesh.
        arView.environment.sceneUnderstanding.options.insert(.physics)
        // Display a debug visualization of the mesh.
        arView.debugOptions.insert(.showSceneUnderstanding)
        // For performance, disable render options that are not required for this app.
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
        // Manually configure what kind of AR session to run
        arView.automaticallyConfigureSession = false
        
        return arView
    }
    
    public func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<ARDepthView>) {
        
    }
}
