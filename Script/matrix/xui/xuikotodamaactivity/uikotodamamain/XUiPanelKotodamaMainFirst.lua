--该界面及其逻辑已弃用
local XUiPanelKotodamaMainFirst=XClass(XUiNode,'XUiPanelKotodamaMainFirst')

function XUiPanelKotodamaMainFirst:OnStart()
    self.BtnStart.CallBack=function() 
        self.Parent:OpenContinuePanel()
    end
    self.BtnTask.CallBack=function() 
        XLuaUiManager.Open('UiKotodamaTask')
    end
    local showItems=self._Control:GetShowItems(XMVCA.XKotodamaActivity:GetCurActivityId())
    XUiHelper.RefreshCustomizedList(self.PanelReward, self.Grid256New, showItems and #showItems or 0, function(index, obj)
        local gridCommont = XUiGridCommon.New(self, obj)

        gridCommont:Refresh(showItems[index])
    end)
    
    self.TaskRedId=self:AddRedPointEvent(self.BtnTask, self.OnTaskRedPointEvent, self, { XRedPointConditions.Types.CONDITION_KOTODAMA_REWARD },nil,true)
end

function XUiPanelKotodamaMainFirst:OnEnable()
    XRedPointManager.Check(self.TaskRedId)
    self:RefreshLeftTime()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
    self.Timer=XScheduleManager.ScheduleForever(function()
        self:RefreshLeftTime()
    end,XScheduleManager.SECOND,0)
end

function XUiPanelKotodamaMainFirst:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer=nil
    end
end

--region 界面更新
function XUiPanelKotodamaMainFirst:RefreshLeftTime()
    local timeId=self._Control:GetActivityTimeId()
    local endTime=XFunctionManager.GetEndTimeByTimeId(timeId)
    local leftTime=endTime-XTime.GetServerNowTimestamp()
    leftTime=leftTime>0 and leftTime or 0
    
    self.TxtTime.text=XUiHelper.GetText('KotodamaLeftTime',XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
end

function XUiPanelKotodamaMainFirst:SetUiSprite(image, spriteName, callBack)
    self.Parent:SetUiSprite(image, spriteName, callBack)
end
--endregion

--region 事件
function XUiPanelKotodamaMainFirst:OnTaskRedPointEvent(count)
    self.BtnTask:ShowReddot(count>=0)
end
--endregion

return XUiPanelKotodamaMainFirst