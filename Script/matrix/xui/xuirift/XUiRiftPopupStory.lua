---@class XUiRiftPopupStory : XLuaUi 剧情弹框
---@field _Control XRiftControl
local XUiRiftPopupStory = XLuaUiManager.Register(XLuaUi, "UiRiftPopupStory")

function XUiRiftPopupStory:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiRiftPopupStory:OnStart(storyId, closeCb)
    self._CallBack = closeCb
    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
    local config = self._Control:GetRiftStoryById(storyId)
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(config.Words)
    self.RImgStory:SetRawImage(config.Bg)
    XSaveTool.SaveData(string.format("RiftStory_%s_%s", storyId, XPlayer.Id), true)
end

function XUiRiftPopupStory:Close()
    self.Super.Close(self)
    if self._CallBack then
        self._CallBack()
    end
end

return XUiRiftPopupStory