local XUiGridGuildGiftItem = XClass(nil, "XUiGridGuildGiftItem")
local GuildWillRequestTips
local GuildWillRequestDesTips
local TotalReqcount

function XUiGridGuildGiftItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    GuildWillRequestTips = CS.XTextManager.GetText("GuildWillRequestTips")
    GuildWillRequestDesTips = CS.XTextManager.GetText("GuildWillRequestDesTips")
    TotalReqcount = XGuildConfig.GetGuildWishMaxCountByLevel(XDataCenter.GuildManager.GetGuildLevel())
    XTool.InitUiObject(self)
end

function XUiGridGuildGiftItem:Init(uiRoot)
    self.UiRoot = uiRoot
    self.GridItemUI = XUiGridCommon.New(uiRoot,self.GridItem)
    self:InitFun()
end

function XUiGridGuildGiftItem:OnBtnSetClick()
    XLuaUiManager.Open("UiDialog", GuildWillRequestTips, GuildWillRequestDesTips, XUiManager.DialogType.Normal, nil, function ()
        self:PublishWishRequest()
    end)
end

function XUiGridGuildGiftItem:PublishWishRequest()
    local curcount = XDataCenter.GuildManager.GetCurWishReqCount()
    if curcount == TotalReqcount then
        XUiManager.TipText("GuildDonationPublishTips")
        return
    end

    XDataCenter.GuildManager.PublishWishRequest(self.ItemData.Id,function()
        self.UiRoot:SetCurGiftReqCount()
        XUiManager.TipText("GuildDonationPublishSuccessTips")
    end)
end

function XUiGridGuildGiftItem:InitFun()
    XUiHelper.RegisterClickEvent(self.GridItemUI, self.GridItemUI.BtnClick, function()self:OnBtnSetClick()end)
end

-- 更新数据
function XUiGridGuildGiftItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end

    self.ItemData = itemdata
    self.GridItemUI:Refresh(itemdata.Id)
end

return XUiGridGuildGiftItem