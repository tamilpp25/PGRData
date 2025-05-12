local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSameColorGameGridRole = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGameGridRole")
local XUiSameColorGameGridBall = require("XUi/XUiSameColorGame/BattleReady/XUiSameColorGameGridBall")
---@class XUiSameColorGamePanelRole:XUiNode
---@field _Control XSameColorControl
local XUiSameColorGamePanelRole = XClass(XUiNode, "XUiSameColorGamePanelRole")

function XUiSameColorGamePanelRole:Ctor(ui, rootUi)
    ---@type XUiSameColorGameBoss
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XSCRole
    self.Role = nil
    ---@type XSCRole[]
    self.Roles = nil
    ---@type XSCBoss
    self.Boss = nil
    ---@type XUiSameColorGameGridBall[]
    self.BallGrids = {}
    ---@type XSCRoleSkill
    self.MainSkill = nil
    
    self:InitRoleList()
    self:AddBtnListener()
end

---@param role XSCRole
---@param boss XSCBoss
function XUiSameColorGamePanelRole:SetData(role, boss)
    self.Boss = boss or self.Boss
    self.Role = role
    self.Roles = XDataCenter.SameColorActivityManager.GetRoleManager():GetRoles()
    self:RefreshRoles(table.indexof(self.Roles, role))
    self:RefreshCurrentRole(role)
end

--region Ui - RoleList
function XUiSameColorGamePanelRole:InitRoleList()
    self.GridRole.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiSameColorGameGridRole, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiSameColorGamePanelRole:RefreshRoles(index)
    self.DynamicTable:SetDataSource(self.Roles)
    self.DynamicTable:ReloadDataSync(index or 1)
end

---@param grid XUiSameColorGameGridRole
function XUiSameColorGamePanelRole:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.Roles[index], self.Boss)
        grid:SetSelectStatusByRole(self.Role)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        for _, theGrid in pairs(self.DynamicTable:GetGrids()) do
            theGrid:SetSelectStatusByRole(self.Role)
        end
    end
end
--endregion

--region Ui - CurRole
---@param role XSCRole
function XUiSameColorGamePanelRole:RefreshCurrentRole(role)
    self.Role = role
    self.MainSkill = role:GetMainSkill()
    
    self:_RefreshTitle()
    self:_RefreshElement()
    self:_RefreshSkillInfo()
    self:_RefreshDamageFactors()
end

function XUiSameColorGamePanelRole:_RefreshTitle()
    local characterViewModel = self.Role:GetCharacterViewModel()
    if self.TxtName then
        self.TxtName.text = characterViewModel:GetLogName()
    end
    if self.TxtTradeName then
        self.TxtTradeName.text = XUiHelper.GetText("SameColorGameRoleTip1", characterViewModel:GetTradeName())
    end
    if self.RImgName then
        self.RImgName:SetRawImage(self.Role:GetNameEnIcon())
    end
end

function XUiSameColorGamePanelRole:_RefreshElement()
    local elementType = self._Control:GetCfgAttributeFactorElementType(self.Role:GetAttributeFactorId())
    if not self.RImgElement then
        return
    end
    self.RImgElement:SetRawImage(self._Control:GetCfgAttributeTypeIcon(elementType))
    self.TxtElementDescribe.text =  self._Control:GetCfgAttributeFactorElementDesc(self.Role:GetAttributeFactorId())
end

function XUiSameColorGamePanelRole:_RefreshSkillInfo()
    local mainSkill = self.MainSkill
    local isTimeType = self.Boss:IsTimeType()
    if self.RImgSkillIcon then
        self.RImgSkillIcon:SetRawImage(mainSkill:GetIcon())
    end
    self.TxtSkillName.text = mainSkill:GetName()
    if self.TxtSkillCD then
        self.TxtSkillCD.text = XUiHelper.GetText("SameColorGameRoleTip2", mainSkill:GetCD(isTimeType))
    end
    if self.TxtSkillDesc then
        self.TxtSkillDesc.text = XUiHelper.ReplaceTextNewLine(mainSkill:GetDesc(isTimeType))
    end
    if self.TxtSkillDesc2 then
        self.TxtSkillDesc2.text = XUiHelper.ReplaceTextNewLine(mainSkill:GetDesc(isTimeType))
    end
    self.TxtPower.text = XUiHelper.GetText("SameColorGameRoleTip3", mainSkill:GetEnergyCost())
    -- 三期不需要切换逻辑
    self.TxtPower.gameObject:SetActiveEx(true)
    self.BtnChange.gameObject:SetActiveEx(false)
    self.BtnChange2.gameObject:SetActiveEx(false)
    -- 被动技能
    local passiveSkillId = self.Role:GetPassiveSkillId()
    local isShowPassive = passiveSkillId ~= 0
    self.PanelPassiveSkill.gameObject:SetActiveEx(isShowPassive)
    if isShowPassive then
        self.TxtPassiveSkillTitle.text = self._Control:GetCfgPassiveSkillName(passiveSkillId)
        self.TxtPassiveSkillDesc.text = self._Control:GetCfgPassiveSkillDesc(passiveSkillId)
    end
end

function XUiSameColorGamePanelRole:_RefreshDamageFactors()
    local balls = self.Role:GetBalls()
    self.GridBall.gameObject:SetActiveEx(false)
    for _, ballGrid in ipairs(self.BallGrids) do
        ballGrid.GameObject:SetActiveEx(false)
    end
    for index, ball in ipairs(balls) do
        local ballGrid = self.BallGrids[index]
        if ballGrid == nil then
            local go = CS.UnityEngine.Object.Instantiate(self.GridBall, self.PanelBall)
            ballGrid = XUiSameColorGameGridBall.New(go)
            self.BallGrids[index] = ballGrid
        end
        ballGrid:SetData(ball)
        ballGrid.GameObject:SetActiveEx(true)
    end
end

function XUiSameColorGamePanelRole:UpdateCurrentRole(role)
    self.AnimQieHuan:Play()
    self:RefreshCurrentRole(role)
    if self.RootUi:GetLastSelectableRole() == role then
        self.RootUi:SetIsSelected(true)
    else
        self.RootUi:SetBtnChange()
    end
    self.RootUi:UpdateCurrentRole(role)
end
--endregion

--region Ui - BtnListener
function XUiSameColorGamePanelRole:AddBtnListener()
    local func = function()
        self.RootUi:UpdateCurrentRole(self.RootUi:GetLastSelectableRole())
        self.RootUi:UpdateChildPanel(XEnumConst.SAME_COLOR_GAME.UI_BOSS_CHILD_PANEL_TYPE.MAIN)
    end
    self.BtnBoss.CallBack = func
    XUiHelper.RegisterClickEvent(self, self.BtnClose, func)
end

function XUiSameColorGamePanelRole:OnBtnChangeClicked()
    self.MainSkill:ChangeSwitch()
    self:_RefreshSkillInfo()
    self.AnimQieHuan2:Play()
end
--endregion

return XUiSameColorGamePanelRole