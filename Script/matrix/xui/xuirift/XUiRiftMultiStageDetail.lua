--大秘境关卡节点详情 多队伍
local XUiRiftMultiStageDetail = XLuaUiManager.Register(XLuaUi, "UiRiftMultiStageDetail")
local XUiGridRiftMultiMonster = require("XUi/XUiRift/Grid/XUiGridRiftMultiMonster")

function XUiRiftMultiStageDetail:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiRiftMultiStageDetail:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseMask, self.OnBtnCloseMaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick)
    XUiHelper.RegisterClickEvent(self, self.BtnResetting, self.OnBtnResetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReward, self.OnBtnRewardClick)
end

function XUiRiftMultiStageDetail:InitDynamicTable()
    -- 选择作战层的滑动列表
    self.DynamicTable = XDynamicTableNormal.New(self.PanelMonsterList)
    self.DynamicTable:SetProxy(XUiGridRiftMultiMonster, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftMultiStageDetail:OnStart(layerId, closeCb)
    self.LayerId = layerId
    self.CloseCb = closeCb
end

function XUiRiftMultiStageDetail:OnEnable()
    self:RefreshUiShow()
end

function XUiRiftMultiStageDetail:RefreshUiShow()
    -- 关卡信息
    self.XFightLayer = XDataCenter.RiftManager.GetEntityFightLayerById(self.LayerId)
    self.XStageGroup = self.XFightLayer:GetStage()
    self.TxtStageName.text = self.XStageGroup:GetName()
    self.TxtStageInfo.text = self.XStageGroup:GetDesc()
    local cur , total = self.XStageGroup:GetProgress()
    self.TxtProgress.text = cur.."/"..total
    local allStageList = self.XStageGroup:GetAllEntityStages()
    -- 赛季信息
    if self.XFightLayer:IsSeasonLayer() then
        self.TxtMatchName2.text = XDataCenter.RiftManager:GetSeasonName()
        self:CountDown()
        self.Timer = XScheduleManager.ScheduleForever(function()
            self:CountDown()
        end, XScheduleManager.SECOND, 0)
    else
        self.TxtMatchName2.text = ""
        self.TxtMatchTime.text = ""
    end
    -- 敌人情报
    self:RefreshDynamicTable(allStageList)
end

function XUiRiftMultiStageDetail:CountDown()
    local time = XDataCenter.RiftManager:GetSeasonEndTime()
    if time > 0 then
        self.TxtMatchTime.text = XUiHelper.GetText("TurntableTime", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
    end
end

function XUiRiftMultiStageDetail:RefreshDynamicTable(list)
    self.DataList = list
    self.DynamicTable:SetDataSource(list)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiRiftMultiStageDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DataList[index], self.XStageGroup, index)
    end
end

function XUiRiftMultiStageDetail:OnBtnFightClick()
    local doFun = function ()
        XLuaUiManager.PopThenOpen("UiRiftDeploy", self.XStageGroup)
    end

    local xChapter = self.XStageGroup:GetParent():GetParent()
    XDataCenter.RiftManager.CheckDayTipAndDoFun(xChapter, doFun)
end

function XUiRiftMultiStageDetail:OnBtnCloseMaskClick()
    self:Close()
end

function XUiRiftMultiStageDetail:OnDestroy()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
    self.Timer = nil
    self.CloseCb()
end

function XUiRiftMultiStageDetail:OnBtnResetClick()
    local title = XUiHelper.GetText("TipTitle")
    local content = XUiHelper.GetText("RiftRefreshRandomConfirm")
    local sureCallback = function()
        XDataCenter.RiftManager.RiftStartLayerRequestWithCD(self.XFightLayer:GetId(), function()
            self:RefreshUiShow()
        end)
    end

    if self.XFightLayer:CheckIsOwnFighting() then
        XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, sureCallback)
    else
        sureCallback()
    end
end

function XUiRiftMultiStageDetail:OnBtnRewardClick()
    XLuaUiManager.Open("UiRiftPreview", self.XFightLayer)
end

return XUiRiftMultiStageDetail