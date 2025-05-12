local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
---@class XUiGridCharacterTowerInformation
local XUiGridCharacterTowerInformation = XClass(nil, "XUiGridCharacterTowerInformation")

function XUiGridCharacterTowerInformation:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnPlay, self.OnBtnPlayClick)
end

function XUiGridCharacterTowerInformation:Refresh(relationId, eventId, index)
    self.RelationId = relationId
    self.EventId = eventId
    self.Index = index
    ---@type XCharacterTowerRelation
    self.RelationViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerRelation(relationId)
    
    self:RefreshInfo()
end

function XUiGridCharacterTowerInformation:RefreshInfo()
    -- 描述
    local num = self.RelationViewModel:GetRelationFinishNumByIndex(self.Index)
    self.TxtName.text = XUiHelper.GetText("CharacterTowerRelationFinishDesc", num)
    -- 是否激活
    local fetterActive = self.RelationViewModel:CheckRelationActive(self.EventId, self.Index)
    local storyId = self.RelationViewModel:GetRelationStoryIdByIndex(self.Index)
    self.ImgLock.gameObject:SetActiveEx(not fetterActive)
    self.BtnPlay.gameObject:SetActiveEx(fetterActive and not string.IsNilOrEmpty(storyId))
end

-- 播放剧情
function XUiGridCharacterTowerInformation:OnBtnPlayClick()
    local fetterActive = self.RelationViewModel:CheckRelationActive(self.EventId, self.Index)
    if not fetterActive then
        return
    end
    local storyId = self.RelationViewModel:GetRelationStoryIdByIndex(self.Index)
    if not string.IsNilOrEmpty(storyId) then
        XDataCenter.MovieManager.PlayMovie(storyId)
    end
end

return XUiGridCharacterTowerInformation