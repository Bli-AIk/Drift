import QtQuick
import "KeyframesModel.js" as Model

QtObject {
    id: root

    property var ids: ({})
    property int count: 0
    property int revision: 0

    function replace(newRefs) {
        const next = {}
        for (let i = 0; i < newRefs.length; ++i)
            next[Model.keyId(newRefs[i].prop, newRefs[i].seconds)] = { "prop": newRefs[i].prop, "seconds": newRefs[i].seconds }
        ids = next
        count = Object.keys(next).length
        revision++
    }

    function set(newRefs) {
        replace(newRefs)
    }

    function add(newRefs) {
        replace(refs().concat(newRefs))
    }

    function toggle(ref) {
        if (has(ref.prop, ref.seconds)) {
            const id = Model.keyId(ref.prop, ref.seconds)
            replace(refs().filter(function (r) { return Model.keyId(r.prop, r.seconds) !== id }))
        } else {
            add([ref])
        }
    }

    function clear() {
        if (count === 0)
            return
        replace([])
    }

    function refs() {
        return Object.keys(ids).map(function (k) { return ids[k] })
    }

    function has(prop, seconds) {
        void revision
        return ids[Model.keyId(prop, seconds)] !== undefined
    }

    function span() {
        const all = refs()
        if (all.length === 0)
            return null
        let start = all[0].seconds
        let end = start
        for (let i = 1; i < all.length; ++i) {
            start = Math.min(start, all[i].seconds)
            end = Math.max(end, all[i].seconds)
        }
        return { "start": start, "end": end }
    }

    function props() {
        const seen = {}
        const out = []
        const all = refs()
        for (let i = 0; i < all.length; ++i) {
            if (!seen[all[i].prop]) {
                seen[all[i].prop] = true
                out.push(all[i].prop)
            }
        }
        return out
    }
}
