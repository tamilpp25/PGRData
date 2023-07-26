local XUiMoeWarPollTips = XLuaUiManager.Register(XLuaUi,"UiMoeWarPollTips")
local XUiGridVoteItem = require("XUi/XUiMoeWar/ChildItem/XUiGridVoteItem")

function XUiMoeWarPollTips:OnStart(playerId, isFailGroup)
    self.PlayerId = playerId
    self.IsFailGroup = isFailGroup
    self:InitVoteItemList()
    self:RegisterButtonEvent()
	if self.TxtName then
		self.TxtName.text = CS.XTextManager.GetText("MoeWarSupportTitle",XDataCenter.MoeWarManager.GetPlayer(self.PlayerId):GetName())
	end
	if self.TxtNumber then
		local match = XDataCenter.MoeWarManager.GetCurMatch()
		local dailyLimitCount = match:GetDailyLimitCount()
		local currCount = XDataCenter.MoeWarManager.GetDailyVoteCount()
		self.TxtNumber.text = string.format("%s/%s",currCount,dailyLimitCount)
	end
end

function XUiMoeWarPollTips:RegisterButtonEvent()
    self.BtnClose.CallBack = function() XLuaUiManager.Close("UiMoeWarPollTips") end
    self.BtnTanchuangClose.CallBack = function() XLuaUiManager.Close("UiMoeWarPollTips") end
end

function XUiMoeWarPollTips:InitVoteItemList()
    self.VoteItemDic = {}
    local voteItems = XMoeWarConfig.GetVoteItems()
    for i = 1, #voteItems do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridCore,self.PanelContent)
        local grid = XUiGridVoteItem.New(obj, self.PlayerId, i, function(voteId)
            self:OnGridValueChanged(voteId)
        end, function(voteNumber)
            self:OnVoteSuccess(voteNumber, self.PlayerId)
        end, self,self.IsFailGroup)
        self.VoteItemDic[i] = grid
    end
    self.GridCore.gameObject:SetActiveEx(false)
end

function XUiMoeWarPollTips:OnVoteSuccess(voteNumber,playerId)
    XLuaUiManager.Close("UiMoeWarPollTips")
    XLuaUiManager.Open("UiMoeWarSupportTips",voteNumber,playerId)
	CS.XGameEventManager.Instance:Notify(XEventId.EVENT_MOE_WAR_VOTE_PANEL_UPDATE)
end

function XUiMoeWarPollTips:OnGridValueChanged(voteId)
    for id,grid in pairs(self.VoteItemDic) do
        if id ~= voteId then
            grid:SetVoteNumber(0)
        end
    end
end

return XUiMoeWarPollTips