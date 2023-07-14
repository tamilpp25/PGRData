local XUiPanelAssignFormation = XClass(nil, "XUiPanelAssignFormation")

local XUiGridAssignFormationTeam = require("XUi/XUiAssign/XUiGridAssignFormationTeam")

function XUiPanelAssignFormation:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiPanelAssignFormation:InitComponent()
    self.GridFormationTeam.gameObject:SetActiveEx(false)
    -- CsXUiHelper.RegisterClickEvent(self.BtnClose, function() self:OnBtnCloseClick() end)
    CsXUiHelper.RegisterClickEvent(self.BtnConfirm, function() self:OnBtnConfirmClick() end)
    self.TeamGridList = {}
end

function XUiPanelAssignFormation:Show(groupId)
    self.GroupId = groupId
    XDataCenter.FubenAssignManager.OccupyFirstSelectTeamId = nil
    XDataCenter.FubenAssignManager.OccupyFirstSelectOrder = nil
    XDataCenter.FubenAssignManager.OccupySecondSelectTeamId = nil
    XDataCenter.FubenAssignManager.OccupySecondSelectOrder = nil
    self.GameObject:SetActiveEx(true)
    self:Refresh()
end

function XUiPanelAssignFormation:Close()
    self.GameObject:SetActiveEx(false)
    self:RemoveTimer()
end

function XUiPanelAssignFormation:GetTeamGrid(index)
    local grid = self.TeamGridList[index]
    if not grid then
        local obj = CS.UnityEngine.Object.Instantiate(self.GridFormationTeam)
        obj.transform:SetParent(self.PanelFormationTeamContent, false)
        grid = XUiGridAssignFormationTeam.New(self, obj)
        self.TeamGridList[index] = grid
    end
    return grid
end

function XUiPanelAssignFormation:ResetTeamGridList(len)
    if #self.TeamGridList > len then
        for _ = len + 1, #self.TeamGridList do
            self.TeamGridList.GameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelAssignFormation:Refresh()
    local data = XDataCenter.FubenAssignManager.GetGroupDataById(self.GroupId)
    self.ListData = data:GetTeamInfoId()

    self:ResetTeamGridList(#self.ListData)
    for i, _ in ipairs(self.ListData) do
        local grid = self:GetTeamGrid(i)
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(self.GroupId, i, self.ListData[i])
    end
end

function XUiPanelAssignFormation:RefreshMemberEffect(state)
    for i, _ in ipairs(self.ListData) do
        local grid = self:GetTeamGrid(i)
        grid.GameObject:SetActiveEx(true)
        grid:RefreshMemberEffect(state)
    end
end

function XUiPanelAssignFormation:RefreshForAnim()
    self:RemoveTimer()
    XLuaUiManager.SetMask(true)

    self:Refresh()
    self:RefreshMemberEffect(XDataCenter.FubenAssignManager.FormationState.Effect)
    self.scheduleId = XScheduleManager.ScheduleOnce(function()
        self:RefreshMemberEffect(XDataCenter.FubenAssignManager.FormationState.Reset)
        XLuaUiManager.SetMask(false)
    end, XDataCenter.FubenAssignManager.FomationAnimFinishDelay)
end

function XUiPanelAssignFormation:RemoveTimer()
    if self.scheduleId then
        XScheduleManager.UnSchedule(self.scheduleId)
        self.scheduleId = nil
    end
end

function XUiPanelAssignFormation:OnBtnConfirmClick()
    self:Close()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_ASSIGN_FORMATION_CONFIRM)
end


function XUiPanelAssignFormation:OnBtnCloseClick()
    self:Close()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_ASSIGN_FORMATION_CONFIRM)
end

return XUiPanelAssignFormation