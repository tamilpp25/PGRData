---@class XUiDunhuangEditPaintingGrid : XUiNode
---@field _Control XDunhuangControl
local XUiDunhuangEditPaintingGrid = XClass(XUiNode, "XUiDunhuangEditPaintingGrid")

function XUiDunhuangEditPaintingGrid:OnStart()
    self._Button = XUiHelper.TryGetComponent(self.Transform, "", "XUiButton")
    self._Data = false
    self:AddBtnListener()
    self._IsOnGame = false
    self._IsSelected = false

    self.Red2 = self.Red2 or XUiHelper.TryGetComponent(self.Transform, "Red2", "Transform")
end

---@param data XDunhuangPaintingData
function XUiDunhuangEditPaintingGrid:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    if self.TxtNameSelected then
        self.TxtNameSelected.text = data.Name
    end
    self.RImgMaterial:SetRawImage(data.Icon)
    self:UpdateUseAndNew(data)
    if data.IsUnlock then
        self._Button:SetButtonState(CS.UiButtonState.Normal)
    else
        self._Button:SetButtonState(CS.UiButtonState.Disable)
    end
    if self.Red2 then
        self.Red2.gameObject:SetActiveEx(data.IsAfford)
    end
    self:UpdateSelected(self._Control:GetUiData().PaintingEditingOnGame)
end

--region Ui - BtnListener
function XUiDunhuangEditPaintingGrid:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self._Button, self.OnClick)
end
--endregion

function XUiDunhuangEditPaintingGrid:OnClick()
    if self._IsOnGame then
        self._Control:SetSelectedPaintingOnGame(self._Data)
    else
        self._Control:SetSelectedPaintingOnHangBook(self._Data)
    end
end

function XUiDunhuangEditPaintingGrid:UpdateSelected(data)
    if not self._Data or not data then
        return
    end
    local isSelected = self._Data.Id == data.Id
    --self.PanelUse.gameObject:SetActiveEx(isSelected)
    self.Select.gameObject:SetActiveEx(isSelected)
    self._IsSelected = isSelected
end

function XUiDunhuangEditPaintingGrid:SetIsOnGame(value)
    self._IsOnGame = value
end

---@param data XDunhuangPaintingData
function XUiDunhuangEditPaintingGrid:UpdateUseAndNew(data)
    if data then
        self.PanelUse.gameObject:SetActiveEx(data.IsUsing)
        self.Red.gameObject:SetActiveEx(data.IsNew)
    else
        self.PanelUse.gameObject:SetActiveEx(false)
        self.Red.gameObject:SetActiveEx(false)
    end
end

function XUiDunhuangEditPaintingGrid:PlayAnimationIfSelected(callback)
    if self._IsSelected then
        self:PlayAnimation("UnlockEnable", callback)
        return true
    end
    return false
end

return XUiDunhuangEditPaintingGrid
