import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

Item {
    id: shapeRoot
    anchors.fill: parent

    Shape {
        id: topRightArc
        width: Config.sc(15)
        height: Config.sc(15)
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Config.sc(Config.topbarwidth)
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.samples: 0
        layer.smooth: true
        layer.mipmap: true
        asynchronous: true

        ShapePath {
            id: topRight
            strokeWidth: 0
            fillColor: Config.background
            PathMove {
                x: 0
                y: 0
            }
            PathArc {
                x: Config.sc(15)
                y: Config.sc(15)
                radiusX: Config.sc(15)
                radiusY: Config.sc(15)
                useLargeArc: false
                direction: PathArc.Clockwise
            }
            PathLine {
                x: Config.sc(15)
                y: 0
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    Shape {
        id: topLeftArc
        width: Config.sc(15)
        height: Config.sc(15)
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: Config.sc(Config.topbarwidth)
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.samples: 0
        layer.smooth: true
        layer.mipmap: true
        asynchronous: true

        ShapePath {
            id: topLeft
            strokeWidth: 0
            fillColor: Config.background
            PathMove {
                x: Config.sc(15)
                y: 0
            }
            PathArc {
                x: 0
                y: Config.sc(15)
                radiusX: Config.sc(15)
                radiusY: Config.sc(15)
                useLargeArc: false
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: 0
                y: 0
            }
            PathLine {
                x: Config.sc(15)
                y: 0
            }
        }
    }

    Shape {
        id: bottomLeftArc
        width: Config.sc(15)
        height: Config.sc(15)
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.samples: 0
        layer.smooth: true
        layer.mipmap: true
        asynchronous: true

        ShapePath {
            id: bottomLeft
            strokeWidth: 0
            fillColor: Config.background
            PathMove {
                x: 0
                y: 0
            }
            PathArc {
                x: Config.sc(15)
                y: Config.sc(15)
                radiusX: Config.sc(15)
                radiusY: Config.sc(15)
                useLargeArc: false
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: 0
                y: Config.sc(15)
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    Shape {
        id: bottomRightArc
        width: Config.sc(15)
        height: Config.sc(15)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.samples: 0
        layer.smooth: true
        layer.mipmap: true
        asynchronous: true

        ShapePath {
            id: bottomRight
            strokeWidth: 0
            fillColor: Config.background
            PathMove {
                x: Config.sc(15)
                y: 0
            }
            PathArc {
                x: 0
                y: Config.sc(15)
                radiusX: Config.sc(15)
                radiusY: Config.sc(15)
                useLargeArc: false
                direction: PathArc.Clockwise
            }
            PathLine {
                x: Config.sc(15)
                y: Config.sc(15)
            }
            PathLine {
                x: Config.sc(15)
                y: 0
            }
        }
    }
}
