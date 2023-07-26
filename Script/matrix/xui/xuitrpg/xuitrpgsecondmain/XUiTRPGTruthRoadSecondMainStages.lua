--常规主线的关卡格子
local XUiTRPGTruthRoadSecondMainStage = require("XUi/XUiTRPG/XUiTRPGSecondMain/XUiTRPGTruthRoadSecondMainStage")

local ipairs = ipairs
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local TWEE_DURATION
local MAX_STAGE_NUM = CS.XGame.ClientConfig:GetInt("TRPGTruthRoadStageMaxCount")

local XUiTRPGTruthRoadSecondMainStages = XClass(nil, "XUiTRPGTruthRoadSecondMainStages")

function XUiTRPGTruthRoadSecondMainStages:Ctor(ui, secondMainId, cb, currSelectSecondMainStageId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.CurrSelectSecondMainStageId = currSelectSecondMainStageId
    self.SecondMainId = secondMainId
    self.CallBack = cb
    self.MarkX = self.ViewPort.rect.width * 0.5
    self.InitPosX = self.PanelStageContent.localPosition.x
    TWEE_DURATION = XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration
    self.LineList = {}
    self.StageList = {}

    self:InitStagesMap()
end

function XUiTRPGTruthRoadSecondMainStages:InitStagesMap()
    for i = 1, MAX_STAGE_NUM do
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
    local secondMainStageIdList = XTRPGConfigs.GetSecondMainStageId(self.SecondMainId)
    local lastUnlockSecondMainStageId
    local stageId
    for i, secondMainStageId in ipairs(secondMainStageIdList) do
        local stageParent = self["Stage" .. i]
        if XTool.UObjIsNil(stageParent) then
            XLog.Error(string.format("ui界面 %s 不存在 stage%s，检测TRPGSecondMain配置和该场景", self.GameObject.name, i))
        else
            local prefabPath = XTRPGConfigs.GetSecondMainStagePrefabName(secondMainStageId)
            local ui = stageParent:LoadPrefab(prefabPath)
            self.GridStages[i] = XUiTRPGTruthRoadSecondMainStage.New(ui, self, secondMainStageId, clickCb)

            stageId = XTRPGConfigs.GetSecondMainStageStageId(secondMainStageId)
            if XDataCenter.TRPGManager.IsStagePass(stageId) then
                lastUnlockSecondMainStageId = secondMainStageId
            end
        end
    end

    --自动滑动到当前列表中选择的关卡或已解锁的最后1个关卡
    local secondMainStageId
    for _, v in ipairs(self.GridStages) do
        secondMainStageId = v:GetSecondMainStageId()
        if secondMainStageId == self.CurrSelectSecondMainStageId or secondMainStageId == lastUnlockSecondMainStageId then
            self:PlayScrollViewMove(v, true)
            return
        end
    end
end

function XUiTRPGTruthRoadSecondMainStages:UpdateStagesMap()
    self.GameObject:SetActiveEx(false)
    for i, grid in ipairs(self.GridStages) do
        grid:Refresh()
    end
    self:UpdateStagesActiveState()
    self.GameObject:SetActiveEx(true)
end

function XUiTRPGTruthRoadSecondMainStages:UpdateStagesActiveState()
    for i = 1, MAX_STAGE_NUM do
        self:SetStageActive(i, false)
        self:SetLineActive(i - 1, false)
    end

    local secondMainStageList = XTRPGConfigs.GetSecondMainStageId(self.SecondMainId)
    local conditionIsFinish

    for i, secondMainStage in ipairs(secondMainStageList) do
        conditionIsFinish = XDataCenter.TRPGManager.CheckSecondMainStageCondition(secondMainStage)
        if self.GridStages[i] and conditionIsFinish then
            self:SetStageActive(i, true)
            self:SetLineActive(i - 1, true)
        end
    end
end

function XUiTRPGTruthRoadSecondMainStages:SetStageActive(index, active)
    local stage = self.StageList[index]
    if stage then
        stage.gameObject:SetActiveEx(active)
    end
end

function XUiTRPGTruthRoadSecondMainStages:SetLineActive(index, active)
    local line = self.LineList[index]
    if line then
        line.gameObject:SetActive(active)
    end
end

function XUiTRPGTruthRoadSecondMainStages:PlayScrollViewMove(grid, ignoreAnim)
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
                    self.CallBack(self.LastSelectGrid:GetSecondMainStageId())
                end
            end)
        else
            self.PanelStageContent.localPosition = tarPos
        end
    end
end

function XUiTRPGTruthRoadSecondMainStages:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

function XUiTRPGTruthRoadSecondMainStages:SetParent(parent)
    self.Transform:SetParent(parent, false)
end

function XUiTRPGTruthRoadSecondMainStages:CancalSelectLastGrid()
    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
    end
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

return XUiTRPGTruthRoadSecondMainStages