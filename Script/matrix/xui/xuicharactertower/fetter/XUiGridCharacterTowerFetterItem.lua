local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
---@class XUiGridCharacterTowerFetterItem
local XUiGridCharacterTowerFetterItem = XClass(nil, "XUiGridCharacterTowerFetterItem")

function XUiGridCharacterTowerFetterItem:Ctor(ui, rootUi, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = cb
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick)
    self.IsActive = false
end

function XUiGridCharacterTowerFetterItem:Refresh(relationId, eventId, index)
    self.RelationId = relationId
    self.EventId = eventId
    self.Index = index
    ---@type XCharacterTowerRelation
    self.RelationViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerRelation(relationId)
    
    self:RefreshInfo()
end

function XUiGridCharacterTowerFetterItem:RefreshInfo()
    local fightEventIds = self.RelationViewModel:GetRelationFightEventIds()
    -- 标题
    local title = self.RelationViewModel:GetRelationFettersTitleByIndex(self.Index)
    self.TxtName.text = XUiHelper.ConvertLineBreakSymbol(title)
    -- 百分比
    local totalCount = #fightEventIds
    self.TxtNum.text = string.format("%s/%s", self.Index, totalCount)
    -- 羁绊描述
    local desc = self.RelationViewModel:GetRelationFettersDescribeByIndex(self.Index)
    self.TxtSelect.text = XUiHelper.ConvertLineBreakSymbol(desc)
    -- 是否激活
    local fetterActive = self.RelationViewModel:CheckRelationActive(self.EventId, self.Index)
    self.PanelNormal.gameObject:SetActiveEx(true)
    self.PanelLock.gameObject:SetActiveEx(not fetterActive)
    -- 红点（默认是隐藏的）
    self:ShowBtnClickRed(false)
    -- 特效默认隐藏
    self.Effect.gameObject:SetActiveEx(false)
    self.IsActive = false
end

function XUiGridCharacterTowerFetterItem:SetFetterSelect(isSelect)
    if not self.GameObject or not self.GameObject:Exist() then
        return
    end
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

function XUiGridCharacterTowerFetterItem:ShowBtnClickRed(isShow)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.Red.gameObject:SetActiveEx(isShow)
end

function XUiGridCharacterTowerFetterItem:ShowFetterEffect()
    self.IsActive = true
    -- 选择
    if self.ClickCb then
        self.ClickCb(self)
    end
    self.PanelLock.gameObject:SetActiveEx(false)
    self:ShowBtnClickRed(true)
    self.Effect.gameObject:SetActiveEx(true)
end

function XUiGridCharacterTowerFetterItem:ActiveFetter()
    local storyId = self.RelationViewModel:GetRelationStoryIdByIndex(self.Index)
    if not string.IsNilOrEmpty(storyId) then
        XDataCenter.CharacterTowerManager.CharacterTowerSaveStoryIdRequest(self.RelationId, storyId, function()
            XDataCenter.MovieManager.PlayMovie(storyId, function()
                self:ActivateFightEventId(storyId)
            end, nil, nil, false)
        end)
    else
        self:ActivateFightEventId(storyId)
    end
end

function XUiGridCharacterTowerFetterItem:ActivateFightEventId(storyId)
    if self.EventId < 0 then
        self:ActiveFinish(storyId, self.EventId)
    else
        XDataCenter.CharacterTowerManager.CharacterTowerActivateFightEventIdRequest(self.RelationId, self.EventId, function()
            self:ActiveFinish(storyId, self.EventId)
        end)
    end
end

function XUiGridCharacterTowerFetterItem:ActiveFinish(storyId, eventId)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.IsActive = false
    self:ShowBtnClickRed(false)
    self.Effect.gameObject:SetActiveEx(false)
    self.RootUi:AutomaticFetterFinishCallback(storyId, eventId)
end

function XUiGridCharacterTowerFetterItem:OnBtnClickClick()
    if self.IsActive then
        -- 激活羁绊
        self:ActiveFetter()
    end
    -- 是否激活
    local fetterActive = self.RelationViewModel:CheckRelationActive(self.EventId, self.Index)
    if not fetterActive and not self.IsActive then
        local num = self.RelationViewModel:GetRelationFinishNumByIndex(self.Index)
        XUiManager.TipMsg(XUiHelper.GetText("CharacterTowerRelationLockTips", num))
        return
    end
    if self.ClickCb then
        self:ClickCb(self)
    end
end

return XUiGridCharacterTowerFetterItem
