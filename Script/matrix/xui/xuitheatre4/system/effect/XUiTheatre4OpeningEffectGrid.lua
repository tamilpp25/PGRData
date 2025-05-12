---@class XUiTheatre4OpeningEffectGrid : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4OpeningEffectGrid = XClass(XUiNode, "XUiTheatre4OpeningEffectGrid")

function XUiTheatre4OpeningEffectGrid:Ctor()
    ---@type XTheatre4SetControlAffixData
    self._Data = false
end

function XUiTheatre4OpeningEffectGrid:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnYes, self.OnClickYes)
end

---@param data XTheatre4SetControlAffixData
function XUiTheatre4OpeningEffectGrid:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    self.TxtProgress.text = data.Desc
    if data.IsUnlock then
        self.PanelLock.gameObject:SetActiveEx(false)
        self.BtnYes.gameObject:SetActiveEx(data.IsSelected)
    else
        self.BtnYes.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(true)
        self.TxtUnlockDesc.text = data.LockDesc
    end
    if self.ImgOn.SetRawImage then
        self.ImgOn:SetRawImage(data.TeamLogo)
    end
    self.RImgIcon:SetRawImage(data.Icon)
    self.ImgSelect.gameObject:SetActiveEx(data.IsSelected)
    if not data.IsSelected then
        ---@type UnityEngine.RectTransform
        local transform = self.Transform
        local scale = transform.localScale
        if scale.x ~= 1 and scale.y ~= 1 then
            scale.x = 1
            scale.y = 1
            scale.z = 1
            transform.localScale = scale
        end
    end

    if self.ImgBgRed then
        if data.Id == XEnumConst.Theatre4.OpeningEffectRed then
            self.ImgBgRed.gameObject:SetActiveEx(true)
        else
            self.ImgBgRed.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatre4OpeningEffectGrid:OnClick()
    self._Control.SetControl:SelectAffix(self._Data)
end

function XUiTheatre4OpeningEffectGrid:OnClickYes()
    self._Control.SetControl:RequestSetAffix(self._Data)
end

return XUiTheatre4OpeningEffectGrid
