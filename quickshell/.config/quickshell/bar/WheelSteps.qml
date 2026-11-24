import QtQuick

// Wheel input as whole steps: step(1) for each notch up, step(-1) for each
// notch down. Movement is summed, so high-resolution wheels and touchpads,
// which send many small events per notch, step at the same rate as a plain
// wheel. Qt reports Wayland wheel events from a "touchpad" device, which
// WheelHandler ignores by default, so both device types are accepted.
WheelHandler {
    id: root

    property real accumulated: 0

    signal step(int direction)

    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: event => {
        accumulated += event.angleDelta.y;
        while (Math.abs(accumulated) >= 120) {
            const direction = accumulated > 0 ? 1 : -1;
            accumulated -= direction * 120;
            root.step(direction);
        }
    }
}
