local XUiGridDeployTeamMember = require("XUi/XUiTheatre/MultiDeploy/XUiGridDeployTeamMember")
local XTheatreTeam = require("XEntity/XTheatre/XTheatreTeam")

local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local MemberMaxNum = XEntityHelper.TEAM_MAX_ROLE_COUNT

local XUiGridDeployTeam = XClass(nil, "XUiGridDeployTeam")

function XUiGridDeployTeam:Ctor(ui, rootUi, fightCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.MemberGrids = {}
    self.FightCb = fightCb
    self.RootUi = rootUi

    XTool.InitUiObject(self)

    self.BtnLeader.CallBack = function() self:OnBtnLeaderClick() end
    self.BtnFight.CallBack = function() self:OnBtnFightClick() end
    self.BtnReset.CallBack = function() self:OnBtnResetClick() end

    self.GridDeployMember.gameObject:SetActiveEx(false)

    self.AdventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    self.AdventureMultiDeploy = self.AdventureManager:GetAdventureMultiDeploy()
end

function XUiGridDeployTeam:OnDestroy()
end

--teamId：第几个队伍的下标
--theatreStageId：TheatreStage表的Id
function XUiGridDeployTeam:Refresh(teamId, theatreStageId)
    local stageIdList = XTheatreConfigs.GetTheatreStageIdList(theatreStageId)
    local stageId = stageIdList[teamId]
    if not XTool.IsNumberValid(stageId) then
        return
    end

    self.TeamId = teamId
    self.TheatreStageId = theatreStageId
    self.StageId = stageId
    local team = self:GetTeam()

    --队伍图标
    local icon = XFubenConfigs.GetStageIcon(stageId)
    if icon and icon ~= "" then
        self.RootUi:SetUiSprite(self.ImgRune, icon)
        self.ImgTitleBgFight.gameObject:SetActiveEx(true)
    else
        self.ImgTitleBgFight.gameObject:SetActiveEx(false)
    end

    --队伍名
    self.TxtTitle.text = XFubenConfigs.GetStageName(stageId)

    --队伍描述
    self.TxtBuff.text = XDataCenter.FubenManager.GetStageDes(stageId)

    --战力推荐
    self.TxtRequireAbility.text = XTheatreConfigs.GetTheatreStageSuggestAbility(theatreStageId)

    local isFinished = self.AdventureMultiDeploy:GetMultipleTeamIsWin(teamId)
    self.PanelVictory.gameObject:SetActiveEx(isFinished)

    self:UpdateView()
end

function XUiGridDeployTeam:UpdateView()
    self:UpdateTeam()
end

function XUiGridDeployTeam:UpdateTeam()
    local teamId = self.TeamId
    local theatreStageId = self.TheatreStageId
    local team = self:GetTeam()

    self.TxtLeaderSkill.text = team and team:GetCaptainSkillDesc() or ""

    for index = 1, MemberMaxNum do
        local grid = self.MemberGrids[index]
        if not grid then
            local go = index == 1 and self.GridDeployMember or XUiHelper.Instantiate(self.GridDeployMember, self.PanelDeployMembers)
            grid = XUiGridDeployTeamMember.New(go)
            self.MemberGrids[index] = grid
        end

        grid:Refresh(teamId, index, theatreStageId)

        --蓝色放到第一位
        if index == 2 then
            grid.Transform:SetAsFirstSibling()
        end

        grid.GameObject:SetActiveEx(true)
    end

    for index = MemberMaxNum + 1, #self.MemberGrids do
        self.MemberGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiGridDeployTeam:OnBtnLeaderClick()
    local groupId = self.GroupId
    local teamId = self.TeamId
    local MemberMaxNum = XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
    local team = self:GetTeam()
    local characterIdList = team:GetCharacterAndRobotIds()
    local captainPos = team:GetCaptainPos()
    XLuaUiManager.Open("UiNewRoomSingleTip", self, characterIdList, captainPos, function(index)
        team:UpdateCaptainPos(index)
        self:UpdateTeam()
    end)
end

function XUiGridDeployTeam:GetTeam()
    return self.AdventureMultiDeploy:GetMultipleTeamByIndex(self.TeamId)
end

function XUiGridDeployTeam:OnBtnFightClick()
    self.AdventureMultiDeploy:RequestSetMultiTeam(function()
        if self.FightCb then self.FightCb() end
        local teamId = self.TeamId
        XDataCenter.TheatreManager.SetCurFightStageIndex(teamId)
        XDataCenter.TheatreManager.SetMultiFightState(true)
        self.AdventureManager:EnterFight(self.TheatreStageId, teamId)
    end, self.TheatreStageId)
end

function XUiGridDeployTeam:OnBtnResetClick()
    local callFunc = function()
        local teamId = self.TeamId
        self.AdventureMultiDeploy:RequestTheatreMultiTeamReset(teamId, function()
            local theatreStageId = self.TheatreStageId
            self:Refresh(teamId, theatreStageId)
        end)
    end
    local title = CSXTextManagerGetText("StrongholdTeamResetStageConfirmTitle")
    local content = CSXTextManagerGetText("StrongholdTeamResetStageConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
end

return XUiGridDeployTeam