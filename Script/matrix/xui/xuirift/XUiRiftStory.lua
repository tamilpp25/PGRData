---@class XUiRiftStory : XLuaUi 剧情回忆
---@field _Control XRiftControl
local XUiRiftStory = XLuaUiManager.Register(XLuaUi, "UiRiftStory")

function XUiRiftStory:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close)
end

function XUiRiftStory:OnStart(index)
    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    local btns = {}
    local chapters = self._Control:GetEntityChapter()
    XUiHelper.RefreshCustomizedList(self.BtnTab.transform.parent, self.BtnTab, #chapters, function(i, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.BtnTab:SetNameByGroup(0, chapters[i]:GetConfig().Name)
        table.insert(btns, uiObject.BtnTab)
    end)

    self.PanelTabList:Init(btns, function(i)
        local chapter = chapters[i]:GetConfig()
        local storys = self._Control:GetChapterStory(chapter.Id)
        self.TxtTitle.text = chapter.Name
        XUiHelper.RefreshCustomizedList(self.GridStory.parent, self.GridStory, storys and #storys or 0, function(i, go)
            local story = storys[i]
            local uiObject = {}
            XUiHelper.InitUiClass(uiObject, go)
            local isUnlock = true
            if XTool.IsNumberValid(story.Condition) then
                isUnlock = XConditionManager.CheckCondition(story.Condition)
            end
            local isAvg = XTool.IsNumberValid(story.AvgId)
            uiObject.PanelLock.gameObject:SetActiveEx(not isUnlock)
            uiObject.PanelStoryDesc.gameObject:SetActiveEx(isUnlock and not isAvg)
            uiObject.PanelAvg.gameObject:SetActiveEx(isUnlock and isAvg)
            uiObject.TxtStoryDesc.text = XUiHelper.ReplaceTextNewLine(story.Words)
            uiObject.TxtAvgDesc.text = XUiHelper.ReplaceTextNewLine(story.Words)
            uiObject.BtnAvg.CallBack = function()
                if isAvg then
                    XDataCenter.MovieManager.PlayMovie(story.AvgId, nil, nil, nil, false)
                end
            end
        end)
        if self._IsPlayTween then
            self:PlayAnimation("QieHuan")
        end
        self._IsPlayTween = true
    end)

    self.PanelTabList:SelectIndex(index or 1)
end

return XUiRiftStory