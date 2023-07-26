
local XUiSSBSelectCoreGrid = XClass(nil, "XUiSSBSelectCoreGrid")

local TextName = {
    Name = 0, --名称文本
    Gain = 1, --增益文本
    UnlockTips = 2, --解锁条件文本
}

function XUiSSBSelectCoreGrid:Ctor(prefab, core, rootUi)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, prefab)
    self:Refresh(core)
end

function XUiSSBSelectCoreGrid:Refresh(core)
    self.Core = core
    self.BtnCore:SetNameByGroup(TextName.Name, self.Core:GetName())
    self.BtnCore:SetNameByGroup(TextName.Gain, XUiHelper.GetText("SSBSelectCoreGain", self.Core:GetAtkLevel() + self.Core:GetLifeLevel()))
    self.BtnCore:SetNameByGroup(TextName.UnlockTips, self.Core:GetUnlockTips())  
    self.BtnCore:SetRawImage(self.Core:GetIcon())
    local quality = self.Core:GetStar()
    local qualityPath = XArrangeConfigs.GeQualityPath(quality)
    self.BtnCore:SetSprite(qualityPath)
    self.BtnCore:SetButtonState(self.Core:CheckIsLock() and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiSSBSelectCoreGrid:GetButton()
    return self.BtnCore
end

function XUiSSBSelectCoreGrid:OnSelect(value)

end

function XUiSSBSelectCoreGrid:GetCore()
    return self.Core
end

return XUiSSBSelectCoreGrid