import SceneKit

public extension SCNVector3 {
    func length() -> Float {
        sqrtf(x * x + y * y + z * z)
    }
}

func -(l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z)
}

func +(l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    SCNVector3(l.x + r.x, l.y + r.y, l.z + r.z)
}

func /(l: SCNVector3, r: Float) -> SCNVector3 {
    SCNVector3(l.x / r, l.y / r, l.z / r)
}
