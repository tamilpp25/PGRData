local XUiPanelPracticeMainline = XClass(nil,"XUiPanelPracticeMainline")
local XUiGridStagePracticeCharacter = require("XUi/XUiFubenPractice/XUiGridStagePracticeCharacter")

local MAX_STAGE_COUNT = CS.XGame.ClientConfig:GetInt("PracticeStageMaxCount")
local Fight = "GridStagePracticeCharacterFight"
local Reward = "GridStagePracticeCharacterReward"

function XUiPanelPracticeMainline:Ctor(ui, groupId, hideStageCb, showStageCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GroupId = groupId
    self.HideStageCb = hideStageCb
    self.ShowStageCb = showStageCb
    
    self.LineItemList = {}      -- 关卡线数组
    
    self.GridStageList = {}
    self.StageIds = XPracticeConfigs.GetPracticeStageIdsByGroupId(self.GroupId)
    
    self:LoadBackGroundImage()
    self:InitComponent()
end

function XUiPanelPracticeMainline:LoadBackGroundImage()
    local bg = XPracticeConfigs.GetPracticeGroupBackGroundImage(self.GroupId)
    if bg then
        self.PanelClass:SetRawImage(bg)
    end
end

function XUiPanelPracticeMainline:InitComponent()
    -- 保存关卡与关卡线物体
    self:FindItem("Line%d", self.LineItemList)

    -- 实例化关卡类
    for i = 1, #self.StageIds do
        local stageId = self.StageIds[i]
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)

        if stageInfo.IsOpen then
            local grid = self.GridStageList[i]
            if not grid then
                local uiName = XTool.IsNumberValid(stageCfg.FirstRewardId) and Reward or Fight
                local parent = self.PanelStageContent.transform:Find("Stage" .. i)
                local prefabName = CS.XGame.ClientConfig:GetString(uiName)
                local prefab = parent:LoadPrefab(prefabName)

                grid = XUiGridStagePracticeCharacter.New(prefab, handler(self, self.ClickStageGrid))
                grid.Parent = parent
                self.GridStageList[i] = grid
            end
            grid:UpdateStage(stageId, self.GroupId)
            grid.Parent.gameObject:SetActiveEx(true)
            
            self:SetLineActive(i, true)
        end
        --默认选中排序最小的未通关关卡
        if stageInfo.IsOpen and stageInfo.Unlock and not stageInfo.Passed and not XTool.IsNumberValid(self.LastOpenStage) then
            self.LastOpenStage = i
        end
    end

    local activeStageCount = #self.GridStageList
    for i = activeStageCount + 1, MAX_STAGE_COUNT do
        local parent = self.PanelStageContent.transform:Find("Stage" .. i)
        if parent then
            parent.gameObject:SetActiveEx(false)
        end

        self:SetLineActive(i, false)
    end
    local icon = self.GridStageList[activeStageCount].Parent.transform:Find("Icon")
    if icon then
        icon.gameObject:SetActiveEx(true)
    end
end

function XUiPanelPracticeMainline:FindItem(itemName, saveList)
    local i = 1
    local item = self.PanelStageContent:Find(string.format(itemName, i))
    while item do
        table.insert(saveList, item)
        i = i + 1
        item = self.PanelStageContent:Find(string.format(itemName, i))
    end
end

function XUiPanelPracticeMainline:SetLineActive(index, isActive)
    local line = self.LineItemList[index - 1]
    if line then
        line.gameObject:SetActiveEx(isActive)
    end
end

function XUiPanelPracticeMainline:Refresh()
    -- 章节名字
    self.TxtChapterName.text = XPracticeConfigs.GetPracticeGroupName(self.GroupId)

    -- 关卡进度
    local passNum, totalNum = XDataCenter.PracticeManager.GetChapterProgress(self.GroupId)
    self.TxtProgressNumber.text = string.format("%d/%d", passNum, totalNum)
    
    self:MoveToLastStage()
end

-- 滑动到最后一个关卡
function XUiPanelPracticeMainline:MoveToLastStage()
    if self.LastOpenStage then
        local grid = self.GridStageList[self.LastOpenStage]
        local gridTf = grid.Parent.gameObject:GetComponent("RectTransform")
        local diffX = gridTf.localPosition.x + self.PanelStageContent.localPosition.x
        
        local viewPortRectTransform = XUiHelper.TryGetComponent(self.PanelStageContent.parent,"","RectTransform")
        local left = viewPortRectTransform.offsetMin.x

        if diffX > CS.XResolutionManager.OriginWidth / 2 - left then
            local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridTf.localPosition.x - left
            local tarPos = self.PanelStageContent.localPosition
            tarPos.x = tarPosX

            XLuaUiManager.SetMask(true)
            self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted

            XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
                XLuaUiManager.SetMask(false)
                self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic

            end)
        end
    end
end

-- 选中一个 stage grid
function XUiPanelPracticeMainline:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid.StageId == grid.StageId then
        return
    end

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(grid.StageId)
    if not stageInfo.Unlock then
        XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(grid.StageId))
        return
    end
    
    -- 选中回调
    if self.ShowStageCb then
        self.ShowStageCb(grid.StageId)
    end

    -- 取消上一个选择
    if curGrid then
        curGrid:SetSelect(false)
    end
    
    -- 选中当前选择
    grid:SetSelect(true)

    -- 滚动容器自由移动
    self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    -- 面板移动
    self:PlayScrollViewMove(grid)

    self.CurStageGrid = grid
end

-- 返回滚动容器是否动画回弹
function XUiPanelPracticeMainline:CancelSelect()
    if not self.CurStageGrid then
        return false
    end

    self.CurStageGrid:SetSelect(false)
    self.CurStageGrid = nil

    if self.HideStageCb then
        self.HideStageCb()
    end
    
    self:EndScrollViewMove()
end

function XUiPanelPracticeMainline:PlayScrollViewMove(grid)
    -- 动画
    local gridTf = grid.Parent.gameObject:GetComponent("RectTransform")
    local diffX = gridTf.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTf.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

--- 结束关卡列表滑动
function XUiPanelPracticeMainline:EndScrollViewMove()
    self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

return XUiPanelPracticeMainline