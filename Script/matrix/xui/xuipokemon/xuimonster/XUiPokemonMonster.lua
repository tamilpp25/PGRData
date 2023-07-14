local XUiGridPokemonMonster = require("XUi/XUiPokemon/XUiMonster/XUiGridPokemonMonster")
local XRedPointConditionPokemonNewRole = require("XRedPoint/XRedPointConditions/XRedPointConditionPokemonNewRole")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local pairs = pairs
local tableInsert = table.insert
local tonumber = tonumber
local mathFloor = math.floor
local Lerp = CS.UnityEngine.Mathf.Lerp
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local CsXTextManagerGetText = CsXTextManagerGetText
local NewSkillSaveKey = "PokemonNewSkillSaveKey_%s_%d_%d"
local TabBtnIndex = {
    Shooter = 1, --射手
    Shield = 2, --盾卫
    Knight = 3, --骑士
    Assassin = 4, --刺客
}
local SCORE_ANIM_DURATION = 1

local XUiPokemonMonster = XLuaUiManager.Register(XLuaUi, "UiPokemonMonster")

function XUiPokemonMonster:OnAwake()
    self:AutoAddListener()
    self:InitDynamicTable()
    self:InitTabBtns()

    self.GridStar.gameObject:SetActiveEx(false)
    self.BtnSkill.gameObject:SetActiveEx(false)
    self.GridMonster.gameObject:SetActiveEx(false)

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.PokemonLevelUpItem, function()
        self.AssetActivityPanel:Refresh({ XDataCenter.ItemManager.ItemId.PokemonLevelUpItem, XDataCenter.ItemManager.ItemId.PokemonStarUpItem, XDataCenter.ItemManager.ItemId.PokemonLowStarUpItem })
    end, self.AssetActivityPanel)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.PokemonStarUpItem, function()
        self.AssetActivityPanel:Refresh({ XDataCenter.ItemManager.ItemId.PokemonLevelUpItem, XDataCenter.ItemManager.ItemId.PokemonStarUpItem, XDataCenter.ItemManager.ItemId.PokemonLowStarUpItem })
    end, self.AssetActivityPanel)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.PokemonLowStarUpItem, function()
        self.AssetActivityPanel:Refresh({ XDataCenter.ItemManager.ItemId.PokemonLevelUpItem, XDataCenter.ItemManager.ItemId.PokemonStarUpItem, XDataCenter.ItemManager.ItemId.PokemonLowStarUpItem })
    end, self.AssetActivityPanel)
end

function XUiPokemonMonster:OnStart()
    self.StarGrids = {}
    self.SkillGrids = {}

    self:InitDefaultSelect()
    self:InitSceneRoot()
    self.AssetActivityPanel:Refresh({ XDataCenter.ItemManager.ItemId.PokemonLevelUpItem, XDataCenter.ItemManager.ItemId.PokemonStarUpItem, XDataCenter.ItemManager.ItemId.PokemonLowStarUpItem })
end

function XUiPokemonMonster:OnEnable()
    --local isBossEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmpty(XPokemonConfigs.MonsterType.Boss)
    --self.BtnTabBoss:SetDisable(isBossEmpty)
    --
    --local isMemberEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmpty(XPokemonConfigs.MonsterType.Member)
    --self.BtnTabMember:SetDisable(isMemberEmpty)
    local isShooterEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Shooter)
    local isShieldEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Shield)
    local isKnightEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Knight)
    local isAssassinEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Assassin)
    self.BtnTabShooter:SetDisable(isShooterEmpty)
    self.BtnTabShield:SetDisable(isShieldEmpty)
    self.BtnTabKnight:SetDisable(isKnightEmpty)
    self.BtnTabAssassin:SetDisable(isAssassinEmpty)
    self.PanelCharacterTypeBtns:SelectIndex(self.SelectTabBtnIndex)
    self:CheckTabRedDot()
end

function XUiPokemonMonster:OnDisable()
    self:DestroyTimer()
end

function XUiPokemonMonster:OnGetEvents()
    local eventIds = XPokemonConfigs.GetToCheckItemIdEventIds()
    tableInsert(eventIds, XEventId.EVENT_POKEMON_MONSTERS_SKILL_SWITCH)
    tableInsert(eventIds, XEventId.EVENT_POKEMON_MONSTERS_LEVEL_UP)
    tableInsert(eventIds, XEventId.EVENT_POKEMON_MONSTERS_DATA_CHANGE)
    tableInsert(eventIds, XEventId.EVENT_POKEMON_MONSTERS_STAR_UP)
    return eventIds
end

function XUiPokemonMonster:OnNotify(evt, ...)
    local eventIds = XPokemonConfigs.GetToCheckItemIdEventIds()
    for _, eventId in pairs(eventIds) do
        if evt == eventId then
            self:UpdateCostItem()
            return
        end
    end

    if evt == XEventId.EVENT_POKEMON_MONSTERS_SKILL_SWITCH then
        self:UpdateSkills()
    elseif evt == XEventId.EVENT_POKEMON_MONSTERS_DATA_CHANGE then
        self:UpdateMonsters()
    elseif evt == XEventId.EVENT_POKEMON_MONSTERS_LEVEL_UP or
    evt == XEventId.EVENT_POKEMON_MONSTERS_STAR_UP then
        self:UpdateCostItem()
    end
end

function XUiPokemonMonster:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiGridPokemonMonster)
    self.DynamicTable:SetDelegate(self)
end

function XUiPokemonMonster:InitTabBtns()
    self.TabBtns = { self.BtnTabShooter, self.BtnTabShield, self.BtnTabKnight, self.BtnTabAssassin }
    self.PanelCharacterTypeBtns:Init(self.TabBtns, function(index) self:OnSelectMonsterType(index) end)
end

function XUiPokemonMonster:InitDefaultSelect()
    --if not XDataCenter.PokemonManager.CheckOwnMonsterEmpty(XPokemonConfigs.MonsterType.Boss) then
    --    self.SelectTabBtnIndex = TabBtnIndex.Shooter
    --else
    --    self.SelectTabBtnIndex = TabBtnIndex.Shield
    --end
    local isShooterEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Shooter)
    local isShieldEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Shield)
    local isKnightEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Knight)
    local isAssassinEmpty = XDataCenter.PokemonManager.CheckOwnMonsterEmptyByCareer(XPokemonConfigs.MonsterCareer.Assassin)

    if not isShooterEmpty then
        self.SelectTabBtnIndex = TabBtnIndex.Shooter
    elseif not isShieldEmpty then
        self.SelectTabBtnIndex = TabBtnIndex.Shield
    elseif not isKnightEmpty then
        self.SelectTabBtnIndex = TabBtnIndex.Knight
    elseif not isAssassinEmpty then
        self.SelectTabBtnIndex = TabBtnIndex.Assassin
    end

    self.SelectMonsterIndex = 1
end

function XUiPokemonMonster:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiPokemonMonster:OnSelectMonsterType(index)
    self.SelectTabBtnIndex = index
    self.SelectMonsterIndex = 1

    self:UpdateMonsters()
end

function XUiPokemonMonster:UpdateMonsters()
    local careerType = self:GetSelectMonsterType()
    local monsterIds = XDataCenter.PokemonManager.GetOwnMonsterIdsByCareer(careerType)
    if XTool.IsTableEmpty(monsterIds) then
        XUiManager.TipText("PokemonMonsterListEmpty")
        return
    end

    self:PlayAnimation("QieHuan")

    self.MonsterIds = monsterIds
    table.sort(self.MonsterIds, function(a, b)
        local costA = XPokemonConfigs.GetMonsterEnergyCost(a)
        local costB = XPokemonConfigs.GetMonsterEnergyCost(b)
        costA = costA == 0 and math.huge or costA
        costB = costB == 0 and math.huge or costB
        return costA > costB
    end)
    self.DynamicTable:SetDataSource(monsterIds)
    self.DynamicTable:ReloadDataASync()

    self:UpdateCurrentMonster()
    self:UpdateCurrentMonsterModel()
end

function XUiPokemonMonster:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then

        local monsterId = self.MonsterIds[index]

        grid:Refresh(monsterId)

        if self.SelectMonsterIndex == index then
            grid:SetSelect(true)
            self.LastSelectMonsterGrid = grid
            self:CheckTabRedDot()
        else
            grid:SetSelect(false)
        end
        XRedPointManager.CheckOnce(grid.ShowRedDot, grid, { XRedPointConditions.Types.CONDITION_POKEMON_NEW_ROLE }, monsterId)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then

        if self.LastSelectMonsterGrid then
            self.LastSelectMonsterGrid:SetSelect(false)
        end
        self.LastSelectMonsterGrid = grid
        grid:SetSelect(true)
        self:CheckTabRedDot()
        self.SelectMonsterIndex = index
        self:UpdateCurrentMonster()
        self:UpdateCurrentMonsterModel()

        self:PlayAnimation("QieHuan")

    end
end

function XUiPokemonMonster:UpdateCurrentMonster()
    local monsterId = self.MonsterIds[self.SelectMonsterIndex]

    local name = XPokemonConfigs.GetMonsterName(monsterId)
    self.TxtName.text = name

    local level = XDataCenter.PokemonManager.GetMonsterLevel(monsterId)
    local maxLevel = XDataCenter.PokemonManager.GetMonsterMaxLevel(monsterId)
    self.TxtLevel.text = level .. "/" .. maxLevel
    self.BtnReset.gameObject:SetActiveEx(level ~= 1)
    local ability = XDataCenter.PokemonManager.GetMonsterAbility(monsterId)
    self.TxtAbility.text = ability

    local hp = XDataCenter.PokemonManager.GetMonsterHp(monsterId)
    self.TxtHp.text = hp

    local attack = XDataCenter.PokemonManager.GetMonsterAttack(monsterId)
    self.TxtAttack.text = attack

    local star = XDataCenter.PokemonManager.GetMonsterStar(monsterId)
    local maxStar = XPokemonConfigs.GetMonsterStarMaxStar(monsterId)
    for index = 1, maxStar do
        local grid = self.StarGrids[index]
        if not grid then
            local go = index == 1 and self.GridStar or CSUnityEngineObjectInstantiate(self.GridStar, self.PanelStar)
            grid = XTool.InitUiObjectByUi({}, go)
            self.StarGrids[index] = grid
        end

        grid.GameObject:SetActiveEx(true)
        grid.ImgStar.gameObject:SetActiveEx(index <= star)
    end
    for index = maxStar + 1, #self.StarGrids do
        local grid = self.StarGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

    self:UpdateCostItem()
    self:UpdateSkills()

end

function XUiPokemonMonster:UpdateCurrentMonsterModel()
    local monsterId = self.MonsterIds[self.SelectMonsterIndex]
    local modelId = XPokemonConfigs.GetMonsterModelId(monsterId)
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.RoleModelPanel:UpdateRoleModel(modelId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiPokemonMonster, function(model)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
        self.PanelDrag.Target = model.transform
    end, nil)
end

function XUiPokemonMonster:UpdateCostItem()
    local monsterId = self.MonsterIds[self.SelectMonsterIndex]

    if not XDataCenter.PokemonManager.IsMonsterMaxLevel(monsterId) then

        local itemId, itemCount = XDataCenter.PokemonManager.GetMonsterLevelUpCostItemInfo(monsterId)

        local icon = XItemConfigs.GetItemIconById(itemId)
        self.RImgIconCost:SetRawImage(icon)

        self.TxtCostNum.text = itemCount
        self.PanelCost.gameObject:SetActiveEx(true)

        self.BtnUpgrade:SetDisable(false)
        self.BtnUpgrade.gameObject:SetActiveEx(true)

        self.BtnUpgradeStars.gameObject:SetActiveEx(false)

        self.BtnAutoUpgrade.gameObject:SetActiveEx(true)
        self.BtnAutoUpgrade:SetDisable(false)

    elseif not XDataCenter.PokemonManager.IsMonsterMaxStar(monsterId) then

        local itemId, itemCount = XDataCenter.PokemonManager.GetMonsterStarUpCostItemInfo(monsterId)

        local icon = XItemConfigs.GetItemIconById(itemId)
        self.RImgIconCost:SetRawImage(icon)
        self.TxtCostNum.text = itemCount

        self.PanelCost.gameObject:SetActiveEx(true)

        self.BtnUpgrade.gameObject:SetActiveEx(false)

        self.BtnUpgradeStars.gameObject:SetActiveEx(true)

        self.BtnAutoUpgrade:SetDisable(true)
        self.BtnAutoUpgrade.gameObject:SetActiveEx(true)

    else

        self.PanelCost.gameObject:SetActiveEx(false)

        self.BtnUpgrade:SetDisable(true)
        self.BtnUpgrade.gameObject:SetActiveEx(true)

        self.BtnUpgradeStars.gameObject:SetActiveEx(false)

        self.BtnAutoUpgrade.gameObject:SetActiveEx(false)

    end
end

function XUiPokemonMonster:UpdateSkills()
    local monsterId = self.MonsterIds[self.SelectMonsterIndex]

    local isBoss = XPokemonConfigs.CheckMonsterType(monsterId, XPokemonConfigs.MonsterType.Boss)
    self.TxtSkillDescBoss.gameObject:SetActiveEx(isBoss)
    self.TxtSkillDescMember.gameObject:SetActiveEx(not isBoss)

    local skillIds = XDataCenter.PokemonManager.GetMonsterUsingSkillIdList(monsterId)
    for index, skillId in pairs(skillIds) do
        local grid = self.SkillGrids[index]
        if not grid then
            local go = index == 1 and self.BtnSkill or CSUnityEngineObjectInstantiate(self.BtnSkill, self.PanelSkillLayout)
            grid = XTool.InitUiObjectByUi({}, go)
            self.SkillGrids[index] = grid
        end

        local uiButton = grid.UiButton

        local icon = XPokemonConfigs.GetMonsterSkillIcon(skillId)
        uiButton:SetRawImage(icon)

        local name = XPokemonConfigs.GetMonsterSkillName(skillId)
        uiButton:SetNameByGroup(0, name)

        local canSwith = XDataCenter.PokemonManager.IsMonsterSkillCanSwitch(monsterId, skillId)
        uiButton:ShowTag(canSwith)

        local paramSkillId = skillId
        grid.UiButton.CallBack = function()
            XSaveTool.SaveData(string.format(NewSkillSaveKey, XPlayer.Id, monsterId, index), 0)
            grid.NewPanel.gameObject:SetActiveEx(false)
            self:OnClickBtnSkill(paramSkillId)
        end
        local isNewSkill = XSaveTool.GetData(string.format(NewSkillSaveKey, XPlayer.Id, monsterId, index))
        grid.NewPanel.gameObject:SetActiveEx(isNewSkill == 1)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #skillIds + 1, #self.SkillGrids do
        local grid = self.SkillGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

end

function XUiPokemonMonster:OnClickBtnSkill(skillId)
    local monsterId = self.MonsterIds[self.SelectMonsterIndex]
    if XDataCenter.PokemonManager.IsMonsterSkillCanSwitch(monsterId, skillId) then
        local skillIds = XDataCenter.PokemonManager.GetMonsterCanSwitchSkillIdList(monsterId, skillId)
        XLuaUiManager.Open("UiPokemonSkillSelect", monsterId, skillIds)
    else
        XLuaUiManager.Open("UiPokemonSkillDetails", skillId)
    end
end

function XUiPokemonMonster:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self:BindHelpBtn(self.BtnHelp, "PokemonMonster")
    self.BtnUpgrade.CallBack = function() self:OnClickBtnUpgrade() end
    self.BtnUpgradeStars.CallBack = function() self:OnClickBtnUpgradeStars() end
    self.BtnAutoUpgrade.CallBack = function() self:OnClickBtnAutoUpgrade() end
    self.BtnReset.CallBack = function() self:OnClickBtnReset() end
end

function XUiPokemonMonster:OnClickBtnBack()
    self:Close()
end

function XUiPokemonMonster:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiPokemonMonster:OnClickBtnReset()
    local monsterId = self.MonsterIds[self.SelectMonsterIndex]
    XUiManager.DialogTip(CS.XTextManager.GetText("PokemonResetTipsTitle"), CS.XTextManager.GetText("PokemonResetTipsContent"), XUiManager.DialogType.Normal, nil, function()
        XDataCenter.PokemonManager.PokemonResetUpgradeRequest(monsterId, function(rewards)
            for index, grid in pairs(self.SkillGrids) do
                XSaveTool.SaveData(string.format(NewSkillSaveKey, XPlayer.Id, monsterId, index), 0)
                grid.NewPanel.gameObject:SetActiveEx(false)
            end
            if rewards and #rewards > 0 then
                XUiManager.OpenUiObtain(rewards)
            end
        end)
    end)
end

function XUiPokemonMonster:OnClickBtnUpgrade()
    local monsterId = self.MonsterIds[self.SelectMonsterIndex]
    if XDataCenter.PokemonManager.IsMonsterMaxLevel(monsterId) then
        XUiManager.TipText("PokemonMonsterMaxLevel")
        return
    end

    local costItemId, costItemCount = XPokemonConfigs.GetMonsterLevelCostItemInfo(monsterId, XDataCenter.PokemonManager.GetMonsterLevel(monsterId))
    if costItemId and costItemCount and XDataCenter.ItemManager.GetCount(costItemId) < costItemCount then
        XUiManager.TipText("PokemonUpgradeItemNotEnough")
        return
    end

    local times = 1
    local cb = function() self:PlayLevelUpAnim(monsterId) end
    XDataCenter.PokemonManager.PokemonLevelUpRequest(monsterId, times, cb)
end

function XUiPokemonMonster:OnClickBtnUpgradeStars()
    local monsterId = self.MonsterIds[self.SelectMonsterIndex]

    if XDataCenter.PokemonManager.IsMonsterMaxStar(monsterId) then
        return
    end
    local costItemId, costItemCount = XPokemonConfigs.GetMonsterStarCostItemInfo(monsterId, XDataCenter.PokemonManager.GetMonsterStar(monsterId))
    if costItemId and costItemCount and XDataCenter.ItemManager.GetCount(costItemId) < costItemCount then
        XUiManager.TipText("PokemonUpgradeItemNotEnough")
        return
    end

    local oldStar = XDataCenter.PokemonManager.GetMonsterStar(monsterId)
    local cb = function()
        self:UpdateCurrentMonster()
        self:UpdateCurrentMonsterModel()
        local star = XDataCenter.PokemonManager.GetMonsterStar(monsterId)
        local unlockSkillIds = XDataCenter.PokemonManager.GetMonsterStarUnlockSkillIds(monsterId, star)
        local skillId = unlockSkillIds[1]
        if skillId then
            local pos = XPokemonConfigs.GetMonsterSkillGroupId(skillId) + 1
            local grid = self.SkillGrids[pos]
            if grid then
                XSaveTool.SaveData(string.format(NewSkillSaveKey, XPlayer.Id, monsterId, pos), 1)
                grid.NewPanel.gameObject:SetActiveEx(true)
            end
        end
        XLuaUiManager.Open("UiPokemonStarSuccess", monsterId, oldStar)
    end
    XDataCenter.PokemonManager.PokemonStarUpRequest(monsterId, cb)
end

function XUiPokemonMonster:OnClickBtnAutoUpgrade()
    local monsterId = self.MonsterIds[self.SelectMonsterIndex]

    if XDataCenter.PokemonManager.IsMonsterMaxLevel(monsterId) then
        XUiManager.TipText("PokemonMonsterMaxLevel")
        return
    end

    local times = XDataCenter.PokemonManager.GetMonsterCanLevelUpTimes(monsterId)
    if times < 1 then
        XUiManager.TipText("PokemonMonsterAutoLevelUpLackItem")
        return
    end

    local curLevel = XDataCenter.PokemonManager.GetMonsterLevel(monsterId)
    local cb = function()
        local toLevel = times + curLevel
        local msg = CsXTextManagerGetText("PokemonMonsterLevelUpTo", toLevel)
        XUiManager.TipMsg(msg)
        self:PlayLevelUpAnim(monsterId)
    end
    XLuaUiManager.Open("UiPokemonUpgradePreview", monsterId, cb)
end

local TabBtnIndexToMonsterType = {
    [TabBtnIndex.Shooter] = XPokemonConfigs.MonsterCareer.Shooter,
    [TabBtnIndex.Shield] = XPokemonConfigs.MonsterCareer.Shield,
    [TabBtnIndex.Knight] = XPokemonConfigs.MonsterCareer.Knight,
    [TabBtnIndex.Assassin] = XPokemonConfigs.MonsterCareer.Assassin,
}
function XUiPokemonMonster:GetSelectMonsterType()
    return TabBtnIndexToMonsterType[self.SelectTabBtnIndex]
end

function XUiPokemonMonster:GetSelectMonsterId()
    return self.MonsterIds[self.SelectMonsterIndex]
end

function XUiPokemonMonster:PlayLevelUpAnim(monsterId)
    local asynPlayAnim = asynTask(self.PlayAnimation, self)
    local asynLetAttrsRoll = asynTask(self.LetAttrsRoll, self)

    RunAsyn(function()
        local targetHp = XDataCenter.PokemonManager.GetMonsterHp(monsterId)
        local targetAttack = XDataCenter.PokemonManager.GetMonsterAttack(monsterId)
        local startHp = tonumber(self.TxtHp.text) or 0
        local startAttack = tonumber(self.TxtAttack.text) or 0

        --addAttr refresh
        local deltaHp = targetHp - startHp
        self.TxtAddHealth.text = "+" .. deltaHp
        local deltaAttack = targetAttack - startAttack
        self.TxtAddAttack.text = "+" .. deltaAttack
        --ui refresh
        self:UpdateCurrentMonster()
        self:UpdateCurrentMonsterModel()
        --addAttr anim appear
        asynPlayAnim("NumberEnable")

        --attr anim
        asynLetAttrsRoll(startHp, targetHp, startAttack, targetAttack)

        --addAttr anim disappear
        asynPlayAnim("NumberDisable")

        self:UpdateCurrentMonster()
    end)
end

function XUiPokemonMonster:LetAttrsRoll(startHp, targetHp, startAttack, targetAttack, finishCb)
    if not targetHp then return end
    if not targetAttack then return end

    local onRefreshFunc = function(time)
        if XTool.UObjIsNil(self.TxtHp)
        or XTool.UObjIsNil(self.TxtAttack)
        then
            self:DestroyTimer()
            return true
        end

        if startHp == targetHp
        and startAttack == targetAttack
        then
            return true
        end

        self.TxtHp.text = mathFloor(Lerp(startHp, targetHp, time))
        self.TxtAttack.text = mathFloor(Lerp(startAttack, targetAttack, time))
    end

    self:DestroyTimer()
    self.Timer = XUiHelper.Tween(SCORE_ANIM_DURATION, onRefreshFunc, finishCb)
end

function XUiPokemonMonster:DestroyTimer()
    if self.Timer then
        CSXScheduleManagerUnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPokemonMonster:CheckTabRedDot()
    for index, career in pairs(TabBtnIndexToMonsterType) do
        local monsters = XDataCenter.PokemonManager.GetOwnMonsterIdsByCareer(career)
        local isShowRed = true
        for _, id in pairs(monsters) do
            isShowRed = isShowRed and XRedPointConditionPokemonNewRole.Check(id)
        end
        self.TabBtns[index]:ShowReddot(not isShowRed)
    end
end