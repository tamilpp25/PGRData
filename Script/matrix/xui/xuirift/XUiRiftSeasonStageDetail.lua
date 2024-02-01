local XUiGridRiftMonsterDetail = require("XUi/XUiRift/Grid/XUiGridRiftMonsterDetail")

---@class XUiRiftSeasonStageDetail : XLuaUi
local XUiRiftSeasonStageDetail = XLuaUiManager.Register(XLuaUi, "UiRiftSeasonStageDetail")

function XUiRiftSeasonStageDetail:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseMask, self.OnBtnCloseMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnBtnRewardClick)
end

function XUiRiftSeasonStageDetail:OnStart(layerId, closeCb)
    self.XFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(layerId)
    self.XStageGroup = self.XFightLayer:GetStage()
    self.CloseCb = closeCb
    self:UpdateView()
    self:CountDown()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:CountDown()
    end, XScheduleManager.SECOND, 0)
end

function XUiRiftSeasonStageDetail:OnEnable()
    self:UpdateView()
end

function XUiRiftSeasonStageDetail:OnDestroy()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
    end
    self.CloseCb()
end

function XUiRiftSeasonStageDetail:UpdateView()
    self.TxtStageName.text = XDataCenter.RiftManager:GetSeasonName()
    self.TxtStageInfo.text = XDataCenter.RiftManager:GetSeasonDesc()

    local cur, total = self.XStageGroup:GetProgress()
    self.TxtProgress.text = cur .. "/" .. total

    local datas = self.XStageGroup:GetAllEntityMonsters()
    self:RefreshTemplateGrids(self.GridMonster, datas, self.GridMonster.parent, nil, "UiRiftSeasonStageDetail", function(cell, data)
        local grid = XUiGridRiftMonsterDetail.New(cell.Transform)
        grid:Refresh(data, self.XStageGroup)
    end)
end

function XUiRiftSeasonStageDetail:CountDown()
    local time = XDataCenter.RiftManager:GetSeasonEndTime()
    if time > 0 then
        local time = XDataCenter.RiftManager:GetSeasonEndTime()
        local seasonIndex = XDataCenter.RiftManager:GetSeasonIndex()
        local config = XDataCenter.RiftManager.GetCurrentConfig()
        local txt
        if seasonIndex == 1 then
            txt = XUiHelper.GetText("RiftCountDownDesc1", XDataCenter.RiftManager:GetSeasonName())
        elseif seasonIndex == #config.PeriodName then
            txt = XUiHelper.GetText("RiftCountDownDesc2")
        else
            txt = XUiHelper.GetText("RiftCountDownDesc3")
        end
        self.TxtTime.text = string.format("%s%s", txt, XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
    end
end

function XUiRiftSeasonStageDetail:OnBtnCloseMaskClick()
    self:Close()
end

function XUiRiftSeasonStageDetail:OnBtnFightClick()
    local doFun = function()
        local stageId = XDataCenter.RiftManager.GetCurrSelectRiftStageGroup():GetAllEntityStages()[1].StageId -- 单人只有1个stage
        XLuaUiManager.PopThenOpen("UiBattleRoleRoom", stageId, XDataCenter.RiftManager.GetSingleTeamData(), require("XUi/XUiRift/Grid/XUiRiftBattleRoomProxy"))
    end

    local xChapter = self.XStageGroup:GetParent():GetParent()
    XDataCenter.RiftManager.CheckDayTipAndDoFun(xChapter, doFun)
end

function XUiRiftSeasonStageDetail:OnBtnRewardClick()
    XLuaUiManager.Open("UiRiftPreview", self.XFightLayer)
end

return XUiRiftSeasonStageDetail