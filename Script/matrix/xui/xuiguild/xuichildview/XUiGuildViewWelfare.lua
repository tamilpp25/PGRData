local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGuildViewWelfare = XClass(nil, "XUiGuildViewWelfare")

local XUiGridWelfareItem = require("XUi/XUiGuild/XUiChildItem/XUiGridWelfareItem")

function XUiGuildViewWelfare:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:InitChildView()
end

function XUiGuildViewWelfare:OnEnable()
    self.GameObject:SetActiveEx(true)

    self:SetChildViewDatas()
end

function XUiGuildViewWelfare:OnDisable()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildViewWelfare:OnViewDestroy()

end

function XUiGuildViewWelfare:InitChildView()
    if not self.DynamicWelfareTable then
        self.DynamicWelfareTable = XDynamicTableNormal.New(self.PanelWelfare.gameObject)
        self.DynamicWelfareTable:SetProxy(XUiGridWelfareItem)
        self.DynamicWelfareTable:SetDelegate(self)
    end

end

function XUiGuildViewWelfare:SetChildViewDatas()
    if not self.WelfareDatas then

        self.WelfareDatas = XGuildConfig.GetGuildWelfares()
        if self.WelfareDatas then
            self.DynamicWelfareTable:SetDataSource(self.WelfareDatas)
            self.DynamicWelfareTable:ReloadDataASync()

        end
    end
end

function XUiGuildViewWelfare:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local welfareItem = self.WelfareDatas[index]
        if welfareItem then
            grid:SetItemData(welfareItem)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local welfareItem = self.WelfareDatas[index]
        if welfareItem then
            self:OnWelfareItemClick(welfareItem)
        end
    end
end

function XUiGuildViewWelfare:OnWelfareItemClick(welfareItem)
    -- 中途被踢出公会
    if not XDataCenter.GuildManager.IsJoinGuild() then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        self.UiRoot:Close()
        return
    end

    -- condition
    local welfareCondition = welfareItem.Condition
    if welfareCondition > 0 then
        local result, desc = XConditionManager.CheckCondition(welfareCondition)
        if not result then
            XUiManager.TipMsg(desc)
            return
        end
    end

    if welfareItem.SkipId == 2 then
        if XDataCenter.GuildManager.IsGuildTourist() then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildTourstAccess"))
            return
        end
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
            local targetShopId = XGuildConfig.GuildPersonalShop
            XShopManager.GetShopInfo(targetShopId, function()
                XLuaUiManager.Open("UiGuildShop", targetShopId)
            end)
        end
    elseif welfareItem.SkipId == 3 then
        XLuaUiManager.Open("UiGuildDonation")
    elseif welfareItem.SkipId == 1 then
        if XDataCenter.GuildManager.IsGuildTourist() then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildTourstAccess"))
            return
        end
        if not XDataCenter.GuildManager.IsGuildAdminister() then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
            return
        end
        XLuaUiManager.Open("UiGuildWelcomeWord")
    elseif welfareItem.SkipId == 4 then
        if XDataCenter.GuildManager.IsGuildTourist() then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildTourstAccess"))
            return
        end
        if not XDataCenter.GuildManager.IsGuildAdminister() then
            XUiManager.TipMsg(CS.XTextManager.GetText("GuildNotAdministor"))
            return
        end
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
            local targetShopId = XGuildConfig.GuildPurchaseShop
            XShopManager.GetShopInfo(targetShopId, function()
                XLuaUiManager.Open("UiGuildShop", targetShopId)
            end)
        end
    end
end

return XUiGuildViewWelfare