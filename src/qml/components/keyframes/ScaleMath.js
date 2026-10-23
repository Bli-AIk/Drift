.pragma library

// 100% is the box that fills the canvas on its tighter axis.
function scaleOf(w, h, canvasW, canvasH) {
    return Math.max(w / canvasW, h / canvasH)
}

// Scales the box about `anchor` (fractions of the box). The anchor's offset from the centre turns
// with the clip, so the centre moves by the rotated delta. `start` holds x, y, w, h, scale and
// rot (radians) as they were when the drag began.
function scaledRect(start, scale, anchor) {
    const k = scale / start.scale
    const w = Math.max(1, start.w * k)
    const h = Math.max(1, start.h * k)
    const ex = (anchor.x - 0.5) * (start.w - w)
    const ey = (anchor.y - 0.5) * (start.h - h)
    const cx = start.x + start.w / 2 + ex * Math.cos(start.rot) - ey * Math.sin(start.rot)
    const cy = start.y + start.h / 2 + ex * Math.sin(start.rot) + ey * Math.cos(start.rot)
    return { "x": cx - w / 2, "y": cy - h / 2, "w": w, "h": h, "k": k }
}
