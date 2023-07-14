local CsGetText = CS.XTextManager.GetText
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
--######################## XUiSuperTowerBattleRoomRoleGrid ########################
local XUiSuperTowerBattleRoomRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiSuperTowerBattleRoomRoleGrid")

-- superTowerRole : XSuperTowerRole
-- team : XTeam
function XUiSuperTowerBattleRoomRoleGrid:SetData(superTowerRole, team, stageId)
    local characterViewModel = superTowerRole:GetCharacterViewModel()
    self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
    self.RImgQuality:SetRawImage(characterViewModel:GetQualityIcon())
    -- 元素图标
    local obtainElementIcons = characterViewModel:GetObtainElementIcons()
    local elementIcon
    for i = 1, 3 do
        elementIcon = obtainElementIcons[i]
        self["RImgElement" .. i].gameObject:SetActiveEx(elementIcon ~= nil)
        if elementIcon then
            self["RImgElement" .. i]:SetRawImage(elementIcon)
        end
    end
    local superTowerManager = XDataCenter.SuperTowerManager
    self.TxtPower.text = superTowerRole:GetAbility()
    -- 超限等级
    self.TxtSuperLevel.text = superTowerRole:GetSuperLevel()
    local isOpenTransfinite = superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.Transfinite)
    self.PanelSuperLevel.gameObject:SetActiveEx(isOpenTransfinite)
    -- 试玩
    self.PanelTry.gameObject:SetActiveEx(superTowerRole:GetIsRobot())
    -- 是否上阵了同一角色
    local isInTeam = team:GetEntityIdIsInTeam(superTowerRole:GetId())
    local isHasSameCharacterInTeam = team:CheckHasSameCharacterId(superTowerRole:GetId())
    if not isInTeam and isHasSameCharacterInTeam then
        self.PanelSameRole.gameObject:SetActiveEx(true)
    else
        self.PanelSameRole.gameObject:SetActiveEx(false)
    end
    -- 特典
    local isOpenBonusChara = superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.BonusChara)
    self.PanelRogueLikeTheme.gameObject:SetActiveEx(isOpenBonusChara and superTowerRole:GetIsInDult())
    -- 其他梯队信息
    local targetStage = superTowerManager.GetTargetStageByStageId(stageId)
    if targetStage then
        local index = superTowerManager.GetTeamManager():CheckMemberIsInTeam(
        superTowerManager.TeamId[targetStage:GetStageType()]
        , XSuperTowerConfigs.MaxMultiTeamCount
        , superTowerRole:GetId())
        self.PanelTeamSupport.gameObject:SetActiveEx(index > 0)
        if index > 0 then
            self.TxtEchelonIndex.text = CsGetText("STMultiTeamInHint", index)
        end
    else
        self.PanelTeamSupport.gameObject:SetActiveEx(false)
    end
end

function XUiSuperTowerBattleRoomRoleGrid:SetInTeamStatus(value)
    self.ImgInTeam.gameObject:SetActiveEx(value)
    if value then
        self.PanelTeamSupport.gameObject:SetActiveEx(false)
    end
end

--######################## XUiSuperTowerBattleRoomRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiSuperTowerBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiSuperTowerBattleRoomRoleDetail")

-- characterType : XCharacterConfigs.CharacterType
function XUiSuperTowerBattleRoomRoleDetail:GetEntities(characterType)
    return XDataCenter.SuperTowerManager.GetRoleManager():GetCanFightRoles(characterType)
end

function XUiSuperTowerBattleRoomRoleDetail:GetFilterJudge()
    return XDataCenter.SuperTowerManager.GetRoleManager():GetFilterJudge()
end

function XUiSuperTowerBattleRoomRoleDetail:GetGridProxy()
    return XUiSuperTowerBattleRoomRoleGrid
end

function XUiSuperTowerBattleRoomRoleDetail:GetChildPanelData()
    if self.ChildPanelData == nil then
        self.ChildPanelData = {
            assetPath = XUiConfigs.GetComponentUrl("UiSuperTowerBattleRoomRoleDetail"),
            proxy = require("XUi/XUiSuperTower/Room/XUiSuperTowerBattleRoomChildPanel"),
            proxyArgs = { "Team", "StageId", "CurrentEntityId" }
        }
    end
    return self.ChildPanelData
end

function XUiSuperTowerBattleRoomRoleDetail:GetCharacterViewModelByEntityId(entityId)
    return XDataCenter.SuperTowerManager.GetRoleManager():GetRole(entityId):GetCharacterViewModel()
end

-- team : XTeam
-- sortTagType : XRoomCharFilterTipsConfigs.EnumSortTag
function XUiSuperTowerBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
    if sortTagType == nil then
        entities = XUiSuperTowerBattleRoomRoleDetail.Super.SortEntitiesWithTeam(self, team, entities)
    else
        entities = XDataCenter.SuperTowerManager.GetRoleManager():SortRoles(entities, sortTagType, true)
        local roleManager = XDataCenter.SuperTowerManager.GetRoleManager()
        local role, entityId
        local entityIds = team:GetEntityIds()
        for pos = XEntityHelper.TEAM_MAX_ROLE_COUNT, 1, -1 do
            entityId = entityIds[pos]
            role = roleManager:GetRole(entityId)
            if role then
                local index = table.indexof(entities, role)
                if index ~= false then
                    table.remove(entities, index)
                    table.insert(entities, 1, role)
                end
            end
        end
    end
    return entities
end

function XUiSuperTowerBattleRoomRoleDetail:GetAutoCloseInfo()
    return true, XDataCenter.SuperTowerManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.SuperTowerManager.HandleActivityEndTime()
        end
    end
end

function XUiSuperTowerBattleRoomRoleDetail:GetRoleDynamicGrid(rootUi)
    return rootUi.GridCharacterSupertower
end

-- return { [XRoomCharFilterTipsConfigs.EnumSortTag.xxx] = true } 即为隐藏
function XUiSuperTowerBattleRoomRoleDetail:GetHideSortTagDic()
    local superTowerManager = XDataCenter.SuperTowerManager
    local isOpen = superTowerManager.CheckFunctionUnlockByKey(superTowerManager.FunctionName.Transfinite)
    return {[XRoomCharFilterTipsConfigs.EnumSortTag.SuperLevel] = not isOpen }
end

-- return1 : XRoomCharFilterTipsConfigs.EnumFilterType
-- return2 : XRoomCharFilterTipsConfigs.EnumSortType
function XUiSuperTowerBattleRoomRoleDetail:GetFilterTypeAndSortType()
    return XRoomCharFilterTipsConfigs.EnumFilterType.SuperTower, XRoomCharFilterTipsConfigs.EnumSortType.SuperTower
end


--######################## AOP ########################
function XUiSuperTowerBattleRoomRoleDetail:AOPOnStartBefore(rootUi)
    rootUi.PanelAsset.gameObject:SetActiveEx(false)
end

function XUiSuperTowerBattleRoomRoleDetail:AOPOnStartAfter(rootUi)

end

function XUiSuperTowerBattleRoomRoleDetail:AOPOnBtnJoinTeamClickedBefore(rootUi)
    local currentEntityId = rootUi.CurrentEntityId
    local targetStage = XDataCenter.SuperTowerManager.GetTargetStageByStageId(rootUi.StageId)
    if not targetStage then return end
    if targetStage:GetStageType() ~= XDataCenter.SuperTowerManager.StageType.MultiTeamMultiWave then
        return
    end
    -- 多队伍情况下不能上阵同一个角色
    local teams = XDataCenter.SuperTowerManager.GetTeamManager():GetTeamsByIdAndCount(
    XDataCenter.SuperTowerManager.TeamId[targetStage:GetStageType()], XSuperTowerConfigs.MaxMultiTeamCount)
    local exchangeTeam = nil
    local exchangePos = nil
    for teamIndex, team in ipairs(teams) do
        if team:GetId() ~= rootUi.Team:GetId() then
            local hasSame, pos = team:CheckHasSameCharacterId(currentEntityId)
            if hasSame then
                exchangeTeam = team
                exchangePos = pos
                break
            end
        end
    end
    -- 其他队伍有相同的角色  
    if exchangeTeam ~= nil then
        -- 如果该角色的实体id不在任何一个队伍里，弹特殊提示
        local teamIndex = XDataCenter.SuperTowerManager.GetTeamManager():CheckMemberIsInTeam(
        XDataCenter.SuperTowerManager.TeamId[targetStage:GetStageType()]
        , XSuperTowerConfigs.MaxMultiTeamCount
        , currentEntityId)
        if teamIndex <= 0 then
            XUiManager.TipError(CsGetText("STSameCharacterNotInTeamTip"))
            return true
        end
        local finishedCallback = function()
            local characterName = XDataCenter.SuperTowerManager:GetRoleManager():GetRole(currentEntityId):GetCharacterViewModel():GetName()
            local currentTeamIndex = nil
            for teamIndex, team in ipairs(teams) do
                if team:GetId() == rootUi.Team:GetId() then
                    currentTeamIndex = teamIndex
                    break
                end
            end
            XLuaUiManager.Open("UiDialog", CsGetText("ExchangeTeamMemberTitle")
            , CsGetText("ExchangeTeamMemberContent", characterName, CsGetText("BattleTeamTitle", teamIndex), CsGetText("BattleTeamTitle", currentTeamIndex))
            , XUiManager.DialogType.Normal, nil, function()
                local currentTeam = rootUi.Team
                local currentPos = rootUi.Pos
                local currentPosEntityId = currentTeam:GetEntityIdByTeamPos(currentPos)
                exchangeTeam:UpdateEntityTeamPos(currentPosEntityId, exchangePos, true)
                rootUi.Team:UpdateEntityTeamPos(currentEntityId, currentPos, true)
                rootUi:Close()
            end)
        end
        if rootUi:CheckCanJoin(currentEntityId, finishedCallback) then
            finishedCallback()
        end
        return true
    end
    -- 当前的实体是否在其他梯队中
    self.__AOP_OtherTeam = exchangeTeam
end

function XUiSuperTowerBattleRoomRoleDetail:AOPOnBtnJoinTeamClickedAfter(rootUi)
    local team = self.__AOP_OtherTeam
    if not team then return nil end
    if team:GetId() == rootUi.Team:GetId() then return nil end
    team:UpdateEntityTeamPos(rootUi.CurrentEntityId, nil, false)
    self.__AOP_OtherTeam = nil
end

return XUiSuperTowerBattleRoomRoleDetail