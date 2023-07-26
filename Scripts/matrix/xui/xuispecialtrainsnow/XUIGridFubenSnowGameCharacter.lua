---@class XUIGridFubenSnowGameCharacter
local XUIGridFubenSnowGameCharacter = XClass(nil, "XUIGridFubenSnowGameCharacter")

function XUIGridFubenSnowGameCharacter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitUi()
end

function XUIGridFubenSnowGameCharacter:InitUi()
    self.RImgHeadIcon = self.Transform:Find("PanelHead/RImgHeadIcon"):GetComponent("RawImage")
    self.ImgSelected = self.Transform:Find("PanelSelected/ImgSelected"):GetComponent("Image")
    self.TxtCur = self.Transform:Find("TxtCur"):GetComponent("Text")
    self.Txt1 = self.Transform:Find("Txt1"):GetComponent("Text")
    self.Txt2 = self.Transform:Find("Txt2"):GetComponent("Text")
end


function XUIGridFubenSnowGameCharacter:Refresh(robotId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(robotId)
    self.RImgHeadIcon:SetRawImage(XCharacterCuteConfig.GetCuteModelSmallHeadIcon(characterId))
    self.Txt1.text = XEntityHelper.GetCharacterName(robotId)
    self.Txt2.text = XEntityHelper.GetCharacterTradeName(robotId)
end

function XUIGridFubenSnowGameCharacter:SetSelected(isSelected)
    self.ImgSelected.gameObject:SetActiveEx(isSelected)
end

function XUIGridFubenSnowGameCharacter:SetCurrentSign(isActive)
    self.TxtCur.gameObject:SetActiveEx(isActive)
end

return XUIGridFubenSnowGameCharacter