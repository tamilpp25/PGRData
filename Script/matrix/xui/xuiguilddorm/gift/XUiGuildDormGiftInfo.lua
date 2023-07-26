--=================
--公会宿舍奖励页面
--=================
local XUiGuildDormGiftInfo = XLuaUiManager.Register(XLuaUi, "UiGuildDormGiftInfo")

function XUiGuildDormGiftInfo:OnAwake()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self:InitDynamicTable()
    self:InitEventListeners()
end

function XUiGuildDormGiftInfo:InitEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED, self.Refresh, self)
end

function XUiGuildDormGiftInfo:OnEnable()
    self:Refresh()
end


function XUiGuildDormGiftInfo:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED, self.Refresh, self)
end

function XUiGuildDormGiftInfo:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GiftList)
    local GridProxy = require("XUi/XUiGuildDorm/Gift/XUiGuildDormGiftGrid")
    self.DynamicTable:SetProxy(GridProxy)
    self.DynamicTable:SetDelegate(self)
end

function XUiGuildDormGiftInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.GiftList and self.GiftList[index] then
            grid:RefreshData(self, self.GiftList[index])
        end
    end
end

function XUiGuildDormGiftInfo:Refresh()
    local giftGuildLevel = XDataCenter.GuildManager.GetGiftGuildLevel()
    self.GiftList = XTool.Clone(XGuildConfig.GetGuildGiftByGuildLevel(giftGuildLevel))
    local giftLevelGots = XDataCenter.GuildManager.GetGiftLevelGot()
    table.sort(self.GiftList, function(data1, data2)
            local isData1Get = giftLevelGots[data1.GiftLevel] or false
            local isData2Get = giftLevelGots[data2.GiftLevel] or false
            if isData1Get == isData2Get then
                return data1.GiftLevel < data2.GiftLevel
            else
                if isData1Get then
                    return false
                else
                    return true
                end
            end
        end)
    self.DynamicTable:SetDataSource(self.GiftList)
    self.DynamicTable:ReloadDataASync(1)
    self.TxtActive.text = XUiHelper.GetText("GuildDormGiftInfoCurrentContribution", XDataCenter.GuildManager.GetGiftContribute())
end
