local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local MAX_GRID_NUM = 3

local XUiChessPursuitGridQuickDeployMember = require("XUi/XUiChessPursuit/XUi/QuickDeploy/XUiChessPursuitGridQuickDeployMember")

local XUiChessPursuitGridQuickDeployTeam = XClass(nil, "XUiChessPursuitGridQuickDeployTeam")

function XUiChessPursuitGridQuickDeployTeam:Ctor(ui, memberClickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MemberGridList = {}
    self.Team = {}
    self.MemberClickCb = memberClickCb

    XTool.InitUiObject(self)
    self.TabGroup = {
        self.BtnRed,
        self.BtnBlue,
        self.BtnYellow,
    }
    self.TagCaptainGroup = {
        self.BtnCaptainRed,
        self.BtnCaptainBlue,
        self.BtnCaptainYellow
    }
    self.PanelTabFirst:Init(self.TabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.PanelTabCaptain:Init(self.TagCaptainGroup, function(tabIndex) self:OnClickCaptainTabCallBack(tabIndex) end)
    self.GridTeamMember.gameObject:SetActiveEx(false)
end

function XUiChessPursuitGridQuickDeployTeam:Refresh(teamGridIndex, mapId, team)
    self.Team = team
    self.TeamGridIndex = teamGridIndex
    self.TextTitle.text = CS.XTextManager.GetText("ChessPursuitQuickDeployTeamTitle", teamGridIndex)

    local stageId = XChessPursuitConfig.GetChessPursuitBossStageIdByMapId(mapId)
    local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(stageId)
    local captainPos = XDataCenter.ChessPursuitManager.GetCaptainPosInTempTeamData(mapId, teamGridIndex)
    local firstFightPos = XDataCenter.ChessPursuitManager.GetFirstFightPosInTempTeamData(mapId, teamGridIndex)

    for index = 1, MAX_GRID_NUM do
        local pos = XDataCenter.ChessPursuitManager.TeamPosConvert(index)
        local grid = self.MemberGridList[index]
        local characterId = team.TeamData[pos]

        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridTeamMember, self.PanelRole)
            local clickCb = function(paramCharacterId, paramGrid, paramPos, cacheTeam, cacheCharacterLimitType, teamGridIndex)
                self.MemberClickCb(paramCharacterId, paramGrid, paramPos, cacheTeam, cacheCharacterLimitType, teamGridIndex)
            end

            grid = XUiChessPursuitGridQuickDeployMember.New(go, pos, clickCb)
            grid.GameObject:SetActiveEx(true)
            self.MemberGridList[index] = grid
        end

        
        grid:Refresh(characterId, self.Team, characterLimitType, teamGridIndex)
        grid:RefreshCaptainPos(captainPos)
        grid:RefreshFirstFightPos(firstFightPos)

        self.TabGroup[pos].gameObject:SetActiveEx(true)
    end

    if not self.SelectedFirstPos then
        self.PanelTabFirst:SelectIndex(firstFightPos)
    end

    if not self.SelectedCaptainPos then
        self.PanelTabCaptain:SelectIndex(captainPos)
    end

    if not XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType) then
        self.PanelRequireCharacter.gameObject:SetActiveEx(false)
        return
    else
        self.PanelRequireCharacter.gameObject:SetActiveEx(true)
    end

    local icon = XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    self.ImgRequireCharacter:SetSprite(icon)

    local name = XFubenConfigs.GetStageCharacterLimitName(characterLimitType)
    self.TxtRequireCharacter.text = name
end

function XUiChessPursuitGridQuickDeployTeam:OnClickTabCallBack(firstFightPos)
    if self.SelectedFirstPos and self.SelectedFirstPos == firstFightPos then
        return
    end
    self.SelectedFirstPos = firstFightPos

    if self.Team then
        self.Team.FirstFightPos = firstFightPos
    end

    local gridList = self.MemberGridList
    local gridNum = #gridList
    for index = 1, gridNum do
        local grid = gridList[index]
        grid:RefreshFirstFightPos(firstFightPos)
    end

    XDataCenter.ChessPursuitManager.SetPlayerTeamDataFirstFightPos(firstFightPos, self.TeamGridIndex)
end

function XUiChessPursuitGridQuickDeployTeam:OnClickCaptainTabCallBack(captainPos)
    if self.SelectedCaptainPos and self.SelectedCaptainPos == captainPos then
        return
    end
    self.SelectedCaptainPos = captainPos

    if self.Team then
        self.Team.CaptainPos = captainPos
    end

    local gridList = self.MemberGridList
    local gridNum = #gridList
    for index = 1, gridNum do
        local grid = gridList[index]
        grid:RefreshCaptainPos(captainPos)
    end

    XDataCenter.ChessPursuitManager.SetPlayerTeamDataCaptainPos(captainPos, self.TeamGridIndex)
end

function XUiChessPursuitGridQuickDeployTeam:GetTeam()
    return self.Team
end

return XUiChessPursuitGridQuickDeployTeam