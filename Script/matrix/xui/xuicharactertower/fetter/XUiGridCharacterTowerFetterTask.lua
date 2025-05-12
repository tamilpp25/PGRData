local XUiGridCharacter = require("XUi/XUiCharacter/XUiGridCharacter")
---@class XUiGridCharacterTowerFetterTask
local XUiGridCharacterTowerFetterTask = XClass(nil, "XUiGridCharacterTowerFetterTask")

function XUiGridCharacterTowerFetterTask:Ctor(ui, rootUi, relationId, characterId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self.RelationId = relationId
    self.CharacterId = characterId
    ---@type XCharacterTowerRelation
    self.RelationViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerRelation(relationId)
    self.FinishCanvasGroups = self.Finish:GetComponentsInChildren(typeof(CS.UnityEngine.CanvasGroup))
end

function XUiGridCharacterTowerFetterTask:Refresh(conditionId)
    self.ConditionId = conditionId
    self.SkipId = self.RelationViewModel:GetRelationConditionSkipIdByConditionId(conditionId)
    local isPlayEffect = XDataCenter.CharacterTowerManager.CheckRelationTaskPlayAnim(conditionId)
    local isOpen, desc = self.RelationViewModel:CheckFinishCondition(conditionId, self.CharacterId)
    self.TxtTitle.text = self.RelationViewModel:GetRelationConditionTitleByConditionId(conditionId)
    self.TxtDesc.text = desc
    local isActive = (isOpen and isPlayEffect) or self.RootUi.PlayConditionId == conditionId
    self.Finish.gameObject:SetActiveEx(isActive)
end

function XUiGridCharacterTowerFetterTask:PlayAnimation(cb)
    self.Finish.gameObject:SetActiveEx(true)
    self.FinishEnable:PlayTimelineAnimation(function(isFinish)
        if not isFinish then
            -- 动画被打断 需要将alpha设置为1
            XTool.LoopArray(self.FinishCanvasGroups, function(canvasGroup)
                canvasGroup.alpha = 1
            end)
        end
        if cb then
            cb(self.ConditionId)
        end
    end)
end

function XUiGridCharacterTowerFetterTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnAdvance, self.OnBtnAdvanceClick)
end

function XUiGridCharacterTowerFetterTask:OnBtnAdvanceClick()
    if XTool.IsNumberValid(self.SkipId) then
        XFunctionManager.SkipInterface(self.SkipId)
    end
end

return XUiGridCharacterTowerFetterTask