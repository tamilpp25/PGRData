local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XDirectionChangeNodeEntity = XClass(XMaintainerActionNodeEntity, "XDirectionChangeNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XDirectionChangeNodeEntity:DoEvent(data)
    if not data then return end
    data.player:DoChangeDirection()
    data.player:MarkNodeEvent()
    if data.cb then data.cb() end
end

return XDirectionChangeNodeEntity