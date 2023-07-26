local XUiGridPokemonMonster = require("XUi/XUiPokemon/XUiMonster/XUiGridPokemonMonster")
local XUiGridPokemonStageMonster = require("XUi/XUiPokemon/XUiPokemonFormation/XUiGridPokemonStageMonster")
local XUiGridPokemonMemberMonster = require("XUi/XUiPokemon/XUiPokemonFormation/XUiGridPokemonMemberMonster")
local XUiGridPokemonInfinityStageMonster = require("XUi/XUiPokemon/XUiPokemonFormation/XUiGridPokemonInfinityStageMonster")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local ipairs = ipairs
local pairs = pairs
local tableInsert = table.insert
local tableSort = table.sort

local TabBtnIndex = {
    Shooter = 1, --射手
    Shield = 2, --盾卫
    Knight = 3, --骑士
    Assassin = 4,--刺客
}

local XUiPokemonFormation = XLuaUiManager.Register(XLuaUi, "UiPokemonFormation")

function XUiPokemonFormation:OnAwake()
    self:AutoAddListener()
    self:InitTabBtns()
    self:InitDynamicTable()
    self:InitToggleState()

    self.GridEnemy.gameObject:SetActiveEx(false)
    self.GridTeamMonster.gameObject:SetActiveEx(false)
    self.GridMonster.gameObject:SetActiveEx(false)
end

function XUiPokemonFormation:OnStart(stageId)
    self.StageId = stageId
    self.EnemyGrids = {}
    self.TeamMemberGrids = {}
    self.TempSpriteList = {}
    self.TeamMonsterIds = XDataCenter.PokemonManager.GetTeamMonsterIds()

    self:InitPanelEnemy()
    self:InitSuitDrdOptionList()
    self:InitDefaultSelect()
end

function XUiPokemonFormation:OnEnable()
    --local isBossEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmpty(XPokemonConfigs.MonsterType.Boss)
    --self.BtnTabBoss:SetDisable(isBossEmpty)
    --
    --local isMemberEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmpty(XPokemonConfigs.MonsterType.Member)
    --self.BtnTabMember:SetDisable(isMemberEmpty)

    self.PanelTypeGroup:SelectIndex(self.SelectTabBtnIndex)

    self:UpdatePanelTeamMembers()
end

function XUiPokemonFormation:OnDestroy()
    for _, info in pairs(self.TempSpriteList) do
        CS.UnityEngine.Object.Destroy(info.Sprite)
        CS.XResourceManager.Unload(info.Resource)
    end
end

function XUiPokemonFormation:InitToggleState()
    local isSpeedUp = XDataCenter.PokemonManager.IsSpeedUp()
    self.BtnToggle:SetButtonState(isSpeedUp and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiPokemonFormation:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTableMonster)
    self.DynamicTable:SetProxy(XUiGridPokemonMonster)
    self.DynamicTable:SetDelegate(self)
end

function XUiPokemonFormation:InitTabBtns()
    local tabBtns = { self.BtnTabBoss, self.BtnTabMember, self.BtnTabKnight, self.BtnTabAssassin }
    for _,button in pairs(tabBtns) do
        button:SetButtonState(CS.UiButtonState.Normal)
    end
    self.PanelTypeGroup:Init(tabBtns, function(index) self:OnSelectMonsterType(index) end, -1)
end

function XUiPokemonFormation:InitDefaultSelect()
    local isShooterEmpty = XDataCenter.PokemonManager.CheckBagMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Shooter)
    local isShieldEmpty = XDataCenter.PokemonManager.CheckBagMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Shield)
    local isKnightEmpty = XDataCenter.PokemonManager.CheckBagMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Knight)
    local isAssassinEmpty = XDataCenter.PokemonManager.CheckBagMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Assassin)

    if not isShooterEmpty then
        self.SelectTabBtnIndex = TabBtnIndex.Shooter
    elseif not isShieldEmpty then
        self.SelectTabBtnIndex = TabBtnIndex.Shield
    elseif not isKnightEmpty then
        self.SelectTabBtnIndex = TabBtnIndex.Knight
    elseif not isAssassinEmpty then
        self.SelectTabBtnIndex = TabBtnIndex.Assassin
    else
        self.SelectTabBtnIndex = TabBtnIndex.Shooter
    end

    self.SelectMonsterIndex = 1
end

function XUiPokemonFormation:InitSuitDrdOptionList()
    self.DrdCareer:ClearOptions()

    local allCareers = XPokemonConfigs.GetAllCareers()
    self.AllCareers = allCareers

    local optionDataList = CS.UnityEngine.UI.Dropdown.OptionDataList()
    for _, career in ipairs(allCareers) do

        local optionData = CS.UnityEngine.UI.Dropdown.OptionData()

        local careerName = XPokemonConfigs.GetCareerName(career)
        optionData.text = careerName

        local careerIcon = XPokemonConfigs.GetCareerIcon(career)
        if careerIcon then
            local resource = CS.XResourceManager.Load(careerIcon)
            local asset = resource.Asset

            local sprite
            if asset and asset.width and asset.height then
                --texture
                sprite = CS.UnityEngine.Sprite.Create(asset,
                CS.UnityEngine.Rect(0, 0, asset.width, asset.height),
                CS.UnityEngine.Vector2.zero)

                local info = {
                    Sprite = sprite,
                    Resource = resource,
                }
                tableInsert(self.TempSpriteList, info)
            else
                --sprite
                sprite = asset
            end
            optionData.image = sprite
           
        end

        optionDataList.options:Add(optionData)

    end

    self.DrdCareer:AddOptions(optionDataList.options)

    local defaultValue = #allCareers
    self.DrdCareer.value = defaultValue - 1
    self.SortCareer = self.AllCareers[defaultValue]
end

function XUiPokemonFormation:InitPanelEnemy()
    local stageId = self.StageId
    local stageMonsterIds
    if XDataCenter.PokemonManager.IsInfinityStage(stageId) then
        stageMonsterIds = XDataCenter.PokemonManager.GetRandomMonsters()
    else
        stageMonsterIds = XDataCenter.PokemonManager.GetStageMonsterIds(stageId)
    end
    self.StageMonsterIds = stageMonsterIds

    for pos = 1, XPokemonConfigs.TeamNum do

        local grid = self.EnemyGrids[pos]
        if not grid then
            local parent = self["PanelEnemy" .. pos]
            local go = pos == 1 and self.GridEnemy or CSUnityEngineObjectInstantiate(self.GridEnemy, parent)
            if XDataCenter.PokemonManager.IsInfinityStage(stageId) then
                grid = XUiGridPokemonInfinityStageMonster.New(go, pos)
            else
                grid = XUiGridPokemonStageMonster.New(go)
            end
            grid.Transform:SetParent(parent)
            grid.Transform:Reset()
            self.EnemyGrids[pos] = grid
        end

        local stageMonsterId = stageMonsterIds[pos]
        if stageMonsterId and stageMonsterId > 0 then
            grid:Refresh(stageMonsterId)

            grid.GameObject:SetActiveEx(true)
        else
            grid.GameObject:SetActiveEx(false)
        end

    end

end

function XUiPokemonFormation:UpdatePanelTeamMembers()

    local selectPos = self.SelectMemberPos
    local monsterIds = self.TeamMonsterIds
    for pos = 1, XPokemonConfigs.TeamNum do

        local grid = self.TeamMemberGrids[pos]
        if not grid then
            local parent = self["PanelMonster" .. pos]
            local go = pos == 1 and self.GridTeamMonster or CSUnityEngineObjectInstantiate(self.GridTeamMonster, parent)
            local clickCb = function(selectPos)
                self:OnSelectTeamMemberPos(selectPos)
            end
            grid = XUiGridPokemonMemberMonster.New(go, clickCb)
            grid.Transform:SetParent(parent)
            grid.Transform:Reset()
            self.TeamMemberGrids[pos] = grid
        end

        local monsterId = monsterIds[pos]
        local stageMonsterId = self.StageMonsterIds[pos]
        if XDataCenter.PokemonManager.IsInfinityStage(self.StageId) then
            local stageMonsterCareer = stageMonsterId and XPokemonConfigs.GetMonsterCareer(stageMonsterId)
            local recommendCareer = XPokemonConfigs.GetMonsterCareerRecommendCareer(stageMonsterCareer)
            grid:Refresh(pos, recommendCareer, monsterId, selectPos, stageMonsterCareer)
            grid.GameObject:SetActiveEx(true)
        else
            local stageMonsterCareer = stageMonsterId and XPokemonConfigs.GetStageMonsterCareer(stageMonsterId)
            local recommendCareer = XPokemonConfigs.GetMonsterCareerRecommendCareer(stageMonsterCareer)
            grid:Refresh(pos, recommendCareer, monsterId, selectPos, stageMonsterCareer)
            grid.GameObject:SetActiveEx(true)
        end
    end

    local currentCostEnergy = self:GetCurrentCostEnergy()
    local maxCostEnergy = XDataCenter.PokemonManager.GetMaxEnergy()
    local canCostEnrgy = maxCostEnergy - currentCostEnergy
    self.TxtEnergy.text = CSXTextManagerGetText("PokemonMonsterEnergyCostProgress", canCostEnrgy, maxCostEnergy)

end

function XUiPokemonFormation:OnSelectTeamMemberPos(selectPos)

    local oldSelectPos = self.SelectMemberPos
    if oldSelectPos then

        --已经处于选中状态
        if selectPos == oldSelectPos then

            --再次选中相同位置下阵
            self.TeamMonsterIds[selectPos] = 0

        elseif selectPos then

            --选中不同位置, 互相交换
            local monsterIds = self.TeamMonsterIds
            monsterIds[oldSelectPos], monsterIds[selectPos] = monsterIds[selectPos], monsterIds[oldSelectPos]

        end

        --取消选中状态，隐藏遮罩
        self.BtnFullMask.gameObject:SetActiveEx(false)

        self.SelectMemberPos = nil
        self:UpdatePanelTeamMembers()
        self:UpdateMonsters()

    else

        --置为选中状态，增加遮罩
        if selectPos then
            self.BtnFullMask.gameObject:SetActiveEx(true)
        end

        self.SelectMemberPos = selectPos
        self:UpdatePanelTeamMembers()
        self:UpdateMonsters()

    end

end

function XUiPokemonFormation:OnSelectMonsterType(index)
    self.SelectTabBtnIndex = index

    if index == TabBtnIndex.Boss then

        self.TxtBossDisableTip.gameObject:SetActiveEx(true)
        self.TxtEnergy.gameObject:SetActiveEx(false)

    else

        self.TxtBossDisableTip.gameObject:SetActiveEx(false)
        self.TxtEnergy.gameObject:SetActiveEx(true)

    end

    self:UpdateMonsters()

    self:PlayAnimationWithMask("QieHuan")
end

function XUiPokemonFormation:UpdateMonsters()
    local monsterIds = self:GetCanSelectMonsterIdList()

    local isEmpty = XTool.IsTableEmpty(monsterIds)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)

    self.MonsterIds = monsterIds
    self.DynamicTable:SetDataSource(monsterIds)
    self.DynamicTable:ReloadDataASync()
end

function XUiPokemonFormation:UpdateSelectIndex()
    --if self.SelectTabBtnIndex == TabBtnIndex.Member then
    --    return
    --end
    --
    --if XDataCenter.PokemonManager.CheckBagMonsterEmpty(XPokemonConfigs.MonsterType.Boss) and not XDataCenter.PokemonManager.CheckOwnMonsterEmpty(XPokemonConfigs.MonsterType.Member) then
    --    self.SelectTabBtnIndex = TabBtnIndex.Member
    --else
    --    self.SelectTabBtnIndex = TabBtnIndex.Boss
    --end
    self.PanelTypeGroup:SelectIndex(self.SelectTabBtnIndex)
end

function XUiPokemonFormation:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then

        local monsterId = self.MonsterIds[index]
        grid:Refresh(monsterId)

        local isDisable = XPokemonConfigs.CheckMonsterType(monsterId,XPokemonConfigs.MonsterType.Boss) and self:CheckBossInTeam()
        grid:SetDisable(isDisable)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then

        local monsterId = self.MonsterIds[index]

        --能量超出可分配上限
        if self:CheckMonsterCostEnergyOverMax(monsterId) then
            XUiManager.TipText("PokemonMonsterFormationMaxEnergyCost")
            return
        end

        --队伍已满
        if self:CheckTeamFull() then
            XUiManager.TipText("PokemonMonsterFormationTeamFull")
            return
        end

        --已上阵BOSS
        if self:CheckBossInTeam() and XPokemonConfigs.CheckMonsterType(monsterId,XPokemonConfigs.MonsterType.Boss) then
            return
        end

        local firstEmptyPos = self:GetFirstEmptyTeamMemberPos()
        self.TeamMonsterIds[firstEmptyPos] = monsterId

        self:UpdatePanelTeamMembers()
        self:UpdateMonsters()
        self:UpdateSelectIndex()
    end
end

function XUiPokemonFormation:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self.BtnClear.CallBack = function() self:OnClickBtnClear() end
    self.BtnStart.CallBack = function() self:OnClickBtnStart() end
    self.BtnFullMask.CallBack = function() self:OnClickBtnFullMask() end
    self.BtnToggle.CallBack = function() self:OnClickSpeedUpToggle() end
    self.DrdCareer.onValueChanged:AddListener(function() self:OnDrdSuitValueChanged() end)
end

function XUiPokemonFormation:OnDrdSuitValueChanged()
    self.SortCareer = self.AllCareers[self.DrdCareer.value + 1]
    self:UpdateMonsters()

    self:PlayAnimationWithMask("QieHuan")
end

function XUiPokemonFormation:OnClickSpeedUpToggle()
    local isSelect = self.BtnToggle:GetToggleState()
    self.BtnToggle:SetButtonState(not isSelect and XUiButtonState.Select or XUiButtonState.Normal)
    if isSelect then
        local content =  string.gsub(CSXTextManagerGetText("PokemonSpeedUpTipContent"), "\\n", "\n")
        XUiManager.DialogTip(CSXTextManagerGetText("PokemonSpeedUpTipTitle"), content, XUiManager.DialogType.Normal, function()
            self.BtnToggle:SetButtonState(XUiButtonState.Normal)
            XDataCenter.PokemonManager.SetSpeedUp(false)
        end, function()
            self.BtnToggle:SetButtonState(XUiButtonState.Select)
            XDataCenter.PokemonManager.SetSpeedUp(true)
        end)
    else
        self.BtnToggle:SetButtonState(XUiButtonState.Normal)
        XDataCenter.PokemonManager.SetSpeedUp(false)
    end
end

function XUiPokemonFormation:OnClickBtnBack()
    self:Close()
end

function XUiPokemonFormation:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiPokemonFormation:OnClickBtnClear()
    if self:CheckTeamEmpty() then
        XUiManager.TipText("PokemonMonsterFormationTeamEmpty")
        return
    end

    self:ResetTeam()
    self:OnSelectTeamMemberPos(nil)
end

function XUiPokemonFormation:OnClickBtnStart()
    --未上阵BOSS
    if not self:CheckBossInTeam() then
        XUiManager.TipText("PokemonMonsterFormationTeamWithoutBoss")
        return
    end

    local monsterIdList = self.TeamMonsterIds
    local cb = function()
        local stageId = self.StageId
        local fightStageId = XDataCenter.PokemonManager.GetStageFightStageId(stageId)

        self:Close()
        XDataCenter.FubenManager.EnterPokemonFight(fightStageId)
    end
    XDataCenter.PokemonManager.PokemonSetFormationRequest(monsterIdList, cb)
end

function XUiPokemonFormation:OnClickBtnFullMask()
    self:OnSelectTeamMemberPos(nil)
end
------------UI DATA BEGIN---------------
local TabBtnIndexToMonsterType = {
    [TabBtnIndex.Shooter] = XPokemonConfigs.MonsterCareer.Shooter,
    [TabBtnIndex.Shield] = XPokemonConfigs.MonsterCareer.Shield,
    [TabBtnIndex.Knight] = XPokemonConfigs.MonsterCareer.Knight,
    [TabBtnIndex.Assassin] = XPokemonConfigs.MonsterCareer.Assassin,
}
function XUiPokemonFormation:GetSelectMonsterType()
    return TabBtnIndexToMonsterType[self.SelectTabBtnIndex]
end

function XUiPokemonFormation:ResetTeam()
    for pos = 1, XPokemonConfigs.TeamNum do
        self.TeamMonsterIds[pos] = 0
    end
end

function XUiPokemonFormation:GetFirstEmptyTeamMemberPos()
    local pos = 0

    for teamPos = 1, XPokemonConfigs.TeamNum do
        if not XDataCenter.PokemonManager.IsTeamPosLock(teamPos) then

            local teamMonsterId = self.TeamMonsterIds[teamPos]
            if not teamMonsterId or teamMonsterId == 0 then
                pos = teamPos
                break
            end

        end
    end

    return pos
end

function XUiPokemonFormation:CheckTeamFull()
    return self:GetFirstEmptyTeamMemberPos() == 0
end

function XUiPokemonFormation:CheckTeamEmpty()
    for _, teamMonsterId in pairs(self.TeamMonsterIds) do
        if teamMonsterId ~= 0 then
            return false
        end
    end
    return true
end

function XUiPokemonFormation:CheckBossInTeam()
    for _, teamMonsterId in pairs(self.TeamMonsterIds) do
        if XPokemonConfigs.CheckMonsterType(teamMonsterId, XPokemonConfigs.MonsterType.Boss) then
            return true
        end
    end

    return false
end

function XUiPokemonFormation:CheckMonsterInTeam(monsterId)
    if not monsterId or monsterId == 0 then return false end

    for _, teamMonsterId in pairs(self.TeamMonsterIds) do
        if teamMonsterId == monsterId then
            return true
        end
    end

    return false
end

function XUiPokemonFormation:GetCanSelectMonsterIdList()
    local monsterIds = {}

    local careerType = self:GetSelectMonsterType()
    local ownMonsterIds = XDataCenter.PokemonManager.GetOwnMonsterIdsByCareer(careerType)
    local teamMonsterIds = self.TeamMonsterIds

    --剔除已在队伍中的成员
    for _, monsterId in pairs(ownMonsterIds) do
        if monsterId > 0 and not self:CheckMonsterInTeam(monsterId) then
            tableInsert(monsterIds, monsterId)
        end
    end

    local sortCareer = self.SortCareer
    tableSort(monsterIds, function(aMonsterId, bMonsterId)
        --if sortCareer ~= XPokemonConfigs.DefaultAllCareer then
        --    local aCareer = XPokemonConfigs.GetMonsterCareer(aMonsterId)
        --    local bCareer = XPokemonConfigs.GetMonsterCareer(bMonsterId)
        --    if aCareer ~= bCareer then
        --        return aCareer == sortCareer
        --    end
        --end
        --
        --local aAbility = XDataCenter.PokemonManager.GetMonsterAbility(aMonsterId)
        --local bAbility = XDataCenter.PokemonManager.GetMonsterAbility(bMonsterId)
        --return aAbility > bAbility
        local costA = XPokemonConfigs.GetMonsterEnergyCost(aMonsterId)
        local costB = XPokemonConfigs.GetMonsterEnergyCost(bMonsterId)
        costA = costA == 0 and math.huge or costA
        costB = costB == 0 and math.huge or costB
        return costA > costB
    end)

    return monsterIds
end

function XUiPokemonFormation:GetCurrentCostEnergy()
    local energy = 0

    for _, teamMonsterId in pairs(self.TeamMonsterIds) do
        if teamMonsterId and teamMonsterId ~= 0 then
            local costEnergy = XPokemonConfigs.GetMonsterEnergyCost(teamMonsterId)
            energy = energy + costEnergy
        end
    end

    return energy
end

function XUiPokemonFormation:CheckMonsterCostEnergyOverMax(monsterId)
    if not monsterId or monsterId == 0 then return false end

    local maxCostEnergy = XDataCenter.PokemonManager.GetMaxEnergy()
    local currentCostEnergy = self:GetCurrentCostEnergy()
    local costEnergy = XPokemonConfigs.GetMonsterEnergyCost(monsterId)

    return currentCostEnergy + costEnergy > maxCostEnergy
end
------------UI DATA END---------------