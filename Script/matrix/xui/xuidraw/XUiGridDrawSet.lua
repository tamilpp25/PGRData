local XUiGridDrawSet = XClass(nil, "XUiGridDrawSet")
local FirstIndex = 1
function XUiGridDrawSet:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.CurType = XDrawConfigs.DrawSetType.Normal
    self:SetButtonCallback()
end

function XUiGridDrawSet:Reset()
    self.DrawMainBanner = nil
    self.DrawSubBanner = nil
    self.GameObject.name = "GridDrawSet"
end

function XUiGridDrawSet:SetButtonCallback()
    self.BtnChange.CallBack = function()
        self:OnBtnChangeClick()
    end
end

function XUiGridDrawSet:OnBtnChangeClick()
    local IsNormal = self.CurType == XDrawConfigs.DrawSetType.Normal
    self.CurType = IsNormal and XDrawConfigs.DrawSetType.Destiny or XDrawConfigs.DrawSetType.Normal
    self:Update()
end

function XUiGridDrawSet:Update()
    if self.IsCanShow then
        if self.DrawMainBanner and self.DrawSubBanner then

            local IsNormal = self.CurType == XDrawConfigs.DrawSetType.Normal
            self.DrawMainBanner.GameObject:SetActiveEx(IsNormal)
            self.DrawSubBanner.GameObject:SetActiveEx(not IsNormal)

            local mainTypeName = ""
            local subTypeName = ""
            local typeChangeCfg = XDrawConfigs.GetDrawTypeChangeCfgById(self.DrawMainBanner.Info.Id)
            if typeChangeCfg then
                mainTypeName = typeChangeCfg.MainTypeName
                subTypeName = typeChangeCfg.SubTypeName[FirstIndex]
            end
            self.BtnChange:SetName(IsNormal and subTypeName or mainTypeName)
            self.BtnChange.gameObject:SetActiveEx(true)

        else
            self.BtnChange.gameObject:SetActiveEx(false)
        end
    end
    self.GameObject:SetActiveEx(self.IsCanShow and (self.DrawMainBanner or self.DrawSubBanner))
end

function XUiGridDrawSet:SetDrawMainBanner(banner)
    if banner then
        self.DrawMainBanner = banner
        self.DrawMainBanner.Transform:SetParent(self.PanelSet, false)
        self.GameObject.name = string.format("GridDrawSet%d",banner.Info.Id)
    end
end

function XUiGridDrawSet:SetDrawSubBanner(banner)
    if banner then
        self.DrawSubBanner = banner
        self.DrawSubBanner.Transform:SetParent(self.PanelSet, false)
    end
end

return XUiGridDrawSet