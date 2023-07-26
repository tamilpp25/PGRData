local XUiLivWarmRaceStage = require("XUi/XUiLivWarmRace/XUiLivWarmRaceStage")

local ipairs = ipairs
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local TWEE_DURATION

local XUiLivWarmRaceStageGroup = XClass(nil, "XUiLivWarmRaceStageGroup")

function XUiLivWarmRaceStageGroup:Ctor(ui, groupId, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.GroupId = groupId
    self.CallBack = cb
    self.MarkX = self.ViewPort.rect.width * 0.5
    self.InitPosX = self.PanelStageContent.localPosition.x
    TWEE_DURATION = XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration
    self.LineList = {}
    self.StageList = {}

    self:InitStagesMap()
end

function XUiLivWarmRaceStageGroup:InitStagesMap()
    local groupId = self:GetGroupId()
    local stageIdList = XLivWarmRaceConfigs.GetGroupStageIds(groupId)
    for i = 1, #stageIdList do
        if self["Stage" .. i] then
            self.StageList[i] = self["Stage" .. i]
        end
        if self["Line" .. i - 1] then
            self.LineList[i - 1] = self["Line" .. i - 1]
        end
    end

    self.LastSelectGrid = nil
    local clickCb = function(grid)
        grid:SetSelect(true)
        self.LastSelectGrid = grid
        self:PlayScrollViewMove(grid)
    end

    self.GridStages = {}
    local lastUnlockStageId
    local stageParent
    local prefabPath
    local ui
    for i, stageId in ipairs(stageIdList) do
        stageParent = self["Stage" .. i]
        if XTool.UObjIsNil(stageParent) then
            XLog.Error(string.format("ui界面 %s 不存在 stage%s，检测RunGameGroup配置和该场景", self.GameObject.name, i))
        else
            prefabPath = XLivWarmRaceConfigs.GetStagePrefab(stageId)
            ui = stageParent:LoadPrefab(prefabPath)
            self.GridStages[i] = XUiLivWarmRaceStage.New(ui, stageId, groupId, clickCb)

            if XDataCenter.LivWarmRaceManager.IsStageClear(stageId) then
                lastUnlockStageId = stageId
            end
        end
    end

    --自动滑动到已解锁的最后1个关卡
    for _, v in ipairs(self.GridStages) do
        if v:GetStageId() == lastUnlockStageId then
            self:PlayScrollViewMove(v, true)
            return
        end
    end
end

function XUiLivWarmRaceStageGroup:UpdateStagesMap()
    self.GameObject:SetActiveEx(false)
    for i, grid in ipairs(self.GridStages) do
        grid:Refresh()
    end
    self:UpdateStagesActiveState()
    self.GameObject:SetActiveEx(true)
end

function XUiLivWarmRaceStageGroup:UpdateStagesActiveState()
    local groupId = self:GetGroupId()
    local stageIdList = XLivWarmRaceConfigs.GetGroupStageIds(groupId)
    local isOpen, lockPreStageId
    local isPreStageOpen
    
    for i, stageId in ipairs(stageIdList) do
        isOpen, lockPreStageId = XDataCenter.LivWarmRaceManager.IsStageOpen(stageId)
        isPreStageOpen = XDataCenter.LivWarmRaceManager.IsStageOpen(lockPreStageId)
        self:SetStageActive(i, isPreStageOpen or isOpen)
        self:SetLineActive(i - 1, isPreStageOpen or isOpen)
    end
end

function XUiLivWarmRaceStageGroup:SetStageActive(index, active)
    local stage = self.StageList[index]
    if stage then
        stage.gameObject:SetActiveEx(active or false)
    end
end

function XUiLivWarmRaceStageGroup:SetLineActive(index, active)
    local line = self.LineList[index]
    if line then
        line.gameObject:SetActiveEx(active or false)
    end
end

function XUiLivWarmRaceStageGroup:PlayScrollViewMove(grid, ignoreAnim)
    local gridX = grid.Transform.parent:GetComponent("RectTransform").localPosition.x
    local contentPos = self.PanelStageContent.localPosition
    local markX = self.MarkX
    local diffX = gridX - markX
    if diffX ~= 0 then
        local targetPosX = self.InitPosX - diffX
        local tarPos = contentPos
        tarPos.x = targetPosX

        if not ignoreAnim then
            XLuaUiManager.SetMask(true)
            self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
            XUiHelper.DoMove(self.PanelStageContent, tarPos, TWEE_DURATION, XUiHelper.EaseType.Sin, function()
                XLuaUiManager.SetMask(false)
                if self.CallBack and self.LastSelectGrid then
                    self.CallBack(self.LastSelectGrid:GetStageId())
                end
            end)
        else
            self.PanelStageContent.localPosition = tarPos
        end
    end
end

function XUiLivWarmRaceStageGroup:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

function XUiLivWarmRaceStageGroup:SetParent(parent)
    self.Transform:SetParent(parent, false)
end

function XUiLivWarmRaceStageGroup:CancalSelectLastGrid()
    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
    end
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

function XUiLivWarmRaceStageGroup:GetGroupId()
    return self.GroupId
end

return XUiLivWarmRaceStageGroup