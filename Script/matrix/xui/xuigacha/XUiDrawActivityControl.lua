local XUiDrawActivityControl = XClass(nil, "XUiDrawActivityControl")
local characterRecord = require("XUi/XUiDraw/XUiDrawTools/XUiDrawCharacterRecord")

local MAX_GACHA_BTN_COUNT = 2

function XUiDrawActivityControl:Ctor(rootUi, gachaCfg, gachaCb, uiGacha)
    self.RootUi = rootUi
    self.GachaCfg = gachaCfg
    self.GachaCb = gachaCb
    self.UiGacha = uiGacha
    self.IsCanGacha = true
    self:InitRes()
    self:InitButtons()
    return self
end

function XUiDrawActivityControl:InitRes()
    self.UseItemIcon = XDataCenter.ItemManager.GetItemBigIcon(self.GachaCfg.ConsumeId)
end

function XUiDrawActivityControl:InitButtons()
    for i = 1, MAX_GACHA_BTN_COUNT do
        local btnName = "BtnDraw" .. i
        local btn = XUiHelper.TryGetComponent(self.RootUi.PanelDrawButtons, btnName)
        if btn then
            self:InitButton(btn, i)
        end
    end
end

function XUiDrawActivityControl:InitButton(btn, index)
    --@DATA
    local gachaCount = self.GachaCfg.BtnGachaCount[index]
    btn.transform:Find("TxtDrawDesc"):GetComponent("Text").text = CS.XTextManager.GetText("DrawCount", gachaCount)
    local itemIcon = btn.transform:Find("ImgUseItemIcon"):GetComponent("RawImage")
    itemIcon:SetRawImage(self.UseItemIcon)
    btn.transform:Find("TxtUseItemCount"):GetComponent("Text").text = gachaCount * self.GachaCfg.ConsumeCount

    self.RootUi:RegisterClickEvent(btn:GetComponent("Button"), function()
        self.UiGacha:UpdateItemCount()
        self:OnDraw(gachaCount)
    end)
end

function XUiDrawActivityControl:ShowGacha()

    XDataCenter.AntiAddictionManager.BeginDrawCardAction()
    self.UiGacha.OpenSound = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiDrawCard_GachaOpen)

    if self.GachaCb then
        self.GachaCb()
    end

    if self.RewardList and #self.RewardList > 0 then
        self.IsCanGacha = true
        self.UiGacha:PushShow(self.RewardList)
    else
        self.UiGacha:PushShow(self.RewardList)
    end

    self.UiGacha:UpDataPreviewData()
    self.UiGacha.IsReadyForGacha = false
end


function XUiDrawActivityControl:OnDraw(gachaCount)
    if XMVCA.XEquip:CheckBoxOverLimitOfDraw() then
        return
    end

    local ownItemCount = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId).Count
    local lackItemCount = self.GachaCfg.ConsumeCount * gachaCount - ownItemCount
    local gachaRule = XGachaConfigs.GetGachaRuleCfgById(self.GachaCfg.Id)

    if lackItemCount > 0 then
        if gachaRule.ItemNotEnoughSkipId > 0 then
            self:TipDialog(nil, function()
                XFunctionManager.SkipInterface(gachaRule.ItemNotEnoughSkipId)
            end, "GachaNotEnoughSkipHint")
        else
            XUiManager.TipError(CS.XTextManager.GetText("DrawNotEnoughError"))
        end
        return
    end
    local dtCount = XDataCenter.GachaManager.GetMaxCountOfAll(self.GachaCfg.Id) - XDataCenter.GachaManager.GetCurCountOfAll(self.GachaCfg.Id)
    if dtCount < gachaCount and not XDataCenter.GachaManager.GetIsInfinite(self.GachaCfg.Id) then
        XUiManager.TipMsg(CS.XTextManager.GetText("GachaIsNotEnough"))
        return
    end
    if not XDataCenter.GachaManager.CheckGachaIsOpenById(self.GachaCfg.Id, true) then
        return
    end
    if self.IsCanGacha then
        self.IsCanGacha = false

        characterRecord.Record()
        self.UiGacha.ImgMask.gameObject:SetActiveEx(true)

        XDataCenter.GachaManager.DoGacha(self.GachaCfg.Id, gachaCount, function(rewardList)
            self.UiGacha:PlayAnimation("DrawRetract", function()
                self.UiGacha.IsReadyForGacha = true
            end)
            self.RewardList = rewardList
        end, function()
            self.UiGacha.ImgMask.gameObject:SetActiveEx(false)
        end)
    end
end

function XUiDrawActivityControl:TipDialog(cancelCb, confirmCb, TextKey)
    XLuaUiManager.Open("UiDialog", CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText(TextKey),
    XUiManager.DialogType.Normal, cancelCb, confirmCb)
end

return XUiDrawActivityControl