import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import "."

Item {
    id: shapeRoot
    anchors.fill: parent

    Shape {
        id: topRightArc
        width: 15
        height: 15
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Config.topbarwidth
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
                x: 15
                y: 15
                radiusX: 15
                radiusY: 15
                useLargeArc: false
                direction: PathArc.Clockwise
            }
            PathLine {
                x: 15
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
        width: 15
        height: 15
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: Config.topbarwidth
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
                x: 15
                y: 0
            }
            PathArc {
                x: 0
                y: 15
                radiusX: 15
                radiusY: 15
                useLargeArc: false
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: 0
                y: 0
            }
            PathLine {
                x: 15
                y: 0
            }
        }
    }

    Shape {
        id: bottomLeftArc
        width: 15
        height: 15
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
                x: 15
                y: 15
                radiusX: 15
                radiusY: 15
                useLargeArc: false
                direction: PathArc.Counterclockwise
            }
            PathLine {
                x: 0
                y: 15
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    Shape {
        id: bottomRightArc
        width: 15
        height: 15
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
                x: 15
                y: 0
            }
            PathArc {
                x: 0
                y: 15
                radiusX: 15
                radiusY: 15
                useLargeArc: false
                direction: PathArc.Clockwise
            }
            PathLine {
                x: 15
                y: 15
            }
            PathLine {
                x: 15
                y: 0
            }
        }
    }
}
