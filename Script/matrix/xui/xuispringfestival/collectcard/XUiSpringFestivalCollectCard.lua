local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiSpringFestivalCollectCard = XLuaUiManager.Register(XLuaUi, "UiSpringFestivalCollectCard")
local XUiGridSpringFestivalCollectCard = require("XUi/XUiSpringFestival/CollectCard/XUiGridSpringFestivalCollectCard")

function XUiSpringFestivalCollectCard:OnStart()
    self.EndTime = XDataCenter.SpringFestivalActivityManager.GetActivityEndTime()
    self:Init()
end

function XUiSpringFestivalCollectCard:OnEnable()
    self:RefreshRemainingTime()
    self:StartTimer()
    self:RefreshGridPanel()
    XRedPointManager.AddRedPointEvent(self.BtnActivity, self.CheckTaskRedPoint, self, { XRedPointConditions.Types.CONDITION_SPRINGFESTIVAL_TASK_RED },XSpringFestivalActivityConfigs.GetSpringFestivalCollectActivityId())
    XRedPointManager.AddRedPointEvent(self.BtnMail, self.CheckBtnMailRedPoint, self, { XRedPointConditions.Types.CONDITION_SPRINGFESTIVAL_BAG_RED })
    local isShowHelp = XSaveTool.GetData(string.format("%s%s",XSpringFestivalActivityConfigs.COLLECT_WORD_HELP_KEY,XPlayer.Id))
    if not isShowHelp then
        self:ShowHelp()
        XSaveTool.SaveData(string.format("%s%s",XSpringFestivalActivityConfigs.COLLECT_WORD_HELP_KEY,XPlayer.Id),true)
    end
end

function XUiSpringFestivalCollectCard:OnDisable()
    self:StopTimer()
end

function XUiSpringFestivalCollectCard:OnDestroy()
    
end

function XUiSpringFestivalCollectCard:OnGetEvents()
    return {
        XEventId.EVENT_SPRING_FESTIVAL_COLLECT_CARD_REFRESH,
    }
end

function XUiSpringFestivalCollectCard:OnNotify(event, ...)
    if event == XEventId.EVENT_SPRING_FESTIVAL_COLLECT_CARD_REFRESH then
        self:RefreshGridPanel()
    end
end

function XUiSpringFestivalCollectCard:Init()
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.UniversalWord)
    if self.BtnHelpCourse then
        self.BtnHelpCourse.gameObject:SetActiveEx(XSpringFestivalActivityConfigs.GetCollectHelpId() > 0)
    end
    self:RegisterButtonEvent()
    self.GridReward = {}
    self.GridReward[XSpringFestivalActivityConfigs.CollectWordsRewardType.Up] = XUiGridSpringFestivalCollectCard.New(self.GridReward01, XSpringFestivalActivityConfigs.CollectWordsRewardType.Up)
    self.GridReward[XSpringFestivalActivityConfigs.CollectWordsRewardType.Down] = XUiGridSpringFestivalCollectCard.New(self.GridReward02, XSpringFestivalActivityConfigs.CollectWordsRewardType.Down)
    self.GridReward[XSpringFestivalActivityConfigs.CollectWordsRewardType.Final] = XUiGridSpringFestivalCollectCard.New(self.GridReward03, XSpringFestivalActivityConfigs.CollectWordsRewardType.Final)
end

function XUiSpringFestivalCollectCard:CheckTaskRedPoint(count)
    self.BtnActivity:ShowReddot(count >= 0)
end

function XUiSpringFestivalCollectCard:CheckBtnMailRedPoint(count)
    self.BtnMail:ShowReddot(count >= 0)
end

function XUiSpringFestivalCollectCard:RegisterButtonEvent()
    self.BtnBack.CallBack = function()
        self:OnClickBackBtn()
    end
    self.BtnMainUi.CallBack = function()
        self:OnClickMainBtn()
    end
    self.BtnActivity.CallBack = function()
        self:OnClickBtnActivity()
    end
    self.BtnGive.CallBack = function()
        self:OnClickBtnGive()
    end
    self.BtnHelp.CallBack = function()
        self:OnClickBtnHelp()
    end
    self.BtnMail.CallBack = function()
        self:OnClickBtnMail()
    end

    if self.BtnTool then
        self.BtnTool.CallBack = function() 
            local universalWord = XDataCenter.ItemManager.GetItem(XDataCenter.ItemManager.ItemId.UniversalWord)
            XLuaUiManager.Open("UiTip", universalWord, true, "")
        end
    end
    if self.BtnHelpCourse then
        local template = XHelpCourseConfig.GetHelpCourseTemplateById(XSpringFestivalActivityConfigs.GetCollectHelpId())
        self:BindHelpBtn(self.BtnHelpCourse,template.Function)
    end
end

function XUiSpringFestivalCollectCard:OnClickBackBtn()
    XLuaUiManager.Close("UiSpringFestivalCollectCard")
end

function XUiSpringFestivalCollectCard:OnClickMainBtn()
    XLuaUiManager.RunMain()
end

function XUiSpringFestivalCollectCard:OnClickBtnHelp()
    if XDataCenter.SpringFestivalActivityManager.HasRequestWord() then
        XLuaUiManager.Open("UiSpringFestivalHelpTips2")
    else
        XLuaUiManager.Open("UiSpringFestivalHelpTips1")
    end
end

function XUiSpringFestivalCollectCard:OnClickBtnMail()
    XLuaUiManager.Open("UiSpringFestivalBagTips")
end

function XUiSpringFestivalCollectCard:OnClickBtnActivity()
    XLuaUiManager.Remove("UiFubenSpringFestivalChapter")
    XLuaUiManager.Remove("UiSpringFestivalCollectCard")
    local skipId = XSpringFestivalActivityConfigs.GetSpringFestivalActivityCollectSkipId()
    XFunctionManager.SkipInterface(skipId)
end

function XUiSpringFestivalCollectCard:OnClickBtnGive()
    XLuaUiManager.Open("UiSpringFestivalGiveTips")
end

function XUiSpringFestivalCollectCard:ShowHelp()
    local helpId = XSpringFestivalActivityConfigs.GetCollectHelpId()
    if helpId > 0 then
        local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
        XUiManager.ShowHelpTip(template.Function)
    end
end

function XUiSpringFestivalCollectCard:RefreshGridPanel()
    for _, grid in pairs(self.GridReward) do
        grid:Refresh()
    end
end

function XUiSpringFestivalCollectCard:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtTime) then
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

function XUiSpringFestivalCollectCard:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiSpringFestivalCollectCard:RefreshRemainingTime()
    local endTime = XDataCenter.SpringFestivalActivityManager.GetActivityEndTime()
    local startTime = XDataCenter.SpringFestivalActivityManager.GetActivityStartTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = XMath.Clamp(endTime - now,0,endTime-startTime)
    self.TxtTime.text = XUiHelper.GetTime(offset,XUiHelper.TimeFormatType.ACTIVITY)
end

return XUiSpringFestivalCollectCard