
local ButtonStateNormal = CS.UiButtonState.Normal
local ButtonStateSelect = CS.UiButtonState.Select
local ButtonStateDisable = CS.UiButtonState.Disable
local CSXTextManagerGetText = CS.XTextManager.GetText
local MaxMatchCount = 4

local XUiMoeWarMain = XLuaUiManager.Register(XLuaUi, "UiMoeWarMain")

function XUiMoeWarMain:OnStart()
    self:RegisterButtonEvent()
    self:InitRedPoint()
	self:InitUi()
end

function XUiMoeWarMain:OnEnable()
	self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
    self:StartTimer()
    self:RefreshPreparation()
    self:RefreshVotePanel()
    self:CheckRedPoint()
end

function XUiMoeWarMain:OnDisable()
    self:StopTimer()
end

function XUiMoeWarMain:OnGetEvents()
    return {
        XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE,
		XEventId.EVENT_MOE_WAR_UPDATE,
    }
end

function XUiMoeWarMain:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE then
        self:RefreshPreparation()
	elseif event == XEventId.EVENT_MOE_WAR_UPDATE then
		self:RefreshVotePanel()
    end
end

function XUiMoeWarMain:InitRedPoint()
    self.BtnPrepareRedPointEventId = XRedPointManager.AddRedPointEvent(self.BtnPrepare, self.OnPrepareRedPointEvent, self, { XRedPointConditions.Types.CONDITION_MOEWAR_PREPARATION })
    XRedPointManager.AddRedPointEvent(self.BtnTask,self.OnTaskRedPointEvent,self,{XRedPointConditions.Types.CONDITION_MOEWAR_TASK})
    XRedPointManager.AddRedPointEvent(self.BtnReward,self.OnGachaRedPointEvent,self,{XRedPointConditions.Types.CONDITION_MOEWAR_DRAW})
end

function XUiMoeWarMain:InitUi()
	self.TxtName.text = XMoeWarConfig.GetActivityName()
	self.ActInfo = XDataCenter.MoeWarManager.GetActivityInfo()
	self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
	for i = 1,#self.ActInfo.CurrencyId do
		XDataCenter.ItemManager.AddCountUpdateListener(self.ActInfo.CurrencyId[i], function()
				self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
			end, self.AssetActivityPanel)
	end

	self.ItemGridList = {}
    local showItems = XMoeWarConfig.GetShowItems()
	for i = 1,#showItems do
		if self.ItemGrid then
			local obj = CS.UnityEngine.GameObject.Instantiate(self.ItemGrid,self.ItemContent)
			local grid = XUiGridCommon.New(self,obj)
			local itemTemplate = XDataCenter.ItemManager.GetItemTemplate(showItems[i])
			table.insert(self.ItemGridList,grid)
			grid:Refresh(itemTemplate)
		end
	end
	if self.ItemGrid then
		self.ItemGrid.gameObject:SetActiveEx(false)
	end
	self.BtnVote:SetName(CS.XTextManager.GetText("MoeWarGoVote"))
	self.BtnRank:SetName(CS.XTextManager.GetText("MoeWarRankName"))
	self.BtnRole:SetName(CS.XTextManager.GetText("MoeWarIntroduceName"))
	self.BtnSchedule:SetName(CS.XTextManager.GetText("MoeWarGameName"))
	self.BtnActivity:SetNameByGroup(0,CS.XTextManager.GetText("MoeWarWebName"))
	self.BtnActivity:SetNameByGroup(1,CS.XTextManager.GetText("MoeWarWebNameEng"))
	self.BtnReward:SetNameByGroup(0,CS.XTextManager.GetText("MoeWarRewardName"))
	self.BtnReward:SetNameByGroup(1,CS.XTextManager.GetText("MoeWarRewardNameEng"))
	self.BtnShop:SetNameByGroup(0,CS.XTextManager.GetText("MoeWarGachaName"))
	self.BtnShop:SetNameByGroup(1,CS.XTextManager.GetText("MoeWarGachaNameEng"))
	self.BtnTask:SetNameByGroup(0,CS.XTextManager.GetText("MoeWarTaskName"))
	self.BtnTask:SetNameByGroup(1,CS.XTextManager.GetText("MoeWarTaskNameEng"))
    self.TxtRewardMain = self.Transform:Find("SafeAreaContentPane/PanelAll/PanelReward/Text"):GetComponent("Text")
    if self.TxtRewardMain then
        local text = CS.XTextManager.GetText("MoeWarMainText")
        self.TxtRewardMain.text = string.gsub(text, "\\n", "\n")
    end
    self:InitBtnPrepare()
    self:RefreshActivityTime()
    self:RefreshVoteTime()
end

function XUiMoeWarMain:InitBtnPrepare()
    local preparationActivityId = XMoeWarConfig.GetPreparationActivityIdInTime()
    if not preparationActivityId then
        return
    end

    local activityName = XMoeWarConfig.GetPreparationActivityName(preparationActivityId)
    local smallTitle = CSXTextManagerGetText("MoeWarBtnPrepareSmallTitle")
    self.BtnPrepare:SetNameByGroup(0, activityName)
    self.BtnPrepare:SetNameByGroup(1, smallTitle)
end

function XUiMoeWarMain:RegisterButtonEvent()
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end

    self.BtnBack.CallBack = function()
        self:Close()
    end

    self.BtnShop.CallBack = function()
        local gachaSkipId = XMoeWarConfig.GetGachaSkipId()
        if gachaSkipId then
            XFunctionManager.SkipInterface(gachaSkipId)
        end
    end

    self.BtnActivity.CallBack = function()
        local webUrl = XMoeWarConfig.GetWebUrl()
        if webUrl then
            if string.find(webUrl, "eden") ~= nil then -- 伊甸文化跳转
                local uid = XUserManager.UserId
                local serverId = CS.XHeroBdcAgent.ServerId
                if uid and uid ~= "" then
                    if serverId and serverId ~= "" then
                        CS.UnityEngine.Application.OpenURL(webUrl.."?uid="..uid.."&serverId="..serverId)
                    else
                        CS.UnityEngine.Application.OpenURL(webUrl.."?uid="..uid)
                    end
                else
                    CS.UnityEngine.Application.OpenURL(webUrl)
                end
            else
                CS.UnityEngine.Application.OpenURL(webUrl)
            end
        end
    end

    self.BtnReward.CallBack = function()
        local rewardSkipId = XMoeWarConfig.GetRewardSkipId()
        if rewardSkipId then
            XFunctionManager.SkipInterface(rewardSkipId)
        end
    end

    self.BtnTask.CallBack = function()
        XLuaUiManager.Open("UiMoeWarTask")
    end

    self.BtnRank.CallBack = function()
        XLuaUiManager.Open("UiMoeWarRankingList")
    end

    self.BtnRole.CallBack = function()
        XLuaUiManager.Open("UiMoeWarMessage")
    end

    self.BtnSchedule.CallBack = function()
        XLuaUiManager.Open("UiMoeWarSchedule")
    end

    self.BtnPrepare.CallBack = function()
        XLuaUiManager.Open("UiMoeWarPreparation")
    end

    self.BtnVote.CallBack = function()
        self:OnClickBtnVote()
    end

    if self.BtnHelp then
        local mainHelpId = XMoeWarConfig.GetMainHelpId()
        self.BtnHelp.CallBack = function ()
            if mainHelpId > 0 then
                local template = XHelpCourseConfig.GetHelpCourseTemplateById(mainHelpId)
                XUiManager.ShowHelpTip(template.Function)
            end
        end
        self.BtnHelp.gameObject:SetActiveEx(mainHelpId > 0)
    end
end

function XUiMoeWarMain:OnClickBtnVote()
	local match = XDataCenter.MoeWarManager.GetCurMatch()
	if match:GetType() == XMoeWarConfig.MatchType.Publicity then
		local index = XDataCenter.MoeWarManager.GetDefaultSelect()
		local saveKey = string.format("%s_%s_%d_%d",XMoeWarConfig.MOE_WAR_VOTE_ANIMATION_RECORD,tostring(XPlayer.Id),match:GetSessionId(),index)
		local data = XSaveTool.GetData(saveKey)
		local isSkip = XSaveTool.GetData(string.format("%s_%s",XMoeWarConfig.SKIP_KEY_PREFIX,XPlayer.Id)) or false
		if not data and not isSkip then
			XDataCenter.MoeWarManager.EnterAnimation(match:GetPairList()[index],match,function()
				XDataCenter.MoeWarManager.OpenVotePanel(index)
                XLuaUiManager.Remove("UiMoeWarAnimation")
			end)
			XSaveTool.SaveData(saveKey,1)
		else
			XDataCenter.MoeWarManager.OpenVotePanel(index)
		end
	else
		XDataCenter.MoeWarManager.OpenVotePanel()	
	end
end

function XUiMoeWarMain:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtTime) then
            self:StopTimer()
            return
        end
        self:RefreshVoteTime()
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND, 0)
end

function XUiMoeWarMain:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMoeWarMain:RefreshVotePanel()
	local match = XDataCenter.MoeWarManager.GetCurMatch()
    if not match then return end
        local desc = match:GetDesc()
        local matchType = match:GetType()
        local session = match:GetSessionId()
        self.TxtVoteTitle.text = match:GetName()
        if matchType == XMoeWarConfig.MatchType.Publicity and session == XMoeWarConfig.SessionType.Game3In1 then
            self.Group01.gameObject:SetActiveEx(false)
            self.Group02.gameObject:SetActiveEx(true)
            local playerEntity = XDataCenter.MoeWarManager.GetPlayer(match:GetPairList()[1].WinnerId)
            self.ImgVictoryHead:SetRawImage(playerEntity:GetCircleHead())
            self.TxtVictoryName.text = playerEntity:GetName()
        else
            self.Group01.gameObject:SetActiveEx(true)
            self.Group02.gameObject:SetActiveEx(false)
            self.TxtMatchState.text = desc[1]
            self.TxtMatchDesc.text = desc[2]
		self.ImgCover:SetRawImage(match:GetCoverImg())
	end
end

function XUiMoeWarMain:RefreshVoteTime()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if not match then return end
    local endTime = match:GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
	if match:GetVoteEnd() and (not match:GetResultOut()) and match:GetType() == XMoeWarConfig.MatchType.Voting then
		self.TxtVoteTime.text = CS.XTextManager.GetText("MoeWarMatchVoteNoResult")
	else
		self.TxtVoteTime.text = XUiHelper.GetTime(offset,XUiHelper.TimeFormatType.CHALLENGE)
	end
end

function XUiMoeWarMain:RefreshActivityTime()
    local endTime = XDataCenter.MoeWarManager.GetActivityEndTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
	if offset <= 0 then
		XLuaUiManager.RunMain()
		XUiManager.TipText("MoeWarActivityOver")
		self:StopTimer()
		return
	end	
    self.TxtTime.text = XUiHelper.GetTime(offset,XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiMoeWarMain:RefreshPreparation()
    local preparationActivityId = XMoeWarConfig.GetPreparationActivityIdInTime()
    local defaultPreparationActivityId = XMoeWarConfig.GetPreparationActivityIdInTime(true)

    --活动结束时，使用最后一个结束的活动id显示
    local matchIds = defaultPreparationActivityId and XMoeWarConfig.GetPreparationActivityMatchIds(defaultPreparationActivityId) or {}
    for i = 1, MaxMatchCount do
        if matchIds[i] then
            local matchId = matchIds[i]
            local numText = XMoeWarConfig.GetPreparationMatchNumText(matchId)
            local matchState = XDataCenter.MoeWarManager.GetPreparationMatchOpenState(matchId)
            local btnState
            local lineState = ButtonStateNormal
            if matchState == XMoeWarConfig.MatchState.Open then
                btnState = ButtonStateSelect
            elseif matchState == XMoeWarConfig.MatchState.Over then
                btnState = ButtonStateDisable
                lineState = ButtonStateDisable
            else
                btnState = ButtonStateNormal
            end
            self["GridProgress" .. i]:SetNameByGroup(0, numText)
            self["GridProgress" .. i]:SetButtonState(btnState)
            self["GridProgress" .. i].gameObject:SetActiveEx(true)
            if self["Line" .. i] then
                self["Line" .. i]:SetButtonState(lineState)
                self["Line" .. i].gameObject:SetActiveEx(true)
            end
        else
            self["GridProgress" .. i].gameObject:SetActiveEx(false)
            if self["Line" .. i] then
                self["Line" .. i].gameObject:SetActiveEx(false)
            end
        end
    end

    if not preparationActivityId then
        self.BtnPrepare:SetDisable(true, false)
        self.PanelOver.gameObject:SetActiveEx(true)
        self.PanelJd.gameObject:SetActiveEx(false)
        return
    end

    if self.BtnPrepare.ButtonState == ButtonStateDisable then
        self.BtnPrepare:SetDisable(false)
    end

    local maxStageCount = XMoeWarConfig.GetPreparationActivityMaxStageCount(preparationActivityId)
    local currOpenStageCount = XDataCenter.MoeWarManager.GetPreparationAllOpenStageCount()
    self.PrepareJdTxtNumber.text = currOpenStageCount .. "/" .. maxStageCount
    self.PrepareJd.fillAmount = maxStageCount > 0 and currOpenStageCount / maxStageCount or 0
    self.PanelOver.gameObject:SetActiveEx(false)
    self.PanelJd.gameObject:SetActiveEx(true)
end

function XUiMoeWarMain:OnPrepareRedPointEvent(count)
    self.BtnPrepare:ShowReddot(count >= 0)
end

function XUiMoeWarMain:OnTaskRedPointEvent(count)
	self.BtnTask:ShowReddot(count >= 0)
end

function XUiMoeWarMain:OnGachaRedPointEvent(count)
    self.BtnShop:ShowReddot(count >= 0)
end

function XUiMoeWarMain:CheckRedPoint()
    XRedPointManager.Check(self.BtnPrepareRedPointEventId)
end