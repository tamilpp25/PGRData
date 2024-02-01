---@class XUiTempleChangeRoleGrid : XUiNode
---@field _Control XTempleControl
local XUiTempleChangeRoleGrid = XClass(XUiNode, "UiTempleChangeRoleGrid")

function XUiTempleChangeRoleGrid:OnStart()
    self._Data = false

    ---@type XTempleUiControl
    self._UiControl = self._Control:GetUiControl()
    self:AddBtnListener()
end

---@param data XTempleUiControlCharacter
function XUiTempleChangeRoleGrid:Update(data)
    self._Data = data
    self.RImgHeadIcon:SetRawImage(data.Icon)
    self.TxtRobotName.text = data.Name
    self.TxtRobotTradeName.text = data.TradeName
    self.ImgHeart:SetSprite(data.HeartIcon)
    self.TxtLv.text = data.HeartLv
    self.TxtFavorabilityLv.text = data.HeartText
    self:UpdateSelected()
end

--region Ui - BtnListener
function XUiTempleChangeRoleGrid:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end
--endregion

function XUiTempleChangeRoleGrid:OnClick()
    if self._Data then
        self._UiControl:SetSelectedCharacterId(self._Data.Id)
    end
end

function XUiTempleChangeRoleGrid:UpdateSelected()
    if self._Data then
        if self._UiControl:IsCharacterSelected(self._Data.Id) then
            self.PanelSelected.gameObject:SetActiveEx(true)
        else
            self.PanelSelected.gameObject:SetActiveEx(false)
        end
    end
end

return XUiTempleChangeRoleGrid