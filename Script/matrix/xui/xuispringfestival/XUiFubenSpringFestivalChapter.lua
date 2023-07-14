local XUiFubenSpringFestivalChapter = XLuaUiManager.Register(XLuaUi, "UiFubenSpringFestivalChapter")
local XUiPanelFubenSpringFestivalStage = require("XUi/XUiSpringFestival/XUiPanelFubenSpringFestivalStage")
function XUiFubenSpringFestivalChapter:OnStart()
    self.Chapter = XDataCenter.FubenFestivalActivityManager.GetFestivalChapterById(XSpringFestivalActivityConfigs.GetSpringFestivalActivityChapterId())
    self.EndTime = XDataCenter.SpringFestivalActivityManager.GetActivityEndTime()
    self:Init()
end

function XUiFubenSpringFestivalChapter:OnEnable()
    self:RefreshRemainingTime()
    self:StartTimer()
    self.StagePanel:Refresh()
    XRedPointManager.AddRedPointEvent(self.BtnReward, self.CheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_SPRINGFESTIVAL_TASK_RED },XSpringFestivalActivityConfigs.GetSpringFestivalActivityTaskActivityId())
end

    function XUiFubenSpringFestivalChapter:OnDisable()
        self:StopTimer()
    end

    function XUiFubenSpringFestivalChapter:OnDestroy()

    end

    function XUiFubenSpringFestivalChapter:Init()
        self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
        self:InitChapter()
        self:RegisterBtnEvent()
    end

    function XUiFubenSpringFestivalChapter:InitChapter()
        local chapterGameObject = self.PanelChapter:LoadPrefab(self.Chapter:GetFubenPrefab())
        self.StagePanel = XUiPanelFubenSpringFestivalStage.New(self,chapterGameObject,self.Chapter)
end

function XUiFubenSpringFestivalChapter:CheckTaskRedPoint(count)
    self.BtnReward:ShowReddot(count >= 0)
end

function XUiFubenSpringFestivalChapter:RegisterBtnEvent()
    self.SceneBtnBack.CallBack = function()
        self:OnClickBackBtn()
    end
    self.SceneBtnMainUi.CallBack = function()
        self:OnClickMainBtn()
    end
    self.BtnReward.CallBack = function()
        self:OnClickRewardBtn()
    end
    self.BtnCollectCard.CallBack = function()
        self:OnClickCollectCardBtn()
    end
    self.BtnSmashEggs.CallBack = function()
        self:OnClickSmashEggsBtn()
    end
end

function XUiFubenSpringFestivalChapter:OnClickBackBtn()
    XLuaUiManager.Close("UiFubenSpringFestivalChapter")
end

function XUiFubenSpringFestivalChapter:OnClickMainBtn()
    XLuaUiManager.RunMain()
end

function XUiFubenSpringFestivalChapter:OnClickRewardBtn()
    XLuaUiManager.Remove("UiFubenSpringFestivalChapter")
    local activitySkipId = XSpringFestivalActivityConfigs.GetSpringFestivalActivitySkipId()
    XFunctionManager.SkipInterface(activitySkipId)
end

function XUiFubenSpringFestivalChapter:OnClickCollectCardBtn()
    XLuaUiManager.Open("UiSpringFestivalCollectCard")
end

function XUiFubenSpringFestivalChapter:OnClickSmashEggsBtn()
    XLuaUiManager.Open("UiSpringFestivalSmashEggs")
end

function XUiFubenSpringFestivalChapter:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtDay) then
            self:StopTimer()
            return
        end
        local currentTime = XTime.GetServerNowTimestamp()
        if currentTime > self.EndTime then
            XDataCenter.SpringFestivalActivityManager.OnActivityEnd()
            return
        end
        self:RefreshRemainingTime()
    end,XScheduleManager.SECOND)
end

function XUiFubenSpringFestivalChapter:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiFubenSpringFestivalChapter:RefreshRemainingTime()
    local endTime = XDataCenter.SpringFestivalActivityManager.GetActivityEndTime()
    local startTime = XDataCenter.SpringFestivalActivityManager.GetActivityStartTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = XMath.Clamp(endTime - now,0,endTime-startTime)
    self.TxtDay.text = XUiHelper.GetTime(offset,XUiHelper.TimeFormatType.ACTIVITY)
end

return XUiFubenSpringFestivalChapter