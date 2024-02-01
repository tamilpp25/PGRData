
---@class XUiPanelSingleStory : XUiNode
---@field _Control XBirthdayPlotControl
local XUiPanelSingleStory = XClass(XUiNode, "XUiPanelSingleStory")

function XUiPanelSingleStory:OnStart(storyId)
    self.BtnSkipDialog.CallBack = function() 
        self:OnBtnCloseClick()
    end
    self.BtnGo.CallBack = function() 
        self:OnBtnGoClick()
    end
    
    self.BtnWait.CallBack = function() 
        self:OnBtnWaitClick()
    end
end

function XUiPanelSingleStory:OnEnable()
    local storyId = self.StoryId

    local roleName = self._Control:GetStoryRoleName(storyId)
    self.TxtChat.text = XUiHelper.GetText("SingleStoryInviteContentText", roleName)
    local isVoiceover = self._Control:GetStoryIsVoiceover(self.StoryId)
    self.TxtName.gameObject:SetActiveEx(not isVoiceover)
    if not isVoiceover then
        self.TxtName.text = roleName
    end
    self.TxtWords.text = self._Control:GetStoryText(storyId)
    self.ImgRole:SetRawImage(self._Control:GetFullBodyImage(storyId))
end

function XUiPanelSingleStory:RefreshView(storyId)
    self.StoryId = storyId
    self:Open()
end

function XUiPanelSingleStory:OnBtnCloseClick()
    self._Control:HideSingleStory()
end

function XUiPanelSingleStory:OnBtnGoClick()
    self._Control:ViewSingleStoryMovie(self.StoryId)
end

function XUiPanelSingleStory:OnBtnWaitClick()
    self._Control:HideSingleStory()
end

return XUiPanelSingleStory
