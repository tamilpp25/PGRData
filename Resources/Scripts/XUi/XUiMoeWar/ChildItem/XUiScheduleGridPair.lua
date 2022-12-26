local XUiScheduleGridPair = XClass(nil, "XUiScheduleGridPair")

local XUiScheduleGridPlayer = require("XUi/XUiMoeWar/ChildItem/XUiScheduleGridPlayer")

function XUiScheduleGridPair:Ctor(ui, teamNo, modelUpdater)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.TeamNo = teamNo
    self.ModelUpdater = modelUpdater

    --XTool.InitUiObject(self)
    self:AutoRegister()
    self.BtnPlayBack.CallBack = function() self:OnBtnPlayBack() end

    self.Player1 = XUiScheduleGridPlayer.New(self.Player1Go)
    self.Player2 = XUiScheduleGridPlayer.New(self.Player2Go)
    self.PlayerWin = XUiScheduleGridPlayer.New(self.PlayerWinGo)
end

function XUiScheduleGridPair:AutoRegister()
    self.Player1Normal = self.Transform:Find("Line1/PanelNone")
    self.Player1Win = self.Transform:Find("Line1/PanelWin")
    self.Player2Normal = self.Transform:Find("Line2/PanelNone")
    self.Player2Win = self.Transform:Find("Line2/PanelWin")
    self.PlayerWinNormal = self.Transform:Find("LineWin/PanelNone")
    self.PlayerWinWin = self.Transform:Find("LineWin/PanelWin")
    self.BtnPlayBack = self.Transform:Find("BtnPlayBack"):GetComponent("XUiButton")
    self.Player1Go = self.Transform:Find("PanelRole1")
    self.Player2Go = self.Transform:Find("PanelRole2")
    self.PlayerWinGo = self.Transform:Find("PanelRole3")
    self.PanelNone = self.Transform:Find("PanelWenhao")
end

function XUiScheduleGridPair:Refresh(pair, match)
    self.PairInfo = pair
    if pair.Players[1] < pair.Players[2] then
        self.Player1Entity = XDataCenter.MoeWarManager.GetPlayer(pair.Players[1])
        self.Player2Entity = XDataCenter.MoeWarManager.GetPlayer(pair.Players[2])
    else
        self.Player1Entity = XDataCenter.MoeWarManager.GetPlayer(pair.Players[2])
        self.Player2Entity = XDataCenter.MoeWarManager.GetPlayer(pair.Players[1])
    end
    self.Match = match
    self.Player1:Refresh(self.Player1Entity, match)
    self.Player2:Refresh(self.Player2Entity, match)
    if match:GetResultOut() then
        local winner
        if self.Player1Entity.MatchInfoDic[match.Id].IsWin then
            winner = self.Player1Entity
        elseif self.Player2Entity.MatchInfoDic[match.Id].IsWin then
            winner = self.Player2Entity
        end
        self.Player1Win.gameObject:SetActiveEx(winner == self.Player1Entity)
        self.Player1Normal.gameObject:SetActiveEx(winner ~= self.Player1Entity)
        self.Player2Win.gameObject:SetActiveEx(winner == self.Player2Entity)
        self.Player2Normal.gameObject:SetActiveEx(winner ~= self.Player2Entity)
        self.PlayerWinNormal.gameObject:SetActiveEx(false)
        self.PlayerWinWin.gameObject:SetActiveEx(true)
        self.BtnPlayBack.gameObject:SetActiveEx(true)
        self.PlayerWin:Refresh(winner, match)
        if self.ModelUpdater then
            self.ModelUpdater(self.TeamNo, winner)
            self.PanelNone.gameObject:SetActiveEx(false)
        end
    else
        self.PlayerWinNormal.gameObject:SetActiveEx(true)
        self.PlayerWinWin.gameObject:SetActiveEx(false)
        self.BtnPlayBack.gameObject:SetActiveEx(false)
        self.PlayerWin:Refresh()

        if self.ModelUpdater then
            self.ModelUpdater(self.TeamNo, nil)
            self.PanelNone.gameObject:SetActiveEx(true)
        end
    end
end

function XUiScheduleGridPair:OnBtnPlayBack()
    XDataCenter.MoeWarManager.EnterAnimation(self.PairInfo, self.Match)
end

return XUiScheduleGridPair