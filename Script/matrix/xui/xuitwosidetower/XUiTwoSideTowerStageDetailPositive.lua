local XUiTwoSideTowerStageDetailPositive = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerStageDetailPositive")
local XUiGridTwoSideTowerStageDetail = require("XUi/XUiTwoSideTower/XUiGridTwoSideTowerStageDetail")

function XUiTwoSideTowerStageDetailPositive:OnAwake()
    self.GridStage.gameObject:SetActiveEx(false)
end

---@param pointData XTwoSideTowerPoint
function XUiTwoSideTowerStageDetailPositive:OnStart(pointData, chapterData)
    self.PointData = pointData
    self.ChapterData = chapterData
    self.StageGrids = {}
    self.BtnBack.CallBack = function()
        self:Close()
    end
end

function XUiTwoSideTowerStageDetailPositive:OnEnable()
    self:Refresh()
end

function XUiTwoSideTowerStageDetailPositive:Refresh()
    local stageList = self.PointData:GetStageDataList()
    for i, stageData in ipairs(stageList) do
        local index = i
        local gridStage = self.StageGrids[i]
        if not gridStage then
            local obj = CS.UnityEngine.GameObject.Instantiate(self.GridStage, self.PanelChooseStage.transform)
            obj.gameObject:SetActiveEx(true)
            gridStage = XUiGridTwoSideTowerStageDetail.New(obj, stageData, self.PointData, self.ChapterData, function() 
                self:Remove()
            end, 
            function() self:OnSelectGrid(index) end)
            table.insert(self.StageGrids, gridStage)
        end
        gridStage:Refresh(stageData, self.PointData, self.ChapterData)
    end

    self.AnimUilEnable:PlayTimelineAnimation(function()
        --self:OnSelectGrid(1)
    end)
end

function XUiTwoSideTowerStageDetailPositive:OnSelectGrid(index)
    for i, grid in ipairs(self.StageGrids) do
        local isSelect = index == i
        grid:RefreshSelect(isSelect)
    end
end

return XUiTwoSideTowerStageDetailPositive
