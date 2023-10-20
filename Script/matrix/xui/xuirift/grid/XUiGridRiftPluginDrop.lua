local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

---@class XUiGridRiftPluginDrop : XUiNode
local XUiGridRiftPluginDrop = XClass(XUiNode, "UiGridRiftPluginDrop")

function XUiGridRiftPluginDrop:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnBtnClick)
end

function XUiGridRiftPluginDrop:SetClickCallBack(cb)
    self._ClickCb = cb
end

function XUiGridRiftPluginDrop:Refresh(dropData)
    local pluginId = dropData.PluginId
    local isDecompose = dropData.DecomposeCount > 0

    local plugin = XDataCenter.RiftManager.GetPlugin(pluginId)
    self:RefreshByPlugin(plugin)

    -- 已拥有
    self.PanelOwned.gameObject:SetActiveEx(isDecompose)
    if isDecompose then
        local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.RiftGold)
        self.RImgIcon:SetRawImage(icon)
        self.TxtItem.text = dropData.DecomposeCount
    end
end

---@param plugin XRiftPlugin
function XUiGridRiftPluginDrop:RefreshByPlugin(plugin)
    self._Plugin = plugin
    local isUnlock, lockTxt = plugin:IsUnlock()
    if isUnlock and not plugin:GetHave() then
        lockTxt = XUiHelper.GetText("RiftPluginNoGain")
    end
    local fixTypeList = plugin:GetPropTag()
    if not self._Pool then
        self._Pool = { self.PanelAddition }
    end
    if not self.PluginGrid then
        self.PluginGrid = XUiRiftPluginGrid.New(self.GridRiftPlugin)
    end
    for i, v in ipairs(fixTypeList) do
        local grid = self._Pool[i]
        if not grid then
            grid = XUiHelper.Instantiate(self.PanelAddition, self.PanelAddition.parent)
            self._Pool[i] = grid
        end
        local uiObject = {}
        XTool.InitUiObjectByUi(uiObject, grid)
        grid.gameObject:SetActiveEx(true)
        uiObject.TxtAddition.text = v
    end
    for i = #fixTypeList + 1, #self._Pool do
        self._Pool[i].gameObject:SetActiveEx(false)
    end

    self.PluginGrid:Refresh(plugin)
    self.TxtPluginName.text = plugin:GetName()
    self.TxtCoreExplain.text = plugin:GetDesc()
    self.ImgStar:SetSprite(plugin:GetImageDropHead())
    self.PanelGold.gameObject:SetActiveEx(plugin:IsSpecialQuality())
    self.TxtGold.text = plugin:GetGoldDesc()
    self.TxtLoad.text = plugin.Config.Load
    self.TxtLock.text = lockTxt
    self.TxtLock.gameObject:SetActiveEx(lockTxt ~= "")

    local quality = self._Plugin:GetQuality()
    for i = 1, 5 do
        local imgQuality = self["ImgQuality" .. i]
        local imgStar = self["ImgStar" .. i]
        if imgQuality and imgStar then
            if i == 5 then
                imgQuality.gameObject:SetActiveEx(quality >= i)
                imgStar.gameObject:SetActiveEx(quality >= i)
            else
                imgQuality.gameObject:SetActiveEx(quality == i)
                imgStar.gameObject:SetActiveEx(quality == i)
            end
        end
    end
end

function XUiGridRiftPluginDrop:RefreshBg()
    local star = self._Plugin:GetStar()
    local isSpecial = self._Plugin:IsSpecialQuality()

    self.PanelCard.gameObject:SetActiveEx(true)
    self.EffectGuangBei.gameObject:SetActiveEx(isSpecial)

    self.Bg01.gameObject:SetActiveEx(star <= 5)
    self.Bg02.gameObject:SetActiveEx(star == 6 and not isSpecial)
    self.Bg03.gameObject:SetActiveEx(star == 6 and isSpecial)
end

---翻转
function XUiGridRiftPluginDrop:DoOverturn()
    local star = self._Plugin:GetStar()
    local isSpecial = self._Plugin:IsSpecialQuality()

    self.CardDisable:Play()

    self.EffectXiaoShi01.gameObject:SetActiveEx(star <= 4)
    self.EffectXiaoShi02.gameObject:SetActiveEx(star == 5)
    self.EffectXiaoShi03.gameObject:SetActiveEx(star == 6 and not isSpecial)
    self.EffectXiaoShi04.gameObject:SetActiveEx(star == 6 and isSpecial)

    self.Timer = XScheduleManager.ScheduleOnce(function()
        self.EffectXiaoShi01.gameObject:SetActiveEx(false)
        self.EffectXiaoShi02.gameObject:SetActiveEx(false)
        self.EffectXiaoShi03.gameObject:SetActiveEx(false)
        self.EffectXiaoShi04.gameObject:SetActiveEx(false)
    end, 500)

    self.EffectGuang01.gameObject:SetActiveEx(star <= 3)
    self.EffectGuang02.gameObject:SetActiveEx(star == 4)
    self.EffectGuang03.gameObject:SetActiveEx(star == 5 )
    self.EffectGuang04.gameObject:SetActiveEx(star == 6)
end

function XUiGridRiftPluginDrop:OnDestroy()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiGridRiftPluginDrop:OnBtnClick()
    if self._ClickCb then
        self._ClickCb()
    end
end

return XUiGridRiftPluginDrop
