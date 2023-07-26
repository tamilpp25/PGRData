---@class XUiGuildSignBase : XLuaUi
---@field
local XUiGuildSignBase = XClass(XLuaUi, "XUiGuildSignBase")

local TxtPos = {
    Yi = 1,
    Ji = 2
}

function XUiGuildSignBase:OnAwake()
    self:InitCb()
end

function XUiGuildSignBase:OnStart()
    self:InitView()
end

function XUiGuildSignBase:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_SHOW, true)
end

function XUiGuildSignBase:InitCb()
    self.BtnTanchuangCloseWhite.CallBack = function()
        self:Close()
    end

    self.BtnDetermine.CallBack = function()
        self:OnBtnDetermineClick()
    end
end

function XUiGuildSignBase:InitView()
    local signInfo = XDataCenter.GuildManager.GetSignInfo()
    if signInfo and signInfo.Id == 0 then
        XDataCenter.GuildManager.GetSignInfoRequest(function(rsp)
            if rsp.Id == 1 then
                self.EffectFirst.gameObject:SetActiveEx(true)
            end
            self:RefreshSignInfo()
        end)
    else
        self:RefreshSignInfo()
    end
    self.GridList = {}
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_SHOW, false)
end

function XUiGuildSignBase:RefreshSignInfo()
    local signInfo = XDataCenter.GuildManager.GetSignInfo()
    local signCfg = XGuildConfig.GetGuildSignById(signInfo.Id)
    local contentDic = {}
    for i, id in ipairs(signInfo.SignEventIds) do
        local eventCfg = XGuildConfig.GetGuildSignEventById(id)
        if not contentDic[eventCfg.Pos] then
            contentDic[eventCfg.Pos] = eventCfg.SignContent
        else
            contentDic[eventCfg.Pos] = contentDic[eventCfg.Pos] .."、".. eventCfg.SignContent
        end
    end
    self.TxtYiContent.text = contentDic[TxtPos.Yi] or ""
    self.TxtJiContent.text = contentDic[TxtPos.Ji] or ""
    self.RImgResult:SetRawImage(signCfg.ImageMap[self.Name])
    self.TxtNumber.text = CS.XTextManager.GetText("GuildSignNumberTex")
    self.TxtTime.text = XTime.TimestampToGameDateTimeString(XTime.GetServerNowTimestamp(), "MM  dd")
    self.BtnDetermine:SetDisable(true, false)

    local rewards = XRewardManager.MergeAndSortRewardGoodsList(signInfo.RewardGoodsList)
    self.GridList = {}
    for _, item in ipairs(rewards) do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridIcon)
        local grid = XUiGridCommon.New(self, ui)
        grid.Transform:SetParent(self.PanelIcon, false)
        grid:Refresh(item, { ShowReceived = true }, nil, true)
        grid.GameObject:SetActive(true)
        table.insert(self.GridList, grid)
    end
    self.GridIcon.gameObject:SetActiveEx(false)
end

function XUiGuildSignBase:OnBtnDetermineClick()
    XDataCenter.GuildManager.GuildSignRewardRequest(function(rewardGoodsList)
        if XTool.IsTableEmpty(rewardGoodsList) then
            return
        end
        XUiManager.OpenUiObtain(rewardGoodsList, nil, function()
            for _, grid in pairs(self.GridList) do
                grid:SetReceived(true)
            end
            self.BtnDetermine:SetDisable(true, false)
        end, nil)
    end)
end

return XUiGuildSignBase