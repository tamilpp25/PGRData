local XUiPanelNierCharacterTeaching = XClass(nil, "XUiPanelNierCharacterTeaching")
local XUiGridNierStage = require("XUi/XUiNieR/XUiGridNierStage")

function XUiPanelNierCharacterTeaching:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = parent

    XTool.InitUiObject(self)
    
    self.StageLine = {}
    self.StageNode = {}
    for index = 1, 4 do
        if index <= 3 then
            self.StageLine[index] = self["Line"..index]
            self.StageLine[index].gameObject:SetActiveEx(false)
        end
        self.StageNode[index] = self["Stage"..index]
    end
    self.GridList = {}
    self.JumpToIndex = true
end

function XUiPanelNierCharacterTeaching:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelNierCharacterTeaching:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelNierCharacterTeaching:InitAllInfo()
    local characterData = XDataCenter.NieRManager.GetSelNieRCharacter()
    local stageIds = characterData:GetTeachingStageIds()
    local stageNum = #stageIds
    stageNum = stageNum > 4 and 4 or stageNum
    
    local defIndex
    for index = 1, 4 do
        local prefab = self.GridAssignNierStage
        local stageType = XNieRConfigs.NieRStageType.Teaching
        
        if stageIds[index] and XDataCenter.FubenManager.GetStageInfo(stageIds[index]).Unlock then
            self:CreatStageNode(index, prefab)
            self.GridList[index]:UpdateNieRStageGrid(stageIds[index], stageType, index)
            self.StageNode[index].gameObject:SetActiveEx(true)
            if index > 1 then
                self.StageLine[index-1].gameObject:SetActiveEx(true)
            end
            if not defIndex or defIndex < index then
                defIndex = index
            end
        else
            self.StageNode[index].gameObject:SetActiveEx(false)
            if index > 1 then
                self.StageLine[index-1].gameObject:SetActiveEx(false)
            end
        end
    end
    if self.JumpToIndex then
        
        if not defIndex then
            defIndex = 1
        end
        self:MoveIntoStage(defIndex)
    end
end

function XUiPanelNierCharacterTeaching:CreatStageNode(index, prefab)
    local grid
    if self.GridList[index] then
        grid = self.GridList[index]
    else
        local ui = CS.UnityEngine.Object.Instantiate(prefab)
        grid = XUiGridNierStage.New(ui, self.RootUi)
        grid.Transform:SetParent(self.StageNode[index], false)
        grid.Transform:GetComponent("RectTransform").anchoredPosition = CS.UnityEngine.Vector2(0, 0)
        self.GridList[index] = grid
    end 
end

function XUiPanelNierCharacterTeaching:MoveIntoStage(stageIndex)
    local gridRect = self.StageNode[stageIndex].transform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    local viewRect = self.ViewPort.transform:GetComponent("RectTransform")
    if diffX > viewRect.rect.width / 2 then
        local tarPosX = (viewRect.rect.width / 4) - gridRect.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        -- XLuaUiManager.SetMask(true)
        -- self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
        -- XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        --     XLuaUiManager.SetMask(false)
        --     self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        -- end)
        self.PanelStageContent.localPosition = tarPos
    end
end

-- function XUiPanelNierCharacterTeaching:PlayScrollViewMove(gridTransform)
--     self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
--     local gridRect = gridTransform:GetComponent("RectTransform")
--     local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
--     if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
--         local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
--         local tarPos = self.PanelStageContent.localPosition
--         tarPos.x = tarPosX
--         XLuaUiManager.SetMask(true)
--         XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
--             XLuaUiManager.SetMask(false)
--         end)
--     end
-- end

function XUiPanelNierCharacterTeaching:SetPanelStageListMovementType(moveMentType)
    if not self.PanelStageList then return end
    self.PanelStageList.movementType = moveMentType
end

return XUiPanelNierCharacterTeaching