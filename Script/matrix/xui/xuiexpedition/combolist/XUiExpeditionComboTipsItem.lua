--虚像地平线羁绊组合详细页面: 羁绊详细项控件
local XUiExpeditionComboTipsItem = XClass(nil, "XUiExpeditionComboTipsItem")

local TextGroup = {
      Effect = 0, -- 效果描述
      Condition = 1, -- 条件描述
      Title = 2  -- 标题描述
    }
function XUiExpeditionComboTipsItem:Ctor(ui, rootUi)
    self:Init(ui, rootUi)
end

function XUiExpeditionComboTipsItem:Init(ui, rootUi)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
    self.RootUi = rootUi
end

function XUiExpeditionComboTipsItem:RefreshDatas(phaseCombo, eCombo, index)
    self.ECombo = eCombo
    self.PhaseCombo = phaseCombo
    self.IsActive = eCombo:GetComboActive() and eCombo:GetPhase() == index
    self.Normal.gameObject:SetActiveEx(not self.IsActive)
    self.Active.gameObject:SetActiveEx(self.IsActive)
    if self.IsActive then
        self.TxtTitleActive.text = CS.XTextManager.GetText("ExpeditionComboTipsPhaseTitle", index)
        self.TxtEffectActive.text = self.ECombo:GetPhaseComboEffectDes(index)
        self.TxtConditionActive.text = self.ECombo:GetPhaseComboConditionDes(index)
    else
        self.TxtTitleNormal.text = CS.XTextManager.GetText("ExpeditionComboTipsPhaseTitle", index)
        self.TxtEffectNormal.text = self.ECombo:GetPhaseComboEffectDes(index)
        self.TxtConditionNormal.text = self.ECombo:GetPhaseComboConditionDes(index)
    end
end

return XUiExpeditionComboTipsItem