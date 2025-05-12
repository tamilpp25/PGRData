---@class XUiPanelFavorabilityStoryList: XUiNode
---@field _Control XFavorabilityControl
local XUiPanelFavorabilityStoryList = XClass(XUiNode, 'XUiPanelFavorabilityStoryList')
local XUiGridFavorabilityStory=require('XUi/XUiFavorability/StoryPanel/XUiGridFavorabilityStory')

local Sequence={
    First=0,
    Mid=1,
    Last=2
}

function XUiPanelFavorabilityStoryList:OnStart(currentCharacterId)
    self.CurrentCharacterId = currentCharacterId
    self:InitGrids()
    self.GridStoryStage.gameObject:SetActiveEx(false) 
end

function XUiPanelFavorabilityStoryList:OnEnable()
    self:RefreshStoryData()
end

function XUiPanelFavorabilityStoryList:InitGrids()
    self.StoryGridCtrls={}
    for i=1,15 do
        if self['GridStoryStage'..i] then
            local go = CS.UnityEngine.GameObject.Instantiate(self.GridStoryStage, self['GridStoryStage'..i].transform)
            go.gameObject:SetActiveEx(false)
            local grid = XUiGridFavorabilityStory.New(go, self)
            grid:Close()
            table.insert(self.StoryGridCtrls, grid)
            if not self.StoryContent then
                self.StoryContent = self['GridStoryStage'..i].transform.parent
            end
        end
    end
end

function XUiPanelFavorabilityStoryList:SetLayoutHorizontalPos(posX)
    if XTool.IsNumberValid(posX) then
        self.StoryContent.anchoredPosition = Vector2(posX, self.StoryContent.anchoredPosition.y)
    end
end

function XUiPanelFavorabilityStoryList:RefreshStoryData()
    --隐藏格子和线条
    for i=1,15 do
        if self['GridStoryStage'..i] then
            self['GridStoryStage'..i].gameObject:SetActiveEx(false)
        end
        if self['Line'..i] then
            self['Line'..i].gameObject:SetActiveEx(false)
        end
    end

    --显示和设置格子数据
    local plotDatas = XMVCA.XFavorability:GetCharacterStoryById(self.CurrentCharacterId)
    local dataCount = #plotDatas
    for i, data in ipairs(plotDatas) do
        if data and self.StoryGridCtrls[i] then
            self['GridStoryStage'..i].gameObject:SetActiveEx(true)
            self.StoryGridCtrls[i]:Open()
            self.StoryGridCtrls[i]:Refresh(data)
            local isFirst = i == 1
            local isFinal = i == dataCount

            -- 只控制第一和最后的箭头，中间保留UI设置的状态
            if isFirst or isFinal then
                self.StoryGridCtrls[i]:SetArrowShow(isFirst, isFinal)
            end
            
        end
    end

    --显示线条
    for i = 1, dataCount - 1 do
        if self['Line'..i] then
            self['Line'..i].gameObject:SetActiveEx(true)
        end
    end
end

function XUiPanelFavorabilityStoryList:SetResumeTrigger(trigger)
    self.Parent:SetResumeTrigger(trigger, self.StoryContent.anchoredPosition.x)
end

return XUiPanelFavorabilityStoryList