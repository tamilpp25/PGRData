local XUiGridSwitchEnhanceSkill = require("XUi/XUiCharacterV2P6/Grid/XUiGridSwitchEnhanceSkill")
local XUiCharacterEnhacneSkillSwitch = XLuaUiManager.Register(XLuaUi, "UiCharacterEnhacneSkillSwitch")

function XUiCharacterEnhacneSkillSwitch:OnAwake()
    self:AutoAddListener()
    self.SkillItem.gameObject:SetActiveEx(false)
end

--- func desc
---@param enhanceSkillGroupId number
---@param enhanceSkillGroupData XEnhanceSkillGroup
---@param characterId number
---@param switchCb function 
function XUiCharacterEnhacneSkillSwitch:OnStart(enhanceSkillGroupId, enhanceSkillGroupData, characterId, switchCb)
    self.EnhanceSkillGroupId = enhanceSkillGroupId
    self.EnhanceSkillGroupData = enhanceSkillGroupData
    self.CharacterId = characterId
    self.SwitchCb = switchCb
end

function XUiCharacterEnhacneSkillSwitch:OnEnable()
    self:Refresh()
end

function XUiCharacterEnhacneSkillSwitch:Refresh()
    local enhanceSkillGroupCfg = XMVCA.XCharacter:GetModelEnhanceSkillGroup()[self.EnhanceSkillGroupId]
    local skillIds = enhanceSkillGroupCfg.SkillId

    self.Grids = self.Grids or {}
    for index, skillId in pairs(skillIds) do
        local grid = self.Grids[index]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.SkillItem, self.Content)
            local switchCb = function()
                self:Refresh()
                self.SwitchCb()
            end
            grid = XUiGridSwitchEnhanceSkill.New(go, self, switchCb)
            self.Grids[index] = grid
        end

        local isCurrent = self.EnhanceSkillGroupData:GetActiveSkillId() == skillId
        grid:Refresh(skillId, self.EnhanceSkillGroupData:GetLevel(), isCurrent)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #skillIds + 1, #self.Grids do
        self.Grids[i].GameObject:SetActiveEx(false)
    end
end

function XUiCharacterEnhacneSkillSwitch:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnBackClick)
end

function XUiCharacterEnhacneSkillSwitch:OnBtnBackClick()
    self:Close()
end