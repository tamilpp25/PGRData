local XUiGridLikeRoleItem = require("XUi/XUiFavorability/XUiGridLikeRoleItem")
XUiGridLineCharacter = XClass(XUiGridLikeRoleItem, "XUiGridLineCharacter")

function XUiGridLineCharacter:RefreshAssist(data, rootUi)
    self.RootUi = rootUi
    self:RefreshAddButton(data.IsAdd)
    if data.IsAdd then
        return
    end
    self.Super.OnRefresh(self, data)
    --self.ImgAssist.gameObject:SetActive(data.ChiefAssistant)
end

function XUiGridLineCharacter:RefreshAddButton(isAdd)
    self.BtnAdd.CallBack = function () self.RootUi:OnBtnAddAssistListClick() end
    if isAdd then
        for i = 0, self.Transform.childCount - 1 do
            local childGo = self.Transform:GetChild(i).gameObject
            childGo:SetActiveEx(self.BtnAdd.gameObject.name == childGo.name) 
        end
    else
        for i = 0, self.Transform.childCount - 1 do
            local childGo = self.Transform:GetChild(i).gameObject
            childGo:SetActiveEx(self.BtnAdd.gameObject.name ~= childGo.name) 
        end
    end
end

function XUiGridLineCharacter:OnBtnAddClick()
    self.RootUi:OnBtnAddAssistListClick()
end

function XUiGridLineCharacter:IsRed()
    return false
end

function XUiGridLineCharacter:OnSelect(flag)
    self.ImgSelected.gameObject:SetActiveEx(flag)
end

return XUiGridLineCharacter