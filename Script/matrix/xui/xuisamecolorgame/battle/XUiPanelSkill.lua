local XUiPanelSkill = XClass(nil, "XUiPanelSkill")
local XUiGridSkill = require("XUi/XUiSameColorGame/Battle/XUiGridSkill")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiPanelSkill:Ctor(ui, base, role)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Role = role
    self.IsInPrepSkill = false
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    XTool.InitUiObject(self)
    self:Init()
end

function XUiPanelSkill:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ENERGYCHANGE, self.UpdateGrids, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectSkill, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_CDCHANGE, self.SetSkillCountdown, self)
end

function XUiPanelSkill:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ENERGYCHANGE, self.UpdateGrids, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectSkill, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_CDCHANGE, self.SetSkillCountdown, self)
end

function XUiPanelSkill:Init()
    self.GridSkillList = {}
    self.GridSubSkill = {
        self.GridSubSkill1, 
        self.GridSubSkill2, 
        self.GridSubSkill3
        }
    
    local mainSkill = self.BattleManager:GetBattleRoleSkill(self.Role:GetMainSkillGroupId())
    local subSkillGroupIdList = self.Role:GetUsingSkillGroupIds(true)
    local subSkillCount = XSameColorGameConfigs.RoleMaxSkillCount
    
    self:CreateSkillGrid(self.GridMainSkill, true)
    for index = 1, subSkillCount do
        self:CreateSkillGrid(self.GridSubSkill[index], false)
    end
    
    for index, gridSkill in pairs(self.GridSkillList or {}) do
        if index == 1 then
            gridSkill:UpdateGrid(mainSkill)
        else
            local skillGroupId = subSkillGroupIdList[index - 1]
            local subSkill = skillGroupId and self.BattleManager:GetBattleRoleSkill(skillGroupId)
            gridSkill:UpdateGrid(subSkill)
        end
    end
end

function XUiPanelSkill:UpdateGrids()
    local mainSkill = self.BattleManager:GetBattleRoleSkill(self.Role:GetMainSkillGroupId())
    local subSkillGroupIdList = self.Role:GetUsingSkillGroupIds(true)

    for index, gridSkill in pairs(self.GridSkillList or {}) do
        if index == 1 then
            gridSkill:UpdateGrid(mainSkill)
        else
            local skillGroupId = subSkillGroupIdList[index - 1]
            local subSkill = skillGroupId and self.BattleManager:GetBattleRoleSkill(skillGroupId)
            gridSkill:UpdateGrid(subSkill)
        end
    end
end

function XUiPanelSkill:CreateSkillGrid(gridObj, IsMainSkill)
    local grid = XUiGridSkill.New(gridObj, self, IsMainSkill)
    table.insert(self.GridSkillList, grid)
end

function XUiPanelSkill:SelectSkill(skill)
    if not self.IsInPrepSkill then
        self.IsInPrepSkill = true
        self:SetSkillDisable(true, skill)
        self.BattleManager:SetPrepSkill(skill)
        XEventManager.DispatchEvent(XEventId.EVENT_SC_PREP_SKILL, skill)
    end
end

function XUiPanelSkill:UnSelectSkill()
    self.IsInPrepSkill = false
    self:SetSkillDisable(false)
end

function XUiPanelSkill:SetSkillDisable(IsDisable, excludeSkill)
    for _,gridSkill in pairs(self.GridSkillList) do
        gridSkill:SetDisable(IsDisable, excludeSkill)
    end
end

function XUiPanelSkill:SetSkillCountdown(data)
   for _,gridSkill in pairs(self.GridSkillList) do
        gridSkill:SetCountdown(data.SkillGroupId, data.LeftCd)
        self:SetSkillDisable(false)
   end
end

return XUiPanelSkill