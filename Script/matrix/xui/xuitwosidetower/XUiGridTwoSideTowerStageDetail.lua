---@class XUiGridTwoSideTowerStageDetail
local XUiGridTwoSideTowerStageDetail = XClass(nil, "XUiGridTwoSideTowerStageDetail")

---@param transform UnityEngine.RectTransform
---@param stageData XTwoSideTowerStage
function XUiGridTwoSideTowerStageDetail:Ctor(transform, stageData, pointData, chapterData, callback, selectCallback)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.StageData = stageData
    self.PointData = pointData
    self.ChapterData = chapterData
    self.CallBack = callback
    XTool.InitUiObject(self)
    self.BtnGo.CallBack = function() self:OnClickBtnFight() end
    self.BtnAutoFight.CallBack = function() self:OnClickBtnAutoFight() end
    self.BtnBuffClick.CallBack = function() self:OnClickBuff() end
    self.BtnStageDetail.CallBack = function()
        XUiManager.DialogTip(CS.XTextManager.GetText("TwoSideTowerStageDetailTitle"), self.StageData:GetDesc(), XUiManager.DialogType.NoBtn)
    end
    XUiHelper.RegisterClickEvent(self, self.RImgBg, selectCallback)
end

---@param stageData XTwoSideTowerStage
---@param pointData XTwoSideTowerPoint
---@param chapterData XTwoSideTowerChapter
function XUiGridTwoSideTowerStageDetail:Refresh(stageData, pointData, chapterData)
    self.StageData = stageData or self.StageData
    self.PointData = pointData or self.PointData
    self.ChapterData = chapterData or self.ChapterData
    local isFinishPoint = self.PointData:IsFinish(XTwoSideTowerConfigs.Direction.Positive)
    local isFinishStage = self.StageData:GetDirection() == XTwoSideTowerConfigs.Direction.Positive
    local isUnlockPoint = self.ChapterData:IsUnlockPoint(self.PointData)
    self.PanelCondition.gameObject:SetActiveEx(not isUnlockPoint and not isFinishPoint)
    self.BtnGo.gameObject:SetActiveEx(isUnlockPoint and (not isFinishStage))
    self.PanelDisable.gameObject:SetActiveEx(isFinishStage)
    self.BtnAutoFight.gameObject:SetActiveEx(isUnlockPoint and self.ChapterData:CheckIsCanSweep(self.StageData:GetStageId()))
    if isFinishPoint then
        self.BtnAutoFight.gameObject:SetActiveEx(false)
        self.BtnGo.gameObject:SetActiveEx(false)
        self.PanelCleared.gameObject:SetActiveEx(true)
    end
    self.RImgIcon:SetRawImage(self.StageData:GetBigMonsterIcon())
    self.TxtName.text = self.StageData:GetStageTypeName()
    self.TxtNumberName.text = self.StageData:GetStageNumberName()
    self.RImgWeakIcon:SetRawImage(self.StageData:GetWeakIcon())
    local featureCfg = XTwoSideTowerConfigs.GetFeatureCfg(self.StageData:GetFeatureId())
    self.RImgBuffIcon:SetRawImage(featureCfg.Icon)
    self.Effect.gameObject:SetActiveEx(featureCfg.Type == 2)
end

function XUiGridTwoSideTowerStageDetail:OnClickBtnAutoFight()
    XUiManager.DialogTip(CS.XTextManager.GetText("TwoSideTowerAutoFightTitle"), CS.XTextManager.GetText("TwoSideTowerAutoFightContent"), XUiManager.DialogType.Normal, nil, function()
        XDataCenter.TwoSideTowerManager.SweepPositiveStageRequest(self.StageData:GetStageId(), function()
            self:Refresh()
            local pointId = self.PointData:GetId()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_TWO_SIDE_TOWER_POINT_SWEEP, pointId)
            if self.CallBack then
                self.CallBack()
            end
        end)
    end)
end

function XUiGridTwoSideTowerStageDetail:OnClickBtnFight()
    local isSkipTips = XDataCenter.TwoSideTowerManager.GetDiglogHintCookie()
    if isSkipTips then
        self:OnEnterFight()
    else
        local title = XUiHelper.GetText("TwoSideTowerStageEnterTipsTitle")
        local content = XUiHelper.GetText("TwoSideTowerStageEnterTipsContent")
        local status = XDataCenter.TwoSideTowerManager.GetDiglogHintCookie()
        local hintInfo  = {
            SetHintCb = XDataCenter.TwoSideTowerManager.SetDiglogHintCookie,
            Status = status,
            HintText = XUiHelper.GetText("EnterNoTips"),
        }
        
        local sureCb = function()
            self:OnEnterFight()
        end
        XUiManager.DialogHintTip(title, content, "", nil, sureCb, hintInfo)
    end
end

function XUiGridTwoSideTowerStageDetail:OnEnterFight()
    if self.CallBack then
        self.CallBack()
    end

    local stageId = self.StageData:GetStageId()
    XDataCenter.TwoSideTowerManager.OpenUiBattleRoleRoom(stageId)
end

function XUiGridTwoSideTowerStageDetail:OnClickBuff()
    XLuaUiManager.Open("UiTwoSideTowerDetails", { self.StageData:GetFeatureId() })
end

function XUiGridTwoSideTowerStageDetail:RefreshSelect(isSelect)
    if self.IsSelect == isSelect or (self.IsSelect == nil and isSelect == false) then
        return
    end

    self.PanelSelect.gameObject:SetActiveEx(isSelect)
    self.PanelBtn.gameObject:SetActiveEx(isSelect)
    if isSelect then
        self.SelectEnable:PlayTimelineAnimation()
    else
        self.SelectDisable:PlayTimelineAnimation()
    end

    self.IsSelect = isSelect
end

return XUiGridTwoSideTowerStageDetail
