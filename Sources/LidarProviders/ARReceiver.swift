/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A utility class that receives processed depth information.
*/

import Foundation
import SwiftUI
import Combine
import ARKit
import MetalKit
import LidarExtensions

// Receive the newest AR data from an `ARReceiver`.
protocol ARDataReceiver: AnyObject {
    func onNewARData(arData: ARData)
}

//- Tag: ARData
// Store depth-related AR data.
public final class ARData {
    public var depthMap: CVPixelBuffer?
    public var anchors: [ARMeshAnchor]?
    public var capturedImage: CVPixelBuffer?
    public var cameraIntrinsics = simd_float3x3()
    public var cameraResolution = CGSize()
}

// Configure and run an AR session to provide the app with depth-related AR data.
public final class ARReceiver: NSObject, ARSessionDelegate, SCNSceneExportDelegate {
    public var arData = ARData()
    var arSession: ARSession
    weak var delegate: ARDataReceiver?
    
    
    // Configure and start the ARSession.
    public init(arSession: ARSession) {
        self.arSession = arSession
        super.init()
        self.arSession.delegate = self
        start()
    }
    
    // Configure the ARKit session.
    public func start() {
        guard ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth, .smoothedSceneDepth]) else { return }
        // Enable the `sceneDepth` frame semantics.
        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = [.sceneDepth]
        config.sceneReconstruction = .mesh
        config.environmentTexturing = .automatic
        arSession.run(config)
    }
    
    public func pause() {
        arSession.pause()
    }
    
    public func createVertexDescriptor(vertices: ARGeometrySource) -> MDLVertexDescriptor {
        let vertexFormat = MTKModelIOVertexFormatFromMetal(vertices.format)
        
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: vertexFormat, offset: 0, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: vertices.stride)
        
        return vertexDescriptor
    }
    
    func createMash(vertices: ARGeometrySource, submeshes: [MDLSubmesh], vertexBuffer: MDLMeshBuffer) -> MDLMesh {
        let vertexDescriptor = createVertexDescriptor(vertices: vertices)
        return MDLMesh(vertexBuffer: vertexBuffer, vertexCount: vertices.count, descriptor: vertexDescriptor, submeshes: submeshes)
    }
    
    public func parseVerticesGeometryToWorldSpace(vertices: ARGeometrySource, geometry: ARMeshGeometry, meshAnchor: ARMeshAnchor) -> (UnsafeMutableRawPointer, Int) {
        let verticesPointer = vertices.buffer.contents()
        
        for vertexIndex in 0..<vertices.count {

            // Extracting the current vertex with an extension method provided by Apple in Extensions.swift
            let vertex = geometry.vertex(at: UInt32(vertexIndex))

            // Building a transform matrix with only the vertex position
            // and apply the mesh anchors transform to convert into world space
            var vertexLocalTransform = matrix_identity_float4x4
            vertexLocalTransform.columns.3 = SIMD4<Float>(x: vertex.0, y: vertex.1, z: vertex.2, w: 1)
            let vertexWorldPosition = (meshAnchor.transform * vertexLocalTransform).position

            // Writing the world space vertex back into it's position in the vertex buffer
            let vertexOffset = vertices.offset + vertices.stride * vertexIndex
            let componentStride = vertices.stride / 3
            verticesPointer.storeBytes(of: vertexWorldPosition.x, toByteOffset: vertexOffset, as: Float.self)
            verticesPointer.storeBytes(of: vertexWorldPosition.y, toByteOffset: vertexOffset + componentStride, as: Float.self)
            verticesPointer.storeBytes(of: vertexWorldPosition.z, toByteOffset: vertexOffset + (2 * componentStride), as: Float.self)
        }
        let byteCountVertices = vertices.count * vertices.stride
        
        return (verticesPointer, byteCountVertices)
    }
    
    public func createVertexBuffer(vertices: ARGeometrySource, geometry: ARMeshGeometry, meshAnchor: ARMeshAnchor, allocator: MTKMeshBufferAllocator) -> MDLMeshBuffer {
        let (verticesPointer, verticesByteCount) = parseVerticesGeometryToWorldSpace(
            vertices: vertices, geometry: geometry, meshAnchor: meshAnchor
        )
        return allocator.newBuffer(with: Data(bytesNoCopy: verticesPointer, count: verticesByteCount, deallocator: .none), type: .vertex)
    }
    
    public func createSubmash(faces: ARGeometryElement, indexBuffer: MDLMeshBuffer) -> MDLSubmesh {
        let material = MDLMaterial(name: "mat1", scatteringFunction: MDLPhysicallyPlausibleScatteringFunction())
        
        let indexCount = faces.count * faces.indexCountPerPrimitive
        return MDLSubmesh(indexBuffer: indexBuffer, indexCount: indexCount, indexType: .uInt32, geometryType: .triangles, material: material)
    }
    
    public func createIndexBuffer(faces: ARGeometryElement, allocator: MTKMeshBufferAllocator) -> MDLMeshBuffer {
        let facesPointer = faces.buffer.contents()
        let facesByteCount = faces.count * faces.indexCountPerPrimitive * faces.bytesPerIndex
        
        return allocator.newBuffer(with: Data(bytesNoCopy: facesPointer, count: facesByteCount, deallocator: .none), type: .index)
    }
    
    public func createModel() -> SCNScene {
        let allocator = MTKMeshBufferAllocator(device: EnvironmentVariables.shared.metalDevice)
        let asset = MDLAsset(bufferAllocator: allocator)
        guard let anchors = self.arData.anchors else { fatalError("No anchors were found") }
        
        for meshAnchor in anchors {
            // Recupera as geometrias da cena AR
            let geometry = meshAnchor.geometry
            
            // Cria um buffer de indices que serão utilizadas como a geometria do objeto 3D
            // e adiciona em uma sub mash
            let faces = geometry.faces
            let indexBuffer = createIndexBuffer(faces: faces, allocator: allocator)
            let submesh = createSubmash(faces: faces, indexBuffer: indexBuffer)
            
            // Cria os vertices que conectam as faces e apartir deles
            // cria a mash principal que será adicionada ao modelo 3D
            let vertices = geometry.vertices
            let vertexBuffer = createVertexBuffer(vertices: vertices, geometry: geometry, meshAnchor: meshAnchor, allocator: allocator)
            let mesh = createMash(vertices: vertices, submeshes: [submesh], vertexBuffer: vertexBuffer)
            
            // Adiciona a mash gerada ao modelo 3D
            asset.add(mesh)

        }
        
        return SCNScene(mdlAsset: asset)
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if(frame.sceneDepth != nil) {
            arData.depthMap = frame.sceneDepth!.depthMap
            arData.anchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
            arData.capturedImage = frame.capturedImage
            arData.cameraIntrinsics = frame.camera.intrinsics
            arData.cameraResolution = frame.camera.imageResolution
            delegate?.onNewARData(arData: arData)
        }
    }
}
