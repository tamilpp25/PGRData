---@class XUiPanelRogueSimTransition : XUiNode
---@field private _Control XRogueSimControl
---@field private Parent XUiRogueSimBattle
local XUiPanelRogueSimTransition = XClass(XUiNode, "XUiPanelRogueSimTransition")

function XUiPanelRogueSimTransition:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    -- 是否关闭
    self.IsClose = false
end

function XUiPanelRogueSimTransition:Refresh()
    -- 当前回合数
    local curTurnCount = self._Control:GetCurTurnNumber()
    self.TxtRound.text = curTurnCount
    -- 描述
    local maxTurnCount = self._Control:GetRogueSimStageMaxTurnCount(self._Control:GetCurStageId())
    if curTurnCount >= maxTurnCount then
        self.TxtDesc.text = self._Control:GetClientConfig("TransitionDesc", 2)
    else
        local desc = self._Control:GetClientConfig("TransitionDesc", 1)
        self.TxtDesc.text = string.format(desc, maxTurnCount - curTurnCount)
    end
    -- 播放动画
    self.IsClose = false
    self:PlayAnimation("PanelTransitionEnable", function()
        self:Next()
    end)
end

function XUiPanelRogueSimTransition:OnBtnCloseClick()
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
    local curTurnCount = self._Control:GetCurTurnNumber()
    -- 第一回合没有回合开始
    if curTurnCount == 1 then
        return
    end
    XLuaUiManager.Open("UiRogueSimPopupRoundStart")
end

-- 检查打开道具奖励选择界面
function XUiPanelRogueSimTransition:CheckOpenRewardSelect()
    local rewardDic = self._Control:GetRewardData()
    local _, reward = next(rewardDic)
    if reward then
        local itemId = reward:GetId()
        self._Control.MapSubControl:ExplorePropGrid(itemId)
    end
end

return XUiPanelRogueSimTransition
