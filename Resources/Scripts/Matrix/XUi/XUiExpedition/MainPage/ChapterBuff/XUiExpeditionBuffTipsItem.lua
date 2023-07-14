--虚像地平线词缀展示界面：词缀详细显示控件
local XUiExpeditionBuffTipsItem = XClass(nil, "XUiExpeditionBuffTipsItem")
function XUiExpeditionBuffTipsItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiExpeditionBuffTipsItem:RefreshData(data)
    self.Cfg = data.Cfg
    if data.Type == XDataCenter.ExpeditionManager.BuffTipsType.GlobalBuff then
        self:RefreshGlobalType()
    elseif data.Type == XDataCenter.ExpeditionManager.BuffTipsType.StageBuff then
        self:RefreshStageType()
    elseif data.Type == XDataCenter.ExpeditionManager.BuffTipsType.Skill then
        self:RefreshSkillType()
    end
end

function XUiExpeditionBuffTipsItem:RefreshGlobalType()
    local comboCfg = XExpeditionConfig.GetComboById(self.Cfg.Id)
    self.RImgIcon:SetRawImage(self.Cfg.IconPath)
    self.TxtName.text = self.Cfg.Name
    self.TxtDesc.text = comboCfg.EffectDescription
end

function XUiExpeditionBuffTipsItem:RefreshStageType()
    self.RImgIcon:SetRawImage(self.Cfg.Icon)
    self.TxtName.text = self.Cfg.Name
    self.TxtDesc.text = self.Cfg.Description
end

function XUiExpeditionBuffTipsItem:RefreshSkillType()
    self.RImgIcon:SetRawImage(self.Cfg.IconPath)
    self.TxtName.text = self.Cfg.SkillInfo.Name
    self.TxtDesc.text = self.Cfg.SkillInfo.Intro
end

return XUiExpeditionBuffTipsItem