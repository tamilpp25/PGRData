local XUiGridMemorySave = require("XUi/XUiMemorySave/XUiGridMemorySave")
local XUiMemorySaveStageLine = XClass(nil, "XUiMemorySaveStageLine")

-- 滑动列表滑动类型
local MovementType = {
    Elastic         = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic,
    Unrestricted    = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted,
    Clamped         = CS.UnityEngine.UI.ScrollRect.MovementType.Clamped,
}

function XUiMemorySaveStageLine:Ctor(ui, data)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    if data then
        self.HideDetailCb = data.HideDetailCB
        self.ShowDetailCb = data.ShowDetailCB
    end
end

function XUiMemorySaveStageLine:Refresh(chapterId)
    self.ChapterId = chapterId
    local prefabPath = XMemorySaveConfig.GetStageLinePrefab(chapterId)
    local stageLineObj = self.Transform:LoadPrefab(prefabPath)
    -- 不使用XTool.InitUiObjectByUi
    local uiObject = stageLineObj.transform:GetComponent("UiObject")
    for i = 0, uiObject.NameList.Count - 1 do
        self[uiObject.NameList[i]] = uiObject.ObjList[i]
    end

    -- 重设滑动类型
    self:SetPanelStageListMovementType(MovementType.Elastic)

    self.StageList = XDataCenter.MemorySaveManager.GetChapterStageIds(chapterId)

    -- 刷新关卡显示
    self:RefreshStage(chapterId)
    -- 恢复上次滑动位置
    self:ScrollLastPos(chapterId)
    -- 更新滑动框宽度
    self.PanelStageContentSizeFitter:SetLayoutHorizontal()
end

-- 记录上次滑动的位置，每次从关闭到开启界面时恢复到上次滑动的位置
function XUiMemorySaveStageLine:ScrollLastPos(chapterId)
    local posX =  XDataCenter.MemorySaveManager.GetScrollViewPos(chapterId)
    if posX then
        --[[ 缓动动画
        local targetPos = self.PanelStageContent.localPosition
        targetPos.x = posX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, targetPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function ()
            XLuaUiManager.SetMask(false)
        end)
        ]]--

        local rt = self.PanelStageContent:GetComponent("RectTransform")
        rt:DOAnchorPosX(posX, 0)
    end
end

-- 刷新关卡界面显示
function XUiMemorySaveStageLine:RefreshStage(chapterId)
    self.ItemStages = {}
    for idx, stageId in ipairs(self.StageList) do
        local stage = self.PanelStageContent:Find("Stage"..idx)
        local line = self.PanelStageContent:Find("Line"..idx)
        if stage then
            local itemStage = XUiGridMemorySave.New(stage, stageId, chapterId)
            local data = {
                stageIndex = idx,
                HideDetailCb        = self.HideDetailCb,
                ShowDetailCb        = self.ShowDetailCb,
                ScrollViewMoveCb    = handler(self, self.PlayScrollViewMove),
                UpDateSelectStageCb = handler(self, self.OnUpdateSelectStage),
            }
            itemStage:Refresh(data)
            self.ItemStages[idx] = itemStage
        end
        if line then
            local nextStageId = self.StageList and self.StageList[idx + 1] or nil
            if nextStageId then
                local isOpen = XDataCenter.MemorySaveManager.GetStageIsOpen(nextStageId)
                line.gameObject:SetActiveEx(isOpen)
            else
                line.gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 更新选择框
function XUiMemorySaveStageLine:OnUpdateSelectStage(stageId)
    for idx, selectStageId in ipairs(self.StageList) do
        if self.ItemStages[idx] then
            self.ItemStages[idx]:SetSelected(selectStageId == stageId)
        end
    end
end

-- 缓动动画
function XUiMemorySaveStageLine:PlayScrollViewMove(girdTransform)
    self:SetPanelStageListMovementType(MovementType.Unrestricted)
    local gridRect = girdTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local targetPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
        local targetPos = self.PanelStageContent.localPosition
        targetPos.x = targetPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, targetPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function ()
            XLuaUiManager.SetMask(false)
        end)
    end
end

-- 记录滑动框位置
function XUiMemorySaveStageLine:UpdateScrollPos()
    if not self.PanelStageContent then return end
    local posX = self.PanelStageContent.localPosition.x
    XDataCenter.MemorySaveManager.UpdateScrollViewPos(self.ChapterId, posX)
end

function XUiMemorySaveStageLine:SetPanelStageListMovementType(movementType)
    movementType = movementType or MovementType.Elastic
    if self.PaneStageList then
        self.PaneStageList.movementType = movementType
    end
end

return XUiMemorySaveStageLine