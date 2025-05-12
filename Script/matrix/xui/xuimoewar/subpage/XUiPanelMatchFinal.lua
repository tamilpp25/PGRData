local XUiPanelMatch = require("XUi/XUiOnlineBoss/XUiPanelMatch")
local XUiPanelMatchFinal = XClass(nil, "XUiPanelMatchFinal")

local XUiScheduleGridPlayer = require("XUi/XUiMoeWar/ChildItem/XUiScheduleGridPlayer")
local ipairs = ipairs

local MAX_PLAYER_COUNT = 3

function XUiPanelMatchFinal:Ctor(uiRoot, ui, sessionId, modelUpdater)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ModelUpdater = modelUpdater

    self.ObjGroup = {}
    self.PairList = {}
    self.Rank = {}
    self.SessionId = sessionId
    XTool.InitUiObject(self)
    self:AutoRegister()
    self:InitGroup()

    --XTool.InitUiObject(self)
    self.BtnPlayBack.CallBack = function() self:OnBtnPlayBack() end

    self.Player1 = XUiScheduleGridPlayer.New(self.Player1Go)
    self.Player2 = XUiScheduleGridPlayer.New(self.Player2Go)
    self.Player3 = XUiScheduleGridPlayer.New(self.Player3Go)
    self.PlayerWin = XUiScheduleGridPlayer.New(self.PlayerWinGo)
end

function XUiPanelMatchFinal:AutoRegister()
    self.Player1Normal = self.Transform:Find("PanelTeam1/Line1/PanelNone")
    self.Player1Win = self.Transform:Find("PanelTeam1/Line1/PanelWin")
    self.Player2Normal = self.Transform:Find("PanelTeam1/Line2/PanelNone")
    self.Player2Win = self.Transform:Find("PanelTeam1/Line2/PanelWin")
    self.Player3Normal = self.Transform:Find("PanelTeam1/Line3/PanelNone")
    self.Player3Win = self.Transform:Find("PanelTeam1/Line3/PanelWin")
    self.PlayerWinNormal = self.Transform:Find("PanelTeam1/LineWin/PanelNone")
    self.PlayerWinWin = self.Transform:Find("PanelTeam1/LineWin/PanelWin")
    self.BtnPlayBack = self.Transform:Find("PanelTeam1/BtnPlayBack"):GetComponent("XUiButton")
    self.Player1Go = self.Transform:Find("PanelTeam1/PanelRole1")
    self.Player2Go = self.Transform:Find("PanelTeam1/PanelRole2")
    self.Player3Go = self.Transform:Find("PanelTeam1/PanelRole3")
    self.PlayerWinGo = self.Transform:Find("PanelTeam1/PanelRole4")
    self.PanelNone = self.Transform:Find("PanelTeam1/PanelWenhao")
    self.PanelWin = self.Transform:Find("PanelTeam1/PanelWin")
end

function XUiPanelMatchFinal:InitGroup()
    for i in ipairs(XMoeWarConfig.GetGroups()) do
        local grpName = XDataCenter.MoeWarManager.GetActivityInfo().GroupName[i]
        local txtName = self["Player"..i.."Go"]:Find("TextTeam"):GetComponent("Text")
        txtName.text = grpName
    end
end

function XUiPanelMatchFinal:InitPairGroup()
    -- 整理数据 分组
    self.PairGroup = {}
    local match = XDataCenter.MoeWarManager.GetMatch(self.SessionId)
    self.PairInfo = match.PairList[1]
    for i, playerId in ipairs(self.PairInfo.Players) do
        self.PairGroup[i] = XDataCenter.MoeWarManager.GetPlayer(playerId)
    end

    table.sort(self.PairGroup, function(playerA, playerB)
        return playerA.Id < playerB.Id
    end)
end

function XUiPanelMatchFinal:Refresh(isForce)
    if isForce or not self.PairGroup then
        self:InitPairGroup()
    end
    local pair =  self.PairGroup
    local match = XDataCenter.MoeWarManager.GetMatch(self.SessionId)
    local winner = 0
    self.Player1Entity = pair[1]
    self.Player2Entity = pair[2]
    self.Player3Entity = pair[3]
    self.Player1:Refresh(pair[1], match)
    self.Player2:Refresh(pair[2], match)
    self.Player3:Refresh(pair[3], match)
    if match:GetResultOut() then
        for i = 1, MAX_PLAYER_COUNT do
            local matchInfo = self["Player"..i.."Entity"].MatchInfoDic[match.Id]
            if matchInfo.IsWin then
                self.Rank[i] = 1
                winner = i
            elseif matchInfo.IsSecond then
                self.Rank[i] = 2
            else
                self.Rank[i] = 3
            end
            self["Player"..i.."Win"].gameObject:SetActiveEx(matchInfo.IsWin)
            self["Player"..i.."Normal"].gameObject:SetActiveEx(not matchInfo.IsWin)
        end

        self.PlayerWinNormal.gameObject:SetActiveEx(false)
        self.PlayerWinWin.gameObject:SetActiveEx(true)
        self.PlayerWin:Refresh(pair[winner], match)
        self.BtnPlayBack.gameObject:SetActiveEx(true)

        self.ModelUpdater(self.TeamNo, pair[winner])
        self.PanelNone.gameObject:SetActiveEx(false)
        self.PanelWin.gameObject:SetActiveEx(true)
    else
        for i in pairs(self.PairGroup) do
            self["Player"..i.."Win"].gameObject:SetActiveEx(false)
            self["Player"..i.."Normal"].gameObject:SetActiveEx(true)
        end
        self.PlayerWinNormal.gameObject:SetActiveEx(true)
        self.PlayerWinWin.gameObject:SetActiveEx(false)
        self.BtnPlayBack.gameObject:SetActiveEx(false)
        self.PlayerWin:Refresh()

        self.ModelUpdater(nil, nil)
        self.PanelNone.gameObject:SetActiveEx(true)
        self.PanelWin.gameObject:SetActiveEx(false)
    end

    self.TxtRefreshTip.text = match:GetRefreshVoteText()
    self:SetRankIcon()
end

function XUiPanelMatchFinal:SetRankIcon()
    for index in pairs(self.PairGroup) do
        self["Player"..index]:SetFinalRank(self.Rank[index] or 0)
    end
end

function XUiPanelMatchFinal:OnBtnPlayBack()
    XDataCenter.MoeWarManager.EnterAnimation(self.PairInfo, self.Match)
end

return XUiPanelMatchFinal