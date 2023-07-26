local XUiReformListPanelMobGrid = require("XUi/XUiReform2nd/Reform/Mob/XUiReformListPanelMobGrid")
local XUiReformListPanelMobGridAffix = require("XUi/XUiReform2nd/Reform/Mob/XUiReformListPanelMobGridAffix")
local STATUS_SCROLL = {
    NONE = 0,
    AFFIX_START = 1,
    AFFIX_SCROLL = 2,
    AFFIX_SHOW_START = 3,
    AFFIX_SHOW = 4,
    END = 5,
}
local MovementType = CS.UnityEngine.UI.ScrollRect.MovementType

---@class XUiReformListPanelMob
local XUiReformListPanelMob = XClass(nil, "XUiReformListPanelMob")

function XUiReformListPanelMob:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XViewModelReform2ndList
    self._ViewModel = viewModel
    XTool.InitUiObject(self)
    self:HideAffixList()
    self.GridEnemy.gameObject:SetActiveEx(false)
    self.GridBuff.gameObject:SetActiveEx(false)
    ---@type XUiReformListPanelMobGridAffix[]
    self._GridBuff = {}
    ---@type XUiReformListPanelMobGrid[]
    self._GridMob = {}
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClickSure)
    self.TxtTip2.gameObject:SetActiveEx(true)
    if self.PanelReformEffect then
        self.PanelReformEffect.gameObject:SetActive(true)
    end
    self._Content = XUiHelper.TryGetComponent(self.PanelReformList.transform, "Viewport/Content", "RectTransform")
    self._AffixList = self.PanelAffixList:GetComponent("ScrollRect")

    self._Timer = false
    self._Status = STATUS_SCROLL.NONE
    self._GridFocus = false
    self._TransformGridFocus = false
    self._ScrollSpeed = 10000
    ---@type UnityEngine.Vector2
    self._PositionTemp = false
    self._GridIndex2Show = 0
    self._Duration = 0
    self._DurationGrid2Show = 0.1
end

function XUiReformListPanelMob:OnEnable()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:Tick()
        end, 0)
    end
end

function XUiReformListPanelMob:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    self._PositionTemp = false
    self._TransformGridFocus = false
end

function XUiReformListPanelMob:Update()
    self._ViewModel:UpdateSelectedMob()
    local data = self._ViewModel.DataMob
    local mobList = data.MobList
    if not mobList then
        return
    end
    for i = 1, #mobList do
        local mob = mobList[i]
        local grid = self._GridMob[i]
        if not grid then
            local ui = CS.UnityEngine.GameObject.Instantiate(self.GridEnemy, self.GridEnemy.transform.parent)
            grid = XUiReformListPanelMobGrid.New(ui)
            self._GridMob[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        if not self._ViewModel.DataMob.Update4Affix then
            grid:Show()
        end
        grid:Update(mob)
        grid:RegisterClick(function()
            if self:IsPlayingAnimation() then
                return
            end
            if self._ViewModel:SetSelectedMob(mob) then
                self:UpdateStateUiAffix()
            end
        end)
    end
    for i = #mobList + 1, #self._GridMob do
        local grid = self._GridMob[i]
        grid.GameObject:SetActiveEx(false)
    end

    for i = 1, #mobList do
        local mob = mobList[i]
        if mob.IsSelected then
            self:UpdateStateUiAffix(i)
            break
        end
    end
end

function XUiReformListPanelMob:OnClickSure()
    self:Hide()
    XEventManager.DispatchEvent(XEventId.EVENT_REFORM_UPDATE_MOB)
    if self.BtnReformEffect then
        self.BtnReformEffect.gameObject:SetActive(true)
    end
end

function XUiReformListPanelMob:Show()
    self.GameObject:SetActiveEx(true)
    self:HideAffixList()
end

function XUiReformListPanelMob:Hide()
    self._ViewModel:ClearMobDirty()
    self._ViewModel:ClearSelected()
    self.GameObject:SetActiveEx(false)
    self:HideAffixList()
end

function XUiReformListPanelMob:ShowAffixList()
    self:UpdateAffix()
    self.PanelAffixList.gameObject:SetActiveEx(true)
    self.PanelReformList.vertical = false
end

function XUiReformListPanelMob:HideAffixList()
    self.PanelAffixList.gameObject:SetActiveEx(false)
    if self._AffixList then
        self._AffixList.verticalNormalizedPosition = 1
    end
    self.PanelReformList.vertical = true
    self.PanelReformList.movementType = MovementType.Elastic
end

function XUiReformListPanelMob:UpdateAffix()
    self._ViewModel:UpdateMobAffix()
    local data = self._ViewModel.DataMob

    local affixList = data.AffixList
    for i = 1, #affixList do
        local affix = affixList[i]
        local gridAffix = self._GridBuff[i]
        if not gridAffix then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBuff, self.GridBuff.transform.parent)
            gridAffix = XUiReformListPanelMobGridAffix.New(ui)
            self._GridBuff[i] = gridAffix
            gridAffix:SetViewModel(self._ViewModel)
        end
        gridAffix.GameObject:SetActiveEx(true)
        gridAffix:Update(affix)
    end
    for i = #self._GridBuff + 1, #affixList do
        local grid = self._GridBuff[i]
        grid.GameObject:SetActiveEx(false)
    end
end

function XUiReformListPanelMob:FocusTo(index)
    local gridFocus = self._GridMob[index]
    if not gridFocus then
        return false
    end
    self._GridFocus = gridFocus
    self._TransformGridFocus = gridFocus.GameObject:GetComponent("RectTransform")
    self._Status = STATUS_SCROLL.AFFIX_START
    self._ViewModel:SetPlayingAnimationScroll(true)
    return true
end

function XUiReformListPanelMob:UpdateStateUiAffix(index)
    if self._ViewModel:IsMobSelected() then
        if self._ViewModel.DataMob.Update4Affix then
            self:ShowAffixList()
            self._ViewModel:SetUpdate4Affix(false)
            return
        end
        if index then
            self:FocusTo(index)
        end
    else
        self:HideAffixList()
    end
end

function XUiReformListPanelMob:Tick()
    local status = self._Status
    if status == STATUS_SCROLL.NONE then
        return
    end

    if status == STATUS_SCROLL.AFFIX_START then
        self._Status = STATUS_SCROLL.AFFIX_SCROLL
        self.PanelReformList.movementType = MovementType.Unrestricted

        if not self._PositionTemp then
            self._PositionTemp = Vector2()
        end
        self._PositionTemp.y = self._Content.anchoredPosition.y
        return
    end

    if status == STATUS_SCROLL.AFFIX_SCROLL then
        local yTarget = math.abs(self._TransformGridFocus.localPosition.y)
        if math.abs(self._PositionTemp.y - yTarget) <= self._ScrollSpeed then
            self._Status = STATUS_SCROLL.AFFIX_SHOW_START
            self._PositionTemp.y = yTarget
            self._Content.anchoredPosition = self._PositionTemp
            return
        end

        if yTarget > self._PositionTemp.y then
            self._PositionTemp.y = self._PositionTemp.y + self._ScrollSpeed
        else
            self._PositionTemp.y = self._PositionTemp.y - self._ScrollSpeed
        end
        self._Content.anchoredPosition = self._PositionTemp
        return
    end

    if status == STATUS_SCROLL.AFFIX_SHOW_START then
        if self._GridFocus then
            self:HideGridUnfocus()
            self._GridFocus:PlayAnimationEnableDown()
        end

        self:ShowAffixList()
        for i = 1, #self._GridBuff do
            local grid = self._GridBuff[i]
            grid.GameObject:SetActiveEx(false)
        end
        self._Status = STATUS_SCROLL.AFFIX_SHOW
        self._GridIndex2Show = 0
        self._Duration = 0
        return
    end

    if status == STATUS_SCROLL.AFFIX_SHOW then
        self._Duration = self._Duration + CS.UnityEngine.Time.deltaTime
        if self._Duration < self._DurationGrid2Show then
            return
        end
        self._Duration = 0

        local amount = #self._ViewModel.DataMob.AffixList
        self._GridIndex2Show = self._GridIndex2Show + 1
        if self._GridIndex2Show > amount then
            self._Status = STATUS_SCROLL.END
            return
        end
        local grid = self._GridBuff[self._GridIndex2Show]
        if grid then
            grid.GameObject:SetActiveEx(true)
            grid:PlayAnimationEnable()
        end
        return
    end

    if status == STATUS_SCROLL.END then
        self._ViewModel:SetPlayingAnimationScroll(false)
        self._Status = STATUS_SCROLL.NONE
        return
    end
end

function XUiReformListPanelMob:HideGridUnfocus()
    local gridFocus = self._GridFocus
    for i = 1, #self._GridMob do
        local grid = self._GridMob[i]
        if grid ~= gridFocus then
            grid:Hide()
        end
    end
end

function XUiReformListPanelMob:IsPlayingAnimation()
    return self._ViewModel.DataMob.PlayingAnimation
end

return XUiReformListPanelMob
