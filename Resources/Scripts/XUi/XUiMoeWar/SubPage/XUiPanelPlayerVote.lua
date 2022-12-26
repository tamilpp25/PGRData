local XUiPanelPlayerVote = XClass(nil, "XUiPanelPlayerVote")
local MAX_ANIMATION_NUMBER = 3
local ANIMATION_DELAY = 500
function XUiPanelPlayerVote:Ctor(ui)
	---@type UnityEngine.GameObject
	self.GameObject = ui
	---@type UnityEngine.Transform
	self.Transform = self.GameObject.transform
	self:AutoInitUiObject()
	self.BtnPoll.CallBack = function()
		self:OnClickBtnPoll()
	end
	self.ColdDown = CS.XGame.ClientConfig:GetInt("MoeWarPlayerScreenRecordAnimationCD")
	self.CurrCD = 0
	self.AnimationGridList = {}
	self.AnimationIndex = 1
	self.Timer = CS.XScheduleManager.ScheduleForever(function()
		self:PlayAnimation()
		self.CurrCD = self.CurrCD - 1
		end,1000,0)
	self.BtnPoll:SetName(CS.XTextManager.GetText("MoeWarVote"))
	self.TxtMyTitle.text = CS.XTextManager.GetText("MoeWarMyVote")
end

function XUiPanelPlayerVote:AutoInitUiObject()
	self.TxtName = self.Transform:Find("TxtName"):GetComponent("Text")
	self.TxtAllNumber = self.Transform:Find("PanelRolePoll/TxtNumber"):GetComponent("Text")
	self.TxtDis = self.Transform:Find("PanelRolePoll/TxtDis"):GetComponent("Text")
	self.TxtDis2 = self.Transform:Find("PanelRolePoll/TxtDis2"):GetComponent("Text")
	self.TxtMyNumber = self.Transform:Find("PanelPoll/GridPollMy/TxtNumber"):GetComponent("Text")
	self.TxtMyTitle = self.Transform:Find("PanelPoll/GridPollMy/TxtTitle"):GetComponent("Text")
	self.MyPollPanel = self.Transform:Find("PanelPoll/GridPollMy")
	self.PanelOther = self.Transform:Find("PanelPoll/PanelPollOther")
	self.PlayableDirector = self.Transform:Find("PanelPoll/PanelPollOther/GridPollOther"):GetComponent("PlayableDirector")
	self.TxtOtherName = self.Transform:Find("PanelPoll/PanelPollOther/GridPollOther/TxtName"):GetComponent("Text")
	self.ImgOtherIcon = self.Transform:Find("PanelPoll/PanelPollOther/GridPollOther/TxtNumber/RImgIcon"):GetComponent("RawImage")
	self.TxtOtherNumber = self.Transform:Find("PanelPoll/PanelPollOther/GridPollOther/TxtNumber"):GetComponent("Text")
	self.BtnPoll = self.Transform:Find("BtnPoll"):GetComponent("XUiButton")
	self.ImgAllIcon = self.Transform:Find("PanelRolePoll/RImgIcon"):GetComponent("RawImage")
	self.ImgMyIcon = self.Transform:Find("PanelPoll/GridPollMy/RawImage"):GetComponent("RawImage")
	self.GridPollOther = self.Transform:Find("PanelPoll/PanelPollOther/GridPollOther")
	self.MyVoteChangeEffect = self.Transform:Find("PanelPoll/GridPollMy/TxtNumber/Effect") 
end

function XUiPanelPlayerVote:OnClickBtnPoll()
	XLuaUiManager.Open("UiMoeWarPollTips",self.PlayerId)
end

function XUiPanelPlayerVote:Refresh(playerId)
	self.PlayerId = playerId
	local playerEntity = XDataCenter.MoeWarManager.GetPlayer(self.PlayerId)
	local match = XDataCenter.MoeWarManager.GetCurMatch()
	local allCount = playerEntity:GetSupportCount(XDataCenter.MoeWarManager.GetCurMatchId())
	if XDataCenter.MoeWarManager.IsInStatistics() then
		self.TxtDis.gameObject:SetActiveEx(false)
		self.TxtDis2.gameObject:SetActiveEx(true)
		self.TxtAllNumber.gameObject:SetActiveEx(false)
	else
		self.TxtDis2.gameObject:SetActiveEx(false)
		if allCount == 0 and XDataCenter.MoeWarManager.GetCurMatch():GetType() == XMoeWarConfig.MatchType.Voting then
			self.TxtAllNumber.text = CS.XTextManager.GetText("MoeWarMatchVoteNotRefresh")
			if self.TxtDis then
				self.TxtAllNumber.gameObject:SetActiveEx(false)
				self.TxtDis.gameObject:SetActiveEx(true)
			end
		else
			if self.TxtDis then
				self.TxtAllNumber.gameObject:SetActiveEx(true)
				self.TxtDis.gameObject:SetActiveEx(false)
			end
			self.TxtAllNumber.text = playerEntity:GetSupportCount(XDataCenter.MoeWarManager.GetCurMatchId())
		end
	end
	local myCount = playerEntity:GetMySupportCount(match:GetSessionId())
	self.TxtMyNumber.text = myCount
	self.MyPollPanel.gameObject:SetActiveEx(myCount ~= 0)
	self.TxtName.text = playerEntity:GetName()
	self.ImgAllIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
	self.ImgMyIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
	self.ImgOtherIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
	local matchType = match:GetType()
	if XDataCenter.MoeWarManager.IsInStatistics() then
		self.BtnPoll.gameObject:SetActiveEx(false)
	else
		self.BtnPoll.gameObject:SetActiveEx(matchType ~= XMoeWarConfig.MatchType.Publicity)
	end
end

function XUiPanelPlayerVote:SetVisible(isVisible)
	self.GameObject:SetActiveEx(isVisible)
end

function XUiPanelPlayerVote:SetBtnVoteVisible(isVisible)
	self.BtnPoll.gameObject:SetActiveEx(isVisible)
end

function XUiPanelPlayerVote:PlayAnimation()
	local isSkip = XSaveTool.GetData(string.format("%s_%s",XMoeWarConfig.SKIP_KEY_PREFIX,XPlayer.Id)) or false
	if isSkip then return end
	if XTool.UObjIsNil(self.TxtAllNumber) then
		if self.Timer then
			CS.XScheduleManager.UnSchedule(self.Timer)
		end
		return
	end
	local data = XDataCenter.MoeWarManager.GetScreenRecordByPlayerId(self.PlayerId)
	if not data then return end
	local grid = self.AnimationGridList[self.AnimationIndex % MAX_ANIMATION_NUMBER]
	if not grid then
		local obj = CS.UnityEngine.GameObject.Instantiate(self.GridPollOther,self.PanelOther)
		grid = {}
		grid.Transform = obj
		grid.GameObject = obj.gameObject
		grid.TxtName = obj.transform:Find("TxtName"):GetComponent("Text")
		grid.TxtNumber = obj.transform:Find("TxtNumber"):GetComponent("Text")
		grid.PlayableDirector = obj:GetComponent("PlayableDirector")
		self.AnimationGridList[self.AnimationIndex % MAX_ANIMATION_NUMBER] = grid
	end
	self.AnimationIndex = self.AnimationIndex % MAX_ANIMATION_NUMBER
	grid.Transform:SetAsLastSibling()
	grid.GameObject:SetActiveEx(false)
	grid.GameObject:SetActiveEx(true)
	grid.TxtName.text = data.PlayerName
	grid.TxtNumber.text = data.Vote
	grid.PlayableDirector:Play()
	if self.CurrCD <= 0 then
		self.CurrCD = self.ColdDown
		XEventManager.DispatchEvent(XEventId.EVENT_MOE_WAR_PLAY_SCREEN_RECORD_ANIMATION,self.PlayerId)
	end
end

function XUiPanelPlayerVote:PlayVoteChangeEffect()
	self.MyVoteChangeEffect.gameObject:SetActiveEx(false)
	self.MyVoteChangeEffect.gameObject:SetActiveEx(true)
end

function XUiPanelPlayerVote:ResetEffect()
	self.MyVoteChangeEffect.gameObject:SetActiveEx(false)
end

function XUiPanelPlayerVote:ClearBulletCache()
	for i = 1,#self.AnimationGridList do
		CS.UnityEngine.GameObject.Destroy(self.AnimationGridList[i].GameObject)
	end
	self.AnimationGridList = {}
end

return XUiPanelPlayerVote