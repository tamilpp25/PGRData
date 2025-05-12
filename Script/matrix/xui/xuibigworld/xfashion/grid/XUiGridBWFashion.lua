
---@class XUiGridBWFashion : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent 
---@field _Control 
local XUiGridBWFashion = XClass(XUiNode, "XUiGridBWFashion")

local GridType = {
    Fashion = 1,
    Weapon = 2,
    Head = 3,
}

local ColorEnum = {
    White = CS.UnityEngine.Color.white,
    WhiteWithAlpha = CS.UnityEngine.Color(1, 1, 1, 0.6)
}

function XUiGridBWFashion:OnStart(gridType)
    self._GridType = gridType
    self:InitCb()
    self:InitView()
end

function XUiGridBWFashion:InitCb()
end

function XUiGridBWFashion:InitView()
end

function XUiGridBWFashion:Refresh(charId, fashion, select)
    if self._GridType == GridType.Fashion then
        self:RefreshFashion(charId, fashion, select)
    elseif self._GridType == GridType.Weapon then
        self:RefreshWeapon(charId, fashion, select)
    elseif self._GridType == GridType.Head then
        self:RefreshHead(charId, fashion, select)
    end
end

function XUiGridBWFashion:RefreshFashion(charId, fashion, select)
    local t = XDataCenter.FashionManager.GetFashionTemplate(fashion)
    self.RImgIcon:SetRawImage(t.Icon)
    
    local dressFashion = XMVCA.XBigWorldCharacter:GetFashionId(charId)
    if dressFashion == fashion then
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(true)
        self.RImgIcon.color = ColorEnum.White
    elseif XMVCA.XBigWorldCharacter:CheckFashionUnlock(charId, fashion) then
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.RImgIcon.color = ColorEnum.White
    else
        self.ImgLock.gameObject:SetActiveEx(true)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.RImgIcon.color = ColorEnum.WhiteWithAlpha
    end
    self:SetSelect(select == fashion)
end

function XUiGridBWFashion:RefreshWeapon(charId, fashion, select)
    
end

function XUiGridBWFashion:RefreshHead(charId, fashion, select)
    self.RImgIcon:SetRawImage(fashion.Icon)
    local isUsing = XMVCA.XBigWorldCharacter:CheckHeadUsing(charId, fashion.HeadFashionId, fashion.HeadFashionType)
    local isUnlock = XMVCA.XBigWorldCharacter:CheckHeadUnlock(charId, fashion.HeadFashionId, fashion.HeadFashionType)

    if isUsing then --已穿戴
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(true)
        self.RImgIcon.color = ColorEnum.White
    elseif isUnlock then --已解锁
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.RImgIcon.color = ColorEnum.White
    else -- 未获得
        self.ImgLock.gameObject:SetActiveEx(true)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.RImgIcon.color = ColorEnum.WhiteWithAlpha
    end
    local isSelect = fashion.HeadFashionId == select.HeadFashionId and fashion.HeadFashionType == select.HeadFashionType
    self:SetSelect(isSelect)
    self.ImgTagDefault.gameObject:SetActiveEx(false)
end

function XUiGridBWFashion:IsSelect()
    return self.ImgSelected.gameObject.activeInHierarchy
end

function XUiGridBWFashion:SetSelect(select)
    self.ImgSelected.gameObject:SetActiveEx(select)
end

return XUiGridBWFashion
