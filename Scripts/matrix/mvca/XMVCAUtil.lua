---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 15:46
---
local Dir = "XModule/"
XMVCAUtil = {}
function XMVCAUtil.GetAgencyCls(key)
    local path = Dir .. key .. "/" .. key .. "Agency"
    local cls = require(path)
    return cls
end

function XMVCAUtil.GetModelCls(key)
    local path = Dir .. key .. "/" .. key .. "Model"
    local cls = require(path)
    return cls
end

function XMVCAUtil.GetControlCls(key)
    local path = Dir .. key .. "/" .. key .. "Control"
    local cls = require(path)
    return cls
end
