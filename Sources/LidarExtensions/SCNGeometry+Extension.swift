import Foundation
import SceneKit
import ARKit

public extension SCNGeometry {
    convenience init(geometry: ARMeshGeometry, camera: ARCamera, modelMatrix: simd_float4x4, needTexture: Bool = false) {
        func convertType(type: ARGeometryPrimitiveType) -> SCNGeometryPrimitiveType {
            switch type {
            case .line:
                return .line
            case .triangle:
                return .triangles
            @unknown default:
                fatalError("unknown type")
            }

        }
        func calcTextureCoordinates(vertices: ARGeometrySource, camera: ARCamera, modelMatrix: simd_float4x4) ->  SCNGeometrySource? {
            func getVertex(at index: UInt32) -> SIMD3<Float> {
                assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
                let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
                let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                return vertex
            }
            func buildCoordinates() -> [CGPoint]? {
                let size = camera.imageResolution
                let textureCoordinates = (0..<vertices.count).map { i -> CGPoint in
                    let vertex = getVertex(at: UInt32(i))
                    let vertex4 = vector_float4(vertex.x, vertex.y, vertex.z, 1)
                    let world_vertex4 = simd_mul(modelMatrix, vertex4)
                    let world_vector3 = simd_float3(x: world_vertex4.x, y: world_vertex4.y, z: world_vertex4.z)
                    let pt = camera.projectPoint(world_vector3,
                            orientation: .portrait,
                            viewportSize: CGSize(
                                    width: CGFloat(size.height),
                                    height: CGFloat(size.width)))
                    let v = 1.0 - Float(pt.x) / Float(size.height)
                    let u = Float(pt.y) / Float(size.width)
                    return CGPoint(x: CGFloat(v), y: CGFloat(u))
                }
                return textureCoordinates
            }
            guard let texcoords = buildCoordinates() else {return nil}
            
            let result = SCNGeometrySource(textureCoordinates: texcoords)

            return result
        }
        let vertices = geometry.vertices
        let normals = geometry.normals
        let faces = geometry.faces
        let verticesSource = SCNGeometrySource(buffer: vertices.buffer, vertexFormat: vertices.format, semantic: .vertex, vertexCount: vertices.count, dataOffset: vertices.offset, dataStride: vertices.stride)
        let normalsSource = SCNGeometrySource(buffer: normals.buffer, vertexFormat: normals.format, semantic: .normal, vertexCount: normals.count, dataOffset: normals.offset, dataStride: normals.stride)
        let data = Data(bytes: faces.buffer.contents(), count: faces.buffer.length)
        let facesElement = SCNGeometryElement(data: data, primitiveType: convertType(type: faces.primitiveType), primitiveCount: faces.count, bytesPerIndex: faces.bytesPerIndex)
        var sources = [verticesSource, normalsSource]
        if needTexture {
            let textureCoordinates = calcTextureCoordinates(vertices: vertices, camera: camera, modelMatrix: modelMatrix)!
            sources.append(textureCoordinates)
        }
        self.init(sources: sources, elements: [facesElement])
    }
}
