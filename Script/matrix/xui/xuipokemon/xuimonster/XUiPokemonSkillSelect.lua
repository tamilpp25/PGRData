local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridPokemonMonsterSelectSkill = require("XUi/XUiPokemon/XUiMonster/XUiGridPokemonMonsterSelectSkill")

local XUiPokemonSkillSelect = XLuaUiManager.Register(XLuaUi, "UiPokemonSkillSelect")

function XUiPokemonSkillSelect:OnAwake()
    self:InitDynamicTable()
    self:AutoAddListener()
    self.GridMonsterSkill.gameObject:SetActiveEx(false)
end

function XUiPokemonSkillSelect:OnStart(monsterId, skillIds)
    self.MonsterId = monsterId
    self.SkillIds = skillIds
end

function XUiPokemonSkillSelect:OnEnable()
    self:UpdateSkills()
end

function XUiPokemonSkillSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelScroll)
    self.DynamicTable:SetProxy(XUiGridPokemonMonsterSelectSkill)
    self.DynamicTable:SetDelegate(self)
end

function XUiPokemonSkillSelect:UpdateSkills()
    self.DynamicTable:SetDataSource(self.SkillIds)
    self.DynamicTable:ReloadDataASync()
end

function XUiPokemonSkillSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then

        local monsterId = self.MonsterId
        local skillId = self.SkillIds[index]
        local clickCb = function() self:OnSelectSkill(index) end
        grid:Refresh(monsterId, skillId, clickCb)

    end
end

function XUiPokemonSkillSelect:OnSelectSkill(index)
    local monsterId = self.MonsterId
    local skillId = self.SkillIds[index]

    if not XDataCenter.PokemonManager.IsMonsterSkillUnlock(monsterId, skillId) then
        return
    end

    local cb = function()
        self:UpdateSkills()
    end
    XDataCenter.PokemonManager.PokemonSetSkillRequest(monsterId, skillId, cb)
end

function XUiPokemonSkillSelect:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnBack() end
end

function XUiPokemonSkillSelect:OnClickBtnBack()
    self:Close()
end