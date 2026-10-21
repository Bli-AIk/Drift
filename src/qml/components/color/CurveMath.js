.pragma library

var MAX_POINTS = 16
var MIN_GAP = 0.01

function clamp01(v) {
    return Math.min(1, Math.max(0, v))
}

function sortedPoints(pts) {
    return pts.slice().sort(function (a, b) { return a.x - b.x })
}

// Fritsch-Carlson monotone tangents; must stay identical to the engine's evaluator.
function tangents(pts) {
    var n = pts.length
    var d = []
    var m = []
    for (var k = 0; k < n - 1; ++k) {
        var dx = pts[k + 1].x - pts[k].x
        d.push(dx > 0 ? (pts[k + 1].y - pts[k].y) / dx : 0)
    }
    if (n < 2)
        return [0]
    m.push(d[0])
    for (var i = 1; i < n - 1; ++i)
        m.push(d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2)
    m.push(d[n - 2])
    for (var j = 0; j < n - 1; ++j) {
        if (d[j] === 0) {
            m[j] = 0
            m[j + 1] = 0
        } else {
            var a = m[j] / d[j]
            var b = m[j + 1] / d[j]
            var s = a * a + b * b
            if (s > 9) {
                var t = 3 / Math.sqrt(s)
                m[j] = t * a * d[j]
                m[j + 1] = t * b * d[j]
            }
        }
    }
    return m
}

function evaluate(pts, x, m) {
    var n = pts.length
    if (n === 0)
        return clamp01(x)
    if (n === 1)
        return clamp01(pts[0].y)
    if (x <= pts[0].x)
        return clamp01(pts[0].y)
    if (x >= pts[n - 1].x)
        return clamp01(pts[n - 1].y)
    var tan = m || tangents(pts)
    var k = 0
    while (k < n - 2 && x > pts[k + 1].x)
        ++k
    var h = pts[k + 1].x - pts[k].x
    var t = (x - pts[k].x) / h
    var t2 = t * t
    var t3 = t2 * t
    var y = (2 * t3 - 3 * t2 + 1) * pts[k].y
          + (t3 - 2 * t2 + t) * h * tan[k]
          + (-2 * t3 + 3 * t2) * pts[k + 1].y
          + (t3 - t2) * h * tan[k + 1]
    return clamp01(y)
}
