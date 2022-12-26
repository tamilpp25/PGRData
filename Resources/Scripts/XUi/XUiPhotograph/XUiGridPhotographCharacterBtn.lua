local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridPhotographCharacterBtn = XClass(nil, "XUiGridPhotographCharacterBtn")

function XUiGridPhotographCharacterBtn:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui:GetComponent("RectTransform")
    XTool.InitUiObject(self)
end

function XUiGridPhotographCharacterBtn:Init(rootUi)
    self.rootUi = rootUi
end

function XUiGridPhotographCharacterBtn:Refrash(data)
    self.ImgHead:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(data.Id))
    self.TxtName.text = data.LogName
    self.TxtNameEn.text = data.EnName
    self.TxtAIXin.text = data.TrustLv
end

function XUiGridPhotographCharacterBtn:OnTouched(charId)
    self:SetSelect(true)
    local fashionId = XDataCenter.FashionManager.GetFashionIdByCharId(charId)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_PHOTO_CHANGE_MODEL, charId, fashionId)
end

function XUiGridPhotographCharacterBtn:SetSelect(bool)
    self.Sel.gameObject:SetActiveEx(bool)
end

function XUiGridPhotographCharacterBtn:Reset()
    self:SetSelect(false)
end

return XUiGridPhotographCharacterBtn