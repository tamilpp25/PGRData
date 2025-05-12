local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiGachaLamiyaStageLine : XLuaUi 剧情关界面(用的 festivalActivity 表)
---@field ParentUi XUiGachaLamiyaMain
local XUiGachaLamiyaStageLine = XLuaUiManager.Register(XLuaUi, "UiGachaLamiyaStageLine")

function XUiGachaLamiyaStageLine:OnAwake()
    self._LastOpenStage = nil
    self._StageGroup = {}
    ---@type XUiGridGachaStageItem[]
    self._Stages = {}
    self:InitButton()
end

---@param chapterId number 对应festivalActivity表的Id
---@param isAutoOpen  boolean 是否是强制打开的
function XUiGachaLamiyaStageLine:OnStart(chapterId, panel3D, isAutoOpen)
    self._ChapterId = chapterId
    self._ChapterTemplate = XFestivalActivityConfig.GetFestivalById(self._ChapterId)
    self._Panel3D = panel3D
    self._IsAutoOpen = isAutoOpen
end

function XUiGachaLamiyaStageLine:OnEnable()
    self:Refresh3DSceneInfo()
    self:SetUiData()
    self:MoveIntoStage(self._LastOpenStage or 1) -- 自动定位

    local updateTime = XTime.GetSeverTomorrowFreshTime()
    XSaveTool.SaveData("GachaStoryRedPoint", updateTime)

    local timeId = self.ParentUi._GachaCfg.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if not isClose then
            local time = XFunctionManager.GetEndTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
            self.TxtDay.text = XUiHelper.GetText("GachaLamiyaTime", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
        end
    end, nil, 0)
end

function XUiGachaLamiyaStageLine:OnDisable()
    for _, stage in pairs(self._Stages) do
        stage:Close()
    end
end

function XUiGachaLamiyaStageLine:Refresh3DSceneInfo()
    --if not self._Panel3D or XTool.UObjIsNil(self._Panel3D.GameObject) then
    --    self.ParentUi:Init3DSceneInfo()
    --    self._Panel3D = self.ParentUi.Panel3D
    --end
    --self._Panel3D.UiModelParent.gameObject:SetActiveEx(false)
    --self._Panel3D.UiModelParentStory.gameObject:SetActiveEx(true)
    --self._Panel3D.Model1.gameObject:SetActiveEx(true)
    --
    ---- 在开启前再重新关闭一遍刷新状态,避免父节点直接关闭的情况
    --self._Panel3D.UiFarCameraStory.gameObject:SetActiveEx(false)
    --self._Panel3D.UiNearCameraStory.gameObject:SetActiveEx(false)
    ---- 打开剧情摄像机 关闭其他
    --self._Panel3D.UiFarCameraMain.gameObject:SetActiveEx(false)
    --self._Panel3D.UiFarCameraClock.gameObject:SetActiveEx(false)
    --self._Panel3D.UiFarCameraDeep.gameObject:SetActiveEx(false)
    --self._Panel3D.UiFarCameraStory.gameObject:SetActiveEx(true)
    --
    --self._Panel3D.UiNearCameraMain.gameObject:SetActiveEx(false)
    --self._Panel3D.UiNearCameraClock.gameObject:SetActiveEx(false)
    --self._Panel3D.UiNearCameraDeep.gameObject:SetActiveEx(false)
    --self._Panel3D.UiNearCameraStory.gameObject:SetActiveEx(true)
end

function XUiGachaLamiyaStageLine:InitButton()
    self:RegisterClickEvent(self.SceneBtnBack, self.OnSceneBtnBackClick)
    self:RegisterClickEvent(self.SceneBtnMainUi, function()
        XLuaUiManager.RunMain()
    end)
    self:RegisterClickEvent(self.BtnSet, function()
        XLuaUiManager.Open("UiSet")
    end)
    self:RegisterClickEvent(self.BtnGacha, self.OnGotoGacha)
end

function XUiGachaLamiyaStageLine:SetUiData()
    -- 初始化prefab组件
    local chapterGameObject = self.PanelChapter:LoadPrefab(self._ChapterTemplate.FubenPrefab)
    local uiObj = chapterGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self._StageIds = self._ChapterTemplate.StageId
    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- 界面信息
    self:SwitchFestivalBg(self._ChapterTemplate)
    -- 加载特效
    self:LoadEffect(self._ChapterTemplate.EffectUrl)
    self.TxtChapterName.text = self._ChapterTemplate.Name
    self.TxtChapter.text = (self._ChapterId >= 10) and self._ChapterId or string.format("0%d", self._ChapterId)
    local itemId = XDataCenter.ItemManager.ItemId
    if self.PanelAsset then
        if not self.AssetPanel then
            self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, itemId.FreeGem, itemId.ActionPoint, itemId.Coin)
        end
    end
end

function XUiGachaLamiyaStageLine:HandleStages()
    for i = 1, #self._StageIds do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiGachaLamiyaStageLine:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        self._StageGroup[i] = itemStage
        if not self._Stages[i] then
            self._Stages[i] = require("XUi/XUiGachaLamiya/Grid/XUiGridGachaStageItem").New(itemStage, self)
        end
        self._Stages[i]:Open()
        self._Stages[i]:UpdateNode(i, self._ChapterTemplate.Id, self._StageIds[i])
    end
    self:UpdateNodeLines()
    -- 隐藏多余组件
    local indexStage = #self._StageIds + 1
    local extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    while extraStage do
        extraStage.gameObject:SetActiveEx(false)
        indexStage = indexStage + 1
        extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    end
end

function XUiGachaLamiyaStageLine:HandleStageLines()
    self._FestivalStageLine = {}
    for i = 1, #self._StageIds - 1 do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiGachaLamiyaStageLine:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            return
        end
        itemLine.gameObject:SetActiveEx(false)
        self._FestivalStageLine[i] = itemLine
    end

    -- 隐藏多余组件
    local indexLine = #self._FestivalStageLine
    local extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    while extraLine do
        extraLine.gameObject:SetActiveEx(false)
        indexLine = indexLine + 1
        extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    end
end

-- 背景
function XUiGachaLamiyaStageLine:SwitchFestivalBg()
    self.RImgFestivalBg.gameObject:SetActiveEx(false)
end

-- 加载特效
function XUiGachaLamiyaStageLine:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

-- 更新刷新
function XUiGachaLamiyaStageLine:RefreshFestivalNodes()
    if not self._ChapterTemplate or not self._StageIds then
        return
    end
    for i = 1, #self._StageIds do
        self._Stages[i]:UpdateNode(i, self._ChapterTemplate.Id, self._StageIds[i])
    end
    self:UpdateNodeLines()
    -- 移动至ListView正确的位置
    if self.PanelStageContentSizeFitter then
        self.PanelStageContentSizeFitter:SetLayoutHorizontal()
    end
end

-- 更新节点线条
function XUiGachaLamiyaStageLine:UpdateNodeLines()
    if not self._ChapterTemplate or not self._StageIds then
        return
    end
    local stageLength = #self._StageIds
    for i = 2, stageLength do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self._StageIds[i])
        local isOpen = stageInfo.IsOpen
        self:SetStageLineActive(i - 1, isOpen)
        if isOpen then
            self._LastOpenStage = i
        end
    end
    self:SetStageLineActive(stageLength, false)
end

function XUiGachaLamiyaStageLine:SetStageLineActive(index, isActive)
    if self._FestivalStageLine[index] then
        self._FestivalStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

-- 通过Stage调用的接口
function XUiGachaLamiyaStageLine:OpenStageDetails(stageId)
    XLuaUiManager.Open("UiGachaLamiyaStageDetail", stageId)
end

-- 选中关卡描边效果
function XUiGachaLamiyaStageLine:UpdateNodesSelect(stageId)
    local stageIds = self._StageIds
    for i = 1, #stageIds do
        if self._Stages[i] then
            self._Stages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiGachaLamiyaStageLine:ClearNodesSelect()
    for i = 1, #self.FestivalStageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end
-- 通过Stage调用的接口结束

function XUiGachaLamiyaStageLine:SetPanelStageListMovementType(moveMentType)
    if not self.PanelStageList then
        return
    end
    self.PanelStageList.movementType = moveMentType
end

function XUiGachaLamiyaStageLine:MoveIntoStage(stageIndex)
    local gridRect = self._StageGroup[stageIndex]
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    local left = 100

    if diffX > CS.XResolutionManager.OriginWidth / 2 - left then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x - left
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
            self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        end)
    end
end

function XUiGachaLamiyaStageLine:OnSceneBtnBackClick()
    self:Close()
    self.ParentUi:Close()
end

function XUiGachaLamiyaStageLine:OnGotoGacha()
    self:Close()
    self.ParentUi:OnChildClose()
end

return XUiGachaLamiyaStageLine