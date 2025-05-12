local XUiPanelMatch = require("XUi/XUiOnlineBoss/XUiPanelMatch")
local XUiPanelMatchCommon = XClass(nil, "XUiPanelMatchCommon")
local XUiPanelScheduleCommonPair = require("XUi/XUiMoeWar/ChildItem/XUiPanelScheduleCommonPair")

---@param transform UnityEngine.RectTransform
function XUiPanelMatchCommon:Ctor(transform,showModelFunc)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.ShowModelFunc = showModelFunc
    XTool.InitUiObject(self)
    self.VoteTeamDic = {}
    self.PublishTeamDic = {}
end

function XUiPanelMatchCommon:Refresh(groupIndex, sessionId, isShowModel,isShowGroup)
    self.GroupIndex = groupIndex
    self.SessionId = sessionId
    self.IsShowModel = isShowModel
    self.IsShowGroup = isShowGroup
    ---@type XMoeWarMatch
    local match = XDataCenter.MoeWarManager.GetVoteMatch(self.SessionId)
    if match:GetIsEnd(true) then
        match = XDataCenter.MoeWarManager.GetMatch(self.SessionId)
    end
    if self.TxtRefreshTip then
        self.TxtRefreshTip.text = match:GetRefreshVoteText()    
    end
    local matchType = match:GetType()

    if match:GetSessionId() == XMoeWarConfig.SessionType.GameInAudition then
        self.VoteList.gameObject:SetActiveEx(matchType == XMoeWarConfig.MatchType.Voting)
        self.PublishList.gameObject:SetActiveEx(matchType == XMoeWarConfig.MatchType.Publicity)
    end

    if matchType == XMoeWarConfig.MatchType.Voting and match:GetSessionId() == XMoeWarConfig.SessionType.GameInAudition then
        local playerList = match:GetPlayerListByGroupId(self.GroupIndex)
        local entityList = {}
        entityList.Players = {}
        for _, playerInfo in pairs(playerList) do
            table.insert(entityList.Players, { 
                WinnerId = 0,
                SecondId = 0,
                Players = {
                    playerInfo.PlayerId
                }
            })
        end
        self:RefreshVotePanel(entityList)
    else
        self:RefreshPublishPanel()
    end
end

function XUiPanelMatchCommon:RefreshVotePanel(pairList)
    local match = XDataCenter.MoeWarManager.GetVoteMatch(self.SessionId)
    for i, pair in ipairs(pairList.Players) do
        if not self.VoteTeamDic[i] then
            self.VoteTeamDic[i] = XUiPanelScheduleCommonPair.New(self["PanelVoteTeam" .. i], self.IsShowModel, i, self.ShowModelFunc)
        end
        ---@type XUiPanelScheduleCommonPair
        local com = self.VoteTeamDic[i]
        com:Refresh(pair, match)
    end
end

function XUiPanelMatchCommon:RefreshPublishPanel()
    ---@type XMoeWarMatch
    local match = XDataCenter.MoeWarManager.GetVoteMatch(self.SessionId)
    if match:GetIsEnd(true) then
       match = XDataCenter.MoeWarManager.GetMatch(self.SessionId)
    end
    local pairList
    if self.IsShowGroup then
        pairList = match:GetPairListByGroupId(self.GroupIndex)
    else
        pairList = match:GetPairList()
    end
    table.sort(pairList,function(a, b)
        if #a.Players ~= #b.Players then
            return #a.Players > #b.Players
        end
        return a.WarSituation < b.WarSituation
    end)
    for i, pair in pairs(pairList) do
        if not self.PublishTeamDic[i] then
            self.PublishTeamDic[i] = XUiPanelScheduleCommonPair.New(self["PanelTeam" .. i], self.IsShowModel, i, self.ShowModelFunc)
        end
        ---@type XUiPanelScheduleCommonPair
        local com = self.PublishTeamDic[i]
        com:Refresh(pair, match)
    end
end

function XUiPanelMatchCommon:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelMatchCommon:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelMatchCommon