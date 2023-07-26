local XUiGridAttributeStage = require("XUi/XUiWorldBoss/XUiGridAttributeStage")
local XUiGridAttributeChapter = XClass(nil, "UiGridAttributeChapter")

local FocusTime = 0.5
local ScaleLevel = {}
local MAX_STAGE_COUNT = 20
function XUiGridAttributeChapter:Ctor(ui, areaId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.AreaId = areaId
    self.GridStageList = {}
    ScaleLevel = {
        Small = self.PanelDrag.MinScale,
        Big = self.PanelDrag.MaxScale,
        Normal = (self.PanelDrag.MinScale + self.PanelDrag.MaxScale) / 2,
    }
    self.Mask.gameObject:SetActiveEx(false)

end

function XUiGridAttributeChapter:GoToNearestStage()
    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local stageIds = attributeArea:GetStageIds()
    local canPlayList = {}
    for index, stageId in pairs(stageIds) do
        local stageData = attributeArea:GetStageEntityById(stageId)
        if not stageData:GetIsFinish() and not stageData:GetIsLock() then
            table.insert(canPlayList, index)
        end
    end

    if #canPlayList > 0 then
        local firstCanPlayId = canPlayList[1]
        local firstGridStage = self.GridStageList[firstCanPlayId]
        if not firstGridStage then
            XLog.Error("ExploreGroup's setting is Error by stageIndex:" .. firstCanPlayId)
            return
        end

        local nearestTransform = firstGridStage.Transform
        local minDis = CS.UnityEngine.Vector3.Distance(nearestTransform.position, self.PanelDrag.gameObject.transform.position)
        for i = 2, #canPlayList do
            local canPlayId = canPlayList[i]
            local gridStage = self.GridStageList[canPlayId]
            if not gridStage then
                XLog.Error("ExploreGroup's setting is Error by stageIndex:" .. canPlayId)
                break
            end
            local tempDis = CS.UnityEngine.Vector3.Distance(gridStage.Transform.position, self.PanelDrag.gameObject.transform.position)
            if tempDis < minDis then
                nearestTransform = gridStage.Transform
                minDis = tempDis
            end
        end
        self.PanelDrag:FocusTarget(nearestTransform, ScaleLevel.Normal, FocusTime, CS.UnityEngine.Vector3.zero)
    end
end

function XUiGridAttributeChapter:UpdateStageList()
    local attributeArea = XDataCenter.WorldBossManager.GetAttributeAreaById(self.AreaId)
    local stageIds = attributeArea:GetStageIds()

    -- 初始化副本显示列表，i作为order id，从1开始
    for index,stageId in pairs(stageIds) do
        local stageData = attributeArea:GetStageEntityById(stageId)
        local stageCfg = stageData:GetStageCfg()
        local parent = self.PanelStageContent.transform:Find(string.format("Stage%d", index))
        local grid = self.GridStageList[index]

        if not grid then
            local uiName = "GridWorldBossStage"
            uiName = stageCfg.StageGridStyle and string.format("%s%s", uiName, stageCfg.StageGridStyle) or uiName


            local prefabName = CS.XGame.ClientConfig:GetString(uiName)
            local prefab = parent:LoadPrefab(prefabName)

            grid = XUiGridAttributeStage.New(prefab, self)
            grid.Parent = parent
            self.GridStageList[index] = grid
        end

        grid:UpdateStageGrid(stageData)
        parent.gameObject:SetActiveEx(true)
    end


    for i = 1, MAX_STAGE_COUNT do
        if not self.GridStageList[i] then
            local parent = self.PanelStageContent.transform:Find(string.format("Stage%d", i))
            if parent then
                parent.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiGridAttributeChapter:MoveToStageGrid(cb)
    self.Mask.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
            self.PanelDrag:FocusTarget(self.CurStageGrid.Transform, ScaleLevel.Big, FocusTime, CS.UnityEngine.Vector3.zero, function()
                    if cb then cb() end
                    self.Mask.gameObject:SetActiveEx(false)
                end)
        end, 0)
end

function XUiGridAttributeChapter:ScaleBack()
    self.PanelDrag:FocusTarget(self.CurStageGrid.Transform, ScaleLevel.Normal, FocusTime, CS.UnityEngine.Vector3.zero, nil)
end

return XUiGridAttributeChapter