---@class XUiGridSGPresuppose : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormPresuppose
---@field BtnClick XUiComponent.XUiButton
local XUiGridSGPresuppose = XClass(XUiNode, "XUiGridSGPresuppose")

function XUiGridSGPresuppose:OnStart()
    self:InitUi()
    self:InitCb()
end

function XUiGridSGPresuppose:OnDisable()
    self._Id = -1
end

function XUiGridSGPresuppose:Refresh(presupposeId, areaType, isSelect)
    self:Open()
    
    self._IsSelect = isSelect
    self._Id = presupposeId
    self.TxtName.text = self._Control:GetDormLayoutName(presupposeId)
    
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
    local curId = self._Control:GetLayoutIdByAreaType(areaType)
    self.PanelNow.gameObject:SetActiveEx(curId == self._Id)
    local isEmpty = self._Control:IsLayoutEmpty(areaType, presupposeId)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self.RImgIcon.gameObject:SetActiveEx(not isEmpty)
    if not isEmpty then
        self._Control:GetLayoutIcon(areaType, presupposeId, function(tex)
            if tex then
                self.RImgIcon.texture = tex
            else
                self.RImgIcon:SetRawImage(self._Control:GetDormLayoutDefaultIcon(presupposeId))
            end
        end)
    end
end

function XUiGridSGPresuppose:InitUi()
    self.UiBigWorldRed.gameObject:SetActiveEx(false)
end

function XUiGridSGPresuppose:InitCb()
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiGridSGPresuppose:OnBtnClick()
    if self._IsSelect then
        return
    end
    self.Parent:OnSelectPresuppose(self._Id)
end

function XUiGridSGPresuppose:GetId()
    return self._Id
end

return XUiGridSGPresuppose