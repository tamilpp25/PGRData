local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

---@class XUiGridRiftPluginDrop : XUiNode
---@field Parent XUiRiftSettlePlugin
---@field _Control XRiftControl
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

    local plugin = self._Control:GetPlugin(pluginId)
    self:RefreshByPlugin(plugin)

    -- 已拥有
    self.PanelOwned.gameObject:SetActiveEx(isDecompose)
    if isDecompose then
        local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.RiftGold)
        self.RImgIcon:SetRawImage(icon)
        self.TxtItem.text = dropData.DecomposeCount
    end
end

---@param plugin XTableRiftPlugin
function XUiGridRiftPluginDrop:RefreshByPlugin(plugin)
    self._Plugin = plugin
    local isUnlock, lockTxt = self._Control:IsPluginUnlock(plugin.Id)
    if isUnlock and not self._Control:IsHavePlugin(plugin.Id) then
        lockTxt = XUiHelper.GetText("RiftPluginNoGain")
    end
    local fixTypeList = self._Control:GetPluginPropTag(plugin.Id)
    if not self._Pool then
        self._Pool = { self.PanelAddition }
    end
    if not self.PluginGrid then
        self.PluginGrid = XUiRiftPluginGrid.New(self.GridRiftPlugin, self)
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
    self.TxtPluginName.text = plugin.Name
    self.TxtCoreExplain.text = self._Control:GetPluginDesc(plugin.Id)
    if self.ImgStar then
        self.ImgStar:SetSprite(self._Control:GetPluginQuality(plugin.Quality).ImageDropHead)
    end
    self.TxtLoad.text = plugin.Load
    if self.TxtDropTips then
        self.TxtDropTips.text = lockTxt
        self.TxtDropTips.gameObject:SetActiveEx(lockTxt ~= "")
    end

    local quality = self._Plugin.Quality
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
    local star = self._Plugin.Star
    local isSpecial = self._Control:IsPluginSpecialQuality(self._Plugin.Quality)

    self.PanelCard.gameObject:SetActiveEx(true)
    self.EffectGuangBei.gameObject:SetActiveEx(isSpecial)

    self.Bg01.gameObject:SetActiveEx(star <= 5)
    self.Bg02.gameObject:SetActiveEx(star > 5)
end

---翻转
function XUiGridRiftPluginDrop:DoOverturn()
    local star = self._Plugin.Star
    local isSpecial = self._Control:IsPluginSpecialQuality(self._Plugin.Quality)

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

function XUiGridRiftPluginDrop:ShowAffixDetail()
    local isShowAffixInfo, isShowBuyTip, isShowBuyInfo

    if self._Control:IsHavePlugin(self._Plugin.Id) then
        isShowAffixInfo = true
        self:ShowAffixInfo()
    else
        local isCanBuy = self._Control:IsPluginBuy(self._Plugin.Id)
        if isCanBuy then
            isShowBuyInfo = true
            self:ShowBuyInfo()
        else
            isShowBuyTip = true
            self:ShowBuyCondition()
        end
    end

    self.PanelAiffx.gameObject:SetActiveEx(isShowAffixInfo)
    self.TxtBuyTips.gameObject:SetActiveEx(isShowBuyTip)
    self.BtnTemplate.gameObject:SetActiveEx(isShowBuyInfo)
end

function XUiGridRiftPluginDrop:ShowAffixInfo()
    ---@type UnityEngine.Playables.PlayableDirector[]
    self._AffixAnimations = {}
    XUiHelper.RefreshCustomizedList(self.GridAffix.transform.parent, self.GridAffix, self._Plugin.SlotCount, function(index, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        local affix = self._Control:GetPluginRandomAffixByIdx(self._Plugin.Id, index)
        if XTool.IsNumberValid(affix) then
            local cfg = self._Control:GetRandomAffixById(affix)
            uiObject.GridAffix:SetButtonState(CS.UiButtonState.Normal)
            uiObject.GridAffix:SetSprite(cfg.Icon)
            if self._Control:IsRandomAffixMaxLevel(self._Plugin.Id, index) then
                local color = self._Control:GetMaxLevelPluginAffixColor()
                uiObject.GridAffix:SetNameByGroup(0, string.format("<color=%s>+%s</color>", color, cfg.Desc[2]))
                uiObject.TxtMax.transform.parent.gameObject:SetActiveEx(true)
            else
                uiObject.GridAffix:SetNameByGroup(0, string.format("+%s", cfg.Desc[2]))
                uiObject.TxtMax.transform.parent.gameObject:SetActiveEx(false)
            end
        else
            uiObject.GridAffix:SetButtonState(CS.UiButtonState.Disable)
        end
        uiObject.GridAffix.CallBack = function()
            XLuaUiManager.Open("UiRiftPopupAffix", self._Plugin.Id, index, function(type, slot)
                self:PlayAffixAnim(type, slot)
            end)
        end
        self._AffixAnimations[index] = uiObject.GridAffixUnlockEnable
    end)
end

function XUiGridRiftPluginDrop:ShowBuyCondition()
    self.TxtBuyTips.text = self._Control:GetPluginBuyTxt(self._Plugin.Id)
end

function XUiGridRiftPluginDrop:ShowBuyInfo()
    self.BtnTemplate.CallBack = handler(self,self.OnBuyPlugin)
    self.BtnTemplate:SetNameByGroup(0, self._Plugin.BuyCost)
    self.BtnTemplate:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XEnumConst.Rift.Currency))
end

function XUiGridRiftPluginDrop:OnBuyPlugin()
    if not XDataCenter.ItemManager.CheckItemCountById(XEnumConst.Rift.Currency, self._Plugin.BuyCost) then
        XUiManager.TipError(XUiHelper.GetText("RiftPluginCannotBuy"))
        return
    end
    self._Control:RequestBuyPlugin(self._Plugin.Id)
end

function XUiGridRiftPluginDrop:PlayAffixAnim(type, slot)
    if XTool.IsTableEmpty(self._AffixAnimations) then
        return
    end
    if type == 2 then
        for _, anim in pairs(self._AffixAnimations) do
            anim.gameObject:PlayTimelineAnimation()
        end
    else
        local anim = self._AffixAnimations[slot]
        if anim then
            anim.gameObject:PlayTimelineAnimation()
        end
    end
end

return XUiGridRiftPluginDrop
