local XUiLivWarmActivityPopGrid = XClass(nil, "XUiLivWarmActivityPopGrid")

--头像格子
function XUiLivWarmActivityPopGrid:Ctor(ui, row, colIndex, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ClickCallBack = clickCb
    self.Row = row
    self.ColIndex = colIndex

    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBlank, self.OnBtnClick)
end

function XUiLivWarmActivityPopGrid:Dispose()
    CS.UnityEngine.Object.Destroy(self.GameObject)
end

function XUiLivWarmActivityPopGrid:SetHeadType(headType, stageId)
    self.HeadType = headType
    self.Effect.gameObject:SetActiveEx(false)

    if headType == XLivWarmActivityConfigs.HeadType.Blank then
        self.NorNumber.gameObject:SetActiveEx(false)
        self.BtnClick.gameObject:SetActiveEx(false)
        return
    end

    if headType == XLivWarmActivityConfigs.HeadType.NotClict then
        self.NorNumber.gameObject:SetActiveEx(true)
        self.BtnClick.gameObject:SetActiveEx(false)
        return
    end

    local headPath = XLivWarmActivityConfigs.GetLivWarmActivityStageClientRoleHead(stageId, headType)
    self.BtnClick:SetSprite(headPath)
    self.BtnClick.gameObject:SetActiveEx(true)
    self.BtnCanvasGroup.alpha = 1
    self.NorNumber.gameObject:SetActiveEx(false)
end

function XUiLivWarmActivityPopGrid:PlayClearAnima(finishCb)
    self.Effect.gameObject:SetActiveEx(true)
    self.DisableTimeline.gameObject:SetActiveEx(true)
    self.DisableTimeline:PlayTimelineAnimation(function()
        self.Effect.gameObject:SetActiveEx(false)
        self.DisableTimeline.gameObject:SetActiveEx(false)
        finishCb()
    end)
end

function XUiLivWarmActivityPopGrid:GetHeadType()
    return self.HeadType
end

function XUiLivWarmActivityPopGrid:GetRow()
    return self.Row
end

function XUiLivWarmActivityPopGrid:GetColIndex()
    return self.ColIndex
end

function XUiLivWarmActivityPopGrid:OnBtnClick()
    if self.HeadType == XLivWarmActivityConfigs.HeadType.NotClict then
        return
    end

    if self.ClickCallBack then
        self.ClickCallBack(self)
    end
end

function XUiLivWarmActivityPopGrid:ClickButton()
    self.BtnClick:SetButtonState(CS.UiButtonState.Select)
end

function XUiLivWarmActivityPopGrid:CanelSelectButton()
    self.BtnClick:SetButtonState(CS.UiButtonState.Normal)
end

function XUiLivWarmActivityPopGrid:GetBtnClickTransform()
    return self.BtnClick.transform
end

--已通关处理
function XUiLivWarmActivityPopGrid:Win()
    self.NorNumber.gameObject:SetActiveEx(false)
    self.BtnClick.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(false)
    self.DisableTimeline.gameObject:SetActiveEx(false)
end

function XUiLivWarmActivityPopGrid:Reset()
    if XTool.UObjIsNil(self.BtnClick) then
        return
    end
    self.BtnClick.transform.localPosition = CS.UnityEngine.Vector3.zero
    self:CanelSelectButton()
end

return XUiLivWarmActivityPopGrid