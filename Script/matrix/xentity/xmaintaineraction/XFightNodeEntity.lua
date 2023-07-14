local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XFightNodeEntity = XClass(XMaintainerActionNodeEntity, "XFightNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XFightNodeEntity:Ctor()
    self.StageId = 0
end

function XFightNodeEntity:GetStageId()
    return self.StageId
end

function XFightNodeEntity:GetRewardId()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageLevelcfg = XDataCenter.FubenManager.GetStageLevelControl(self.StageId)
    return (stageLevelcfg and stageLevelcfg.FinishRewardShow > 0 and stageLevelcfg.FinishRewardShow) or 
    (stageCfg and stageCfg.FinishRewardShow > 0 and stageCfg.FinishRewardShow) or 0
end

function XFightNodeEntity:GetRewardTitle()
    return CS.XTextManager.GetText("MaintainerActionFightReward")
end

function XFightNodeEntity:OpenDescTip()
    XLuaUiManager.Open("UiFubenMaintaineractionDetailsTips", self, true)
end

function XFightNodeEntity:DoEvent(data)
    if not data then return end
    if not XLuaUiManager.IsUiShow("UiFubenMaintaineractionFighting") then
        XLuaUiManager.Open("UiFubenMaintaineractionFighting", self:GetStageId())
        if data.cb then data.cb() end
    end
end

return XFightNodeEntity