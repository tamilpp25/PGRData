local XUiGridExpeditionChapter = XClass(nil, "XUiGridExpeditionChapter")
local XUiGridExpeditionStage = require("XUi/XUiExpedition/Chapter/XUiGridExpeditionStage")
local MAX_STAGE_COUNT = CS.XGame.ClientConfig:GetInt("ExpeditionStageMaxCount")
local FocusTime = 0.5
local ScaleLevel = {}

function XUiGridExpeditionChapter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridStageList = {}

    ScaleLevel = {
        Small = self.PanelDrag.MinScale,
        Big = self.PanelDrag.MaxScale,
        Normal = (self.PanelDrag.MinScale + self.PanelDrag.MaxScale) / 2,
    }
end

function XUiGridExpeditionChapter:Refresh(data)
    self.HideStageCb = data.HideStageCb
    self.ShowStageCb = data.ShowStageCb
    self:SetStageList()
end

function XUiGridExpeditionChapter:SetStageList()
    local eActivity = XDataCenter.ExpeditionManager.GetEActivity()
    local stageList = eActivity:GetEStages()
    
    self.CanPlayList = {}

    for i = 1, #stageList do
        local eStage = stageList[i]
        local isShow = eStage:GetStageIsShow()
        if isShow then
            local grid = self.GridStageList[i]
            if not grid then
                local prefabName = eStage:GetStagePrefab()

                local parent = self.PanelStageContent.transform:Find("Stage" .. i)
                local prefab = parent:LoadPrefab(prefabName)

                grid = XUiGridExpeditionStage.New(prefab, self.RootUi, handler(self, self.ClickStageGrid))
                grid.Parent = parent
                self.GridStageList[i] = grid
            end
            grid:Refresh(eStage:GetStageId())
            if not XTool.UObjIsNil(grid.Parent.gameObject) then
                grid.Parent.gameObject:SetActiveEx(true)
            end
            -- 刷新线
            self:UpdateStageLine(grid.Parent, eStage)
        end

        local passed = eStage:GetIsPass()
        if isShow and not passed then
            table.insert(self.CanPlayList, i)
        end
    end

    for i = 1, MAX_STAGE_COUNT do
        if not self.GridStageList[i] then
            local parent = self.PanelStageContent.transform:Find(string.format("Stage%d", i))
            if parent then
                parent.gameObject:SetActiveEx(false)
            end
        end
    end
    
    if self.MoveArea then
        self.MoveArea:UpdateAreaSize(false)
    end
end

function XUiGridExpeditionChapter:UpdateStageLine(parent, eStage)
    local lineAfter = XUiHelper.TryGetComponent(parent.transform,"LineAfter")
    local passed = eStage:GetIsPass()
    if lineAfter then
        lineAfter.gameObject:SetActiveEx(passed)
    end
end

function XUiGridExpeditionChapter:Show()
    if self.GameObject.activeSelf == true then
        return
    end
    self.GameObject:SetActiveEx(true)
end

function XUiGridExpeditionChapter:Hide()
    if not self.GameObject:Exist() or self.GameObject.activeSelf == false then
        return
    end
    self.GameObject:SetActiveEx(false)
end

-- 选中一个 stage grid
function XUiGridExpeditionChapter:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid.StageId == grid.StageId then
        return
    end

    -- 取消上一个选择
    if curGrid then
        curGrid:SetStageSelect(false)
    end

    -- 选中当前选择
    grid:SetStageSelect(true)

    self.CurStageGrid = grid
    
    -- 选中回调
    if self.ShowStageCb then
        self.ShowStageCb(grid.StageId)
    end
    self.Mask.gameObject:SetActiveEx(true)
    self.PanelDrag:FocusTarget(grid.Transform, ScaleLevel.Big, FocusTime, CS.UnityEngine.Vector3.zero, function()
        self.Mask.gameObject:SetActiveEx(false)
    end)

end

-- 返回滚动容器是否动画回弹
function XUiGridExpeditionChapter:CancelSelect()
    if not self.CurStageGrid then
        return false
    end

    self.CurStageGrid:SetStageSelect(false)
    self.CurStageGrid = nil

    if self.HideStageCb then
        self.HideStageCb()
    end
end

--=================
--滚动到最后的关卡
--=================
function XUiGridExpeditionChapter:GoToNearestStage(lastStageIndex)
    if #self.CanPlayList > 0 then
        local firstCanPlayId = self.CanPlayList[1]
        local firstGridStage = self.GridStageList[firstCanPlayId]
        if not firstGridStage then
            XLog.Error("ExploreGroup's setting is Error by stageIndex:" .. firstCanPlayId)
            return
        end

        local nearestTransform = firstGridStage.Transform
        local minDis = CS.UnityEngine.Vector3.Distance(nearestTransform.position, self.PanelDrag.gameObject.transform.position)
        for i = 2, #self.CanPlayList do
            local canPlayId = self.CanPlayList[i]
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
    elseif lastStageIndex and lastStageIndex > 0 then
        local gridStage = self.GridStageList[lastStageIndex]
        local nearestTransform = gridStage.Transform
        self.PanelDrag:FocusTarget(nearestTransform, ScaleLevel.Normal, FocusTime, CS.UnityEngine.Vector3.zero)
    end
end

function XUiGridExpeditionChapter:OnDisable()
    for _, grid in pairs(self.GridStageList) do
        grid:OnDisable()
    end
end

return XUiGridExpeditionChapter