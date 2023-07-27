local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
--############## XUiTheatreBattleRoomRoleGrid ########################
---@class XUiTheatreBattleRoomRoleGrid:XUiBattleRoomRoleGrid
local XUiTheatreBattleRoomRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiTheatreBattleRoomRoleGrid")

function XUiTheatreBattleRoomRoleGrid:Ctor()
    self.AdventureMultiDeploy = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetAdventureMultiDeploy()
end

-- team : XTeam
---@param entity XTheatreAdventureRole
function XUiTheatreBattleRoomRoleGrid:SetData(entity, team, stageId)
    self.Super.SetData(self, entity, team, stageId)
    local characterViewModel = entity:GetCharacterViewModel()
    self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
    --self.TxtFight.text = characterViewModel:GetAbility()
    self.TxtLevel.text = characterViewModel:GetLevel()
    self.RImgQuality:SetRawImage(characterViewModel:GetQualityIcon())
    --其他队伍信息（文本控件的引用名字被改了，兼容新旧两个文本）
    local isInOtherTeam, teamIndex = self.AdventureMultiDeploy:IsInOtherTeam(team:GetId(), entity:GetId())
    local otherTeamIsWin = self.AdventureMultiDeploy:GetMultipleTeamIsWin(teamIndex)
    local otherTeamText = otherTeamIsWin and XUiHelper.GetText("MemberLock") or XUiHelper.GetText("STMultiTeamInHint", teamIndex)
    if self.TxtTeamSupport then
        self.TxtTeamSupport.text = otherTeamText
    end
    if self.TxtEchelonIndex then
        self.TxtEchelonIndex.text = otherTeamText
    end
    self.PanelTeamSupport.gameObject:SetActiveEx(isInOtherTeam)
end

function XUiTheatreBattleRoomRoleGrid:UpdateFight()
    if self.IsFragment then
        self.PanelFight.gameObject:SetActiveEx(false)
        return
    end

    self.TxtFight.gameObject:SetActiveEx(true)
    self.TxtFight.text = self.Character:GetCharacterViewModel():GetAbility()
    self.PanelFight.gameObject:SetActiveEx(true)
end

function XUiTheatreBattleRoomRoleGrid:SetInTeamStatus(value)
    self.ImgInTeam.gameObject:SetActiveEx(value)
    if value then
        self.PanelTeamSupport.gameObject:SetActiveEx(false)
    end
end

--######################## XUiTheatreMultiRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")

---@class XUiTheatreMultiRoleDetail:XUiBattleRoomRoleDetailDefaultProxy
local XUiTheatreMultiRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiTheatreMultiRoleDetail")

function XUiTheatreMultiRoleDetail:Ctor()
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.AdventureMultiDeploy = self.AdventureManager:GetAdventureMultiDeploy()
    self._IdDir = {}
end

-- characterType : XCharacterConfigs.CharacterType
function XUiTheatreMultiRoleDetail:GetEntities()
    local roles = self.AdventureManager:GetCurrentRoles(true)
    for _, role in ipairs(roles) do
        if not role:GetIsLocalRole() then
            local robotId = role:GetRawData().Id
            self._IdDir[robotId] = role:GetId()
        end
    end
    return roles
end

function XUiTheatreMultiRoleDetail:GetCharacterViewModelByEntityId(entityId)
    local role = self.AdventureManager:GetRoleByRobotId(entityId)
    if role == nil then return nil end
    return role:GetCharacterViewModel()
end

function XUiTheatreMultiRoleDetail:GetGridProxy()
    return XUiTheatreBattleRoomRoleGrid
end

function XUiTheatreMultiRoleDetail:AOPOnStartBefore(rootUi)
    return false
end

function XUiTheatreMultiRoleDetail:AOPOnBtnJoinTeamClickedBefore(rootUi)
    local currentEntityId = rootUi.CurrentEntityId
    local curTeam = rootUi.Team
    local role = self.AdventureManager:GetRole(currentEntityId)
    if not role then
        return
    end

    local adventureRoleId = role:GetId()
    local isInOtherTeam, otherTeamIndex, otherTeamPos = self.AdventureMultiDeploy:IsInOtherTeam(curTeam:GetId(), adventureRoleId, true)
    local otherTeam = XTool.IsNumberValid(otherTeamIndex) and self.AdventureMultiDeploy:GetMultipleTeamByIndex(otherTeamIndex)
    -- 其他队伍有相同的角色
    if isInOtherTeam then
        if self.AdventureMultiDeploy:GetMultipleTeamIsWin(otherTeamIndex) then
            XUiManager.TipText("StrongholdElectricDeployInTeamLock")
            return true
        end

        --其他队伍是否已上阵相同型号角色
        local sameCharacter = self.AdventureMultiDeploy:IsInOtherTeam(curTeam:GetId(), adventureRoleId)
        if not sameCharacter then
            XUiManager.TipText("StrongholdElectricDeploySameCharacter")
            return true
        end

        local finishedCallback = function()
            local characterName = self.AdventureManager:GetRole(currentEntityId):GetCharacterViewModel():GetName()
            local currentTeamIndex = curTeam:GetTeamIndex()
            local teamIndex = otherTeam:GetTeamIndex()
            XLuaUiManager.Open("UiDialog", XUiHelper.GetText("ExchangeTeamMemberTitle")
            , XUiHelper.GetText("ExchangeTeamMemberContent", characterName, XUiHelper.GetText("BattleTeamTitle", teamIndex), XUiHelper.GetText("BattleTeamTitle", currentTeamIndex))
            , XUiManager.DialogType.Normal, nil, function()
                local currentTeam = rootUi.Team
                local currentPos = rootUi.Pos
                local currentPosEntityId = currentTeam:GetEntityIdByTeamPos(currentPos)
                otherTeam:UpdateEntityTeamPos(currentPosEntityId, otherTeamPos, true)
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
    self.__AOP_OtherTeam = otherTeam
end

function XUiTheatreMultiRoleDetail:AOPOnBtnJoinTeamClickedAfter(rootUi)
    local team = self.__AOP_OtherTeam
    if not team then return nil end
    if team:GetId() == rootUi.Team:GetId() then return nil end
    local id = self._IdDir[rootUi.CurrentEntityId] and self._IdDir[rootUi.CurrentEntityId] or rootUi.CurrentEntityId
    team:UpdateEntityTeamPos(id, nil, false)
    self.__AOP_OtherTeam = nil
end

function XUiTheatreMultiRoleDetail:GetFilterControllerConfig()
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetModelCharacterFilterController()["UiTheatreBattleRoomDetail"]
end

---v2.6 新筛选器用
function XUiTheatreMultiRoleDetail:CheckInTeam(team, entityId)
    local id = self._IdDir[entityId] and self._IdDir[entityId] or entityId
    return team:GetEntityIdIsInTeam(id)
end

function XUiTheatreMultiRoleDetail:GetCurrentEntityId(currentEntityId)
    for robotId, entityId in pairs(self._IdDir) do
        if entityId == currentEntityId then
            return robotId
        end
    end
    return currentEntityId
end

return XUiTheatreMultiRoleDetail