---@class XUiRiftPluginGrid:XUiNode
---@field Parent XUiRiftCharacter
---@field _Control XRiftControl
local XUiRiftPluginGrid = XClass(XUiNode, "UiRiftPluginGrid")

function XUiRiftPluginGrid:OnStart()
    self:SetButtonCallBack()
    self.Imggou = self.ImgNormalLock.gameObject:FindGameObject("Imggou")
end

function XUiRiftPluginGrid:Init(clickCb, isUiPluginBag)
    self.ClickCb = clickCb
    self.IsUiPluginBag = isUiPluginBag
end

---@param plugin XTableRiftPlugin
function XUiRiftPluginGrid:Refresh(plugin, isSelect)
    self.XPlugin = plugin
    local icon = plugin.Icon
    self.RImgIcon:SetRawImage(icon)
    local qualityImage, qualityImageBg = self._Control:GetPluginQualityImage(plugin.Quality)
    self.ImgQuality:SetSprite(qualityImage)
    self.ImgQualityBg:SetSprite(qualityImageBg)
    self.TxtName.text = plugin.Name
    self:SetDropPercentage()

    if self.IsUiPluginBag then
        local isHave = self._Control:IsHavePlugin(plugin.Id)
        if isHave then
            self.ImgFloorLock.gameObject:SetActiveEx(false)
            self.ImgNormalLock.gameObject:SetActiveEx(false)
        else
            local isUnlock, desc = self._Control:IsPluginUnlock(plugin.Id)
            if isUnlock then
                self.ImgNormalLock.gameObject:SetActiveEx(true)
                self.ImgFloorLock.gameObject:SetActiveEx(false)
                self.Imggou:SetActiveEx(not self._Control:IsPluginBuy(plugin.Id))
            else
                self.TxtLock.text = desc
                self.ImgFloorLock.gameObject:SetActiveEx(true)
                self.ImgNormalLock.gameObject:SetActiveEx(false)
            end
        end
        self:RefreshRed()
    else
        self.ImgFloorLock.gameObject:SetActiveEx(false)
        self.ImgNormalLock.gameObject:SetActiveEx(false)
    end

    local isSpecial = self._Control:IsPluginSpecialQuality(plugin.Quality)
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
    if isSelect and self._Control:IsHavePlugin(self.XPlugin.Id) then
        self._Control:ClosePluginRed(self.XPlugin.Id)
        self:RefreshRed()
    end
end

function XUiRiftPluginGrid:SetDropPercentage(value)
    if not self.TxtDropChance then
        return
    end
    if value then
        self.TxtDropChance.gameObject:SetActiveEx(true)
        local color = self._Control:GetPluginQualityColor(self.XPlugin.Quality)
        self.TxtDropChance.text = string.format("<color=%s>%s%%</color>", color, value)
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
    local isRed = self._Control:IsPluginRed(self.XPlugin.Id)
    self.BtnClick:ShowReddot(isRed)
end

return XUiRiftPluginGrid
