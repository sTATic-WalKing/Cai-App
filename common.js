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

    // console.log("before", before, "current", current, "toRemove", toRemove, "toAppend", toAppend, "inter", inter, "toUpdate", toUpdate)
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
        // console.log(xhr.responseURL, xhr.responseText.toString())
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
            var onInnerError = function(xhr) {
                if (xhr.status !== 404) {
                    onError(xhr)
                }
            }
            var content = {}
            content[key] = keys[i]
            postJSON(host + "/" + mod, onInnerPostJSONComplete, onInnerError, content, false, xhrs)
        }
        onComplete(list)
    }
    postJSON(host + "/" + mod +"s", onPostJSONComplete, onError, {}, true, xhrs)
}

function removeAndNotify(root, mod, key, value) {
    var copy = root[mod].concat()
    var index = find(copy, key, value)
    if (index !== -1) {
        copy.splice(index, 1)
        root[mod] = copy
    }
}

function updateAndNotify(root, mod, key, data) {
    var copy = root[mod].concat()
    var index = find(copy, key, data[key])
    if (index === -1) {
        copy.push(data)
    } else {
        copy[index] = data
    }
    root[mod] = copy
}

function sameDate(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
}

function date2ShortText(date) {
    if (sameDate(date, new Date())) {
        return date.toLocaleTimeString()
    } else {
        return date.toLocaleDateString()
    }
}

function stamp2SpanText(stamp, unitOfTime) {
    var day = parseInt(stamp / (24 * 60 * 60))
    var second = stamp - day * (24 * 60 * 60)
    var hour = parseInt(second / (60 * 60))
    second -= hour * (60 * 60)
    var minute = parseInt(second / 60)
    second -= minute * 60
    var ret = ""
    if (day > 0) {
        ret += day + " " + unitOfTime[4] + " "
    }
    if (hour > 0) {
        ret += hour + " " + unitOfTime[3] + " "
    }
    if (minute > 0) {
        ret += minute + " " + unitOfTime[2] + " "
    }
    if (second > 0) {
        ret += second + " " + unitOfTime[1] + " "
    }

    return  ret
}

function findAssociatedViews(address, views) {
    var ret = []
    for (var i = 0; i < views.length; ++i) {
        var view = views[i]
        if (find(view["states"], "address", address) !== -1) {
            ret.push(i)
        }
    }
    return ret
}

function viewFindAssociatedAutos(uid, autos) {
    return findAll(autos, "view", uid)
}

function furnitureFindAssociatedAutos(address, views, autos) {
    var ret = []
    var associatedViews = findAssociatedViews(address, views)
    for (var i = 0; i < associatedViews.length; ++i) {
        ret = ret.concat(viewFindAssociatedAutos(views[associatedViews[i]]["uid"], autos))
    }
    return ret
}
