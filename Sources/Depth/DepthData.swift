import Accelerate

/**
    Classe para trabalhar com dados de profundidade
 */
class DepthData: ObservableObject {
    private var data = Array(repeating: Array(repeating: Float(-1), count: 192), count: 256)
    private let matrixSize = Float(96*256)
    
    @Published var topRightCorner: Float32?
    @Published var topLeftCorner: Float32?
    @Published var center: Float32?
    @Published var bottomRightCorner: Float32?
    @Published var bottomLeftCorner: Float32?
    @Published var capturingMetrics: Bool = false

    func set(x:Int,y:Int,floatData:Float) {
         data[x][y]=floatData
    }
    
    func get(x:Int,y:Int) -> Float {
        data[x][y]
    }
    
    func getAll() -> [[Float]] {
        data
    }
    
    func updateOffsets(depthMap: CVPixelBuffer) {
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
    
    func updateMetrics() {
        self.bottomLeftCorner = get(x: 0, y: 0)
        self.bottomRightCorner = get(x: 255, y: 0)
        self.center = get(x: 127, y: 95)
        self.topLeftCorner = get(x: 0, y: 191)
        self.topRightCorner = get(x: 255, y: 0)
    }
}
