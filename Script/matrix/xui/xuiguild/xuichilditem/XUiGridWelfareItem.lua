local XUiGridWelfareItem = XClass(nil, "XUiGridWelfareItem")
local SkipTalentType = 1
local SkipShopType = 2

function XUiGridWelfareItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.BtnWelfareItem.CallBack = function() self:OnBtnWelfareClick() end
end

function XUiGridWelfareItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridWelfareItem:SetItemData()
end

function XUiGridWelfareItem:Refresh(welfareConfig)
    self.WelfareConfig = welfareConfig
    self.RImgWelfareNormal:SetRawImage(self.WelfareConfig.WelfareBg)
    self.RImgWelfarePress:SetRawImage(self.WelfareConfig.WelfareBg)
end

function XUiGridWelfareItem:OnBtnWelfareClick()
    if not self.WelfareConfig then return end

    if self.WelfareConfig.Condition > 0 then
        local isOpen, desc = XConditionManager.CheckCondition(self.WelfareConfig.Condition)
        if not isOpen then
            XUiManager.TipMsg(desc)
            return
        end
    end

    if not XDataCenter.GuildManager.IsJoinGuild() then return end
    if self.WelfareConfig.SkipId == SkipShopType then
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
            -- 4001 是绩点商店的id
            XLuaUiManager.Open("UiShop", XShopManager.ShopType.Guild)
        end
    elseif self.WelfareConfig.SkipId == SkipTalentType then
        XDataCenter.GuildManager.EnterGuildTalent()
    end

end
return XUiGridWelfareItem