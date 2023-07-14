local XUiGridDoomsdayTarget = require("XUi/XUiDoomsday/XUiGridDoomsdayTarget")

local XUiDoomsdayLineDetail = XLuaUiManager.Register(XLuaUi, "UiDoomsdayLineDetail")

function XUiDoomsdayLineDetail:OnAwake()
    self:AutoAddListener()
end

function XUiDoomsdayLineDetail:OnStart(stageId, closeCb)
    self.StageId = stageId
    self.CloseCb = closeCb

    self:InitView()
end

function XUiDoomsdayLineDetail:OnEnable()
    self:UpdateView()
end

function XUiDoomsdayLineDetail:AutoAddListener()
    self.BtnClose.CallBack = handler(self, self.OnClickBtnClose)
    self.BtnReStart.CallBack = handler(self, self.OnClickBtnReStart)
    self.BtnEnter.CallBack = handler(self, self.OnClickBtnEnter)
end

function XUiDoomsdayLineDetail:InitView()
    local stageId = self.StageId
    self.TxtTitle.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Name")
    self.TxtDescribe.text = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "Desc")

    local mainTargetId = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "MainTaskId")
    self.TxtMainTarget.text = XDoomsdayConfigs.TargetConfig:GetProperty(mainTargetId, "Desc")
end

function XUiDoomsdayLineDetail:UpdateView()
    local stageId = self.StageId
    local stageData = XDataCenter.DoomsdayManager.GetStageData(stageId)

    local subTargetIds = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "SubTaskId")
    self:RefreshTemplateGrids(self.GridSubTarget, subTargetIds, self.PanelTargetList, XUiGridDoomsdayTarget)
    for index, targetId in pairs(subTargetIds) do
        local target = XDataCenter.DoomsdayManager.GetStageData(stageId):GetTarget(targetId)
        self:BindViewModelPropertyToObj(
            stageData,
            function()
                local passed = XDataCenter.DoomsdayManager.IsStageSubTargetFinished(stageId, targetId)
                self:GetGrid(index):SetPassed(passed)
            end,
            "_Star"
        )
    end

    --按钮状态
    self:BindViewModelPropertyToObj(
        stageData,
        function(fighting)
            if XTool.UObjIsNil(self.BtnReStart) then
                return
            end

            self.BtnReStart.gameObject:SetActiveEx(fighting)
            if fighting then
                self.BtnEnter:SetNameByGroup(
                    0,
                    CsXTextManagerGetText("DoomsdayStagetDetailBtnResume", stageData:GetProperty("_Day"))
                )
            else
                self.BtnEnter:SetNameByGroup(0, CsXTextManagerGetText("DoomsdayStagetDetailBtnEnter"))
            end
        end,
        "_Fighting"
    )
end

function XUiDoomsdayLineDetail:OnClickBtnClose()
    if self.CloseCb then
        self.CloseCb()
    end
    self:Close()
end

function XUiDoomsdayLineDetail:OnClickBtnReStart()
    XDataCenter.DoomsdayManager.EnterFight(self.StageId, true)
end

function XUiDoomsdayLineDetail:OnClickBtnEnter()
    XDataCenter.DoomsdayManager.EnterFight(self.StageId)
end

return XUiDoomsdayLineDetail
