--================
--角色详细核心部分
--================
local XUiSSBCCore = XClass(nil, "XUiSSBCCore")

function XUiSSBCCore:Ctor(prefab)
    XTool.InitUiObjectByUi(self, prefab)
    XUiHelper.RegisterClickEvent(self, self.BtnReplace, function() self:OnClickReplace() end)
end

function XUiSSBCCore:Refresh(chara)
    self.Chara = chara
    local core = chara:GetCore()
    self.PanelCore.gameObject:SetActiveEx(core ~= nil)
    if self.BgAdd then self.BgAdd.gameObject:SetActiveEx(core == nil) end
    if not core then return end
    self:SetStars(core)
    self.TxtName.text = core:GetName()
    self.RImgCore:SetRawImage(core:GetIcon())
    self.TxtAtk.text = XUiHelper.GetText("SSBInfoCoreAtk", core:GetAtkLevel() * XDataCenter.SuperSmashBrosManager.GetAtkUpNumByLevel())
    self.TxtLife.text = XUiHelper.GetText("SSBInfoCoreLife", core:GetLifeLevel() * XDataCenter.SuperSmashBrosManager.GetLifeUpNumByLevel())
end

function XUiSSBCCore:OnClickReplace()
    if self.Chara:IsSmashEggRobot() then
        XUiManager.TipText("SSBEggRobotCantEditCore")
        return
    end
    XLuaUiManager.Open("UiSuperSmashBrosSelectCore", self.Chara)
end

function XUiSSBCCore:SetStars(core)
    local starNum = core:GetStar()
    for i = 1, 5 do --最高五颗星
        self.UnlockStars:Find("Img"..i).gameObject:SetActiveEx(i <= starNum)
    end
end

function XUiSSBCCore:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSSBCCore:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiSSBCCore