local XUiTRPGTruthRoadStage = require("XUi/XUiTRPG/XUiTRPGTruthRoad/XUiTRPGTruthRoadStage")

local ipairs = ipairs
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local TWEE_DURATION
local MAX_STAGE_NUM = CS.XGame.ClientConfig:GetInt("TRPGTruthRoadStageMaxCount")

local XUiTRPGTruthRoadStages = XClass(nil, "XUiTRPGTruthRoadStages")

function XUiTRPGTruthRoadStages:Ctor(ui, truthRoadGroupId, cb, currSelectTruthRoadId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.CurrSelectTruthRoadId = currSelectTruthRoadId
    self.TruthRoadGroupId = truthRoadGroupId
    self.CallBack = cb
    self.MarkX = self.ViewPort.rect.width * 0.6
    self.InitPosX = -960    --self.PanelStageContent.localPosition.x
    TWEE_DURATION = XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration
    self.LineList = {}
    self.StageList = {}

    self:InitStagesMap()
end

function XUiTRPGTruthRoadStages:InitStagesMap()
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
    local truthRoadIdList = XTRPGConfigs.GetTruthRoadIdList(self.TruthRoadGroupId)
    local lastUnlockTruthRoadId
    local condition
    local conditionIsFinish
    for i, truthRoadId in ipairs(truthRoadIdList) do
        local stageParent = self["Stage" .. i]
        if XTool.UObjIsNil(stageParent) then
            XLog.Error("ui界面 stage" .. i .. "不存在，检测TRPGTruthRoadGroup配置")
        else
            local prefabPath = XTRPGConfigs.GetTruthRoadPrafabName(truthRoadId)
            local ui = stageParent:LoadPrefab(prefabPath)
            self.GridStages[i] = XUiTRPGTruthRoadStage.New(ui, self, self.TruthRoadGroupId, truthRoadId, clickCb)

            condition = XTRPGConfigs.GetTruthRoadCondition(truthRoadId)
            conditionIsFinish = XConditionManager.CheckCondition(condition)
            if conditionIsFinish then
                lastUnlockTruthRoadId = truthRoadId
            end
        end
    end

    --自动滑动到当前列表中选择的关卡或已解锁的最后1个关卡
    local truthRoadId
    for _, v in ipairs(self.GridStages) do
        truthRoadId = v:GetTruthRoadId()
        if truthRoadId == self.CurrSelectTruthRoadId or truthRoadId == lastUnlockTruthRoadId then
            self:PlayScrollViewMove(v, true)
            return
        end
    end
end

function XUiTRPGTruthRoadStages:UpdateStagesMap()
    self.GameObject:SetActiveEx(false)
    for i, grid in ipairs(self.GridStages) do
        grid:Refresh()
    end
    self:UpdateStagesActiveState()
    self.GameObject:SetActiveEx(true)
end

function XUiTRPGTruthRoadStages:UpdateStagesActiveState()
    for i = 1, MAX_STAGE_NUM do
        self:SetStageActive(i, false)
        self:SetLineActive(i - 1, false)
    end

    local truthRoadIdList = XTRPGConfigs.GetTruthRoadIdList(self.TruthRoadGroupId)
    local condition
    local conditionIsFinish

    for i, truthRoadId in ipairs(truthRoadIdList) do
        condition = XTRPGConfigs.GetTruthRoadCondition(truthRoadId)
        conditionIsFinish = XConditionManager.CheckCondition(condition)
        if self.GridStages[i] and conditionIsFinish then
            self:SetStageActive(i, true)
            self:SetLineActive(i - 1, true)
        end
    end
end

function XUiTRPGTruthRoadStages:SetStageActive(index, active)
    local stage = self.StageList[index]
    if stage then
        stage.gameObject:SetActiveEx(active)
    end
end

function XUiTRPGTruthRoadStages:SetLineActive(index, active)
    local line = self.LineList[index]
    if line then
        line.gameObject:SetActive(active)
    end
end

function XUiTRPGTruthRoadStages:PlayScrollViewMove(grid, ignoreAnim)
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
                    self.CallBack(self.LastSelectGrid:GetTruthRoadId())
                end
            end)
        else
            self.PanelStageContent.localPosition = tarPos
        end
    end
end

function XUiTRPGTruthRoadStages:SetActive(isActive)
    self.GameObject:SetActiveEx(isActive)
end

function XUiTRPGTruthRoadStages:SetParent(parent)
    self.Transform:SetParent(parent, false)
end

function XUiTRPGTruthRoadStages:CancalSelectLastGrid()
    if self.LastSelectGrid then
        self.LastSelectGrid:SetSelect(false)
    end
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

return XUiTRPGTruthRoadStages