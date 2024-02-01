---@class XUiRiftPluginGrid
local XUiRiftPluginGrid = XClass(nil, "UiRiftPluginGrid")

function XUiRiftPluginGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsUiPluginBag = false

    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiRiftPluginGrid:Init(clickCb, isUiPluginBag)
    self.ClickCb = clickCb
    self.IsUiPluginBag = isUiPluginBag
end

---@param plugin XRiftPlugin
function XUiRiftPluginGrid:Refresh(plugin, isSelect)
    self.XPlugin = plugin
    local icon = plugin:GetIcon()
    self.RImgIcon:SetRawImage(icon)
    local qualityImage, qualityImageBg = plugin:GetQualityImage()
    self.ImgQuality:SetSprite(qualityImage)
    self.ImgQualityBg:SetSprite(qualityImageBg)
    self.TxtName.text = plugin:GetName()
    self:SetDropPercentage()

    if self.IsUiPluginBag then
        local isHave = plugin:GetHave()
        self.ImgNormalLock.gameObject:SetActiveEx(not isHave)
        self:RefreshRed()
    end

    local isSpecial = plugin:IsSpecialQuality()
    if self.ImgBg then
        self.ImgBg.gameObject:SetActiveEx(not isSpecial)
    end
    if self.ImgBgSpecial then
        self.ImgBgSpecial.gameObject:SetActiveEx(isSpecial)
    end
    if self.PanelChaoYuan then
        self.PanelChaoYuan.gameObject:SetActiveEx(isSpecial)
    end
end

function XUiRiftPluginGrid:ShowSelect(isSelect)
    self.ImgActive.gameObject:SetActiveEx(isSelect)
    if isSelect and self.XPlugin:GetHave() then
        XDataCenter.RiftManager.ClosePluginRed(self.XPlugin:GetId())
        self:RefreshRed()
    end
end

function XUiRiftPluginGrid:SetDropPercentage(value)
    if not self.TxtDropChance then
        return
    end
    if value then
        self.TxtDropChance.gameObject:SetActiveEx(true)
        self.TxtDropChance.text = string.format("%s%%", value)
    else
        self.TxtDropChance.gameObject:SetActiveEx(false)
    end
end

function XUiRiftPluginGrid:SetIsWear(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiRiftPluginGrid:SetButtonCallBack()
    self.BtnClick.CallBack = function()
        if self.ClickCb then
            self:ClickCb(self)
        end
    end
end

function XUiRiftPluginGrid:SetBan(value)
    self.ImgBan.gameObject:SetActiveEx(value)
end

---是否【已转化】
function XUiRiftPluginGrid:SetChange(value)
    if self.PanelChange then
        self.PanelChange.gameObject:SetActiveEx(value)
    end
end

function XUiRiftPluginGrid:RefreshRed()
    local isRed = XDataCenter.RiftManager.IsPluginRed(self.XPlugin:GetId())
    self.BtnClick:ShowReddot(isRed)
end

return XUiRiftPluginGrid
