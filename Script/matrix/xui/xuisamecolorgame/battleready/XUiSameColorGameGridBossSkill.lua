---@class XUiSameColorGameGridBossSkill
local XUiSameColorGameGridBossSkill = XClass(nil, "XUiSameColorGameGridBossSkill")
---@param rootUi XUiSameColorGamePanelBoss
function XUiSameColorGameGridBossSkill:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    ---@type XSCBossSkill
    self.Skill = nil
    XTool.InitUiObject(self)
    --self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
end

---@param bossSkill XSCBossSkill
function XUiSameColorGameGridBossSkill:SetData(bossSkill)
    self.Skill = bossSkill
    
    self.TxtSkillDescribe.text = XUiHelper.ReplaceTextNewLine(bossSkill:GetDesc())
    self.RImgSkillIcon:SetRawImage(bossSkill:GetIcon())
end

function XUiSameColorGameGridBossSkill:OnBtnSelfClicked()
    --self.RootUi:UpdateCurrentSkillDetail(self.Skill)
    --self.RootUi:SetGridSelectStatusBySkill(self.Skill)
end

---@param bossSkill XSCBossSkill
function XUiSameColorGameGridBossSkill:SetSelectStatusBySkill(bossSkill)
    self.PanelSelect.gameObject:SetActiveEx(bossSkill:GetId() == self.Skill:GetId())
end

function XUiSameColorGameGridBossSkill:Open()
    self.GameObject:SetActiveEx(true)
end

function XUiSameColorGameGridBossSkill:Close()
    self.GameObject:SetActiveEx(false)
end

return XUiSameColorGameGridBossSkill