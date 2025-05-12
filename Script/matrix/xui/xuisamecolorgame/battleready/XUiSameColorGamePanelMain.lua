---@class XUiSameColorGamePanelMain:XLuaUi
local XUiSameColorGamePanelMain = XClass(nil, "XUiSameColorGamePanelMain")

function XUiSameColorGamePanelMain:Ctor(ui, rootUi)
    ---@type XUiSameColorGameBoss
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AddListener()
end

---@param boss XSCBoss
---@param role XSCRole
function XUiSameColorGamePanelMain:SetData(boss, role)
    self.BtnBossDetail1:SetNameByGroup(0, boss:GetName())
    --self.BtnBossDetail1:SetRawImage(boss:GetNameIcon())
    local characterViewModel = role:GetCharacterViewModel()
    self.BtnRoleDetail1:SetNameByGroup(0, characterViewModel:GetEnName())
    self.BtnRoleDetail1:SetNameByGroup(1, characterViewModel:GetLogName())
    --self.BtnRoleDetail1:SetRawImage(role:GetNameIcon())
    self.TxtMaxScore.text = boss:GetMaxScore()
    self.TxtActionCount.text = boss:GetMaxRound()
    self.TxtCD.text = role:GetMainSkill():GetCD()
    self.TxtSkillDesc.text = role:GetMainSkill():GetName()
end

--region Btn - Listener
function XUiSameColorGamePanelMain:AddListener()
    self.BtnRoleDetail1.CallBack = function() self:OnBtnRoleDetail() end
    self.BtnRoleDetail2.CallBack = function() self:OnBtnRoleDetail() end
    self.BtnBossDetail1.CallBack = function() self:OnBtnBossDetail() end
    self.BtnBossDetail2.CallBack = function() self:OnBtnBossDetail() end
end

function XUiSameColorGamePanelMain:OnBtnRoleDetail()
    self.RootUi:UpdateChildPanel(XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.ROLE)
end

function XUiSameColorGamePanelMain:OnBtnBossDetail()
    self.RootUi:UpdateChildPanel(XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.BOSS)
end
--endregion

return XUiSameColorGamePanelMain