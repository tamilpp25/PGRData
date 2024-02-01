local XUiGridFashionStoryStage = XClass(nil, "XUiGridFashionStoryStage")

function XUiGridFashionStoryStage:Ctor(ui, index, setLineCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Index = index
    self.SetLineCb = setLineCb
    self.IsOpen = false
end

---
--- 加载关卡预制体
function XUiGridFashionStoryStage:LoadStagePrefab(activityId, stageId,singleLineId)
    if activityId and stageId and singleLineId then
        self.ActivityId = activityId
        self.StageId = stageId
        self.SingleLineId=singleLineId
        local prefabName
        local stageType = XFubenConfigs.GetStageMainlineType(stageId)

        -- 选择对应StageType的关卡预制体
        if stageType == XFubenConfigs.STAGETYPE_FIGHT or stageType == XFubenConfigs.STAGETYPE_FIGHTEGG
                or stageType == XFubenConfigs.STAGETYPE_COMMON then
            prefabName = XFashionStoryConfigs.GetChapterFightStagePrefab(singleLineId)
        elseif stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
            prefabName = XFashionStoryConfigs.GetChapterStoryStagePrefab(singleLineId)
        else
            XLog.Error(string.format("XUiGridFashionStoryStage.LoadStagePrefab函数错误，没有对应StageType的处理逻辑，关卡：%s，StageType：%s", stageId, stageType))
            return
        end
        self.StagePrefab = self.Transform:LoadPrefab(prefabName)

        -- 加载关卡预制体的UiObject
        local uiObj = self.StagePrefab.transform:GetComponent("UiObject")
        for i = 0, uiObj.NameList.Count - 1 do
            self[uiObj.NameList[i]] = uiObj.ObjList[i]
        end
        -- 卡关图标
        if self.RImgBg then
            self.RImgBg:SetRawImage(XFubenConfigs.GetStageIcon(self.StageId))
        end
        -- 注册关卡点击响应函数
        if self.BtnStage then
            self.BtnStage.CallBack = function()
                self:OnBtnStageClick()
            end
        end
    else
        self.ActivityId = nil
        self.StageId = nil
    end
end


--------------------------------------------------------刷新-------------------------------------------------------------

function XUiGridFashionStoryStage:Refresh()
    if self.ActivityId and self.StageId then
        self.IsOpen = XDataCenter.FubenManager.CheckStageOpen(self.StageId)
        self.IsUnlock = XDataCenter.FubenManager.CheckStageIsUnlock(self.StageId)
        self.IsPassed = XDataCenter.FubenManager.CheckStageIsPass(self.StageId)

        -- 通关标志
        if self.PanelStagePass then
            self.PanelStagePass.gameObject:SetActiveEx(self.IsPassed)
        end
    else
        self.IsOpen = false
        self.IsUnlock = false
    end

    -- 设置关卡与关卡线条的显隐
    self.GameObject:SetActiveEx(self.IsOpen and self.IsUnlock)
    self.SetLineCb(self.Index, self.IsOpen and self.IsUnlock)
end


-------------------------------------------------------选择关卡----------------------------------------------------------

function XUiGridFashionStoryStage:OnBtnStageClick()
    if self.IsOpen and self.IsUnlock then
        XEventManager.DispatchEvent(XEventId.EVENT_FASHION_STORY_OPEN_STAGE_DETAIL, self.StageId)
    else
        XUiManager.TipMsg(CSXTextManagerGetText("FubenNotUnlock"))
    end
end

---
--- 是否显示选中框
function XUiGridFashionStoryStage:SetSelect(isSelect)
    self.ImageSelected.gameObject:SetActiveEx(isSelect)
end
------------------------------------------------------------------------------------------------------------------------

---
--- 获取关卡索引
function XUiGridFashionStoryStage:GetIndex()
    return self.Index
end

---
--- 获取关卡Id
function XUiGridFashionStoryStage:GetStageId()
    return self.StageId
end

---
--- 关卡是否开放
function XUiGridFashionStoryStage:GetIsOpen()
    return self.IsOpen and self.IsUnlock
end

return XUiGridFashionStoryStage