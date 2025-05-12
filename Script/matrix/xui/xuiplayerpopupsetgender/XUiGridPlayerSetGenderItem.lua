---@class XUiGridPlayerSetGenderItem: XUiNode
local XUiGridPlayerSetGenderItem = XClass(XUiNode, 'XUiGridPlayerSetGenderItem')

function XUiGridPlayerSetGenderItem:OnStart(genderId, index)
    self._GenderId = genderId
    self._Index = index
    self.GridBtn:SetNameByGroup(0, XPlayerInfoConfigs.GetPlayerGenderDescById(self._GenderId))
    self.GridBtn:SetNameByGroup(1, XPlayerInfoConfigs.GetPlayerGenderEnDescById(self._GenderId))
    self.GridBtn:SetSprite(XPlayerInfoConfigs.GetPlayerGenderIconAddressById(self._GenderId))
    self.GridBtn:SetButtonState(genderId == XPlayer.Gender and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiGridPlayerSetGenderItem:GetGenderId()
    return self._GenderId
end

function XUiGridPlayerSetGenderItem:GetButtonCom()
    return self.GridBtn
end



return XUiGridPlayerSetGenderItem