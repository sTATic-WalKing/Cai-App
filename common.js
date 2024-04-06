.pragma library

function difference(a, b) {
    var ret = []
    for (var i = 0; i < a.length; ++i) {
        if (b.indexOf(a[i]) === -1) {
            ret.push(a[i])
        }
    }
    return ret
}

function intersection(a, b) {
    var ret = []
    for (var i = 0; i < a.length; ++i) {
        if (b.indexOf(a[i]) !== -1) {
            ret.push(a[i])
        }
    }
    return ret
}

function compare(a, b) {
    var aKeys = Object.keys(a)
    var bKeys = Object.keys(b)
    if (aKeys.length !== bKeys.length) {
        return false
    }
    var aEntries = Object.entries(a)
    for (var i = 0; i < aEntries.length; ++i) {
        var key = aEntries[i][0]
        var aValue = aEntries[i][1]
        if (aValue !== b[key]) {
            return false
        }
    }
    return true
}

function find(objs, key, value) {
    for (var i = 0; i < objs.length; ++i) {
        if (value === objs[i][key]) {
            return i
        }
    }
    return -1
}

function findModelData(listModel, mod, key, value) {
    for (var i = 0; i < listModel.count; ++i) {
        if (value === listModel.get(i)[mod][key]) {
            return i
        }
    }
    return -1
}

function updateModelData(listModel, objs, mod, key) {
    var before = []
    for (var i = 0; i < listModel.count; ++i) {
        before.push(listModel.get(i)[mod][key])
    }
    var current = []
    for (i = 0; i < objs.length; ++i) {
        current.push(objs[i][key])
    }
    var toRemove = difference(before, current)
    var toAppend = difference(current, before)
    var inter = intersection(before, current)
    var toUpdate = []
    for (i = 0; i < inter.length; ++i) {
        var a = findModelData(listModel, mod, key, inter[i])
        var b = find(objs, key, inter[i])
        if (!compare(listModel.get(a)[mod], objs[b])) {
            toUpdate.push(inter[i])
        }
    }

    for (i = 0; i < toUpdate.length; ++i) {
        var tmp = {}
        tmp[mod] = objs[find(objs, key, toUpdate[i])]
        listModel.set(findModelData(listModel, mod, key, toUpdate[i]), tmp)
    }
    for (i = 0; i < toRemove.length; ++i) {
        listModel.remove(findModelData(listModel, mod, key, toRemove[i]))
    }
    for (i = 0; i < toAppend.length; ++i) {
        tmp = {}
        tmp[mod] = objs[find(objs, key, toAppend[i])]
        listModel.append(tmp)
    }

    console.log("before", before, "current", current, "toRemove", toRemove, "toAppend", toAppend, "inter", inter, "toUpdate", toUpdate)
}
