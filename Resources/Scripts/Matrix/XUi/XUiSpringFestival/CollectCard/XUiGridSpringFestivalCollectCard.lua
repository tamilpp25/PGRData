local XUiGridSpringFestivalCollectCard = XClass(nil, "XUiGridSpringFestivalCollectCard")
local CSXTextManagerGetText = CS.XTextManager.GetText
function XUiGridSpringFestivalCollectCard:Ctor(ui, type)
    self.GameObject = ui
    self.Transform = ui.transform
    self.Type = type
    self.WordsList = XSpringFestivalActivityConfigs.GetWordsItemListByType(self.Type) or {}
    XTool.InitUiObject(self)
    self:RegisterButtonEvent()
    self:RegisterCountChangeEvent()
    self:Refresh()
    XRedPointManager.AddRedPointEvent(self.BtnReceive, self.CheckReddot, self, { XRedPointConditions.Types.CONDITION_SPRINGFESTIVAL_GET_REWARD_RED }, self.Type)
end

function XUiGridSpringFestivalCollectCard:CheckReddot(count)
    self.BtnReceive:ShowReddot(count >= 0)
end

function XUiGridSpringFestivalCollectCard:RegisterButtonEvent()
    self.BtnReceive.CallBack = function()
        self:OnClickGetRewardBtn()
    end
    if self.Btn then
        self.Btn.CallBack = function()
            self:OnClickRewardIconBtn()
        end
    end
    if self.Type ~= XSpringFestivalActivityConfigs.CollectWordsRewardType.Final then
        for i = 1, #self.WordsList do
            local index = i
            self["BtnText" .. i].CallBack = function()
                self:OnClickBtnWord(index)
            end
        end
    end
end

function XUiGridSpringFestivalCollectCard:RegisterCountChangeEvent()
    if self.Type ~= XSpringFestivalActivityConfigs.CollectWordsRewardType.Final then
        for i = 1, #self.WordsList do
            local index = i
            local func = function()
                local count = XDataCenter.ItemManager.GetCount(self.WordsList[index].Id)
                self["WordText" .. index].text = count
                self:RefreshReceiveText()
                self["BtnText"..index]:SetDisable(count == 0, true)
            end
            self["BtnText" .. i]:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.WordsList[index].Id))
            XDataCenter.ItemManager.AddCountUpdateListener(self.WordsList[i].Id, func, self["WordText" .. i])
            func()
        end
    end
end

function XUiGridSpringFestivalCollectCard:OnClickGetRewardBtn()
    local canGetReward, needUniversalCount = XDataCenter.SpringFestivalActivityManager.CheckCanGetCollectWordsReward(self.Type)
    if not canGetReward then
        if self.Type ~= XSpringFestivalActivityConfigs.CollectWordsRewardType.Final then
            XUiManager.TipText("SpringFestivalItemNotEnough")
        else
            XUiManager.TipText("SpringFestivalCanNotGetFinalReward")
        end
        return
    end
    if needUniversalCount and needUniversalCount > 0 then
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("SpringFestivalUniversalTips", needUniversalCount), XUiManager.DialogType.Normal, nil, function()
            self:SendGetRewardRequest()
        end)
    else
        self:SendGetRewardRequest()
    end

end

function XUiGridSpringFestivalCollectCard:OnClickRewardIconBtn()
    local itemData = XDataCenter.ItemManager.GetItem(XSpringFestivalActivityConfigs.ShowItem[self.Type])
    XLuaUiManager.Open("UiTip", itemData, true, "")
end

function XUiGridSpringFestivalCollectCard:SendGetRewardRequest()
    if self.Type == XSpringFestivalActivityConfigs.CollectWordsRewardType.Up
            or self.Type == XSpringFestivalActivityConfigs.CollectWordsRewardType.Down then
        XDataCenter.SpringFestivalActivityManager.CollectWordsRecvRewardRequest(self.Type, function(rewards)
            if not rewards then
                return
            end
            self:OnReceiveReward(rewards)
        end)
    elseif self.Type == XSpringFestivalActivityConfigs.CollectWordsRewardType.Final then
        XDataCenter.SpringFestivalActivityManager.CollectWordsRecvGrandPrizeRewardRequest(function(rewards)
            if not rewards then
                return
            end
            XEventManager.DispatchEvent(XEventId.EVENT_SPRING_FESTIVAL_REWARD_RED)
            self:OnReceiveReward(rewards)
            self:RefreshReceiveText()
        end)
    end
end

function XUiGridSpringFestivalCollectCard:OnReceiveReward(rewards)

    XUiManager.OpenUiTipReward(rewards,CS.XTextManager.GetText("SpringFestivalGetRewardTitle"))
end

function XUiGridSpringFestivalCollectCard:Refresh()
    self:RefreshReceiveText()
    self:RefreshReceiveProcess()
    self:RefreshTextDetail()
end

function XUiGridSpringFestivalCollectCard:RefreshTextDetail()
    local str = CSXTextManagerGetText("SpringFestivalRewardDesc" .. self.Type)
    if self.TxtDetails then
        self.TxtDetails.text = str
    end
end

function XUiGridSpringFestivalCollectCard:RefreshReceiveProcess()
    local str = ""
    if self.Type ~= XSpringFestivalActivityConfigs.CollectWordsRewardType.Final then
        str = CSXTextManagerGetText("SpringFestivalCollectWordProcess", XDataCenter.SpringFestivalActivityManager.GetAlreadyRecvTimes(self.Type), XDataCenter.SpringFestivalActivityManager.GetCollectWordDuringDay())
    else
        str = CSXTextManagerGetText("SpringFestivalCollectWordProcess", XDataCenter.SpringFestivalActivityManager.GetRecvFinalRewardTimes(), XDataCenter.SpringFestivalActivityManager.GetCollectWordDuringDay())
    end
    if self.TxtReceive then
        self.TxtReceive.text = str
    end
end

function XUiGridSpringFestivalCollectCard:RefreshReceiveText()
    if self.Type ~= XSpringFestivalActivityConfigs.CollectWordsRewardType.Final then
        local receiveTime = XDataCenter.SpringFestivalActivityManager.GetAlreadyRecvTimes(self.Type)
        local canReceiveTime = XDataCenter.SpringFestivalActivityManager.GetCollectWordDuringDay()
        local maxReceiveTime = XSpringFestivalActivityConfigs.GetCollectWordsRewardMaxCount(self.Type)
        if receiveTime < canReceiveTime then
            self.BtnReceive.gameObject:SetActiveEx(true)
            self.BtnReceive:SetButtonState(CS.UiButtonState.Normal)
            self.TxtTime.gameObject:SetActiveEx(false)
        elseif receiveTime == canReceiveTime and canReceiveTime < maxReceiveTime then
            self.BtnReceive.gameObject:SetActiveEx(false)
            if self.TxtTime then
                self.TxtTime.gameObject:SetActiveEx(true)
                self.TxtTime.text = CSXTextManagerGetText("SpringFestivalNextGetRewardTime")
            end
        elseif receiveTime == maxReceiveTime then
            self.BtnReceive.gameObject:SetActiveEx(true)
            self.BtnReceive:SetDisable(true, false)
            self.TxtTime.gameObject:SetActiveEx(false)
        end
    else
        local times = XDataCenter.SpringFestivalActivityManager.GetRecvFinalRewardTimes()
        local maxCount = XSpringFestivalActivityConfigs.GetCollectWordsRewardMaxCount(XSpringFestivalActivityConfigs.CollectWordsRewardType.Up)
        if times >= maxCount then
            self.BtnReceive.gameObject:SetActiveEx(true)
            self.BtnReceive:SetDisable(true, false)
            self.TxtTime.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridSpringFestivalCollectCard:OnClickBtnWord(index)
    local wordId = self.WordsList[index]
    if not wordId then
        XLog.Error("XUiGridSpringFestivalCollectCard:OnClickBtnWord:点击的字不存在")
        return
    end
    XLuaUiManager.Open("UiSpringFestivalTip", wordId.Id)
end

function XUiGridSpringFestivalCollectCard:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtTime) then
            self:StopTimer()
            return
        end
        local time = XDataCenter.SpringFestivalActivityManager.GetNextRequestRefreshTime()
        time = XMath.Clamp(time, 0, time)
        if time == 0 then
            self.BtnReceive.gameObject:SetActiveEx(true)
            self.BtnReceive:SetDisable(false,true)
        end
        self.TxtTime.text = CSXTextManagerGetText("SpringFestivalNextGetRewardTime", XTime.TimestampToGameDateTimeString(time, "HH:mm:ss"))
    end, XScheduleManager.SECOND, 0)
end

function XUiGridSpringFestivalCollectCard:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
    self.Timer = nil
end

return XUiGridSpringFestivalCollectCard