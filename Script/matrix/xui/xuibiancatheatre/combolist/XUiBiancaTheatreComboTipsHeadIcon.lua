--肉鸽2.0羁绊组合详细页面: 羁绊详细项控件: 头像控件
local XUiBiancaTheatreComboTipsHeadIcon = XClass(nil, "XUiBiancaTheatreComboTipsHeadIcon")
function XUiBiancaTheatreComboTipsHeadIcon:Ctor(ui, isShowDisplay)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsShowDisplay = isShowDisplay
    XTool.InitUiObject(self)
end

function XUiBiancaTheatreComboTipsHeadIcon:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiBiancaTheatreComboTipsHeadIcon:Hide()
    self.GameObject:SetActiveEx(false)
end

--[[
displayData = {
    EChara: XAdventureRole,
    IsActive
    IsBlank
}
]]
function XUiBiancaTheatreComboTipsHeadIcon:RefreshData(displayData, sampleRank)
    self.SampleRank = sampleRank
    if displayData.IsBlank then
        local blankIconPath = CS.XGame.ClientConfig:GetString("ExpeditionNoMember")
        self.RImgRoleNor:SetRawImage(blankIconPath)
        self.RImgRoleDis:SetRawImage(blankIconPath)
        self.RImgRoleNor.gameObject:SetActiveEx(false)
        self.RImgRoleDis.gameObject:SetActiveEx(true)
        self.TxtDis.gameObject:SetActiveEx(true)
        self.TxtLevel.gameObject:SetActiveEx(false)
        if self.TxtName then self.TxtName.text = "" end
    else
        self.IsActive = displayData.IsActive
        self.TxtLevel.gameObject:SetActiveEx(not self.IsShowDisplay and displayData.EChara:GetIsInRecruit())
        self.TxtDis.gameObject:SetActiveEx(not self.IsShowDisplay and not displayData.EChara:GetIsInRecruit())
        self.RImgRoleNor:SetRawImage(displayData.EChara:GetSmallHeadIcon())
        self.RImgRoleDis:SetRawImage(displayData.EChara:GetSmallHeadIcon())
        self.RImgRoleNor.gameObject:SetActiveEx(self.IsActive)
        self.RImgRoleDis.gameObject:SetActiveEx(not self.IsActive)
        self.TxtLevel.text = displayData.EChara:GetLevelStr()
        if self.TxtName then self.TxtName.text = displayData.EChara:GetCharacterTradeName() end
    end
end
return XUiBiancaTheatreComboTipsHeadIcon