local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridArenaSelfRank = require("XUi/XUiArenaNew/XUiArenaRank/XUiGridArenaSelfRank")

---@class XUiPanelArenaSelfRank : XUiNode
---@field _Control XArenaControl
local XUiPanelArenaSelfRank = XClass(XUiNode, "XUiPanelArenaSelfRank")

---@param groupData XArenaGroupDataBase
function XUiPanelArenaSelfRank:OnStart(groupData)
    self._GroupData = groupData
    self:_InitDynamicTable()
end

function XUiPanelArenaSelfRank:_InitDynamicTable()
    ---@type XDynamicTableNormal
    self._DynamicTable = XDynamicTableNormal.New(self.SViewRank)
    self._DynamicTable:SetProxy(XUiGridArenaSelfRank, self)
    self._DynamicTable:SetDelegate(self)
end

---@param grid XUiGridArenaSelfRank
function XUiPanelArenaSelfRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)
        
        if data then
            grid:Refresh(data, index)
        end
    end
end

function XUiPanelArenaSelfRank:Refresh(challengeId)
    if not challengeId then
        self.ImgEmpty.gameObject:SetActiveEx(true)
        self._DynamicTable:SetActive(false)
        return
    end

    self._Control:ArenaChallengeGetRankRequest(challengeId, function(data)
        self.TxtName.text = XPlayer.Name

        local guildName = XDataCenter.GuildManager.GetGuildName()
        local rank = data.Ranking
        local totalRank = data.MemberCount
        
        if string.IsNilOrEmpty(guildName) then
            self.TxtGuildName.text = XUiHelper.GetText("ArenaNoGuildTips")
        else
            self.TxtGuildName.text = guildName
        end
        if rank == 1 then
            self.TxtRank.text = XUiHelper.GetText("Rank1Color", rank)
        elseif rank == 2 then
            self.TxtRank.text = XUiHelper.GetText("Rank2Color", rank)
        elseif rank == 3 then
            self.TxtRank.text = XUiHelper.GetText("Rank3Color", rank)
        else
            if totalRank and rank > 100 and totalRank > 0 then
                local rankRate = math.ceil(rank / totalRank * 100)
                
                if rankRate >= 100 then
                    rankRate = 99
                end
                
                local rankRateDesc = rankRate .. "%"

                self.TxtRank.text = XUiHelper.GetText("RankOtherColor2", rankRateDesc)
            else
                self.TxtRank.text = XUiHelper.GetText("RankOtherColor2", rank)
            end
        end
        
        local rankList = data.Rank.RankPlayer
        local selfInfo = self._GroupData:GetSelfGroupPlayerData()
        
        if not selfInfo then
            XLog.Error("GroupMemberRequest data error. id not found. playerId:" .. tostring(XPlayer.Id))
            return
        end

        XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)

        self.Parent:RefreshTime(data.BeginTime, data.EndTime)
        self.TxtPoint.text = selfInfo:GetPoint()
        self.ImgEmpty.gameObject:SetActiveEx(#rankList == 0)
        
        self._DynamicTable:SetDataSource(rankList)
        self._DynamicTable:ReloadDataASync()
    end)
end

return XUiPanelArenaSelfRank