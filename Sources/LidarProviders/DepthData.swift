import Accelerate

/**
    Classe para trabalhar com dados de profundidade
 */
public class DepthData: ObservableObject {
    private var data = Array(repeating: Array(repeating: Float(-1), count: 192), count: 256)
    private let matrixSize = Float(96*256)
    
    @Published public var topRightCorner: Float32?
    @Published public var topLeftCorner: Float32?
    @Published public var center: Float32?
    @Published public var bottomRightCorner: Float32?
    @Published public var bottomLeftCorner: Float32?
    @Published public var capturingMetrics: Bool = false
    
    public init() { }

    public func set(x:Int,y:Int,floatData:Float) {
         data[x][y]=floatData
    }
    
    public func get(x:Int,y:Int) -> Float {
        data[x][y]
    }
    
    public func getAll() -> [[Float]] {
        data
    }
    
    public func updateOffsets(depthMap: CVPixelBuffer) {
        let depthWidth = CVPixelBufferGetWidth(depthMap)
        // Busca Altura da matriz
        let depthHeight = CVPixelBufferGetHeight(depthMap)

        // Bloqueia o endereço do pixel buffer
        CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))

        // Converte o buffer para float
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float32>.self)

        // Percorre array de profundidade
        for y in 0...depthHeight - 1 {
            for x in 0...depthWidth - 1 {
                // Define distancia na respectiva posição do array
                self.set(x: x, y: y, floatData: floatBuffer[y * depthWidth + x])
            }
        }
        
    }
    
    public func updateMetrics() {
        self.topLeftCorner = get(x: 0, y: 0)
        self.topRightCorner = get(x: 255, y: 0)
        self.center = get(x: 127, y: 95)
        self.bottomLeftCorner = get(x: 0, y: 191)
        self.bottomRightCorner = get(x: 255, y: 0)
    }
}
