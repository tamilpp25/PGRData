---@class XUiMonsterCombatInfo : XLuaUi
---@field BtnSkillGroup XUiButtonGroup
local XUiMonsterCombatInfo = XLuaUiManager.Register(XLuaUi, "UiMonsterCombatInfo")

local TabBtnIndex = {
    Skill = 1, -- 技能
    BindingSkill = 2, -- 羁绊技能
}

function XUiMonsterCombatInfo:OnAwake()
    self:RegisterUiEvents()
    self.PanelSkill.gameObject:SetActiveEx(false)
    self.PanelBindingSkill.gameObject:SetActiveEx(false)
    
    self.GridImgStarList = {}
    self.GridBuffCharacterList = {}
end

---@param rootUi XUiMonsterCombatRoleList
function XUiMonsterCombatInfo:OnStart(rootUi)
    self.RootUi = rootUi
    local tabBtns = { self.BtnSkill, self.BtnBindingSkill }
    self.BtnSkillGroup:Init(tabBtns, function(index) self:OnSelectSkillClick(index) end)
end

function XUiMonsterCombatInfo:Refresh(monsterId)
    self.MonsterId = monsterId
    self.MonsterEntity = XDataCenter.MonsterCombatManager.GetMonsterEntity(monsterId)
    self:RefreshMonsterView()
    self:RefreshMonsterStatus()
    self.BtnSkillGroup:SelectIndex(1)
end

function XUiMonsterCombatInfo:RefreshMonsterView()
    -- 怪物名称
    self.TxtName.text = self.MonsterEntity:GetName()
    self.TxtMosterName.text = self.MonsterEntity:GetName()
    -- 负重
    local cost = self.MonsterEntity:GetCost()
    for i = 1, cost do
        local grid = self.GridImgStarList[i]
        if not grid then
            grid = i == 1 and self.ImgStar or XUiHelper.Instantiate(self.ImgStar, self.PanelStars)
            self.GridImgStarList[i] = grid
        end
        grid.gameObject:SetActiveEx(true)
    end
    for i = cost + 1, #self.GridImgStarList do
        self.GridImgStarList[i].gameObject:SetActiveEx(false)
    end
    -- 战斗时间
    self.TxtTime.text = XUiHelper.GetText("UiMonsterCombatMonsterFightTimeDesc", self.MonsterEntity:GetFightTime())
    -- 怪物描述
    self.TxtDate.text = self.MonsterEntity:GetDescription()
    -- 解锁条件
    self.TxtCondition.text = self.MonsterEntity:GetUnlockConditionDesc()
    -- 主动技能
    self.TxtActiveSkillName.text = self.MonsterEntity:GetActiveSkillName()
    self.TxtActiveSkillDesc.text = self.MonsterEntity:GetActiveSkillDesc()
    self.TxtActiveSkillCooling.text = XUiHelper.GetText("UiMonsterCombatMonsterCoolingTimeDesc", self.MonsterEntity:GetActiveSkillCooling())
    -- 被动技能
    self.TxtPassiveSkillName.text = self.MonsterEntity:GetPassiveSkillName()
    self.TxtPassiveSkillDesc.text = self.MonsterEntity:GetPassiveSkillDesc()
    -- 羁绊技能
    local buffConfig = XMonsterCombatConfigs.GetBuffConfigByMonsterId(self.MonsterId)
    self.TxtBuffName.text = buffConfig.Name
    self.TxtBuffDesc.text = XUiHelper.ConvertLineBreakSymbol(buffConfig.Description)
    -- 羁绊角色
    local characterIds = buffConfig.CharacterIds
    local charNum = #characterIds
    for i = 1, charNum do
        local grid = self.GridBuffCharacterList[i]
        if not grid then
            local go = i == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.PanelDropContent)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridBuffCharacterList[i] = grid
        end
        local characterId = characterIds[i]
        local headIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
        grid.RImgIcon:SetRawImage(headIcon)
        grid.Name.text = XEntityHelper.GetCharacterTradeName(characterId)
        grid.GameObject:SetActiveEx(true)
    end
    for i = charNum + 1, #self.GridBuffCharacterList do
        self.GridBuffCharacterList[i].GameObject:SetActiveEx(false)
    end
end

function XUiMonsterCombatInfo:RefreshMonsterStatus()
    local isUnlock = self.MonsterEntity:CheckIsUnlock()
    self.PanelOwnedInfo.gameObject:SetActiveEx(isUnlock)
    self.PanelOwnedInfoLock.gameObject:SetActiveEx(not isUnlock)
end

function XUiMonsterCombatInfo:SetJoinBtnIsActive(value)
    self.BtnJoinTeam.gameObject:SetActiveEx(value)
    self.BtnQuitTeam.gameObject:SetActiveEx(not value)
end

function XUiMonsterCombatInfo:SetTeamBtnStatus(value)
    self.BtnQuitTeam.gameObject:SetActiveEx(value)
    self.BtnJoinTeam.gameObject:SetActiveEx(value)
end

-- 怪物描述
function XUiMonsterCombatInfo:SetPanelDateActive(value)
    if self.PanelDate then
        self.PanelDate.gameObject:SetActiveEx(value)
    end
end

function XUiMonsterCombatInfo:OnSelectSkillClick(index)
    self.PanelSkill.gameObject:SetActiveEx(index == TabBtnIndex.Skill)
    self.PanelBindingSkill.gameObject:SetActiveEx(index == TabBtnIndex.BindingSkill)
end

function XUiMonsterCombatInfo:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnQuitTeam, self.OnBtnQuitTeamClick)
    XUiHelper.RegisterClickEvent(self, self.BtnJoinTeam, self.OnBtnJoinTeamClick)
end

function XUiMonsterCombatInfo:OnBtnQuitTeamClick()
    self.RootUi:OnBtnQuitTeamClicked()
end

function XUiMonsterCombatInfo:OnBtnJoinTeamClick()
    self.RootUi:OnBtnJoinTeamClicked()
end

return XUiMonsterCombatInfo