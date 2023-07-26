-- gacha3D剧情关界面(用的 festivalActivity 表)
local XUiEpicFashionGachaStageLine = XLuaUiManager.Register(XLuaUi, "UiEpicFashionGachaStageLine")
local XStageItem = require("XUi/XUiEpicFashionGacha/Grid/XStageItem")
local GachaStoryRedPoint = "GachaStoryRedPoint"

function XUiEpicFashionGachaStageLine:OnAwake()
    self.LastOpenStage = nil
    self.StageGroup = {}
    self:InitButton()
end

function XUiEpicFashionGachaStageLine:InitButton()
    self:RegisterClickEvent(self.SceneBtnBack, self.OnSceneBtnBackClick)
    self:RegisterClickEvent(self.SceneBtnMainUi, function() XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnSet, function () XLuaUiManager.Open("UiSet") end)
    self:RegisterClickEvent(self.BtnGacha, self.OnGotoGacha)
end

---@param chapterId 对应festivalActivity表的Id
---@param isAutoOpen 是否是强制打开的
function XUiEpicFashionGachaStageLine:OnStart(chapterId, panel3D, isAutoOpen)
    self.ChapterId = chapterId
    self.ChapterTemplate = XFestivalActivityConfig.GetFestivalById(self.ChapterId)
    self.Panel3D = panel3D
    self.IsAutoOpen = isAutoOpen
end

function XUiEpicFashionGachaStageLine:OnEnable()
    self:Refresh3DSceneInfo()
    self:SetUiData()
    self:MoveIntoStage(self.LastOpenStage or 1) -- 自动定位

    local updateTime = XTime.GetSeverTomorrowFreshTime()
    XSaveTool.SaveData(GachaStoryRedPoint, updateTime)
end

function XUiEpicFashionGachaStageLine:Refresh3DSceneInfo()
    if not self.Panel3D or XTool.UObjIsNil(self.Panel3D.GameObject) then
        self.ParentUi:Init3DSceneInfo()
        self.Panel3D = self.ParentUi.Panel3D
    end
    self.Panel3D.UiModelParent.gameObject:SetActiveEx(false)
    self.Panel3D.UiModelParentStory.gameObject:SetActiveEx(true)
    self.Panel3D.Model1.gameObject:SetActiveEx(true)

    -- 在开启前再重新关闭一遍刷新状态,避免父节点直接关闭的情况
    self.Panel3D.UiFarCameraStory.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCameraStory.gameObject:SetActiveEx(false)
    -- 打开剧情摄像机 关闭其他
    self.Panel3D.UiFarCameraMain.gameObject:SetActiveEx(false)
    self.Panel3D.UiFarCameraClock.gameObject:SetActiveEx(false)
    self.Panel3D.UiFarCameraDeep.gameObject:SetActiveEx(false)
    self.Panel3D.UiFarCameraStory.gameObject:SetActiveEx(true)
    
    self.Panel3D.UiNearCameraMain.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCameraClock.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCameraDeep.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCameraStory.gameObject:SetActiveEx(true)
end

function XUiEpicFashionGachaStageLine:SetUiData()
    -- 初始化prefab组件
    local chapterGameObject = self.PanelChapter:LoadPrefab(self.ChapterTemplate.FubenPrefab)
    local uiObj = chapterGameObject.transform:GetComponent("UiObject")
    for i = 0, uiObj.NameList.Count - 1 do
        self[uiObj.NameList[i]] = uiObj.ObjList[i]
    end
    self.StageIds = self.ChapterTemplate.StageId
    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- 界面信息
    self:SwitchFestivalBg(self.ChapterTemplate)
    -- 加载特效
    self:LoadEffect(self.ChapterTemplate.EffectUrl)
    self.TxtChapterName.text = self.ChapterTemplate.Name
    self.TxtChapter.text = (self.ChapterId >= 10) and self.ChapterId or string.format("0%d", self.ChapterId)
    local itemId = XDataCenter.ItemManager.ItemId
    if self.PanelAsset then
        if not self.AssetPanel then
            self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, itemId.FreeGem, itemId.ActionPoint, itemId.Coin)
        end
    end
end

function XUiEpicFashionGachaStageLine:HandleStages()
    self.Stages = {}
    for i = 1, #self.StageIds do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiEpicFashionGachaStageLine:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        itemStage.gameObject:SetActiveEx(true)
        self.StageGroup[i] = itemStage
        self.Stages[i] = XStageItem.New(self, itemStage)
        self.Stages[i]:UpdateNode(self.ChapterTemplate.Id, self.StageIds[i])
    end
    self:UpdateNodeLines()
    -- 隐藏多余组件
    local indexStage = #self.StageIds + 1
    local extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    while extraStage do
        extraStage.gameObject:SetActiveEx(false)
        indexStage = indexStage + 1
        extraStage = self.PanelStageContent:Find(string.format("Stage%d", indexStage))
    end
end

function XUiEpicFashionGachaStageLine:HandleStageLines()
    self.FestivalStageLine = {}
    for i = 1, #self.StageIds - 1 do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        if not itemLine then
            XLog.Error("XUiEpicFashionGachaStageLine:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            return
        end
        itemLine.gameObject:SetActiveEx(false)
        self.FestivalStageLine[i] = itemLine
    end

    -- 隐藏多余组件
    local indexLine = #self.FestivalStageLine
    local extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    while extraLine do
        extraLine.gameObject:SetActiveEx(false)
        indexLine = indexLine + 1
        extraLine = self.PanelStageContent:Find(string.format("Line%d", indexLine))
    end
end

-- 背景
function XUiEpicFashionGachaStageLine:SwitchFestivalBg()
    -- if not self.ChapterTemplate or not self.ChapterTemplate.MainBackgound then
    --     self.RImgFestivalBg.gameObject:SetActiveEx(false)
    --     return
    -- end
    self.RImgFestivalBg.gameObject:SetActiveEx(false)
end

-- 加载特效
function XUiEpicFashionGachaStageLine:LoadEffect(effectUrl)
    if not effectUrl or effectUrl == "" then
        self.PanelEffect.gameObject:SetActiveEx(false)
        return
    end

    self.PanelEffect.gameObject:LoadUiEffect(effectUrl)
    self.PanelEffect.gameObject:SetActiveEx(true)
end

-- 更新刷新
function XUiEpicFashionGachaStageLine:RefreshFestivalNodes()
    if not self.ChapterTemplate or not self.StageIds then return end
    for i = 1, #self.StageIds do
        self.Stages[i]:UpdateNode(self.ChapterTemplate.Id, self.StageIds[i])
    end
    self:UpdateNodeLines()
    -- 移动至ListView正确的位置
    if self.PanelStageContentSizeFitter then
        self.PanelStageContentSizeFitter:SetLayoutHorizontal()
    end
end

-- 更新节点线条
function XUiEpicFashionGachaStageLine:UpdateNodeLines()
    if not self.ChapterTemplate or not self.StageIds then return end
    local stageLength = #self.StageIds
    for i = 2, stageLength do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageIds[i])
        local isOpen = stageInfo.IsOpen
        self:SetStageLineActive(i - 1, isOpen)
        if isOpen then
            self.LastOpenStage = i
        end
    end
    self:SetStageLineActive(stageLength, false)
end

function XUiEpicFashionGachaStageLine:SetStageLineActive(index, isActive)
    if self.FestivalStageLine[index] then
        self.FestivalStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

-- 通过Stage调用的接口
function XUiEpicFashionGachaStageLine:OpenStageDetails(stageId)
    XLuaUiManager.Open("UiEpicFashionGachaStageDetail", stageId)
end

-- 选中关卡描边效果
function XUiEpicFashionGachaStageLine:UpdateNodesSelect(stageId)
    local stageIds = self.StageIds
    for i = 1, #stageIds do
        if self.Stages[i] then
            self.Stages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiEpicFashionGachaStageLine:ClearNodesSelect()
    for i = 1, #self.FestivalStageIds do
        if self.FestivalStages[i] then
            self.FestivalStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end
-- 通过Stage调用的接口结束

function XUiEpicFashionGachaStageLine:SetPanelStageListMovementType(moveMentType)
    if not self.PanelStageList then return end
    self.PanelStageList.movementType = moveMentType
end

function XUiEpicFashionGachaStageLine:MoveIntoStage(stageIndex)
    local gridRect = self.StageGroup[stageIndex]
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

function XUiEpicFashionGachaStageLine:OnSceneBtnBackClick()
    self:Close()
    self.ParentUi:Close()
end

function XUiEpicFashionGachaStageLine:OnGotoGacha()
    self:Close()
    self.ParentUi:OnChildClose()
end