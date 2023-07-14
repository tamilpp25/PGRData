local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XSimulationFightNodeEntity = XClass(XMaintainerActionNodeEntity, "XSimulationFightNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText
function XSimulationFightNodeEntity:Ctor()
    self.RewardGoodsList = {}
    self.StageId = {}
end

function XSimulationFightNodeEntity:GetRewardGoodsList()
    return self.RewardGoodsList
end

function XSimulationFightNodeEntity:GetStageId()
    return self.StageId
end

function XSimulationFightNodeEntity:DoEvent(data)
    if not data then return end
    local rewardGoodsList = self:GetRewardGoodsList()
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    gameData:PlusFightWinCount()

    XLuaUiManager.Open("UiFubenMaintaineractionTreasurechest", nil, rewardGoodsList,
        CSTextManagerGetText("MaintainerActionAutoFightGetTitleText"),
        CSTextManagerGetText("MaintainerActionAutoFightGetSubTitleText"),
        gameData:GetFightWinCount(),
        gameData:GetMaxFightWinCount(),function ()
            local IsFightComplete = XDataCenter.MaintainerActionManager.CheckIsFightComplete()
            local IsAllComplete = XDataCenter.MaintainerActionManager.CheckIsAllComplete()
            if IsAllComplete then
                XDataCenter.MaintainerActionManager.AddMessageType(XMaintainerActionConfigs.MessageType.EventComplete)
                XScheduleManager.ScheduleOnce(function()
                        XDataCenter.MaintainerActionManager.CheckEventCompleteMessage()
                    end, 100)
            elseif IsFightComplete then
                XDataCenter.MaintainerActionManager.AddMessageType(XMaintainerActionConfigs.MessageType.FightComplete)
                XScheduleManager.ScheduleOnce(function()
                        XDataCenter.MaintainerActionManager.CheckFightCompleteMessage()
                    end, 100)
            end
        end)

    data.player:MarkNodeEvent()
    if data.cb then data.cb() end
end

return XSimulationFightNodeEntity