local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XWarehouseNodeEntity = XClass(XMaintainerActionNodeEntity, "XWarehouseNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XWarehouseNodeEntity:Ctor()
    self.RewardId = 0
end

function XWarehouseNodeEntity:GetRewardId()
    return self.RewardId
end

function XWarehouseNodeEntity:GetRewardTitle()
    return CS.XTextManager.GetText("MaintainerActionWarehouseReward")
end

function XWarehouseNodeEntity:OpenDescTip()
    XLuaUiManager.Open("UiFubenMaintaineractionDetailsTips", self, true)
end

function XWarehouseNodeEntity:DoEvent(data)
    if not data then return end
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    gameData:PlusWarehouseFinishCount()

    XLuaUiManager.Open("UiFubenMaintaineractionTreasurechest", self:GetRewardId(), nil,
        CSTextManagerGetText("MaintainerActionWarehouseGetTitleText"),
        CSTextManagerGetText("MaintainerActionWarehouseGetSubTitleText"),
        gameData:GetWarehouseFinishCount(),
        gameData:GetMaxWarehouseFinishCount(),function ()
            local IsAllComplete = XDataCenter.MaintainerActionManager.CheckIsAllComplete()
            if IsAllComplete then
                XDataCenter.MaintainerActionManager.AddMessageType(XMaintainerActionConfigs.MessageType.EventComplete)
                XScheduleManager.ScheduleOnce(function()
                        XDataCenter.MaintainerActionManager.CheckEventCompleteMessage()
                    end, 100)
            end
        end)
    data.player:MarkNodeEvent()
    if data.cb then data.cb() end
end

return XWarehouseNodeEntity