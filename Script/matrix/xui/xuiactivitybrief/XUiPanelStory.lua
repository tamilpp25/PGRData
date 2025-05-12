local XUiPanelStory = XClass(nil, "XUiPanelStory")


function XUiPanelStory:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnStory01.CallBack = function() self:OnBtnStoryClick() end

end

function XUiPanelStory:Init(rootUi)
    self.RootUi = rootUi
end

function XUiPanelStory:OnRefreshDatas(configInfo)
    self.ConfigInfo = configInfo
    self:UpdateBtnImageAndText()
end

function XUiPanelStory:UpdateBtnImageAndText()
    XRedPointManager.AddRedPointEvent(self.BtnStory01, self.OnCheckStoryRedPoint, self, { XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_ILLUSTRATEDHANDBOOK },self.ConfigInfo)
    self.ImagePre:SetRawImage(self.ConfigInfo.BgImage)
    local isUnlock
    local desc = ""
    isUnlock,desc = XConditionManager.CheckCondition(self.ConfigInfo.ConditionId)
    if isUnlock then
        self.BtnStory01:SetButtonState(CS.UiButtonState.Normal)
        self.ImageNor:SetRawImage(self.ConfigInfo.BgImage)
    else
        self.BtnStory01:SetButtonState(CS.UiButtonState.Disable)
        self.ImageDis:SetRawImage(self.ConfigInfo.UnlockBgImage)
        local con = XConditionManager.GetConditionDescById(self.ConfigInfo.ConditionId)
        self.Text.text = con
    end
end



function XUiPanelStory:OnBtnStoryClick()
    local isUnlock
    local desc = ""
    isUnlock,desc = XConditionManager.CheckCondition(self.ConfigInfo.ConditionId)
    if isUnlock then
        self.BtnStory01:ShowReddot(false)
        XDataCenter.MovieManager.PlayMovie(self.ConfigInfo.StoryId)
        XDataCenter.ActivityBriefManager.QueryStatistics(self.ConfigInfo.Id)
    else
        local con = XConditionManager.GetConditionDescById(self.ConfigInfo.ConditionId)
        XUiManager.TipMsg(con)
    end
end

function XUiPanelStory:OnCheckStoryRedPoint(count)
    self.BtnStory01:ShowReddot(count >= 0)
end












return XUiPanelStory