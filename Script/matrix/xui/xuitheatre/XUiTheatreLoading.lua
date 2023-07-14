local XUiTheatreLoading = XLuaUiManager.Register(XLuaUi, "UiTheatreLoading")

function XUiTheatreLoading:OnAwake()
    self.TheatreManager = XDataCenter.TheatreManager
    self.CurrentAdventureManager = self.TheatreManager:GetCurrentAdventureManager()
    self.CurrentChapter = nil
    self.LastChapterStoryId = nil
end

function XUiTheatreLoading:OnStart(callback, lastChapterStoryId)
    self.LastChapterStoryId = lastChapterStoryId
    self.CurrentChapter = self.CurrentAdventureManager:GetCurrentChapter()
    self.RImgIndexIcon:SetRawImage(self.CurrentChapter:GetOpenIndexIcon())
    self.RImgTitleIcon:SetRawImage(self.CurrentChapter:GetOpenTitleIcon())
    self:SetAutoCloseInfo(XTime.GetServerNowTimestamp() + 1, function(isClose)
        if isClose then
            XLuaUiManager.Remove("UiTheatreLoading") 
            if callback then callback() end
        end
    end)
    if self.LastChapterStoryId == nil then
        if self.AnimEnableAuto then -- 防打包
            self.AnimEnableAuto:Play()
        end
    end
end

function XUiTheatreLoading:OnEnable()
    self.Super.OnEnable(self)
    if self.LastChapterStoryId then
        self:_StopAutoCloseTimer()
        XDataCenter.MovieManager.PlayMovie(self.LastChapterStoryId, function()
            self:_StartAutoCloseTimer()
            if self.AnimEnableAuto then -- 防打包
                self.AnimEnableAuto:Play()
            end
        end)
    end
end

return XUiTheatreLoading
