local XUiGridTheatre3RewardBase = require("XUi/XUiTheatre3/Reward/XUiGridTheatre3RewardBase")

---@class XUiGridTheatre3LvReward : XUiGridTheatre3RewardBase
local XUiGridTheatre3LvReward = XClass(XUiGridTheatre3RewardBase, "XUiGridTheatre3LvReward")

function XUiGridTheatre3LvReward:OnStart(callBack)
    self.CallBack = callBack
    XUiHelper.RegisterClickEvent(self, self.PanelGrid, self.OnPanelGridClick)
end

function XUiGridTheatre3LvReward:Refresh(battlePassId, curLevel)
    if not XTool.IsNumberValid(battlePassId) then
        return
    end
    self.BattlePassId = battlePassId
    self.CurLevel = curLevel
    self:SetBtnView(self.PanelGrid, battlePassId)
    
    local isRare = self._Control:CheckBattlePassDisplay(battlePassId)
    local received = self._Control:CheckRewardReceived(battlePassId)
    local canGet = self._Control:CheckBattlePassAbleToReceive(battlePassId, curLevel)
    local showLight = not received and canGet
    --已领取
    self.Disable.gameObject:SetActiveEx(received)
    self.EffectRareLight.gameObject:SetActiveEx(not received)
    self.EffectRare.gameObject:SetActiveEx(not received)
    self.EffectNormal.gameObject:SetActiveEx(not received)
    --普通 && 未领取
    self.Normal.gameObject:SetActiveEx(not isRare)
    self.NormaLlight.gameObject:SetActiveEx(not isRare and showLight)
    --稀有 && 未领取
    self.Rare.gameObject:SetActiveEx(isRare)
    self.RareLlight.gameObject:SetActiveEx(isRare and showLight)
end

function XUiGridTheatre3LvReward:OnPanelGridClick()
    if not XTool.IsNumberValid(self.BattlePassId) then
        return
    end
    local canGet = self._Control:CheckBattlePassAbleToReceive(self.BattlePassId, self.CurLevel)
    if canGet then
        self._Control:GetBattlePassRewardRequest(XEnumConst.THEATRE3.GetBattlePassRewardType.GetOnce, self.BattlePassId, self.CallBack)
    else
        local reward = self:GetReward(self.BattlePassId)
        if not reward then
            return
        end
        XLuaUiManager.Open("UiTheatre3Tips", reward.TemplateId)
    end
end

return XUiGridTheatre3LvReward