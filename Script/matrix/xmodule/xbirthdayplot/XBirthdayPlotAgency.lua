---@class XBirthdayPlotAgency : XAgency
---@field private _Model XBirthdayPlotModel
local XBirthdayPlotAgency = XClass(XAgency, "XBirthdayPlotAgency")

local IsNotifyPlayBeginMovie = false

function XBirthdayPlotAgency:OnInit()
    IsNotifyPlayBeginMovie = false
end

function XBirthdayPlotAgency:InitRpc()
    XRpc.NotifyBirthdayPlot = handler(self, self.NotifyBirthdayPlot)
    XRpc.NotifyBirthdayPlayCg = handler(self, self.NotifyBirthdayPlayCg)
    XRpc.NotifyBirthdaySingleStoryShow = handler(self, self.NotifyBirthdaySingleStoryShow)
end

function XBirthdayPlotAgency:InitEvent()
end

function XBirthdayPlotAgency:SetBirthday(birthday)
    if XTool.IsTableEmpty(birthday) then
        return
    end
    self._Model:UpdateBirthday(birthday)
end

function XBirthdayPlotAgency:GetBirthday()
    return self._Model:GetBirthday()
end

function XBirthdayPlotAgency:CheckCanChangeBirthday()
    local birthday = self:GetBirthday()
    if XTool.IsTableEmpty(birthday) then
        return true
    end
    if not self:IsSetBirthday() then
        return true
    end

    if not self:IsChangedBirthday() then
        return true
    end
    
    return false
end

--是否修改过生日
function XBirthdayPlotAgency:IsChangedBirthday()
    local birthday = self:GetBirthday()
    if XTool.IsTableEmpty(birthday) then
        return false
    end
    return birthday.IsChange
end

--是否设置过生日
function XBirthdayPlotAgency:IsSetBirthday()
    local birthday = self:GetBirthday()
    if XTool.IsTableEmpty(birthday) then
        return false
    end
    return birthday.Mon ~= nil and birthday.Day ~= nil
end

--检查生日剧情是否解锁
function XBirthdayPlotAgency:IsStoryUnlock(chapterId)
    local birthday = self:GetBirthday()
    if XTool.IsTableEmpty(birthday) then
        return false
    end
    return birthday.UnLockCg and birthday.UnLockCg[chapterId] ~= nil or false
end

--播放生日剧情动画
function XBirthdayPlotAgency:PlayBirthdayStory()
    if not IsNotifyPlayBeginMovie then
        return false
    end
    local storyId = self._Model:GetBeginMovieId()
    if string.IsNilOrEmpty(storyId) then
        return false
    end
    
    self:PlayBeginMovie(storyId)
    
    return true
end

function XBirthdayPlotAgency:PlayBeginMovie(storyId)
    IsNotifyPlayBeginMovie = false
    XDataCenter.MovieManager.PlayMovie(storyId, function() 
        self:OnEnterSingleStory(true)
    end)
end

function XBirthdayPlotAgency:PlayEndMovie()
    local movieId = self._Model:GetEndMovieId()
    if string.IsNilOrEmpty(movieId) then
        return
    end
    XDataCenter.MovieManager.PlayMovie(movieId)
end

function XBirthdayPlotAgency:OnEnterSingleStory(needPop)
    --没有单人剧情
    if not self._Model:IsSingleStory() then
        return
    end
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    XLuaUiManager.Open("UiBirthdayPlotSingleStory", needPop)
end

function XBirthdayPlotAgency:IsShowBirthdayBtn()
    if not self:IsSetBirthday() then
        return false
    end
    if not self._Model:IsSingleStory() then
        return false
    end
    
    local birthday = self:GetBirthday()
    local now = XTime.GetServerNowTimestamp()
    return XTool.IsNumberValid(birthday.ShowEndTime) and birthday.ShowEndTime > now
end

function XBirthdayPlotAgency:GetLeftTime()
    if not self:IsShowBirthdayBtn() then
        return ""
    end
    local birthday = self:GetBirthday()
    local now = XTime.GetServerNowTimestamp()
    return XUiHelper.GetTime(birthday.ShowEndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
end

--region   ------------------协议交互 start-------------------

function XBirthdayPlotAgency:RequestChangeBirthday(month, day, func)
    if not self:CheckCanChangeBirthday() then
        XUiManager.TipCode(XCode.PlayerDataManagerBirthdayAlreadySet)
        return
    end
    
    local req = {
        Mon = month,
        Day = day
    }
    XNetwork.Call("ChangePlayerBirthdayRequest", req, function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
        
        self._Model:UpdateBirthday(req)

        if func then func() end
    end)
end

function XBirthdayPlotAgency:NotifyBirthdayPlot(data)
    local newData = {
        NextActiveYear = data.NextActiveYear,
        IsChange = data.IsChange == 1,
        UnLockCg = {},
        SingleStoryId = {}
    }
    for _, chapterId in pairs(data.UnLockCg) do
        newData.UnLockCg[chapterId] = chapterId
    end
    for _, storyId in pairs(data.SingleStoryIds or {}) do
        newData.SingleStoryId[storyId] = storyId
    end
    self._Model:UpdateBirthday(newData)
end

function XBirthdayPlotAgency:NotifyBirthdayPlayCg(data)
    if not data then
        return
    end
    IsNotifyPlayBeginMovie = true
    local chapterId = data.ChapterId
    self._Model:SetActiveChapterId(chapterId)
    XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_UNLOCK_BIRTHDAY_STORY)
end

function XBirthdayPlotAgency:NotifyBirthdaySingleStoryShow(data)
    self._Model:SetActiveChapterId(data.ChapterId)
    self._Model:UpdateBirthday({
        ShowEndTime = data.ShowEndTime
    })
end

--endregion------------------协议交互 finish------------------


return XBirthdayPlotAgency