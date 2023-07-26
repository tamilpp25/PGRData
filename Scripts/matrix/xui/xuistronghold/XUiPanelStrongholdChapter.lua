local XUiGridStrongholdGroup = require("XUi/XUiStronghold/XUiGridStrongholdGroup")

local Lerp = CS.UnityEngine.Mathf.Lerp
local Vector3 = CS.UnityEngine.Vector3
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule

local ANIM_DURATION = 0.2
--关卡滑动动画持续时间
local CENTER_PERCENT = 0.3
--关卡要滑动到的位置占屏幕宽度百分比

local XUiPanelStrongholdChapter = XClass(nil, "XUiPanelStrongholdChapter")

function XUiPanelStrongholdChapter:Ctor(ui, clickStageCb, skipCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GroupGrids = {}
    self.ClickStageCb = clickStageCb
    self.SkipCb = skipCb

    XTool.InitUiObject(self)

    self.ViewPort = self.Transform:FindTransform("ViewPort")
    self.PanelStageContent = self.Transform:FindTransform("PanelStageContent")
    self.ScrollRect = self.Transform:FindTransform("PaneStageList"):GetComponent("ScrollRect")
end

function XUiPanelStrongholdChapter:Refresh(chapterId)
    local groupIds = XStrongholdConfigs.GetGroupIds(chapterId)
    self.GroupIds = groupIds

    for index, groupId in ipairs(groupIds) do
        local grid = self.GroupGrids[index]
        if not grid then
            local prefabPath = XStrongholdConfigs.GetGroupPrefabPath(groupId)
            local parent = self["Stage" .. index]
            if not parent then
                XLog.Error(
                    "XUiPanelStrongholdChapter:Refresh error:stage num error: chapterId is: " ..
                        chapterId .. ", index is:" .. index .. ", prefabPath: " .. prefabPath .. ", groupIds:",
                    groupIds
                )
                return
            end
            local go = parent:LoadPrefab(prefabPath)
            local clickStageCb = handler(self, self.OnClickStage)
            grid = XUiGridStrongholdGroup.New(go, index, clickStageCb, self.SkipCb)
            self.GroupGrids[index] = grid
        end

        grid:Refresh(groupId)
        grid.GameObject:SetActiveEx(true)

        self:RefreshClearLine(index, groupId)
    end

    for index = #groupIds + 1, #self.GroupGrids do
        local grid = self.GroupGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelStrongholdChapter:RefreshClearLine(index, groupId)
    local isFinished = XDataCenter.StrongholdManager.IsGroupFinished(groupId)
    local clearLine = self["ClearLine" .. index]
    local notClearLine = self["NotClearLine" .. index]
    if clearLine then
        clearLine.gameObject:SetActiveEx(isFinished)
    end
    if notClearLine then
        notClearLine.gameObject:SetActiveEx(not isFinished)
    end

    local preClearLine = self["PreClearLine" .. index]
    local preNotClearLine = self["PreNotClearLine" .. index]
    if preClearLine and preNotClearLine then
        local buffIds = XDataCenter.StrongholdManager.GetGroupBossBuffIds(groupId)
        local isBuffActive
        local preIsAllClear = true
        for index, buffId in ipairs(buffIds) do
            isBuffActive = XDataCenter.StrongholdManager.CheckBuffActive(buffId)
            if isBuffActive then
                preIsAllClear = false
                break
            end
        end
        preClearLine.gameObject:SetActiveEx(preIsAllClear)
        preNotClearLine.gameObject:SetActiveEx(not preIsAllClear)
    end
end

function XUiPanelStrongholdChapter:OnClickStage(gridIndex)
    self.SelectGridIndex = gridIndex
    if not gridIndex then
        return
    end

    local groupId = self.GroupIds[gridIndex]
    if self.ClickStageCb then
        self.ClickStageCb(groupId)
    end

    for index, grid in pairs(self.GroupGrids) do
        grid:SetSelect(index == gridIndex)
    end

    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    self:CenterToGrid(gridIndex)
end

function XUiPanelStrongholdChapter:OnStageDetailClose()
    self.SelectGridIndex = nil
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic

    for index, grid in pairs(self.GroupGrids) do
        grid:SetSelect(false)
    end
end

function XUiPanelStrongholdChapter:CenterToGrid(gridIndex)
    local parent = self["Stage" .. gridIndex]
    if not parent then
        return
    end

    local gridPosX = parent.transform.anchoredPosition3D.x
    local limitX = self.ViewPort.rect.width * CENTER_PERCENT
    local delta = limitX - gridPosX

    local startPos = self.PanelStageContent.anchoredPosition3D
    local endPosX = delta

    local onRefresh = function(time)
        if XTool.UObjIsNil(self.PanelStageContent) then
            self:DestroyTimer()
            return true
        end

        if startPos.x == endPosX then
            return true
        end

        local posX = Lerp(startPos.x, endPosX, time)
        self.PanelStageContent.anchoredPosition3D = Vector3(posX, startPos.y, startPos.z)
    end

    local onFinish = function()
        XLuaUiManager.SetMask(false)
    end

    XLuaUiManager.SetMask(true)

    self.Timer = XUiHelper.Tween(ANIM_DURATION, onRefresh, onFinish)
end

function XUiPanelStrongholdChapter:DestroyTimer()
    if self.Timer then
        CSXScheduleManagerUnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPanelStrongholdChapter:CenterToLastGrid()
    local gridIndex = #self.GroupIds
    self:OnClickStage(gridIndex)
end

function XUiPanelStrongholdChapter:OnSkipStage(skipGroupId)
    for index, groupId in ipairs(self.GroupIds) do
        if groupId == skipGroupId then
            self:OnClickStage(index)
            return
        end
    end
    XLog.Error(string.format("当前组没有找到可跳转的关卡id。GroupId：%s", skipGroupId))
end

return XUiPanelStrongholdChapter
