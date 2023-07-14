local XUiPanelTwoSideTowerRoadLine = XClass(nil, "XUiPanelTwoSideTowerRoadLine")
local XUiGridTwoSideTowerStage = require("XUi/XUiTwoSideTower/XUiGridTwoSideTowerStage")
---@param gameObject UnityEngine.GameObject
function XUiPanelTwoSideTowerRoadLine:Ctor(gameObject, chapterId, root)
    self.GameObject = gameObject
    self.Transform = gameObject.transform
    self.ChapterId = chapterId
    self.Root = root
    XTool.InitUiObject(self)
    self.StageList = {}
end

function XUiPanelTwoSideTowerRoadLine:Update(chapterId)
    self.ChapterId = chapterId or self.ChapterId
    ---@type XTwoSideTowerChapter
    local chapter = XDataCenter.TwoSideTowerManager.GetChapter(self.ChapterId)
    local pointList = chapter:GetPointData()
    if not chapter:IsPositive() then
        table.sort(pointList, function(a, b) return a:GetId() > b:GetId() end)
    end
    for i, pointData in ipairs(pointList) do
        if not self.StageList[i] then
            ---@type UnityEngine.RectTransform
            local stageObj = CS.UnityEngine.GameObject.Instantiate(self.GridStage, self["Stage" .. i])
            stageObj.localPosition = CS.UnityEngine.Vector3.zero
            local stage = XUiGridTwoSideTowerStage.New(stageObj, pointData, chapter:IsPointPositive(pointData), function(stage) self:OnSelectStage(stage) end, chapter, self)
            table.insert(self.StageList, stage)
        else
            self.StageList[i]:Refresh(pointData, chapter)
        end
    end
    self.GridStage.gameObject:SetActiveEx(false)

    -- 刷新路线
    local pointCnt = #pointList
    for i, pointData in ipairs(pointList) do
        local isPositive = chapter:IsPointPositive(pointData)
        self["RedStage"..i].gameObject:SetActiveEx(not isPositive)
        if i < pointCnt then
            local lineGo = self["Line"..i]
            local redLineGo = self["RedLine"..i]
            if not isPositive then
                local nextPointData = pointList[i + 1]
                local nextIsPositive = chapter:IsPointPositive(nextPointData)
                lineGo.gameObject:SetActiveEx(false)
                redLineGo.gameObject:SetActiveEx(true)
                redLineGo.transform:Find("Effect1").gameObject:SetActiveEx(nextIsPositive)
                redLineGo.transform:Find("Effect2").gameObject:SetActiveEx(not nextIsPositive)
            else
                lineGo.gameObject:SetActiveEx(true)
                redLineGo.gameObject:SetActiveEx(false)
            end
        end
    end
end

---@param stage XUiGridTwoSideTowerStage
function XUiPanelTwoSideTowerRoadLine:OnSelectStage(stage)
    for _, stageEntity in pairs(self.StageList) do
        if stage == stageEntity then
            stageEntity:SetSelect(true)
        else
            stageEntity:SetSelect(false)
        end
    end
end

-- 刷新特性列表
function XUiPanelTwoSideTowerRoadLine:RefreshBuffList()
    for _, stageEntity in pairs(self.StageList) do
        stageEntity:RefreshBuffList()
    end
end

-- 播放切换动画
function XUiPanelTwoSideTowerRoadLine:PlaySwitchAnim()
    for _, stageEntity in pairs(self.StageList) do
        stageEntity:PlaySwitchAnim()
    end
end

return XUiPanelTwoSideTowerRoadLine
