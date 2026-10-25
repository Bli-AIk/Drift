.pragma library

function pad(n, width) {
    return String(n).padStart(width, "0")
}

// HH:MM:SS:FF at a whole-number frame count per second (non-drop-frame).
function format(seconds, fps) {
    const rate = Math.max(1, Math.round(fps))
    const total = Math.max(0, Math.round(seconds * fps))
    const ff = total % rate
    const secs = Math.floor(total / rate)
    return pad(Math.floor(secs / 3600), 2) + ":" + pad(Math.floor(secs / 60) % 60, 2) + ":"
            + pad(secs % 60, 2) + ":" + pad(ff, 2)
}

function parseClock(text, fps) {
    const parts = text.split(":")
    if (parts.length > 4)
        return NaN
    for (let i = 0; i < parts.length; i++) {
        if (!/^\d+$/.test(parts[i]))
            return NaN
    }
    // Fields count from the right: frames, seconds, minutes, hours.
    const unit = [1 / Math.max(1, Math.round(fps)), 1, 60, 3600]
    let seconds = 0
    for (let i = 0; i < parts.length; i++)
        seconds += parseInt(parts[parts.length - 1 - i], 10) * unit[i]
    return seconds
}

// Absolute: "1:02:03:04" timecode (leading fields optional) or plain seconds ("12", "12.5").
// Relative, with a leading + or -: a whole number is frames ("+12"), a decimal is seconds
// ("-1.5"), a colon form is timecode ("-1:00" is one second). NaN when it is neither.
function parse(text, fps, current) {
    const t = text.trim().replace(",", ".")
    if (t.length === 0)
        return NaN
    const sign = t[0] === "+" ? 1 : (t[0] === "-" ? -1 : 0)
    const body = sign !== 0 ? t.slice(1).trim() : t
    let amount
    if (body.indexOf(":") >= 0)
        amount = parseClock(body, fps)
    else if (/^\d+$/.test(body))
        amount = sign !== 0 ? parseInt(body, 10) / fps : parseInt(body, 10)
    else if (/^\d*\.\d+$/.test(body))
        amount = parseFloat(body)
    else
        return NaN
    if (isNaN(amount))
        return NaN
    return sign !== 0 ? current + sign * amount : amount
}

// M:SS with `decimals` fractional digits, for sources that have no frame rate (audio).
function formatClock(seconds, decimals) {
    const s = Math.max(0, seconds)
    const whole = Math.floor(s)
    let text = Math.floor(whole / 60) + ":" + pad(whole % 60, 2)
    if (decimals > 0)
        text += "." + pad(Math.floor((s - whole) * Math.pow(10, decimals)), decimals)
    return text
}
