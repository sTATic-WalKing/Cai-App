﻿.pragma library

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

function findAll(objs, key, value) {
    var ret = []
    for (var i = 0; i < objs.length; ++i) {
        if (value === objs[i][key]) {
            ret.push(i)
        }
    }
    return ret
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

function postJSON(url, onComplete, onError, body={}, async=true, xhrs=[]) {
    var xhr = new XMLHttpRequest()
    xhrs.push(xhr)
    var bodyJSON = JSON.stringify(body)
    xhr.onreadystatechange = function() {
        if(xhr.readyState !== 4) {
            return
        }
        if (xhr.status !== 200) {
            console.log(xhr.responseURL, bodyJSON, xhr.status)
            onError(xhr)
            return
        }
        console.log(xhr.responseURL, xhr.responseText.toString())
        onComplete(JSON.parse(xhr.responseText.toString()))
    }
    xhr.open("POST", url, async)
    xhr.send(bodyJSON);
}

function downloadModelData(host, mod, key, onComplete, onError, xhrs) {
    var onPostJSONComplete = function(rsp) {
        var s_key = key
        if (s_key.substr(s_key.length - 1) === "s") {
            s_key += "es"
        } else {
            s_key += "s"
        }
        var keys = rsp[s_key]
        var list = []
        for (var i = 0; i < keys.length; ++i) {
            var onInnerPostJSONComplete = function(rsp) {
                list.push(rsp)
            }
            var content = {}
            content[key] = keys[i]
            postJSON(host + "/" + mod, onInnerPostJSONComplete, onError, content, false, xhrs)
        }
        onComplete(list)
    }
    postJSON(host + "/" + mod +"s", onPostJSONComplete, onError, {}, true, xhrs)
}