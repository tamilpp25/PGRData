local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XUnKnowNodeEntity = XClass(XMaintainerActionNodeEntity, "XUnKnowNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUnKnowNodeEntity:DoEvent(data)
    if not data then return end
    data.player:MarkNodeEvent()
    if data.cb then data.cb() end
end

function XUnKnowNodeEntity:EventRequest(mainUi, player, cb)
    XDataCenter.MaintainerActionManager.NodeEventRequest(function (data)
            local node = XDataCenter.MaintainerActionManager.CreateNode(data)
            node:OpenHintTip(function ()
                    local tmpData = {
                        player = player,
                        cb = cb,
                        mainUi = mainUi
                    }
                    node:DoEvent(tmpData)
                end)
        end,function (data)
            XDataCenter.MaintainerActionManager.CreateNode(data)
            player:MarkNodeEvent()
            if cb then cb() end
        end)
end

return XUnKnowNodeEntity