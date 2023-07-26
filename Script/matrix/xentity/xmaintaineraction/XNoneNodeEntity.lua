local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XNoneNodeEntity = XClass(XMaintainerActionNodeEntity, "XNoneNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XNoneNodeEntity:DoEvent(data)
    if not data then return end
    data.player:MarkNodeEvent()
    if data.cb then data.cb() end
end

return XNoneNodeEntity