local XUiGridDoomsdayTeam = XClass(nil, "XUiGridDoomsdayTeam")

function XUiGridDoomsdayTeam:Ctor(stageId, selectCb, createTeamCb)
    self.StageId = stageId
    self.SelectCb = selectCb
    self.CreateTeamCb = createTeamCb
end

function XUiGridDoomsdayTeam:Init()
    self.PanelLock = self.PanelLock or XUiHelper.TryGetComponent(self.Transform, "PanelLock")
    self.BtnTeam.CallBack = handler(self, self.OnClickBtnTeam)
    self:SetSelect(false)
end

function XUiGridDoomsdayTeam:Refresh(teamId)
    self.TeamId = teamId

    local stageData = XDataCenter.DoomsdayManager.GetStageData(self.StageId)
    self.StageData = stageData

    self.Parent:BindViewModelPropertiesToObj(
        stageData,
        function(unlockCount, teamCount)
            local lock = teamId > unlockCount --未解锁
            local notTeam = teamId > teamCount --未组建队伍

            self.PanelLock.gameObject:SetActiveEx(notTeam and lock)
            self.PanelNormal.gameObject:SetActiveEx(not notTeam or not lock)
            self.PanelNotTeam.gameObject:SetActiveEx(not lock and notTeam)
            self.BtnTeam.gameObject:SetActiveEx(not notTeam or (not lock and notTeam))

            if notTeam then
                self.BtnTeam:SetName(CsXTextManagerGetText("DoomsdayDetailTeamBtnCreate"))
            else
                self.BtnTeam:SetName(CsXTextManagerGetText("DoomsdayDetailTeamBtn"))
            end

            --队伍状态
            local team = stageData:GetTeam(teamId)
            if not team:IsEmpty() then
                self.Parent:BindViewModelPropertyToObj(
                    team,
                    function(state)
                        self.StatuEvent.gameObject:SetActiveEx(state == XDoomsdayConfigs.TEAM_STATE.BUSY)
                        self.StatusMove.gameObject:SetActiveEx(state == XDoomsdayConfigs.TEAM_STATE.MOVING)
                        self.StatuStand.gameObject:SetActiveEx(state == XDoomsdayConfigs.TEAM_STATE.WAITING)
                        self:UpdateTeamBtn()
                    end,
                    "_State"
                )
            end

            self:UpdateTeamBtn()
        end,
        "_UnlockTeamCount",
        "_TeamCount"
    )
end

function XUiGridDoomsdayTeam:UpdateTeamBtn()
    local teamId = self.TeamId
    local stageData = self.StageData

    if XTool.IsTableEmpty(stageData) then
        return
    end

    local isBusy = stageData:IsTeamBusy(teamId)
    local unlock = stageData:CanCreateTeam(teamId)
    local teamExist = stageData:CheckTeamExist(teamId)

    --未解锁/事件中, 按钮均不可点击
    local btnDisable = isBusy or not unlock
    self.BtnTeam:SetDisable(btnDisable, not btnDisable)
    self.BtnTeam.gameObject:SetActiveEx(unlock or teamExist)
end

function XUiGridDoomsdayTeam:SetSelect(value)
    self.Selected = value
    self.PanelSelect.gameObject:SetActiveEx(value)
    self:UpdateTeamBtn()
end

function XUiGridDoomsdayTeam:SetBtnDisable(value)
    value = value and true or false
    self.BtnTeam:SetDisable(value, not value)
end

function XUiGridDoomsdayTeam:OnClickBtnTeam()
    local teamId = self.TeamId
    local stageData = self.StageData
    local team = stageData:GetTeam(teamId)
    if team:IsEmpty() then
        self.CreateTeamCb()
        XLuaUiManager.Open("UiDoomsdayTeamTip", self.StageId, teamId)
    else
        self.Selected = not self.Selected
        local tmpId = self.Selected and self.TeamId or nil
        self.SelectCb(tmpId)
    end
end

return XUiGridDoomsdayTeam
