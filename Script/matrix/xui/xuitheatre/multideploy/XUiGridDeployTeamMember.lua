local XUiGridDeployTeamMember = XClass(nil, "XUiGridDeployTeamMember")
local XTheatreTeam = require("XEntity/XTheatre/XTheatreTeam")

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.white,
    [false] = CS.UnityEngine.Color.red,
}

--位置对应的颜色框
local MEMBER_POS_COLOR = {
    [1] = "ImgRed",
    [2] = "ImgBlue",
    [3] = "ImgYellow",
}

function XUiGridDeployTeamMember:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnClick.CallBack = function() self:OnMemberClick() end
    self.AdventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    self.AdventureMultiDeploy = self.AdventureManager:GetAdventureMultiDeploy()

    self.PanelHelp.gameObject:SetActiveEx(false)
end

function XUiGridDeployTeamMember:Refresh(teamId, index, theatreStageId)
    self.TeamId = teamId
    self.MemberIndex = index
    self.TheatreStageId = theatreStageId

    local team = self.AdventureMultiDeploy:GetMultipleTeamByIndex(teamId)
    if not team then
        return
    end
    
    local leaderIndex = team:GetCaptainPos()
    self.ImgLeaderTag.gameObject:SetActiveEx(index == leaderIndex)

    local firstFightIndex = team:GetFirstFightPos()
    self.ImgFirstRole.gameObject:SetActiveEx(index == firstFightIndex)

    for i, goName in pairs(MEMBER_POS_COLOR) do
        self[goName].gameObject:SetActiveEx(index == i)
    end

    local adventureRoleId = team:GetEntityIdByTeamPos(index)
    local isEmpty = not XTool.IsNumberValid(adventureRoleId)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self.PanelNotEmpty.gameObject:SetActiveEx(not isEmpty)

    local role = self.AdventureManager:GetRole(adventureRoleId)
    local isRobot = ((role) and not role:GetIsLocalRole()) and true or false
    self.PanelTrial.gameObject:SetActiveEx(isRobot)

    local entityId = role and role:GetRawDataId()
    local ability = role and role:GetAbility() or 0
    self.TxtAbility.text = ability
    if theatreStageId then
        local recommendAbility = XTheatreConfigs.GetTheatreStageSuggestAbility(theatreStageId)
        self.TxtAbility.color = CONDITION_COLOR[ability >= recommendAbility]
    end

    if not isEmpty then
        local headIcon = XEntityHelper.GetCharacterSmallIcon(entityId)
        self.RImgRoleHead:SetRawImage(headIcon)
    end
    self.RImgRoleHead.gameObject:SetActiveEx(not isEmpty)
end

function XUiGridDeployTeamMember:OnMemberClick()
    local stageIdList = XTheatreConfigs.GetTheatreStageIdList(self.TheatreStageId)
    local teamId = self.TeamId
    local stageId = stageIdList[teamId]
    XLuaUiManager.Open("UiBattleRoomRoleDetail"
        , stageId
        , self.AdventureMultiDeploy:GetMultipleTeamByIndex(teamId)
        , self.MemberIndex
        , require("XUi/XUiTheatre/MultiDeploy/XUiTheatreMultiRoleDetail"))
end

return XUiGridDeployTeamMember