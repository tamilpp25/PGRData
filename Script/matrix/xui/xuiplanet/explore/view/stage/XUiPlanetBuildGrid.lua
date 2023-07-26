---@class XUiPlanetBuildGrid
local XUiPlanetBuildGrid = XClass(nil, "XUiPlanetBuildGrid")

function XUiPlanetBuildGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitUiObj()
    self._Callback = false
    self._Building = false
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function()
        if self._Callback and self._Building then
            self._Callback(self._Building)
        end
    end)
end

---@param building XPlanetDataBuilding
---@param stage XPlanetStage
function XUiPlanetBuildGrid:Update(building, stage)
    self._Building = building
    local icon = building:GetIcon()
    self.RImgBuildIcon:SetRawImage(icon)
    self.TxtIcon.text = building:GetCost()
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(building:GetCostIcon())
    end

    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
    self.ImgRecommend.gameObject:SetActiveEx(stage:IsRecommend(building))
    if self.RImgCardDark then
        self.RImgCardDark.gameObject:SetActiveEx(stage:IsBanned(building))
    end
    self.ImgLock.gameObject:SetActiveEx(stage:IsBanned(building))
    self:UpdateBring()
end

function XUiPlanetBuildGrid:RegisterClick(func)
    self._Callback = func
end

---@param buildingSelected XPlanetDataBuilding
function XUiPlanetBuildGrid:UpdateSelected(buildingSelected, isShowSelectEffect)
    self.RImgCardSelect.gameObject:SetActiveEx(buildingSelected == self._Building)
    self:ShowSelectEffect(isShowSelectEffect)
    self:RefreshRedPoint()
end

function XUiPlanetBuildGrid:RefreshRedPoint()
    if self.Red then
        local isShowRed = self._Building and XDataCenter.PlanetManager.CheckOneStageBuildUnlockRed(self._Building:GetId())
        self.Red.gameObject:SetActiveEx(isShowRed)
    end
end

---是否处于被携带状态
function XUiPlanetBuildGrid:UpdateBring()
    if not self._Building then
        self.RImgCardChoice.gameObject:SetActiveEx(false)
        return
    end
    local viewModel = XDataCenter.PlanetManager.GetViewModel()
    local isBring = viewModel:IsBuildingSelected(self._Building)
    self.RImgCardChoice.gameObject:SetActiveEx(isBring)
end

function XUiPlanetBuildGrid:HideBring()
    self.RImgCardChoice.gameObject:SetActiveEx(false)
end

function XUiPlanetBuildGrid:ShowShinyEffect(active)
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(active)
    end
end

function XUiPlanetBuildGrid:ShowSelectEffect(active)
    if self.SelectEffect then
        self.SelectEffect.gameObject:SetActiveEx(active)
    end
end

function XUiPlanetBuildGrid:ShowUnlockEffect(active)
    if self.EffectUnlock then
        self.EffectUnlock.gameObject:SetActiveEx(active)
    end
end

function XUiPlanetBuildGrid:PlayUnlockAnim()
    self.GameObject:SetActiveEx(true)
    --local unlock = XUiHelper.TryGetComponent(self.Transform, "Animation/UnLock")
    --if unlock then
    --    unlock.gameObject:PlayTimelineAnimation()
    --end
    if self.EffectBorn then
        self.EffectBorn.gameObject:SetActiveEx(true)
    end
end

function XUiPlanetBuildGrid:InitUiObj()
    if not self.Effect then
        self.Effect = XUiHelper.TryGetComponent(self.Transform, "RImgCard/Effect")
    end
    if not self.SelectEffect then
        self.SelectEffect = XUiHelper.TryGetComponent(self.Transform, "RImgCardSelect/Effect")
    end
    if not self.EffectUnlock then
        self.EffectUnlock = XUiHelper.TryGetComponent(self.Transform, "RImgCardSelect/EffectUnlock")
    end
    self:ShowUnlockEffect(false)
    self:ShowSelectEffect(false)
    self:ShowShinyEffect(false)
end

return XUiPlanetBuildGrid