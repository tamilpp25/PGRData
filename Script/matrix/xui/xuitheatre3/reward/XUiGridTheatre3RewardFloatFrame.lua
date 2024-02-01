local XUiGridTheatre3RewardBase = require("XUi/XUiTheatre3/Reward/XUiGridTheatre3RewardBase")

---@class XUiGridTheatre3RewardFloatFrame : XUiGridTheatre3RewardBase
local XUiGridTheatre3RewardFloatFrame = XClass(XUiGridTheatre3RewardBase, "XUiGridTheatre3RewardFloatFrame")

function XUiGridTheatre3RewardFloatFrame:OnStart(isShowTag, callBack)
    self.IsShowTag = isShowTag
    self.CallBack = callBack
    XUiHelper.RegisterClickEvent(self, self.PanelGrid, self.OnPanelGridClick)
    XUiHelper.RegisterClickEvent(self, self.PanelGo, self.OnPanelGoClick)
    self.EffectNormal.gameObject:SetActiveEx(false)
    self.NormaLlight.gameObject:SetActiveEx(false)
    self.Normal.gameObject:SetActiveEx(true)
    -- 前往
    self.PanelGo.gameObject:SetActiveEx(true)
end

function XUiGridTheatre3RewardFloatFrame:Refresh(battlePassId)
    if not XTool.IsNumberValid(battlePassId) or self.BattlePassId == battlePassId then
        return
    end
    self.BattlePassId = battlePassId
    self:SetBtnView(self.PanelGrid, battlePassId)
    self.PanelNow.gameObject:SetActiveEx(self.IsShowTag)
end

-- 物品详情
function XUiGridTheatre3RewardFloatFrame:OnPanelGridClick()
    if not XTool.IsNumberValid(self.BattlePassId) then
        return
    end
    local reward = self:GetReward(self.BattlePassId)
    if not reward then
        return
    end
    XLuaUiManager.Open("UiTheatre3Tips", reward.TemplateId)
end

-- 前往
function XUiGridTheatre3RewardFloatFrame:OnPanelGoClick()
    if self.CallBack then
        self.CallBack(self.BattlePassId)
    end
end

return XUiGridTheatre3RewardFloatFrame