local XUiReformListGridBuff = require("XUi/XUiReform2nd/Reform/Main/XUiReformListGridBuff")

---@class XUiReformListPanelMobGrid
local XUiReformListPanelMobGrid = XClass(nil, "XUiReformListPanelMobGrid")

function XUiReformListPanelMobGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    ---@type XUiReformListGridBuff[]
    self._UiBuff = {
        XUiReformListGridBuff.New(self.BtnBuff1),
    }

    self._OnClick = false
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)

    self.Grid = XUiHelper.TryGetComponent(self.Transform, "Grid", "RectTransform")
end

---@param data XUiReformPanelMobData
function XUiReformListPanelMobGrid:Update(data)
    self.Text.text = data.Name

    local dataBuff = data.IconBuff
    for i = 1, #dataBuff do
        local uiBuff = self._UiBuff[i]
        if not uiBuff then
            local ui = CS.UnityEngine.GameObject.Instantiate(self.BtnBuff1, self.BtnBuff1.transform.parent)
            uiBuff = XUiReformListGridBuff.New(ui)
            self._UiBuff[i] = uiBuff
        end
        local icon = dataBuff[i]
        uiBuff:Update(icon)
    end
    for i = #dataBuff + 1, #self._UiBuff do
        local uiBuff = self._UiBuff[i]
        uiBuff:Update()
    end
    self.RawImage:SetRawImage(data.Icon)
    self.TextLevel.text = data.Level
    self.TxtCost.text = data.Pressure
    self.Select.gameObject:SetActiveEx(data.IsSelected)
    self._IsHide = false
end

function XUiReformListPanelMobGrid:OnClick()
    if self._OnClick then
        self._OnClick()
    end
end

function XUiReformListPanelMobGrid:RegisterClick(func)
    self._OnClick = func
end

function XUiReformListPanelMobGrid:Show()
    self.Grid.gameObject:SetActiveEx(true)
    if self._IsHide then
        self:PlayAnimationEnable()
        self._IsHide = false
    end
end

function XUiReformListPanelMobGrid:Hide()
    self._IsHide = true
    self.Grid.gameObject:SetActiveEx(false)
end

function XUiReformListPanelMobGrid:PlayAnimationEnable()
    if not self.GameObject.activeInHierarchy then
        return
    end
    self.Transform:Find("Animation/GridEnable"):PlayTimelineAnimation(function()
        local canvasGroup = self.Grid.transform:GetComponent("CanvasGroup")
        canvasGroup.alpha = 1
    end)
end

function XUiReformListPanelMobGrid:PlayAnimationEnableDown()
    if not self.GameObject.activeInHierarchy then
        return
    end
    self.Transform:Find("Animation/GridEnableDown"):PlayTimelineAnimation(function()
        local canvasGroup = self.Grid.transform:GetComponent("CanvasGroup")
        canvasGroup.alpha = 1
    end)
end

return XUiReformListPanelMobGrid
