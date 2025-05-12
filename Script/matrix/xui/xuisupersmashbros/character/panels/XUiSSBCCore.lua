--================
--角色详细核心部分
--================
local XUiSSBCCore = XClass(nil, "XUiSSBCCore")

function XUiSSBCCore:Ctor(prefab)
    XTool.InitUiObjectByUi(self, prefab)
    XUiHelper.RegisterClickEvent(self, self.BtnReplace, function() self:OnClickReplace() end)
end

---@param chara XSmashBCharacter
function XUiSSBCCore:Refresh(chara)
    self.Chara = chara
    local core = chara:GetCore()
    local desc = chara:GetAssistantSkillDesc()
    if desc then
        self.TxtSkillDesc.text = desc
        self.PanelAid.gameObject:SetActiveEx(true)
    else
        self.PanelAid.gameObject:SetActiveEx(false)
    end
    if self.PanelAid2 then
        if desc then
            self.PanelAid2.gameObject:SetActiveEx(true)
            self.TxtSkillDesc2.text = desc
        else
            self.PanelAid2.gameObject:SetActiveEx(false)
        end
    end
    self.PanelCore.gameObject:SetActiveEx(core ~= nil)
    if self.BgAdd then self.BgAdd.gameObject:SetActiveEx(core == nil) end
    if not core then return end
    self:SetStars(core)
    self.TxtName.text = core:GetName()
    self.RImgCore:SetRawImage(core:GetIcon())
    self.TxtAtk.text = XUiHelper.GetText("SSBInfoCoreAtk", core:GetAtkLevel() * XDataCenter.SuperSmashBrosManager.GetAtkUpNumByLevel())
    self.TxtLife.text = XUiHelper.GetText("SSBInfoCoreLife", core:GetLifeLevel() * XDataCenter.SuperSmashBrosManager.GetLifeUpNumByLevel())
    chara:GetId()
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