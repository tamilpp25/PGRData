local XUiGridPartnerTeachingStage = XClass(nil, "XUiGridPartnerTeachingStage")

function XUiGridPartnerTeachingStage:Ctor(ui, index, setLineCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Index = index
    self.SetLineCb = setLineCb

    self.IsOpen = false
end

---
--- 加载关卡预制体
function XUiGridPartnerTeachingStage:LoadStagePrefab(chapterId, stageId)
    if chapterId and stageId then
        self.ChapterId = chapterId
        self.StageId = stageId
        local prefabName
        local stageType = XFubenConfigs.GetStageMainlineType(stageId)

        -- 选择对应StageType的关卡预制体
        if stageType == XFubenConfigs.STAGETYPE_FIGHT or stageType == XFubenConfigs.STAGETYPE_FIGHTEGG
                or stageType == XFubenConfigs.STAGETYPE_COMMON then
            prefabName = XPartnerTeachingConfigs.GetChapterFightStagePrefab(chapterId)
        elseif stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
            prefabName = XPartnerTeachingConfigs.GetChapterStoryStagePrefab(chapterId)
        else
            XLog.Error(string.format("XUiGridPartnerTeachingStage.Refresh函数错误，没有对应StageType的处理逻辑，关卡：%s，StageType：%s", stageId, stageType))
            return
        end
        self.StagePrefab = self.Transform:LoadPrefab(prefabName)

        -- 加载预制体的UiObject
        local uiObj = self.StagePrefab.transform:GetComponent("UiObject")
        for i = 0, uiObj.NameList.Count - 1 do
            self[uiObj.NameList[i]] = uiObj.ObjList[i]
        end
    else
        self.ChapterId = nil
        self.StageId = nil
    end
end

--------------------------------------------------------刷新-------------------------------------------------------------
function XUiGridPartnerTeachingStage:Refresh()
    if self.ChapterId and self.StageId then
        self.IsOpen = XDataCenter.FubenManager.CheckStageOpen(self.StageId)
        self.IsUnlock = XDataCenter.FubenManager.CheckStageIsUnlock(self.StageId)
        self.IsPassed = XDataCenter.FubenManager.CheckStageIsPass(self.StageId)
        self:RefreshStagePrefab()
    else
        self.IsOpen = false
        self.IsUnlock = false
    end

    -- 刷新关卡前的线条
    self.GameObject:SetActiveEx(self.IsOpen and self.IsUnlock)
    self.SetLineCb(self.Index, self.IsOpen and self.IsUnlock)

    return self.IsOpen and self.IsUnlock
end

---
--- 刷新关卡预制体
function XUiGridPartnerTeachingStage:RefreshStagePrefab()
    -- 编号名称
    if self.TxtStageOrder then
        self.TxtStageOrder.text = XDataCenter.PartnerTeachingManager.GetOrderName(self.ChapterId, self.StageId)
    end
    -- 图标
    if self.RImgBg then
        self.RImgBg:SetRawImage(XFubenConfigs.GetStageIcon(self.StageId))
    end
    -- 通关标志
    if self.PanelStagePass then
        self.PanelStagePass.gameObject:SetActiveEx(self.IsPassed)
    end
    -- 点击响应
    if self.BtnStage then
        self.BtnStage.CallBack = function()
            self:OnBtnStageClick()
        end
    end
end

-------------------------------------------------------选择关卡----------------------------------------------------------
function XUiGridPartnerTeachingStage:OnBtnStageClick()
    if self.IsOpen and self.IsUnlock then
        XEventManager.DispatchEvent(XEventId.EVENT_PARTNER_TEACHING_OPEN_STAGE_DETAIL, self.StageId)
    else
        XUiManager.TipMsg(CSXTextManagerGetText("FubenNotUnlock"))
    end
end

---
--- 是否显示选中框
function XUiGridPartnerTeachingStage:SetSelect(isSelect)
    self.ImageSelected.gameObject:SetActiveEx(isSelect)
end
------------------------------------------------------------------------------------------------------------------------


function XUiGridPartnerTeachingStage:GetIndex()
    return self.Index
end

function XUiGridPartnerTeachingStage:GetStageId()
    return self.StageId
end

return XUiGridPartnerTeachingStage