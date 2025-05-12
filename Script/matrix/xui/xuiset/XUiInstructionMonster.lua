local XUiGridPokemonMonster = require("XUi/XUiPokemon/XUiMonster/XUiGridPokemonMonster")

local tableInsert = table.insert
local tableSort = table.sort
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

---@class XUiInstructionMonster : XUiNode
local XUiInstructionMonster = XClass(XUiNode, "XUiInstructionMonster")

function XUiInstructionMonster:OnStart()
    self.MonsterIds = {}
    ---@type XUiGridPokemonMonster[]
    self.MonsterGrids = {}
    self.SkillGrids = {}

    self:Init()
end

function XUiInstructionMonster:OnEnable()
    self:ShowPanel()
end

function XUiInstructionMonster:OnDisable()
    self:HidePanel()
end

function XUiInstructionMonster:Init()
    local role = CS.XFight.GetActivateClientRole()
    if not role then return end

    local monsterIds = self.MonsterIds
    local count = role.NpcCount or 0
    for index = 1, count do
        local hasNpc, npc = role:GetNpc(index - 1)
        if hasNpc and npc.IsCustomNpc then
            local monsterId = XPokemonConfigs.GetMonsterIdByNpcId(npc.TemplateId)
            tableInsert(monsterIds, monsterId)
        end
    end

    tableSort(monsterIds, function(aId, bId)
        local aIsBoss = XPokemonConfigs.CheckMonsterType(aId, XPokemonConfigs.MonsterType.Boss)
        local bIsBoss = XPokemonConfigs.CheckMonsterType(bId, XPokemonConfigs.MonsterType.Boss)
        if aIsBoss ~= bIsBoss then
            return aIsBoss
        end

        local aAbility = XDataCenter.PokemonManager.GetMonsterAbility(aId)
        local bAbility = XDataCenter.PokemonManager.GetMonsterAbility(bId)
        if aAbility ~= bAbility then
            return aAbility > bAbility
        end
    end)

    for index, monsterId in ipairs(monsterIds) do
        local grid = self.MonsterGrids[index]
        if not grid then
            local go = index == 1 and self.GridMonster or CSUnityEngineObjectInstantiate(self.GridMonster, self.PanelMonster)
            grid = XUiGridPokemonMonster.New(go)
            self.MonsterGrids[index] = grid
        end

        local paramIndex = index
        local clickCb = function()
            self:OnSelectMonster(paramIndex)
        end
        grid:Refresh(monsterId, clickCb)
        grid:Open()
    end

    for index = #monsterIds + 1, #self.MonsterGrids do
        local grid = self.MonsterGrids[index]
        if grid then
            grid:Close()
        end
    end

    self:OnSelectMonster(1)
    local isSpeedUp = XDataCenter.PokemonManager.IsSpeedUp()
    self.BtnToggle:SetButtonState(isSpeedUp and XUiButtonState.Select or XUiButtonState.Normal)
    self.BtnToggle.CallBack = function() self:OnClickSpeedUpToggle() end
end

function XUiInstructionMonster:OnSelectMonster(index)
    self.SelectIndex = index

    for paramIndex, grid in pairs(self.MonsterGrids) do
        grid:SetSelect(paramIndex == index)
    end

    self:UpdateSkills()
end

function XUiInstructionMonster:UpdateSkills()
    local monsterId = self.MonsterIds[self.SelectIndex]

    local skillIds = XDataCenter.PokemonManager.GetMonsterUsingSkillIdList(monsterId)
    for index, skillId in pairs(skillIds) do
        local grid = self.SkillGrids[index]
        if not grid then
            local go = index == 1 and self.GridSkill or CSUnityEngineObjectInstantiate(self.GridSkill, self.PanelSkillContainer)
            grid = XTool.InitUiObjectByUi({}, go)
            self.SkillGrids[index] = grid
        end

        local icon = XPokemonConfigs.GetMonsterSkillIcon(skillId)
        grid.RImgIconSkill:SetRawImage(icon)

        local desc = XPokemonConfigs.GetMonsterSkillDescription(skillId)
        grid.TxtSkillDescription.text = desc

        grid.GameObject:SetActiveEx(true)
    end
    for index = #skillIds + 1, #self.SkillGrids do
        local grid = self.SkillGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiInstructionMonster:ShowPanel()
    self.IsShow = true
end

function XUiInstructionMonster:HidePanel()
    self.IsShow = false
end

function XUiInstructionMonster:CheckDataIsChange()

    return false
end

function XUiInstructionMonster:SaveChange()

end

function XUiInstructionMonster:CancelChange()

end

function XUiInstructionMonster:ResetToDefault()

end

function XUiInstructionMonster:OnClickSpeedUpToggle()
    local isSelect = self.BtnToggle:GetToggleState()
    self.BtnToggle:SetButtonState(not isSelect and XUiButtonState.Select or XUiButtonState.Normal)
    if isSelect then
        local content =  string.gsub(CSXTextManagerGetText("PokemonSpeedUpTipContent"), "\\n", "\n")
        XUiManager.DialogTip(CSXTextManagerGetText("PokemonSpeedUpTipTitle"), content, XUiManager.DialogType.Normal, function()
            self.BtnToggle:SetButtonState(XUiButtonState.Normal)
            XDataCenter.PokemonManager.ResetSpeed()
            XDataCenter.PokemonManager.SetSpeedUp(false)
        end, function()
            self.BtnToggle:SetButtonState(XUiButtonState.Select)
            XDataCenter.PokemonManager.ChangeSpeed()
            XDataCenter.PokemonManager.SetSpeedUp(true)
        end)
    else
        self.BtnToggle:SetButtonState(XUiButtonState.Normal)
        XDataCenter.PokemonManager.ResetSpeed()
        XDataCenter.PokemonManager.SetSpeedUp(false)
    end
end
return XUiInstructionMonster