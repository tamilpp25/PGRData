---@class XUiGridFavorabilityStory: XUiNode
---@field _Control XFavorabilityControl
---@field _RootUiObject UiObject
local XUiGridFavorabilityStory=XClass(XUiNode,"XUiGridFavorabilityStory")

local Sequence={
    First=0,
    Mid=1,
    Last=2
}

function XUiGridFavorabilityStory:OnStart()
    self.GridStoryStage.transform.localPosition = Vector3.zero
    self.GridStoryStage.CallBack=function() self:OnClickEvent() end
    self._RootUiObject = self.Transform.parent:GetComponent(typeof(CS.UiObject))
end

function XUiGridFavorabilityStory:Refresh(data)
    self.PlotData = data
    local characterId = self.Parent.CurrentCharacterId

    if XTool.IsNumberValid(self.PlotData.StoryId) then
        self.IsUnlock = self._Control:IsStoryUnlock(characterId, self.PlotData.Id)
        self.CanUnlock = self._Control:IsStorySatisfyUnlock(characterId, self.PlotData.Id)
    elseif XTool.IsNumberValid(self.PlotData.StageId) then
        self.IsUnlock = XMVCA.XFuben:CheckStageIsUnlock(self.PlotData.StageId)
        self.CanUnlock = self._Control:IsStorySatisfyUnlock(characterId, self.PlotData.Id)
    else
        XLog.Error("好感度剧情没有关卡配置，Id:"..tostring(self.PlotData.Id))
    end
    
    --UI样式
    self.GridStoryStage:SetNameByGroup(0,CS.XTextManager.GetText("FavorabilityStorySectionName", self.PlotData.SectionNumber))
    self.GridStoryStage:SetNameByGroup(1,self.PlotData.Name)
    self.GridStoryStage:SetNameByGroup(2,self.PlotData.ConditionDescript)
    --设置图片
    self.GridStoryStage:SetRawImage(self.PlotData.Icon)

    if XTool.IsNumberValid(self.PlotData.StageId) then
        ---@type XTableStage
        local stageCfg = XMVCA.XFuben:GetStageCfg(self.PlotData.StageId)

        if stageCfg then
            if stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT then
                self:SetStageIcon(CS.XGame.ClientConfig:GetString('CharacterTrustStoryBattleIcon'))
            else
                self:SetStageIcon(CS.XGame.ClientConfig:GetString('CharacterTrustStoryNoBattleIcon'))
            end
        end
    end
    
    --解锁状态
    if self.IsUnlock or self.CanUnlock then
        self.GridStoryStage:SetButtonState(CS.UiButtonState.Normal)
    else
        self.GridStoryStage:SetButtonState(CS.UiButtonState.Disable)
    end
    
    self:RefreshNewTag()

    -- 刷新标签
    XUiHelper.RefreshCustomizedList(self.PanelTag.transform, self.GridTag, self.PlotData.Tips and #self.PlotData.Tips or 0, function(index, go)
        local tipsCfg = self._Control:GetStoryTipsCfg(self.PlotData.Tips[index])
        local imgBg = go:GetComponentInChildren(typeof(CS.UnityEngine.UI.Image))
        local txtTag = go:GetComponentInChildren(typeof(CS.UnityEngine.UI.Text))

        txtTag.text = tipsCfg.Name

        imgBg.color = XUiHelper.Hexcolor2Color(string.gsub(tipsCfg.BgColor, '#', ''))
        txtTag.color = XUiHelper.Hexcolor2Color(string.gsub(tipsCfg.TxtColor, '#', ''))
    end)
end

function XUiGridFavorabilityStory:RefreshNewTag()
    self.IsShowNewTag = XMVCA.XFavorability:IsStoryShowNewTag(self.PlotData.CharacterId, self.PlotData.Id)
    self.GridStoryStage:ShowTag(self.IsShowNewTag)
end

function XUiGridFavorabilityStory:OnClickEvent()
    if self.IsShowNewTag then
        XMVCA.XFavorability:OnUnlockCharacterStory(self.Parent.CurrentCharacterId, self.PlotData.Id,true)
        XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_PLOTUNLOCK)
        self:RefreshNewTag()
    end
    if self.CanUnlock or self.IsUnlock then
        self.Parent:SetResumeTrigger(true)

        if XTool.IsNumberValid(self.PlotData.StoryId) then
            -- 需要先设置性别
            if not XPlayer.IsSetGender() then
                XPlayer.TipsSetGender("SetGenderTips")
                return
            end
            XDataCenter.MovieManager.PlayMovie(self.PlotData.StoryId, nil)
        elseif XTool.IsNumberValid(self.PlotData.StageId) then
            self._Control:DispatchEvent(XControlEventId.EVENT_OPEN_STORY_DETAIL, self.PlotData)
        end
    else
        XUiManager.TipMsg(self.PlotData.ConditionDescript)
    end
end

function XUiGridFavorabilityStory:SetArrowShow(isFirst, isFinal)
    if self._RootUiObject then
        self._RootUiObject:GetObject('RawJiantou').gameObject:SetActiveEx(isFirst)
        self._RootUiObject:GetObject('RawJiantou2').gameObject:SetActiveEx(isFinal)
    end
end

function XUiGridFavorabilityStory:SetStageIcon(rawImage)
    for i = 1, 3 do
        local rImg = self['RawImageBg'..tostring(i)]

        if rImg then
            rImg:SetRawImage(rawImage)
        end
    end
end

return XUiGridFavorabilityStory