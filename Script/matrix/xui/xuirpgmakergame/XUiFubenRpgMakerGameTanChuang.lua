local Normal = CS.UiButtonState.Normal
local Select = CS.UiButtonState.Select

local XUiGrid = XClass(nil, "XUiGrid")

function XUiGrid:Ctor(ui, chapterGroupId, clickCb)
    self.Btn = ui    
    self.ChapterGroupId = chapterGroupId
    self.ClickCb = clickCb
    self:Init(chapterGroupId)
    XUiHelper.RegisterClickEvent(self, ui, handler(self, self.OnBtnClick))
end

function XUiGrid:Init(chapterGroupId)
    local icon = XRpgMakerGameConfigs.GetChapterGroupActivityIcon(chapterGroupId)
    self.Btn:SetRawImage(icon)
    --活动名
    local name = XRpgMakerGameConfigs.GetChapterGroupName(chapterGroupId)
    self.Btn:SetNameByGroup(0, name)
end

function XUiGrid:Refresh(selectChapterGroupId)
    local chapterGroupId = self.ChapterGroupId
    local timeStr, isOpen = self:GetTimeStr(chapterGroupId)
    --活动时间
    self.Btn:SetNameByGroup(1, timeStr)
    --按钮状态
    self.Btn:SetDisable(not isOpen)
    --按钮小红点
    self.Btn:ShowReddot(XDataCenter.RpgMakerGameManager.CheckChapterGroupBtnRedPoint(chapterGroupId))
    if isOpen then
        self.Btn:SetButtonState(selectChapterGroupId == chapterGroupId and Select or Normal)
    end
end

local _NowServerTime
local _TimeId
local _EndTime
local _Format = "yyyy/MM/dd"
function XUiGrid:GetTimeStr(chapterGroupId)
    _NowServerTime = XTime.GetServerNowTimestamp()
    _TimeId = XRpgMakerGameConfigs.GetChapterGroupOpenTimeId(chapterGroupId)
    if not XFunctionManager.CheckInTimeByTimeId(_TimeId, true) then
        return XUiHelper.GetText("RpgMakerGameOpenTime", XTime.TimestampToGameDateTimeString(XFunctionManager.GetStartTimeByTimeId(_TimeId), _Format)), false
    end

    _EndTime = XFunctionManager.GetEndTimeByTimeId(_TimeId)
    return XUiHelper.GetText("RpgMakerGameLastTime", XUiHelper.GetTime(_EndTime - _NowServerTime, XUiHelper.TimeFormatType.RPG_MAKER_GAME_MAIN)), true
end

function XUiGrid:OnBtnClick()
    local chapterGroupId = self.ChapterGroupId
    local timeId = XRpgMakerGameConfigs.GetChapterGroupOpenTimeId(chapterGroupId)
    if not XFunctionManager.CheckInTimeByTimeId(timeId, true) then
        local sTime = XFunctionManager.GetStartTimeByTimeId(timeId)
        XUiManager.TipErrorWithKey("MemorySaveStageNotOpen", XTime.TimestampToUtcDateTimeString(sTime, "yyyy-MM-dd HH:mm"))
        return
    end
    self.ClickCb(chapterGroupId)
end


--系列活动弹窗
local XUiFubenRpgMakerGameTanChuang = XLuaUiManager.Register(XLuaUi, "UiFubenRpgMakerGameTanChuang")

function XUiFubenRpgMakerGameTanChuang:OnAwake()
    self.ChapterGroupIdList = XRpgMakerGameConfigs.GetRpgMakerGameChapterGroupIdList()
    self:InitBtn()
    self:AddListener()
    self:InitBtnCollection()
end

function XUiFubenRpgMakerGameTanChuang:OnStart(closeCb, curSelectChapterId)
    self.CloseCallback = closeCb
    self.CurSelectChapterId = curSelectChapterId
end

function XUiFubenRpgMakerGameTanChuang:OnEnable()
    self:StartActivityTimer()
end

function XUiFubenRpgMakerGameTanChuang:OnDisable()
    self:StopActivityTimer()
end

function XUiFubenRpgMakerGameTanChuang:AddListener()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.Mask, self.Close)
    self:RegisterClickEvent(self.BtnCollection, self.OnBtnCollectionClick)
end

function XUiFubenRpgMakerGameTanChuang:OnBtnCollectionClick()
    local itemId = XUiHelper.GetClientConfig("RpgMakerGameExhibitItemId", XUiHelper.ClientConfigType.Int)
    XUiManager.OpenGoodDetailUi(itemId, "UiFubenRpgMakerGameTanChuang")
end

function XUiFubenRpgMakerGameTanChuang:InitBtnCollection()
    local activityId = XRpgMakerGameConfigs.GetDefaultActivityId()
    local icon = XRpgMakerGameConfigs.GetActivityCollectionIcon(activityId)
    self.BtnCollection:SetRawImage(icon)
end

function XUiFubenRpgMakerGameTanChuang:InitBtn()
    self.BtnGridList = {}
    for i, chapterGroupId in ipairs(self.ChapterGroupIdList) do
        local btn = i == 1 and self.Btn or XUiHelper.Instantiate(self.Btn, self.PanelButtonGroup)
        local btnGrid = XUiGrid.New(btn, chapterGroupId, handler(self, self.OnClickCallback))
        table.insert(self.BtnGridList, btnGrid)
    end
end

function XUiFubenRpgMakerGameTanChuang:OnClickCallback(chapterGroupId)
    self:Close()
    if self.CloseCallback then
        self.CloseCallback(chapterGroupId)
    end
end

function XUiFubenRpgMakerGameTanChuang:StartActivityTimer()
    self:StopActivityTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForeverEx(function() 
        for i, btnGrid in ipairs(self.BtnGridList) do
            btnGrid:Refresh(self.CurSelectChapterId)
        end
    end, XScheduleManager.SECOND)
end

function XUiFubenRpgMakerGameTanChuang:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end