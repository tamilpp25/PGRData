local XUiGridFavorabilityStory=XClass(XUiNode,"XUiGridFavorabilityStory")

local Sequence={
    First=0,
    Mid=1,
    Last=2
}

function XUiGridFavorabilityStory:OnStart()
    self.GridStoryStage.CallBack=function() self:OnClickEvent() end
end

function XUiGridFavorabilityStory:Refresh(data)
    self.PlotData = data
    local characterId = self.Parent.CurrentCharacterId
    self.IsUnlock = self._Control:IsStoryUnlock(characterId, self.PlotData.Id)
    self.CanUnlock = self._Control:CanStoryUnlock(characterId, self.PlotData.Id)
    
    --UI样式
    self.GridStoryStage:SetNameByGroup(0,CS.XTextManager.GetText("FavorabilityStorySectionName", self.PlotData.SectionNumber))
    self.GridStoryStage:SetNameByGroup(1,self.PlotData.Name)
    self.GridStoryStage:SetNameByGroup(2,self.PlotData.ConditionDescript)
    --设置图片
    self.GridStoryStage:SetRawImage(self.PlotData.Icon)
    --解锁状态
    if self.IsUnlock or self.CanUnlock then
        self.GridStoryStage:SetButtonState(CS.UiButtonState.Normal)
    else
        self.GridStoryStage:SetButtonState(CS.UiButtonState.Disable)
    end
    --新解锁红点
    self.GridStoryStage:ShowTag(self.CanUnlock and not self.IsUnlock)
end

function XUiGridFavorabilityStory:SetSequence(sequence)
    self.RawJiantou.gameObject:SetActiveEx(false)
    self.RawJiantou2.gameObject:SetActiveEx(false)
    if sequence==Sequence.First then
        self.RawJiantou.gameObject:SetActiveEx(true)
    elseif sequence== Sequence.Last then
        self.RawJiantou2.gameObject:SetActiveEx(true)
    end
end

function XUiGridFavorabilityStory:OnClickEvent()
    if self.CanUnlock then
        XMVCA.XFavorability:OnUnlockCharacterStory(self.Parent.CurrentCharacterId, self.PlotData.Id,true)
        XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_PLOTUNLOCK)
        self.Parent:SetResumeTrigger(true)
        XDataCenter.MovieManager.PlayMovie(self.PlotData.StoryId, function()
            
        end)
    elseif self.IsUnlock then
        self.Parent:SetResumeTrigger(true)
        XDataCenter.MovieManager.PlayMovie(self.PlotData.StoryId, function()
            
        end)
    else
        XUiManager.TipMsg(self.PlotData.ConditionDescript)
    end
end

return XUiGridFavorabilityStory