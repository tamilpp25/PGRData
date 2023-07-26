local XUiPanelArenaSelfRank = XClass(nil, "XUiPanelArenaSelfRank")
local XUiGridArenaSelfRank = require("XUi/XUiArenaTeamRank/ArenaSelfRank/XUiGridArenaSelfRank")

---@param transform UnityEngine.RectTransform
function XUiPanelArenaSelfRank:Ctor(transform)
    self.GameObject = transform.gameObject
    self.Transform = transform
    XTool.InitUiObject(self)
    self:InitDynamicTable()
end

function XUiPanelArenaSelfRank:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRank)
    self.DynamicTable:SetProxy(XUiGridArenaSelfRank)
    self.DynamicTable:SetDelegate(self)
end

---@param grid XUiGridArenaSelfRank
function XUiPanelArenaSelfRank:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.RankList and self.RankList[index] then
            grid:Refresh(self.RankList[index], index)
        end
    end
end

function XUiPanelArenaSelfRank:Show(challengeId)
    if not challengeId then
        return
    end
    self.GameObject:SetActiveEx(true)
    XDataCenter.ArenaManager.RequestSelfRankList(challengeId, function(res)
        self.TxtName.text = XPlayer.Name
        local guildName = XDataCenter.GuildManager.GetGuildName()
        if string.IsNilOrEmpty(guildName) then
            self.TxtGuildName.text = CS.XTextManager.GetText("ArenaNoGuildTips")
        else
            self.TxtGuildName.text = XDataCenter.GuildManager.GetGuildName()
        end
        local rank = res.Ranking
        local totalRank = res.MemberCount
        if rank == 1 then
            self.TxtRank.text = CS.XTextManager.GetText("Rank1Color", rank)
        elseif rank == 2 then
            self.TxtRank.text = CS.XTextManager.GetText("Rank2Color", rank)
        elseif rank == 3 then
            self.TxtRank.text = CS.XTextManager.GetText("Rank3Color", rank)
        else
            if totalRank and rank > 100 and totalRank > 0 then
                local rankRate = math.ceil(rank / totalRank * 100)
                if rankRate >= 100 then
                    rankRate = 99
                end
                local rankRateDesc = rankRate .. "%"
                self.TxtRank.text = CS.XTextManager.GetText("RankOtherColor2", rankRateDesc)
            else
                self.TxtRank.text = CS.XTextManager.GetText("RankOtherColor2", rank)
            end
        end
        self.RankList = res.Rank.RankPlayer
        local selfInfo = XDataCenter.ArenaManager.GetPlayerArenaInfo()
        if not selfInfo then
            XLog.Error("GroupMemberRequest data error. id not found. playerId:" .. tostring(XPlayer.Id))
            return
        end
        XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
        self.TxtPoint.text = selfInfo.Point
        self.DynamicTable:SetTotalCount(#self.RankList)
        self.ImgEmpty.gameObject:SetActiveEx(#self.RankList == 0)
        self.DynamicTable:ReloadDataASync()
    end)
end

function XUiPanelArenaSelfRank:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelArenaSelfRank