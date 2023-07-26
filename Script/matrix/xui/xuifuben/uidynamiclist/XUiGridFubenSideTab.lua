local XUiGridFubenSideTab = XClass(nil, "XUiGridFubenSideTab")

local BtnState = 
{
    Disable = "Disable",
    Normal = "Normal"
}

function XUiGridFubenSideTab:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.IsDestroy = nil
    self.GridIndex = nil
    self.CenterPosition = self.BtnTab.transform.localPosition
    local downPositionY = self.CenterPosition.y - self.Transform.sizeDelta.y / 4 - self.BtnTab.transform.sizeDelta.y / 2
    self.DownPosition =  CS.UnityEngine.Vector3(self.CenterPosition.x, downPositionY, self.CenterPosition.z)
    local upPositionY = self.CenterPosition.y + self.Transform.sizeDelta.y / 4 + self.BtnTab.transform.sizeDelta.y / 2
    self.UpPosition = CS.UnityEngine.Vector3(self.CenterPosition.x, upPositionY, self.CenterPosition.z)
    self.MoveTimerId = nil
    self.Duration = 0.3
    self.IsBtnDisable = nil
    XUiHelper.RegisterClickEvent(self, self.BtnPressNm, self.OnBtnTabClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnPressDisable, self.OnBtnTabClicked)
end

function XUiGridFubenSideTab:SetData(index)
    self.GridIndex = index
end

function XUiGridFubenSideTab:Click(...)
    -- 侧边栏兼容新手指引    
    if XDataCenter.GuideManager.CheckIsInGuide() and XDataCenter.GuideManager.GetGridNextCb() then
        XDataCenter.GuideManager:DoNextGridCb(self.Index) 
        XDataCenter.GuideManager.SetGridNextCb(nil) -- 执行后将回调置空
        self:SetIsSelected(true)
        self:PlayCenterAnim(false)
    end
end

function XUiGridFubenSideTab:PlayCenterAnim(isAnim, isUp)
    if isAnim == nil then isAnim = true end
    -- XLog.Warning(string.format("================ PlayCenterAnim %s %s ", self.GridIndex, isAnim))
    if not isAnim then
        self.BtnTab.transform.localPosition = self.CenterPosition
        self.BtnPressNm.transform.localPosition = self.CenterPosition
        self.BtnPressDisable.transform.localPosition = self.CenterPosition
        return
    end
    local beginY = self.BtnTab.transform.localPosition.y
    local diffValue = math.abs(self.CenterPosition.y - beginY)
    if isUp then
        diffValue = diffValue * -1
    end
    self:StopMoveTimer()
    self.MoveTimerId = XUiHelper.Tween(self.Duration, function(weight)
        if self.IsDestroy then
            return
        end

        self.BtnTab.transform:UpdateLocalPositionY(beginY + diffValue * weight)
        self.BtnPressNm.transform:UpdateLocalPositionY(beginY + diffValue * weight)
        self.BtnPressDisable.transform:UpdateLocalPositionY(beginY + diffValue * weight)
    end, function()
        self.BtnTab.transform.localPosition = self.CenterPosition
        self.BtnPressNm.transform.localPosition = self.CenterPosition
        self.BtnPressDisable.transform.localPosition = self.CenterPosition
    end)
end

function XUiGridFubenSideTab:PlayMoveUpAnim(isAnim)
    if isAnim == nil then isAnim = true end
    -- XLog.Warning(string.format("================ PlayMoveUpAnim %s %s ", self.GridIndex, isAnim))
    if not isAnim then
        self.BtnTab.transform.localPosition = self.UpPosition
        self.BtnPressNm.transform.localPosition = self.UpPosition
        self.BtnPressDisable.transform.localPosition = self.UpPosition
        return
    end
    local beginY = self.BtnTab.transform.localPosition.y
    local diffValue = math.abs(self.UpPosition.y - beginY)
    self:StopMoveTimer()
    self.MoveTimerId = XUiHelper.Tween(self.Duration, function(weight)
        if self.IsDestroy then
            return
        end

        self.BtnTab.transform:UpdateLocalPositionY(beginY + diffValue * weight)
        self.BtnPressNm.transform:UpdateLocalPositionY(beginY + diffValue * weight)
        self.BtnPressDisable.transform:UpdateLocalPositionY(beginY + diffValue * weight)
    end, function()
        self.BtnTab.transform.localPosition = self.UpPosition
        self.BtnPressNm.transform.localPosition = self.UpPosition
        self.BtnPressDisable.transform.localPosition = self.UpPosition
    end)
end

function XUiGridFubenSideTab:PlayMoveDownAnim(isAnim)
    if isAnim == nil then isAnim = true end
    -- XLog.Warning(string.format("================ PlayMoveDownAnim %s %s ", self.GridIndex, isAnim))
    if not isAnim then
        self.BtnTab.transform.localPosition = self.DownPosition
        self.BtnPressNm.transform.localPosition = self.DownPosition
        self.BtnPressDisable.transform.localPosition = self.DownPosition
        return
    end
    local beginY = self.BtnTab.transform.localPosition.y
    local diffValue = math.abs(self.DownPosition.y - beginY)
    self:StopMoveTimer()
    self.MoveTimerId = XUiHelper.Tween(self.Duration, function(weight)
        if self.IsDestroy then
            return
        end
        
        self.BtnTab.transform:UpdateLocalPositionY(beginY - diffValue * weight)
        self.BtnPressNm.transform:UpdateLocalPositionY(beginY - diffValue * weight)
        self.BtnPressDisable.transform:UpdateLocalPositionY(beginY - diffValue * weight)
    end)
end

function XUiGridFubenSideTab:SetBtnState(stateName)
    self.BtnTab.transform:Find(stateName).gameObject:SetActiveEx(true)
    for i = 0, self.BtnTab.transform.childCount - 1 do
        local trans = self.BtnTab.transform:GetChild(i)
        if trans.gameObject.name ~= stateName then
            trans.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridFubenSideTab:SetBtnSelect(flag)
    local stateName = "Select"
    if flag then
        stateName = self.IsBtnDisable and stateName..BtnState.Disable or stateName..BtnState.Normal
    else
        stateName = self.IsBtnDisable and BtnState.Disable or BtnState.Normal
    end
    self:SetBtnState(stateName)
end

function XUiGridFubenSideTab:SetBtnStateDisable(flag)
    local stateName = flag and "Disable" or "Normal" -- Btn是normal状态的点击按钮，Btn2是Disable的按钮
    self.IsBtnDisable = flag
    self.BtnPressNm.transform.gameObject:SetActiveEx(not flag)
    self.BtnPressDisable.transform.gameObject:SetActiveEx(flag)
    self:SetBtnState(stateName)
end

function XUiGridFubenSideTab:SetIsSelected(value, isDraging, isBeginDrag)
    if self.ImgSelect then
        if not value and isDraging and isBeginDrag then -- 只有拖拽的时候才有聚焦效果
            self.ImgSelect.gameObject:SetActiveEx(true)
        else
            self.ImgSelect.gameObject:SetActiveEx(false)
        end
    end

    if self.ExCheckOwnLock then -- 如果有子判单方法就用该方法判断该标签是否开放
        self:SetBtnStateDisable(self:ExCheckOwnLock())
    elseif self.GroupConfig then -- 判断该标签是否开放
        local isDisable = not XDataCenter.FubenManagerEx.CheckHasOpenBySecondTagId(self.GroupConfig.Id) 
        self:SetBtnStateDisable(isDisable)
    end
    
    if value then
        self:SetBtnSelect(true)
    else
        self:SetBtnSelect(false)
    end
end

function XUiGridFubenSideTab:ResetPosition()
    self.BtnTab.transform.localPosition = self.CenterPosition
end

function XUiGridFubenSideTab:StopMoveTimer()
    if self.MoveTimerId then
        XScheduleManager.UnSchedule(self.MoveTimerId)
    end
    self.MoveTimerId = nil
end

function XUiGridFubenSideTab:OnDestroy()
    self.IsDestroy = true
    self:StopMoveTimer()
end

return XUiGridFubenSideTab