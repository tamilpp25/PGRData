---@class XUiTheatre4PopupInheritGrid : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4PopupInheritGrid = XClass(XUiNode, "XUiTheatre4PopupInheritGrid")

function XUiTheatre4PopupInheritGrid:OnStart()
    self._Data = nil
    XUiHelper.RegisterClickEvent(self, self.BtnYes, self.OnClickSelect)
end

---@param data XTheatre4SetControlCollectionData
function XUiTheatre4PopupInheritGrid:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    self.TxtDetail.text = data.Desc
    self.BtnYes.gameObject:SetActiveEx(true)
    self.RImgIcon:SetRawImage(data.Icon)
    --XUiHelper.SetQualityIcon(nil, self.ImgQuality1, data.Quality)
    self.ImgQuality1.color = self:GetQualityColor(data.Quality)
end

function XUiTheatre4PopupInheritGrid:OnClickSelect()
    self._Control.SetControl:SelectCollection(self._Data)
end

function XUiTheatre4PopupInheritGrid:GetQualityColor(star)
    if star == 3 then
        return XUiHelper.Hexcolor2Color("3e70bb")
    end
    if star == 4 then
        return XUiHelper.Hexcolor2Color("cc68c1")
    end
    if star == 5 then
        return XUiHelper.Hexcolor2Color("ff8d1e")
    end
    return XUiHelper.Hexcolor2Color("3e70bb")
end

function XUiTheatre4PopupInheritGrid:_InitCanvasGroup()
    if XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup = self.Transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
end

function XUiTheatre4PopupInheritGrid:PlayPropCardAnimation()
    self:PlayAnimation("GridPropCardEnable", function()
        self:SetAlpha(1)
    end)
end

function XUiTheatre4PopupInheritGrid:SetAlpha(alpha)
    self:_InitCanvasGroup()
    if not XTool.UObjIsNil(self._CanvasGroup) then
        self._CanvasGroup.alpha = alpha
    end
end

return XUiTheatre4PopupInheritGrid