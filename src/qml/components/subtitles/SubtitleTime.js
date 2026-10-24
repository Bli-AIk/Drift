.pragma library

function pad(n, width) {
    return String(n).padStart(width, "0")
}

function format(seconds) {
    const totalMs = Math.max(0, Math.round(seconds * 1000))
    const ms = totalMs % 1000
    const s = Math.floor(totalMs / 1000) % 60
    const m = Math.floor(totalMs / 60000) % 60
    const h = Math.floor(totalMs / 3600000)
    return pad(h, 2) + ":" + pad(m, 2) + ":" + pad(s, 2) + "." + pad(ms, 3)
}

function parse(text) {
    const t = text.trim().replace(",", ".")
    if (/^\d+(\.\d+)?$/.test(t))
        return parseFloat(t)
    const parts = t.split(":")
    if (parts.length < 2 || parts.length > 3)
        return NaN
    for (let i = 0; i < parts.length; ++i) {
        if (!/^\d+(\.\d+)?$/.test(parts[i]) || (i < parts.length - 1 && parts[i].indexOf(".") >= 0))
            return NaN
    }
    let total = 0
    for (let i = 0; i < parts.length; ++i)
        total = total * 60 + parseFloat(parts[i])
    return total
}
