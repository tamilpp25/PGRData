local XUiGuildDonationItem = XClass(nil, "XUiGuildDonationItem")

function XUiGuildDonationItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    local str = CS.XTextManager.GetText("GuildDonationBtnDes")
    self.BtnSkip:SetNameByGroup(0,str)
end

function XUiGuildDonationItem:InitFun()
    self.BtnSkip.CallBack = function() self:OnBtnDonateRequest() end
end

function XUiGuildDonationItem:Init(uiRoot)
    self.UiRoot = uiRoot
    self.GridItemUI = XUiGridCommon.New(uiRoot,self.GridItem)
    self:InitFun()
end

-- 更新数据
function XUiGuildDonationItem:OnRefresh(itemdata)
    if not itemdata or not next(itemdata)then
        return
    end

    self.ItemData = itemdata
    self.GridItemUI:Refresh(itemdata.ItemId)
    self.TxtName.text = itemdata.Name
    self.TxtNum.text = CS.XTextManager.GetText("GuildDonationHaveDes",XDataCenter.ItemManager.GetCount(itemdata.ItemId))
    self.TxtProNum.text = CS.XTextManager.GetText("GuildDonationProDes", itemdata.GotCount,itemdata.MaxCount)
    self.TxtDelegationName.text = CS.XTextManager.GetText("GuildDonationDeleDes", itemdata.Name)
    self.TxtPostName.text = CS.XTextManager.GetText("GuildDonationPosDes", XDataCenter.GuildManager.GetRankNameByLevel(itemdata.RankLevel))
    if itemdata.GotCount < itemdata.MaxCount then
        self.ImgBlack.gameObject:SetActiveEx(false)
        self.BtnSkip:SetButtonState(XUiButtonState.Normal)
    else
        self.BtnSkip:SetButtonState(XUiButtonState.Disable)
        self.ImgBlack.gameObject:SetActiveEx(true)
    end
    self.ImgProgress.fillAmount = math.floor(itemdata.GotCount/ itemdata.MaxCount)
    -- local info = XPlayerManager.GetHeadPortraitInfoById(rankInfo.HeadPortraitId)
    -- if info ~= nil then
    --     self.RImgPlayerHead:SetRawImage(info.ImgSrc)
    -- end
end

--捐赠
function XUiGuildDonationItem:OnBtnDonateRequest()
    local itemId = self.ItemData.ItemId
    if XDataCenter.ItemManager.GetCount(itemId) == 0 then
        XUiManager.TipText("GuildDonationNotEnoughCount",XUiManager.UiTipType.Wrong)
        return
    end

    local seq = self.ItemData.Seq
    local playerId = self.ItemData.Id
    XDataCenter.GuildManager.DonateRequest(playerId,seq,itemId,function()
        local tem = self.ItemData.GotCount + 1
        self.TxtNum.text = CS.XTextManager.GetText("GuildDonationHaveDes",XDataCenter.ItemManager.GetCount(itemId) - 1)
        self.TxtProNum.text = CS.XTextManager.GetText("GuildDonationProDes", tem,self.ItemData.MaxCount)
        self.ImgProgress.fillAmount = math.floor(tem / self.ItemData.MaxCount)
        if tem == self.ItemData.MaxCount then
            self.BtnSkip:SetButtonState(XUiButtonState.Disable)
            self.ImgBlack.gameObject:SetActiveEx(true)
        end
        XUiManager.TipText("GuildDonationSuccess")
    end)
end

return XUiGuildDonationItem