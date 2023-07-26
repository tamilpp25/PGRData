---@class XUiDoubleTowersSpecialDoor@无限关卡
local XUiDoubleTowersSpecialDoor = XClass(nil, "XUiDoubleTowersSpecialDoor")

function XUiDoubleTowersSpecialDoor:Ctor(ui)
    self._IsSelected = false
    XUiHelper.InitUiClass(self, ui)
    self:InitUi()
end

function XUiDoubleTowersSpecialDoor:GetButtonComponent()
    return self.ButtonMajorTower
end

function XUiDoubleTowersSpecialDoor:Refresh()
    self:UpdateState()
end

function XUiDoubleTowersSpecialDoor:UpdateState()
    local groupId = XDataCenter.DoubleTowersManager.GetSpecialGroupId()
    local state = XDataCenter.DoubleTowersManager.GetGroupState(groupId)
    if state == XDoubleTowersConfigs.StageState.Clear or state == XDoubleTowersConfigs.StageState.NotClear then
        self._ActiveObject.gameObject:SetActiveEx(true)
        self._DeactiveObject.gameObject:SetActiveEx(false)
        self:UpdatePassedStageAmount()
    else
        self._ActiveObject.gameObject:SetActiveEx(false)
        self._DeactiveObject.gameObject:SetActiveEx(true)
    end
end

function XUiDoubleTowersSpecialDoor:UpdatePassedStageAmount()
    self.TxtMajor.text = XDataCenter.DoubleTowersManager.GetSpecialStageWinCount()
end

function XUiDoubleTowersSpecialDoor:SetSelected(isSelected)
    if self._IsSelected == isSelected then
        return
    end
    self._IsSelected = isSelected
    local selectedImg = self:GetSelectedImgTransform()
    selectedImg.gameObject:SetActiveEx(isSelected)
end

function XUiDoubleTowersSpecialDoor:Fold()
    self:SetSelected(false)
end

function XUiDoubleTowersSpecialDoor:Unfold()
    self:SetSelected(true)
end

function XUiDoubleTowersSpecialDoor:GetSelectedImgTransform()
    local groupId = XDataCenter.DoubleTowersManager.GetSpecialGroupId()
    local state = XDataCenter.DoubleTowersManager.GetGroupState(groupId)
    if state == XDoubleTowersConfigs.StageState.Clear then
        return self._ImgActiveSelect
    end
    return self._ImgDeactiveSelect
end

function XUiDoubleTowersSpecialDoor:InitUi()
    self._DeactiveObject = self.MajorTowerNormal
    self._ImgDeactiveSelect = self.MajorTowerNormal:Find("ImgMajorTowers2")
    self._ActiveObject = self.MajorTowerFinish
    self._ImgActiveSelect = self.MajorTowerFinish:Find("ImgMajorTowers2")
end

function XUiDoubleTowersSpecialDoor:UpdateStage()
    self:UpdateState()
end

return XUiDoubleTowersSpecialDoor
