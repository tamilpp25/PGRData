---@class XUiSCBattlePanelRoleSkill
local XUiPanelSkill = XClass(nil, "XUiPanelSkill")
local XUiGridSkill = require("XUi/XUiSameColorGame/Battle/XUiGridSkill")

function XUiPanelSkill:Ctor(ui, base, role)
    ---@type XUiSameColorGameBattle
    self.Base = base
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    ---@type XSCRole
    self.Role = role
    self.IsInPrepSkill = false
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self:Init()
end

function XUiPanelSkill:OnEnable()
    self:AddEventListener()
end

function XUiPanelSkill:OnDisable()
    self:RemoveEventListener()
end

function XUiPanelSkill:Init()
    ---@type XUiSCBattleGridSkill[]
    self.GridSkillList = {}
    ---@type UnityEngine.Transform
    self.GridSubSkill = {
        self.GridSubSkill1, 
        self.GridSubSkill2, 
        self.GridSubSkill3
    }
    
    local mainSkill = self.BattleManager:GetBattleRoleSkill(self.Role:GetMainSkillGroupId())
    local subSkillGroupIdList = self.Role:GetUsingSkillGroupIds(true)
    local subSkillCount = XEnumConst.SAME_COLOR_GAME.ROLE_MAX_SKILL_COUNT
    
    self:CreateSkillGrid(self.GridMainSkill, true)
    -- 设置玩家主技能
    self.BattleManager:SetRoleMainSkill(mainSkill:GetSkillId())
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
    ---@type XUiSCBattleGridSkill
    local grid = XUiGridSkill.New(gridObj, self, IsMainSkill)
    table.insert(self.GridSkillList, grid)
end

---@param skill XSCBattleRoleSkill
function XUiPanelSkill:SelectSkill(skill)
    if not self.IsInPrepSkill or not self.BattleManager:CheckIsPrepSkill(skill) then
        self.IsInPrepSkill = true
        self:SetSkillDisable(true, skill)
        self.BattleManager:SetPrepSkill(skill)
        XEventManager.DispatchEvent(XEventId.EVENT_SC_PREP_SKILL, skill)
    elseif self.BattleManager:CheckIsPrepSkill(skill) then
        -- 已选择技能重复点击则关闭选择
        XEventManager.DispatchEvent(XEventId.EVENT_SC_SKILL_USED, skill)
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

---@param data XSCBattleActionInfo
function XUiPanelSkill:SetSkillCountdown(data)
    for _,gridSkill in pairs(self.GridSkillList) do
        gridSkill:SetCountdown(data.SkillGroupId, data.LeftCd)
    end
end

--region Event
function XUiPanelSkill:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ENERGY_CHANGE, self.UpdateGrids, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectSkill, self)
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_CD_CHANGE, self.SetSkillCountdown, self)
end

function XUiPanelSkill:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_ENERGY_CHANGE, self.UpdateGrids, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_UNPREP_SKILL, self.UnSelectSkill, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SC_ACTION_CD_CHANGE, self.SetSkillCountdown, self)
end
--endregion

return XUiPanelSkill