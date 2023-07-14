local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
--############## XUiTheatreBattleRoomRoleGrid ########################
local XUiTheatreBattleRoomRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiTheatreBattleRoomRoleGrid")

function XUiTheatreBattleRoomRoleGrid:Ctor()
    self.AdventureMultiDeploy = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetAdventureMultiDeploy()
end

-- entity: XAdventureRole
-- team : XTeam
function XUiTheatreBattleRoomRoleGrid:SetData(entity, team, stageId)
    self.Super.SetData(self, entity, team, stageId)
    local characterViewModel = entity:GetCharacterViewModel()
    self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
    self.TxtPower.text = characterViewModel:GetAbility()
    self.TxtLevel.text = characterViewModel:GetLevel()
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
    self.PanelTry.gameObject:SetActiveEx(XEntityHelper.GetIsRobot(characterViewModel:GetSourceEntityId()))

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

function XUiTheatreBattleRoomRoleGrid:SetInTeamStatus(value)
    self.ImgInTeam.gameObject:SetActiveEx(value)
    if value then
        self.PanelTeamSupport.gameObject:SetActiveEx(false)
    end
end

--######################## XUiTheatreMultiRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiTheatreMultiRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiTheatreMultiRoleDetail")

function XUiTheatreMultiRoleDetail:Ctor()
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.AdventureMultiDeploy = self.AdventureManager:GetAdventureMultiDeploy()
end

-- characterType : XCharacterConfigs.CharacterType
function XUiTheatreMultiRoleDetail:GetEntities(characterType)
    local roles = self.AdventureManager:GetCurrentRoles(true)
    local result = {}
    for _, role in ipairs(roles) do
        if role:GetCharacterViewModel():GetCharacterType() == characterType then
            table.insert(result, role)
        end
    end
    return result
end

function XUiTheatreMultiRoleDetail:GetCharacterViewModelByEntityId(entityId)
    local role = self.AdventureManager:GetRole(entityId)
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
    team:UpdateEntityTeamPos(rootUi.CurrentEntityId, nil, false)
    self.__AOP_OtherTeam = nil
end

return XUiTheatreMultiRoleDetail