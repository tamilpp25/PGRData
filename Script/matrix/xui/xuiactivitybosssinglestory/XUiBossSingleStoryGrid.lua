local XUiBossSingleStoryGrid=XClass(nil,'XUiBossSingleStoryGrid')

local UiButtonState=
{
    Normal = 0,
    Press = 1,
    Select = 2,
    Disable = 3,
}

function XUiBossSingleStoryGrid:Ctor(ui,parent)
    XTool.InitUiObjectByUi(self,ui)
    self.Parent=parent
    self.TxtLock2 = self.PanelLock.transform:Find("TxtLock2")
    self.StoryBtn.CallBack=function() self:PlayBtnCallBack() end
end

function XUiBossSingleStoryGrid:Refresh(index,storyId)
    self.Index=index
    self.StoryId=storyId
    local template=XFubenActivityBossSingleConfigs.GetBossActivityStoryTemplate(storyId)
    --显示相应文本内容
    if self.TxtStoryTitle then
        self.TxtStoryTitle.text=template.Name
    end
    --判断是否解锁
    self.IsOpen=XDataCenter.FubenActivityBossSingleManager.IsStoryOpen(self.StoryId)
    if self.IsOpen then
        self.PanelLock.gameObject:SetActiveEx(false)
        self.StoryBtn:SetButtonState(UiButtonState.Normal)
    else
        self.PanelLock.gameObject:SetActiveEx(true)
        self.StoryBtn:SetButtonState(UiButtonState.Disable)
        if self.TxtLock2 then
            local preStoryPassed = XDataCenter.FubenActivityBossSingleManager.CheckPreStoryPass(nil, self.StoryId)
            local challengePassed = XDataCenter.FubenActivityBossSingleManager.CheckChallengePassedByStoryId(self.StoryId)
            self.TxtLock.gameObject:SetActiveEx(not challengePassed)
            self.TxtLock2.gameObject:SetActiveEx(not preStoryPassed and challengePassed)
        end
    end
    self.Bg.gameObject:SetActiveEx(self.IsOpen)
    --判断是否新
    local showReddot=self.IsOpen and not XDataCenter.FubenActivityBossSingleManager.CheckStoryPassed(self.StoryId)
    self.StoryBtn:ShowReddot(showReddot)
    if self.Kill then
        self.Kill.gameObject:SetActiveEx(self.IsOpen and XDataCenter.FubenActivityBossSingleManager.CheckStoryPassed(self.StoryId))
    end
end

---点击剧情按钮
function XUiBossSingleStoryGrid:PlayBtnCallBack()
    if self.IsOpen then
        --直接播放剧情

        --判断当前故事是否已经播放过
        if not XDataCenter.FubenActivityBossSingleManager.CheckStoryPassed(self.StoryId) then
            XDataCenter.FubenActivityBossSingleManager.AddPassedStoryWithId(self.StoryId)
        end

        local template=XFubenActivityBossSingleConfigs.GetBossActivityStoryTemplate(self.StoryId)
        XDataCenter.MovieManager.PlayMovie(template.MovieId)
        
    --else
    --    --显示提示文本
    --    XUiManager.TipText('ActivityBossSingleStoryUnlockCondition'..self.Index)
    end
end


return XUiBossSingleStoryGrid