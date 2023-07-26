local XUiPanelAwarenessFormation = XClass(nil, "XUiPanelAwarenessFormation")

local XUiGridAwarenessFormationTeam = require("XUi/XUiAwareness/Grid/XUiGridAwarenessFormationTeam")

function XUiPanelAwarenessFormation:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiPanelAwarenessFormation:InitComponent()
    self.GridFormationTeam.gameObject:SetActiveEx(false)
    -- CsXUiHelper.RegisterClickEvent(self.BtnClose, function() self:OnBtnCloseClick() end)
    CsXUiHelper.RegisterClickEvent(self.BtnConfirm, function() self:OnBtnConfirmClick() end)
    self.TeamGridList = {}
end

function XUiPanelAwarenessFormation:Show(chapterId)
    self.ChapterId = chapterId
    XDataCenter.FubenAwarenessManager.OccupyFirstSelectTeamId = nil
    XDataCenter.FubenAwarenessManager.OccupyFirstSelectOrder = nil
    XDataCenter.FubenAwarenessManager.OccupySecondSelectTeamId = nil
    XDataCenter.FubenAwarenessManager.OccupySecondSelectOrder = nil
    self.GameObject:SetActiveEx(true)
    self:Refresh()
    XDataCenter.UiPcManager.OnUiEnable(self)
end

function XUiPanelAwarenessFormation:Close()
    XDataCenter.UiPcManager.OnUiDisableAbandoned(true, self)
    self.GameObject:SetActiveEx(false)
    self:RemoveTimer()
end

function XUiPanelAwarenessFormation:GetTeamGrid(index)
    local grid = self.TeamGridList[index]
    if not grid then
        local obj = CS.UnityEngine.Object.Instantiate(self.GridFormationTeam)
        obj.transform:SetParent(self.PanelFormationTeamContent, false)
        grid = XUiGridAwarenessFormationTeam.New(self, obj)
        self.TeamGridList[index] = grid
    end
    return grid
end

function XUiPanelAwarenessFormation:ResetTeamGridList(len)
    if #self.TeamGridList > len then
        for _ = len + 1, #self.TeamGridList do
            self.TeamGridList.GameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelAwarenessFormation:Refresh()
    local data = XDataCenter.FubenAwarenessManager.GetChapterDataById(self.ChapterId)
    self.ListData = data:GetTeamInfoId()

    self:ResetTeamGridList(#self.ListData)
    for i, _ in ipairs(self.ListData) do
        local grid = self:GetTeamGrid(i)
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(self.ChapterId, i, self.ListData[i])
    end
end

function XUiPanelAwarenessFormation:RefreshMemberEffect(state)
    for i, _ in ipairs(self.ListData) do
        local grid = self:GetTeamGrid(i)
        grid.GameObject:SetActiveEx(true)
        grid:RefreshMemberEffect(state)
    end
end

function XUiPanelAwarenessFormation:RefreshForAnim()
    self:RemoveTimer()
    XLuaUiManager.SetMask(true)

    self:Refresh()
    self:RefreshMemberEffect(XDataCenter.FubenAssignManager.FormationState.Effect)
    self.scheduleId = XScheduleManager.ScheduleOnce(function()
        self:RefreshMemberEffect(XDataCenter.FubenAssignManager.FormationState.Reset)
        XLuaUiManager.SetMask(false)
    end, XDataCenter.FubenAssignManager.FomationAnimFinishDelay)
end

function XUiPanelAwarenessFormation:RemoveTimer()
    if self.scheduleId then
        XScheduleManager.UnSchedule(self.scheduleId)
        self.scheduleId = nil
    end
end

function XUiPanelAwarenessFormation:OnBtnConfirmClick()
    self:Close()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_ASSIGN_FORMATION_CONFIRM)
end


function XUiPanelAwarenessFormation:OnBtnCloseClick()
    self:Close()
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_FUBEN_ASSIGN_FORMATION_CONFIRM)
end

return XUiPanelAwarenessFormation