local XUiPartnerTeachingChapterContent = XClass(nil, "XUiPartnerTeachingChapterContent")

local XUiGridPartnerTeachingStage = require("XUi/XUiFubenPartnerTeaching/XUiGridPartnerTeachingStage")

function XUiPartnerTeachingChapterContent:Ctor(ui, chapterId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ChapterId = chapterId

    self.LastOpenStage = nil

    self.StageItemList = {}     -- 关卡数组
    self.LineItemList = {}      -- 关卡线数组

    self.StageClassList = {}    -- 关卡类实例数组
    self.StageIdList = XPartnerTeachingConfigs.GetChapterStageIds(chapterId)    -- 关卡Id数组

    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiPartnerTeachingChapterContent:InitComponent()
    -- 章节名称
    self.TxtChapterName.text = XPartnerTeachingConfigs.GetChapterName(self.ChapterId)

    -- 保存关卡与关卡线物体
    self:FindItem("Stage%d", self.StageItemList)
    self:FindItem("Line%d", self.LineItemList)

    -- 实例化关卡类
    local setLineCb = handler(self, self.SetLineActive)
    for i, stageItem in ipairs(self.StageItemList) do
        local stageClass = XUiGridPartnerTeachingStage.New(stageItem, i, setLineCb)
        self.StageClassList[i] = stageClass
    end

    self:LoadAllStages()
end

---
--- 设置第 'index' 条关卡线的显隐
function XUiPartnerTeachingChapterContent:SetLineActive(index, isActive)
    local line = self.LineItemList[index - 1]
    if line then
        line.gameObject:SetActiveEx(isActive)
    end
end

---
--- 寻找'PanelStageContent'下的 'itemName+index' 物体，并保存在'saveList'
function XUiPartnerTeachingChapterContent:FindItem(itemName, saveList)
    local i = 1
    local item = self.PanelStageContent:Find(string.format(itemName, i))
    while item do
        table.insert(saveList, item)
        i = i + 1
        item = self.PanelStageContent:Find(string.format(itemName, i))
    end
end

---
--- 关卡类根据 StageIdList 来加载对应的关卡预制
function XUiPartnerTeachingChapterContent:LoadAllStages()
    local stageClassNum = #self.StageClassList
    local stageIdNum = #self.StageIdList
    if stageIdNum > stageClassNum then
        XLog.Error(string.format("XUiPartnerTeachingChapterContent:LoadAllStages函数错误,PanelStageContent下的关卡数量少于%s个",
                stageIdNum))
    end

    -- 如果stageClassNum > stageIdNum，多余的stageClass会拿到空的stageId，然后隐藏关卡与线条
    for i, stageClass in ipairs(self.StageClassList) do
        stageClass:LoadStagePrefab(self.ChapterId, self.StageIdList[i])
    end
end

--------------------------------------------------------刷新-------------------------------------------------------------
function XUiPartnerTeachingChapterContent:Refresh()
    -- 通关进度
    local passNum, totalNum = XDataCenter.PartnerTeachingManager.GetChapterProgress(self.ChapterId)
    self.TxtProgressNumber.text = string.format("%d/%d", passNum, totalNum)

    for i, stageClass in ipairs(self.StageClassList) do
        local isOpen = stageClass:Refresh()
        if isOpen then
            self.LastOpenStage = i
        end
    end
    if self.PanelStageContentSizeFitter then
        self.PanelStageContentSizeFitter:SetLayoutHorizontal()
    end
    self:MoveToLastStage()
end

---
--- 滑动到最后一个关卡
function XUiPartnerTeachingChapterContent:MoveToLastStage()
    if self.LastOpenStage then
        local gridRect = self.StageItemList[self.LastOpenStage]
        local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x

        if diffX > CS.XResolutionManager.OriginWidth / 2 then
            local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x
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

-------------------------------------------------------选择关卡----------------------------------------------------------
---
--- 选择关卡
function XUiPartnerTeachingChapterContent:SelectStage(stageId)
    local index = self:FindStageIndex(stageId)
    self:SetStageSelect(index, true)
    self:PlayScrollViewMove(self.StageItemList[index])
end

---
--- 滑动关卡列表，使选择的关卡到达合适位置
function XUiPartnerTeachingChapterContent:PlayScrollViewMove(gridRect)
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x

    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX

        XLuaUiManager.SetMask(true)
        self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted

        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

---
--- 得到关卡 'stageId' 的索引
function XUiPartnerTeachingChapterContent:FindStageIndex(stageId)
    for _, stageClass in ipairs(self.StageClassList) do
        local classStageId = stageClass:GetStageId()
        if classStageId == stageId then
            return stageClass:GetIndex()
        end
    end
end

---
--- 取消选择关卡
function XUiPartnerTeachingChapterContent:CancelSelectStage()
    if self.SelectStageIndex then
        self:SetStageSelect(self.SelectStageIndex, false)
        self.SelectStageIndex = nil
    end
    self:EndScrollViewMove()
end

---
--- 结束关卡列表滑动
function XUiPartnerTeachingChapterContent:EndScrollViewMove()
    self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

---
--- 设置关卡的选择效果
function XUiPartnerTeachingChapterContent:SetStageSelect(index, isActive)
    if not self.StageClassList[index] then
        XLog.Error(string.format("XUiPartnerTeachingChapterContent:SetStageSelect函数错误，没有第%s个关卡的类实例", tostring(index)))
        return
    end
    self.StageClassList[index]:SetSelect(isActive)
    self.SelectStageIndex = index
end

return XUiPartnerTeachingChapterContent