---@class XUiMaverick3PoupuStoryDetail : XLuaUi 孤胆枪手剧情弹框
---@field _Control XMaverick3Control
local XUiMaverick3PoupuStoryDetail = XLuaUiManager.Register(XLuaUi, "UiMaverick3PoupuStoryDetail")

function XUiMaverick3PoupuStoryDetail:OnAwake()
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnPlay.CallBack = handler(self, self.OnBtnPlayClick)
end

function XUiMaverick3PoupuStoryDetail:OnStart(storyId)
    self._StoryConfig = self._Control:GetStoryById(storyId)
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(self._StoryConfig.Words)

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end, nil, 0)
    
    self._Control:CloseAutoPlayStory(storyId)
end

function XUiMaverick3PoupuStoryDetail:OnBtnPlayClick()
    if string.IsNilOrEmpty(self._StoryConfig.AvgId) then
        return
    end
    XDataCenter.MovieManager.PlayMovie(self._StoryConfig.AvgId, nil, nil, nil, true)
end

return XUiMaverick3PoupuStoryDetail