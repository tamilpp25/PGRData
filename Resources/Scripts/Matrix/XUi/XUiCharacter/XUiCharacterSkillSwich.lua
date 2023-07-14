local XUiGridSwitchSkill = require("XUi/XUiCharacter/XUiGridSwitchSkill")

local XUiCharacterSkillSwich = XLuaUiManager.Register(XLuaUi, "UiCharacterSkillSwich")

function XUiCharacterSkillSwich:OnAwake()
    self:AutoAddListener()
    self.SkillItem.gameObject:SetActiveEx(false)
end

function XUiCharacterSkillSwich:OnStart(skillId, skillLevel, switchCb)
    self.SkillId = skillId
    self.SkillLevel = skillLevel
    self.SwitchCb = switchCb
end

function XUiCharacterSkillSwich:OnEnable()
    self:Refresh()
end

function XUiCharacterSkillSwich:Refresh()
    local curSkillId = self.SkillId
    local groupSkillIds = XCharacterConfigs.GetGroupSkillIds(curSkillId)

    self.Grids = self.Grids or {}
    for index, skillId in ipairs(groupSkillIds) do
        local grid = self.Grids[index]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.SkillItem, self.Content)
            local switchCb = function()
                self:Refresh()
                self.SwitchCb()
            end
            grid = XUiGridSwitchSkill.New(go, switchCb)
            self.Grids[index] = grid
        end

        local isCurrent = XDataCenter.CharacterManager.IsSkillUsing(skillId)
        grid:Refresh(skillId, self.SkillLevel, isCurrent)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #groupSkillIds + 1, #self.Grids do
        self.Grids[i].GameObject:SetActiveEx(false)
    end
end

function XUiCharacterSkillSwich:AutoAddListener()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnBackClick)
end

function XUiCharacterSkillSwich:OnBtnBackClick()
    self:Close()
end