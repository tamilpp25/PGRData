---@class XUiPanelRogueSimTransition : XUiNode
---@field private _Control XRogueSimControl
---@field private Parent XUiRogueSimBattle
local XUiPanelRogueSimTransition = XClass(XUiNode, "XUiPanelRogueSimTransition")

function XUiPanelRogueSimTransition:OnStart()
    -- 持续时间
    local duration = self._Control:GetClientConfig("TransitionDuration", 1)
    self.Duration = tonumber(duration)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    -- 是否关闭
    self.IsClose = false
end

function XUiPanelRogueSimTransition:Refresh()
    -- 当前回合数
    local curTurnCount = self._Control:GetCurTurnNumber()
    self.TxtRound.text = string.format(self._Control:GetClientConfig("BattleRoundNumDesc", 2), curTurnCount)
    -- 描述
    local maxTurnCount = self._Control:GetRogueSimStageMaxTurnCount(self._Control:GetCurStageId())
    if curTurnCount >= maxTurnCount then
        self.TxtDesc.text = self._Control:GetClientConfig("TransitionDesc", 2)
    else
        local desc = self._Control:GetClientConfig("TransitionDesc", 1)
        self.TxtDesc.text = string.format(desc, maxTurnCount - curTurnCount)
    end
    -- 持续时间
    self:StopTimer()
    self.IsClose = false
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self:Next()
    end, XScheduleManager.SECOND * self.Duration)
end

function XUiPanelRogueSimTransition:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPanelRogueSimTransition:OnDisable()
    self:StopTimer()
end

function XUiPanelRogueSimTransition:OnBtnCloseClick()
    self:StopTimer()
    self:Next()
end

-- 下一步操作
function XUiPanelRogueSimTransition:Next()
    if self.IsClose then
        return
    end
    self.IsClose = true
    self:Close()
    if self._Control:CheckTurnSettleDataIsEmpty() then
        self:CheckOpenRewardSelect()
        return
    end
    self.Parent:OpenRoundStart() -- 打开回合开始
end

-- 检查打开道具奖励选择界面
function XUiPanelRogueSimTransition:CheckOpenRewardSelect()
    local rewardDic = self._Control:GetRewardData()
    local i, reward = next(rewardDic)
    if reward then
        local itemId = reward:GetId()
        self._Control.MapSubControl:ExplorePropGrid(itemId)
    end
end

return XUiPanelRogueSimTransition
