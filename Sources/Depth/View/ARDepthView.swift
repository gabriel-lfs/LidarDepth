import Foundation
import SwiftUI
import RealityKit


//- Tag: ARDepthView
struct ARDepthView: UIViewRepresentable {
    var arProvider: ARProvider
    #if DEBUG
    @EnvironmentObject var debugData: DepthData
    #endif
    
    func makeCoordinator() -> ARReceiver {
        arProvider.debugData = debugData
        return arProvider.arReceiver
    }
    
    func makeUIView(context: UIViewRepresentableContext<ARDepthView>) -> ARView {
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
    
    func updateUIView(_ uiView: UIViewType, context: UIViewRepresentableContext<ARDepthView>) {
        
    }
}
