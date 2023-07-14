local XUiMoeWarVote = XLuaUiManager.Register(XLuaUi, "UiMoeWarVote")
local XUiPanelPlayerVote = require("XUi/XUiMoeWar/SubPage/XUiPanelPlayerVote")
local tableInsert = table.insert
local Vector2 = CS.UnityEngine.Vector2
local TipTextContentPos = {[1] = Vector2(0,231),[2] = Vector2(-260,231),[3] = Vector2(460,231)}
local TipTextContentPosL = {[1] = Vector2(0,231),[2] = Vector2(-600,231),[3] = Vector2(0,231),[4] = Vector2(600,231)}

function XUiMoeWarVote:OnStart(defaultSelectIndex)
    if defaultSelectIndex then
		self.SelectIndex = self:ConvertIndexToSelectIndex(defaultSelectIndex)
	else
		self.SelectIndex = self:ConvertIndexToSelectIndex(XDataCenter.MoeWarManager.GetDefaultSelect())
	end
	self.IsPlayAnimation = false
	if self:IsFinalSession() and XDataCenter.MoeWarManager.GetCurMatch():GetType() == XMoeWarConfig.MatchType.Publicity then
		self.IsSkip = false
	else
		self.IsSkip = XDataCenter.MoeWarManager.IsSelectSkip()
	end
	if self.IsSkip then self.BtnShield:SetButtonState(CS.UiButtonState.Select) end
    self.BtnTabGoList = {}
    self.BtnObjDic = {}
    self:RegisterButtonEvent()
    self:InitSceneRoot()
    self:InitVotePanel()
	self.LastMatchType = XDataCenter.MoeWarManager.GetCurMatch():GetSessionId()
    self.PairList = XDataCenter.MoeWarManager.GetCurMatch():GetPairList()
    self:InitButtonGroup()
    self:UpdateMatchName()
    self:UpdatePanelState()
    self:UpdateMatchTime()
	if self.PanelSpecialTool then
		self.ActInfo = XDataCenter.MoeWarManager.GetActivityInfo()
		self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
		self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
		for i = 1,#self.ActInfo.CurrencyId do
			XDataCenter.ItemManager.AddCountUpdateListener(self.ActInfo.CurrencyId[i], function()
					self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
				end, self.AssetActivityPanel)
		end
	end
    self.BtnRank:SetName(CS.XTextManager.GetText("MoeWarRankName"))
    self.BtnRole:SetName(CS.XTextManager.GetText("MoeWarIntroduceName"))
    self.BtnSchedule:SetName(CS.XTextManager.GetText("MoeWarGameName"))
	XEventManager.AddEventListener(XEventId.EVENT_MOE_WAR_PLAY_SCREEN_RECORD_ANIMATION,self.PlayScreenRecordAnimation,self)
    self.AfterHandler = function(evt,ui) self:AfterUiOpen(ui) end
end

function XUiMoeWarVote:OnEnable()
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE,self.AfterHandler)
    XLuaUiManager.Remove("UiMoeWarGroupList")
    self.PairList = XDataCenter.MoeWarManager.GetCurMatch():GetPairList()
    self:PlaySwitchAnimation()
    self:UpdateAllPanel()
    self:StartTimer()
end

function XUiMoeWarVote:OnDisable()
    if self.PlayingCv then
        self.PlayingCv:Stop()
    end
    if self.AnimationTimer then
        self.IsPlayAnimation = false
        CS.XScheduleManager.UnSchedule(self.AnimationTimer)
    end
    self:StopTimer()
    self:ClearPanelBulletCache()
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE,self.AfterHandler)
end

function XUiMoeWarVote:OnDestroy()
	XEventManager.RemoveEventListener(XEventId.EVENT_MOE_WAR_PLAY_SCREEN_RECORD_ANIMATION,self.PlayScreenRecordAnimation,self)
end

function XUiMoeWarVote:OnGetEvents()
	return {
		XEventId.EVENT_MOE_WAR_UPDATE,
		XEventId.EVENT_MOE_WAR_PLAY_THANK_ANIMATION,
		XEventId.EVENT_MOE_WAR_VOTE_PANEL_UPDATE,
		XEventId.EVENT_MOE_WAR_ACTIVITY_END,
	}
end

function XUiMoeWarVote:OnNotify(event, ...)
	local args = { ... }
	if event == XEventId.EVENT_MOE_WAR_UPDATE then
		local match = XDataCenter.MoeWarManager.GetCurMatch()
		self.PairList = match:GetPairList()
        if self:CheckIsNeedPop() then return end
        self:UpdateAllPanel()
        if match:GetType() == XMoeWarConfig.MatchType.Publicity then
            XLuaUiManager.Close("UiMoeWarPollTips")
            local saveKey
            if match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1 then
                saveKey = string.format("%s_%s_%d_%d","MOE_WAR_VOTE_ANIMATION_RECORD",tostring(XPlayer.Id),match:GetSessionId(),1)
            else
                saveKey = string.format("%s_%s_%d_%d","MOE_WAR_VOTE_ANIMATION_RECORD",tostring(XPlayer.Id),match:GetSessionId(),self:ConvertSelectIndexToIndex(self.SelectIndex))
            end
            if saveKey then XSaveTool.SaveData(saveKey,1) end
            self:PlayRunAnimation(self.IsSkip)
        end
	elseif event == XEventId.EVENT_MOE_WAR_PLAY_THANK_ANIMATION then
		self:PlayThankAnimation(args[1])
	elseif event == XEventId.EVENT_MOE_WAR_VOTE_PANEL_UPDATE then
		self:UpdateAllPanel()
	elseif event == XEventId.EVENT_MOE_WAR_ACTIVITY_END then
		XUiManager.TipText("MoeWarActivityOver")
		XLuaUiManager.RunMain()
	end
end

function XUiMoeWarVote:AfterUiOpen(ui)
    if ui then
        if ui[0].UiData.UiName ~= self.Name then
            return
        end
    end
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if match:GetType() == XMoeWarConfig.MatchType.Publicity and match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1 then
        local saveKey = string.format("%s_%s_%d_%d", XMoeWarConfig.MOE_WAR_VOTE_ANIMATION_RECORD, tostring(XPlayer.Id), match:GetSessionId(), 1)
        local isShow = XSaveTool.GetData(saveKey)
        if not isShow then
            self:PlayRunAnimation(self.IsSkip)
            XSaveTool.SaveData(saveKey, 1)
        else
            self:PlayWinnerAnimation()
        end
    elseif match:GetType() == XMoeWarConfig.MatchType.Publicity then
        local saveKey = string.format("%s_%s_%d_%d", XMoeWarConfig.MOE_WAR_VOTE_ANIMATION_RECORD, tostring(XPlayer.Id), match:GetSessionId(), self:ConvertSelectIndexToIndex(self.SelectIndex))
        local isShow = XSaveTool.GetData(saveKey)
        if not isShow then
            self:PlayRunAnimation(self.IsSkip)
            XSaveTool.SaveData(saveKey, 1)
        else
            self:PlayWinnerAnimation()
        end
    end
    self:CheckIsNeedPop()
end

function XUiMoeWarVote:PlayModelAnimation(playerEntity,playerModel,type)
    self.IsPlayAnimation = true
    playerModel:PlayAnima(playerEntity:GetAnim(type))
    --self.PlayingCv = XSoundManager.PlaySoundByType(playerEntity:GetCv(type),XSoundManager.SoundType.CV)
    --海外萌战由于语音不全所以屏蔽语音加入显示弹幕
    self.content = XFavorabilityConfigs.GetCvContent(playerEntity:GetCv(type))
    self.TxtContent.text = self.content
    self.PanelLayout.gameObject:SetActiveEx(true)
    self:SetTextContentPosWithId(playerEntity.Id)
    if self.AnimationTimer then
        CS.XScheduleManager.UnSchedule(self.AnimationTimer)
    end
    self.AnimationTimer = CS.XScheduleManager.ScheduleOnce(function()
        self.IsPlayAnimation = false
        self.PanelLayout.gameObject:SetActiveEx(false)
    end,math.floor(playerEntity:GetLength(type) * 1000))
end

function XUiMoeWarVote:PlayThankAnimation(playerId)
    local playerModel = self:GetPlayAnimationPlayer(playerId)
    local playerEntity = XDataCenter.MoeWarManager.GetPlayer(playerId)
    local panelList = self:IsFinalSession() and self.ThreeVotePanel or self.TwoVotePanel
    for i = 1, #panelList do
        panelList[i]:PlayVoteChangeEffect()
    end
    self:PlayModelAnimation(playerEntity, playerModel, XMoeWarConfig.ActionType.Thank)
end

function XUiMoeWarVote:PlayRunAnimation(isSkip)
	if isSkip then return end
	if self:IsFinalSession() then
		if self.PairList[1] then
			XDataCenter.MoeWarManager.EnterAnimation(self.PairList[1])
		end
	else
		local realIndex = self:ConvertSelectIndexToIndex(self.SelectIndex)
		if self.PairList[realIndex] then
			XDataCenter.MoeWarManager.EnterAnimation(self.PairList[realIndex])
		end
	end
end

function XUiMoeWarVote:PlayScreenRecordAnimation(playerId)
	if self.IsPlayAnimation then return end
	local playerModel = self:GetPlayAnimationPlayer(playerId)
	local playerEntity = XDataCenter.MoeWarManager.GetPlayer(playerId)
	playerModel:PlayAnima(playerEntity:GetAnim(XMoeWarConfig.ActionType.Thank))
end

function XUiMoeWarVote:PlayWinnerAnimation()
	local playerModel,playerEntity,pairConfig
	if not self:IsFinalSession() then
		pairConfig = self.PairList[self:ConvertSelectIndexToIndex(self.SelectIndex)]
	else
		pairConfig = self.PairList[1]
	end
	if not pairConfig then return end
    if self.EffectVictory then
        self.EffectVictory.gameObject:SetActiveEx(false)
        self.EffectVictory.gameObject:SetActiveEx(true)
    end
	playerEntity = XDataCenter.MoeWarManager.GetPlayer(pairConfig.WinnerId)
	for i = 1, #pairConfig.Players do
		if pairConfig.Players[i] == pairConfig.WinnerId then
			if self:IsFinalSession() then
				playerModel = self.ThreeCharacterModel[i]
			else
				playerModel = self.TwoCharacterModel[i]	
			end
		end
	end
	
	if not playerModel then return end
    self:PlayModelAnimation(playerEntity,playerModel,XMoeWarConfig.ActionType.Thank)
end

function XUiMoeWarVote:OnClickBtnShield()
	self.IsSkip = self.BtnShield:GetToggleState()
    XDataCenter.MoeWarManager.SetIsSelectSkip(self.IsSkip)
    XDataCenter.MoeWarManager.ClearAllScreenRecord()
end

function XUiMoeWarVote:OnClickPlayRecord()
	self:PlayRunAnimation(false)
end

function XUiMoeWarVote:OnClickRankList()
    XLuaUiManager.Open("UiMoeWarRankingList")
end

function XUiMoeWarVote:OnClickBtnRole()
    XLuaUiManager.Open("UiMoeWarMessage")
end

function XUiMoeWarVote:OnClickBtnSchedule()
    XLuaUiManager.Open("UiMoeWarSchedule",self:GetCurrSelectGroup(self.SelectIndex))
end

function XUiMoeWarVote:OnClickModel(eventData,index)
	if self.IsPlayAnimation then return end
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    local playerEntity,playerModel
    if match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1 then
        local playerId = match:GetPairList()[1].Players[index]
        playerEntity = XDataCenter.MoeWarManager.GetPlayer(playerId)
        playerModel = self.ThreeCharacterModel[index]
    else
        local realIndex = self:ConvertSelectIndexToIndex(self.SelectIndex)
        local playerId = self.PairList[realIndex].Players[index]
        playerEntity = XDataCenter.MoeWarManager.GetPlayer(playerId)
        playerModel = self.TwoCharacterModel[index]
    end
    if playerEntity and playerModel then
        self:PlayModelAnimation(playerEntity,playerModel,XMoeWarConfig.ActionType.Intro)
    end
end

function XUiMoeWarVote:SetTextContentPosWithId(curPlayerId)
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    local index = 0
    local pos = nil
    if match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1 then
        pos = TipTextContentPosL
        for i = 1, 3 do
            local playerId = match:GetPairList()[1].Players[i]
            if playerId == curPlayerId then
                index = i
                break
            end
        end
    else
        pos = TipTextContentPos
        local realIndex = self:ConvertSelectIndexToIndex(self.SelectIndex)
        for i = 1, 2 do
            local playerId = self.PairList[realIndex].Players[i]
            if playerId == curPlayerId then
                index = i
                break
            end
        end
    end
    index = index + 1
    if pos then
        if pos[index] then
            self.PanelChat.anchoredPosition = pos[index]
        else
            self.PanelChat.anchoredPosition = pos[1]
        end
    else
        self.PanelChat.anchoredPosition = TipTextContentPos[1]
    end
end

function XUiMoeWarVote:RegisterButtonEvent()
    self.BtnBack.CallBack = function()
        XLuaUiManager.Close("UiMoeWarVote")
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnRank.CallBack = function()
        self:OnClickRankList()
    end
    self.BtnRole.CallBack = function()
        self:OnClickBtnRole()
    end
    self.BtnSchedule.CallBack = function()
        self:OnClickBtnSchedule()
    end
    self.BtnVideo.CallBack = function() 
        self:OnClickPlayRecord()
    end
	self.BtnShield.CallBack = function()
		self:OnClickBtnShield()
	end
    if self.BtnHelp then
        local voteHelpId = XMoeWarConfig.GetVoteHelpId()
        self.BtnHelp.CallBack = function ()
            if voteHelpId > 0 then
                local template = XHelpCourseConfig.GetHelpCourseTemplateById(voteHelpId)
                XUiManager.ShowHelpTip(template.Function)
            end
        end
        self.BtnHelp.gameObject:SetActiveEx(voteHelpId > 0)
    end
end

function XUiMoeWarVote:InitVotePanel()
    self.TwoVotePanel = {}
    self.TwoVoteResultImgList = {}
    for i = 1, 2 do
        local panel = XUiPanelPlayerVote.New(self.Panel01:FindTransform("PanelVote" .. i).gameObject)
        tableInsert(self.TwoVotePanel, panel)
        local img = self.Panel01:FindTransform("ImgIconResult"..i):GetComponent("Image")
        tableInsert(self.TwoVoteResultImgList,img)
    end
    self.ThreeVotePanel = {}
    self.ThreeVoteResultImgList = {}
    for i = 1, 3 do
        local panel = XUiPanelPlayerVote.New(self.Panel02:FindTransform("PanelVote" .. i).gameObject)
        tableInsert(self.ThreeVotePanel, panel)
        local img = self.Panel02:FindTransform("ImgIconResult"..i):GetComponent("Image")
        tableInsert(self.ThreeVoteResultImgList,img)
    end
end

function XUiMoeWarVote:InitButtonGroup()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if not match or match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1 then
        return
    end
    self.PairList = match:GetPairList()
    local groups = XDataCenter.MoeWarManager.GetActivityInfo()
    local currParentIndex = 0
    for i = 1, #(groups.GroupName) do
        local children = match:GetPairListByGroupId(i)
        local obj = CS.UnityEngine.GameObject.Instantiate(self.BtnFirst, self.PanelTitleBtnContent)
        ---@type XUiComponent.XUiButton
        local btnComponent = obj:GetComponent("XUiButton")
        btnComponent:SetNameByGroup(1, groups.GroupName[i])
        btnComponent:SetNameByGroup(2, groups.GroupSecondName[i])
        currParentIndex = #self.BtnTabGoList + 1
        tableInsert(self.BtnTabGoList, btnComponent)
        for j = 1, #children do
			local currIndex = (i - 1)*#children + j
			local childObj = nil
			if self.BtnObjDic[currIndex] then
				childObj = self.BtnObjDic[currIndex]
			else
            	childObj = CS.UnityEngine.GameObject.Instantiate(self.BtnChild, self.PanelTitleBtnContent)
				self.BtnObjDic[currIndex] = childObj
			end
            ---@type XUiComponent.XUiButton
            local childBtnComponent = childObj:GetComponent("XUiButton")
            childBtnComponent.SubGroupIndex = currParentIndex

            tableInsert(self.BtnTabGoList, childBtnComponent)
            local playerA = XDataCenter.MoeWarManager.GetPlayer(children[j].Players[1])
            local playerB = XDataCenter.MoeWarManager.GetPlayer(children[j].Players[2])
            local imgLeftHead = childObj.transform:Find("Head1/StandIcon"):GetComponent("RawImage")
            local imgRightHead = childObj.transform:Find("Head2/StandIcon"):GetComponent("RawImage")
            imgLeftHead:SetRawImage(playerA:GetCircleHead())
            imgRightHead:SetRawImage(playerB:GetCircleHead())
            if match:GetType() == XMoeWarConfig.MatchType.Publicity then
                local imgLeftLose = childObj.transform:Find("Head1/ImgLose")
                local imgRightLose = childObj.transform:Find("Head2/ImgLose")
                imgLeftLose.gameObject:SetActiveEx(children[j].WinnerId ~= children[j].Players[1])
                imgRightLose.gameObject:SetActiveEx(children[j].WinnerId ~= children[j].Players[2])
            end
        end
    end
	
	for i = 1, #(groups.GroupName) do
		local children = match:GetPairListByGroupId(i)
		for j = #children + 1, (#self.BtnTabGoList / 3) - 1 do
			local currIndex = (i - 1) * #children + j + i
			if self.BtnObjDic[currIndex] then
				self.BtnObjDic[currIndex].gameObject:SetActiveEx(false)
			end
		end
	end
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnChild.gameObject:SetActiveEx(false)
    self.PanelTitleBtnGroup:Init(self.BtnTabGoList, function(index)
        self:OnSelectToggle(index)
    end)
    self.PanelTitleBtnGroup:SelectIndex(self.SelectIndex)
end

function XUiMoeWarVote:OnSelectToggle(index)
    self.SelectIndex = index
    local realIndex = self:ConvertSelectIndexToIndex(index)
    self:UpdateCurrModel(realIndex)
    self:UpdateVotePanel(realIndex)
    self.PanelLayout.gameObject:SetActiveEx(false)
    local match = XDataCenter.MoeWarManager.GetCurMatch()
	self:PlaySwitchAnimation()
    if match:GetType() == XMoeWarConfig.MatchType.Publicity then
        local saveKey = string.format("%s_%s_%d_%d","MOE_WAR_VOTE_ANIMATION_RECORD",tostring(XPlayer.Id),match:GetSessionId(),realIndex)
        local data = XSaveTool.GetData(saveKey)
        if not data then
			if not self.IsSkip then
            	XDataCenter.MoeWarManager.EnterAnimation(self.PairList[realIndex])
			else
				self:PlayWinnerAnimation()	
			end
            XSaveTool.SaveData(saveKey, 1)
		else
			self:PlayWinnerAnimation()
        end
        self:UpdateResultIcon()
    end
end

function XUiMoeWarVote:InitSceneRoot()
    local root = self.UiModelGo.transform
    self.TwoCharacterPanel = root:FindTransform("Panel01")
    self.ThreeCharacterPanel = root:FindTransform("Panel02")
    self.TwoCharacterTransform = {}
    self.TwoCharacterModel = {}
    self.TwoCharacterEffect = {}
    self.TwoCharacterTransform[1] = self.TwoCharacterPanel:FindTransform("PanelModelCase1")
    self.TwoCharacterTransform[2] = self.TwoCharacterPanel:FindTransform("PanelModelCase2")
    for i = 1, #self.TwoCharacterTransform do
        self.TwoCharacterEffect[i] = self.TwoCharacterPanel:Find("PanelModelCase"..i.."/ImgEffectHuanren1").gameObject
        self.TwoCharacterModel[i] = XUiPanelRoleModel.New(self.TwoCharacterTransform[i], self.Name, nil, true, nil, true)
        local inputHandler = self.TwoCharacterTransform[i]:GetComponent(typeof(CS.XGoInputHandler))
        if not inputHandler then
            inputHandler = self.TwoCharacterTransform[i].gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
        local index = i
        inputHandler:AddPointerClickListener(function(eventData)
            self:OnClickModel(eventData,index)
        end)
    end
    self.ThreeCharacterTransform = {}
    self.ThreeCharacterModel = {}
    self.ThreeCharacterEffect = {}
    self.ThreeCharacterTransform[1] = self.ThreeCharacterPanel:FindTransform("PanelModelCase1")
    self.ThreeCharacterTransform[2] = self.ThreeCharacterPanel:FindTransform("PanelModelCase2")
    self.ThreeCharacterTransform[3] = self.ThreeCharacterPanel:FindTransform("PanelModelCase3")
    for i = 1, #self.ThreeCharacterTransform do
        self.ThreeCharacterEffect[i] = self.ThreeCharacterPanel:Find("PanelModelCase"..i.."/ImgEffectHuanren1").gameObject
        self.ThreeCharacterModel[i] = XUiPanelRoleModel.New(self.ThreeCharacterTransform[i], self.Name, nil, true, nil, true)
        local inputHandler = self.ThreeCharacterTransform[i]:GetComponent(typeof(CS.XGoInputHandler))
        if not inputHandler then
            inputHandler = self.ThreeCharacterTransform[i].gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
        local index = i
        inputHandler:AddPointerClickListener(function(eventData)
            self:OnClickModel(eventData,index)
        end)
    end
end

function XUiMoeWarVote:UpdateAllPanel()
	self:UpdateTabGroup()
	self:UpdateVotePanel(self:ConvertSelectIndexToIndex(self.SelectIndex))
	self:UpdateMatchName()
    self:UpdatePanelState()
    self:UpdateMatchTime()
    self:UpdateResultIcon()
    self:UpdateCurrModel(self:ConvertSelectIndexToIndex(self.SelectIndex))
end

function XUiMoeWarVote:UpdateTabGroup()
	local match = XDataCenter.MoeWarManager.GetCurMatch()
	if not match or match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1 then
		return
	end
	self.PairList = match:GetPairList()
	local groups = XDataCenter.MoeWarManager.GetActivityInfo()
	local currParentIndex = 0
	for i = 1, #(groups.GroupName) do
		local children = match:GetPairListByGroupId(i)
        ---@type XUiComponent.XUiButton
		currParentIndex = #self.BtnTabGoList + 1
		for j = 1, #children do
			local currIndex = (i - 1)*#children + j
			local childObj = nil
			if self.BtnObjDic[currIndex] then
				childObj = self.BtnObjDic[currIndex]
			else
				childObj = CS.UnityEngine.GameObject.Instantiate(self.BtnChild, self.PanelTitleBtnContent)
				self.BtnObjDic[currIndex] = childObj
			end
			self:UpdatePairGroup(children[j],childObj)
		end
	end
end

function XUiMoeWarVote:UpdatePairGroup(pairConfig,obj)
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    local playerA = XDataCenter.MoeWarManager.GetPlayer(pairConfig.Players[1])
    local playerB = XDataCenter.MoeWarManager.GetPlayer(pairConfig.Players[2])
    local imgLeftHead = obj.transform:Find("Head1/StandIcon"):GetComponent("RawImage")
    local imgRightHead = obj.transform:Find("Head2/StandIcon"):GetComponent("RawImage")
    imgLeftHead:SetRawImage(playerA:GetCircleHead())
    imgRightHead:SetRawImage(playerB:GetCircleHead())
    if match:GetType() == XMoeWarConfig.MatchType.Publicity then
        local imgLeftLose = obj.transform:Find("Head1/ImgLose")
        local imgRightLose = obj.transform:Find("Head2/ImgLose")
        imgLeftLose.gameObject:SetActiveEx(pairConfig.WinnerId ~= pairConfig.Players[1])
        imgRightLose.gameObject:SetActiveEx(pairConfig.WinnerId ~= pairConfig.Players[2])
    end
end

function XUiMoeWarVote:UpdateCurrModel(index)
    if self:IsFinalSession() then
        for _, pairInfo in pairs(self.PairList) do
            for i = 1, #(pairInfo.Players) do
                local playerEntity = XDataCenter.MoeWarManager.GetPlayer(pairInfo.Players[i])
                self.ThreeCharacterModel[i]:UpdateRoleModel(playerEntity:GetModel(), self.ThreeCharacterTransform[i], XModelManager.MODEL_UINAME.XUiMoeWarVote, function(model)
                    model.gameObject:SetActiveEx(true)
                    local animator = model:GetComponent("Animator")
                    animator.applyRootMotion = false
                end,nil, true, true)
            end
        end
    else
        local pairConfig = self.PairList[index]
        local leftPlayer = XDataCenter.MoeWarManager.GetPlayer(pairConfig.Players[1])
        local rightPlayer = XDataCenter.MoeWarManager.GetPlayer(pairConfig.Players[2])
        self.TwoCharacterModel[1]:UpdateRoleModel(leftPlayer:GetModel(), self.TwoCharacterTransform[1], XModelManager.MODEL_UINAME.XUiMoeWarVote,function(model)
            model.gameObject:SetActiveEx(true)
            local animator = model:GetComponent("Animator")
            animator.applyRootMotion = false
        end, nil, true, true)
        self.TwoCharacterModel[2]:UpdateRoleModel(rightPlayer:GetModel(), self.TwoCharacterTransform[2], XModelManager.MODEL_UINAME.XUiMoeWarVote,function(model)
            model.gameObject:SetActiveEx(true)
            local animator = model:GetComponent("Animator")
            animator.applyRootMotion = false
        end, nil, true, true)
    end
end

function XUiMoeWarVote:UpdateVotePanel(index)
    if self:IsFinalSession() then
        for i = 1, #self.PairList do
            for j = 1, #(self.PairList[i].Players) do
                self.ThreeVotePanel[j]:Refresh(self.PairList[i].Players[j])
            end
        end
    else
        local pairConfig = self.PairList[index]
        for i = 1, #(pairConfig.Players) do
            self.TwoVotePanel[i]:Refresh(pairConfig.Players[i])
        end
    end
end

function XUiMoeWarVote:UpdateResultIcon()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if match:GetType() ~= XMoeWarConfig.MatchType.Publicity then
        return
    end
    local iconList = XMoeWarConfig.GetIconList(match:GetSessionId())
    if self:IsFinalSession() then
        local pairList = match:GetPairList()
        for i = 1,#pairList do
            for j = 1,#(pairList[i].Players) do
                if pairList[i].Players[j] == pairList[i].WinnerId then
                    self:SetUiSprite(self.ThreeVoteResultImgList[j],iconList[1])
                elseif pairList[i].Players[j] == pairList[i].SecondId then
                    self:SetUiSprite(self.ThreeVoteResultImgList[j],iconList[2])
                else
                    self:SetUiSprite(self.ThreeVoteResultImgList[j],iconList[3])
                end
            end
        end
    else
        local index = self:ConvertSelectIndexToIndex(self.SelectIndex)
        local pair = self.PairList[index]
        for i = 1, #(pair.Players) do
            if pair.Players[i] == pair.WinnerId then
                self:SetUiSprite(self.TwoVoteResultImgList[i],iconList[1])
                self.TwoVoteResultImgList[i].gameObject:SetActiveEx(true)
            else
                self.TwoVoteResultImgList[i].gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiMoeWarVote:UpdatePanelState()
    self.Panel01.gameObject:SetActiveEx(not self:IsFinalSession())
    self.Panel02.gameObject:SetActiveEx(self:IsFinalSession())
    self.TwoCharacterPanel.gameObject:SetActiveEx(not self:IsFinalSession())
    self.ThreeCharacterPanel.gameObject:SetActiveEx(self:IsFinalSession())
	local match = XDataCenter.MoeWarManager.GetCurMatch()
	local type = match:GetType()
	self.BtnShield.gameObject:SetActiveEx(not (self:IsFinalSession() and type == XMoeWarConfig.MatchType.Publicity))
	self.BtnShield:SetName(type == XMoeWarConfig.MatchType.Publicity and CS.XTextManager.GetText("MoeWarSkipAnimation") or CS.XTextManager.GetText("MoeWarSkipGift"))
    self.BtnVideo.gameObject:SetActiveEx(type == XMoeWarConfig.MatchType.Publicity)
	for i = 1, #self.TwoVoteResultImgList do
		self.TwoVoteResultImgList[i].gameObject:SetActiveEx(type == XMoeWarConfig.MatchType.Publicity)
	end
	for i = 1, #self.ThreeVoteResultImgList do
		self.ThreeVoteResultImgList[i].gameObject:SetActiveEx(type == XMoeWarConfig.MatchType.Publicity)
	end
end

function XUiMoeWarVote:UpdateMatchName()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if match then
        self.TxtTitle.text = match:GetName()
    end
	if self.RImgIcon then
		local desc = match:GetDesc()
		self.RImgIcon:SetRawImage(match:GetCoverImg())
        if  match:GetType() == XMoeWarConfig.MatchType.Publicity and match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1 then
            self.TxtRefresh.text = match:GetDesc()[3]
            self.TxtTimeTitle.gameObject:SetActiveEx(false)
            self.TxtTime.gameObject:SetActiveEx(false)
            self.RImgIcon:SetRawImage(match:GetFinalImg())
        else
            self.TxtRefresh.text = match:GetRefreshVoteText()
            self.TxtTimeTitle.gameObject:SetActiveEx(true)
        end
		self.TxtTimeTitle.text = desc[2]
	end
end

function XUiMoeWarVote:UpdateMatchTime()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if not match then
        return
    end
    local endTime = match:GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    local offset = endTime - now
    if XDataCenter.MoeWarManager.IsInStatistics() then
        self.TxtRefresh.text = CS.XTextManager.GetText("MoeWarMatchVoteNoResult")
        self.TxtTimeTitle.gameObject:SetActiveEx(false)
    else self.TxtTime.text = XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.CHALLENGE)
    end
end

function XUiMoeWarVote:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self.Timer = CS.XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtTime) then
            self:StopTimer()
            return
        end
		self:UpdateVotePanel(self:ConvertSelectIndexToIndex(self.SelectIndex))
        self:UpdateMatchTime()
    end, CS.XScheduleManager.SECOND, 0)
end

function XUiMoeWarVote:StopTimer()
    if self.Timer then
        CS.XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMoeWarVote:ConvertIndexToSelectIndex(index)
    return math.ceil(index / XDataCenter.MoeWarManager.GetMatchPerGroupCount()) + index
end

function XUiMoeWarVote:ConvertSelectIndexToIndex(index)
    return index - math.ceil(index / (XDataCenter.MoeWarManager.GetMatchPerGroupCount() + 1))
end

function XUiMoeWarVote:GetCurrSelectGroup(selectIndex)
	local realIndex = self:ConvertSelectIndexToIndex(selectIndex)
	return math.ceil(realIndex / XDataCenter.MoeWarManager.GetMatchPerGroupCount())
end

function XUiMoeWarVote:IsFinalSession()
    local match = XDataCenter.MoeWarManager.GetCurMatch()
    if not match then
        return false
    end
    return match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1
end

function XUiMoeWarVote:GetPlayAnimationPlayer(playerId)
	if self:IsFinalSession() then
		for i = 1, #self.PairList do
			for j = 1, #(self.PairList[i].Players) do
				if self.PairList[i].Players[j] == playerId then
					return self.ThreeCharacterModel[j]
				end
			end
		end
	else
		local pairConfig = self.PairList[self:ConvertSelectIndexToIndex(self.SelectIndex)]
		for i = 1, #(pairConfig.Players) do
			if pairConfig.Players[i] == playerId then
				return self.TwoCharacterModel[i]
			end
		end
	end
end

function XUiMoeWarVote:PlaySwitchAnimation()
	local match = XDataCenter.MoeWarManager.GetCurMatch()
	local sessionId = match:GetSessionId()
	local animName = sessionId == XMoeWarConfig.SessionType.Game3In1 and "Panel02QieHuan" or "Panel01QieHuan"
    local effects = sessionId == XMoeWarConfig.SessionType.Game3In1 and self.ThreeCharacterEffect or self.TwoCharacterEffect
    for i = 1, #effects do
        effects[i]:SetActiveEx(false)
        effects[i]:SetActiveEx(true)
    end
	self:PlayAnimation(animName)
end

function XUiMoeWarVote:CheckIsNeedPop()
	local match = XDataCenter.MoeWarManager.GetCurMatch()
	if match:GetSessionId() ~= self.LastMatchType then
		XUiManager.TipText("MoeWarMatchEnd")
		XLuaUiManager.Close("UiMoeWarVote")
		XLuaUiManager.Close("UiMoeWarPollTips")
        return true
	else
		self.LastMatchType = match:GetSessionId()
        return false
	end
end

function XUiMoeWarVote:ClearPanelBulletCache()
    for i = 1,#self.TwoVotePanel do
        self.TwoVotePanel[i]:ClearBulletCache()
    end

    for i = 1,#self.ThreeVotePanel do
        self.ThreeVotePanel[i]:ClearBulletCache()
    end
end

return XUiMoeWarVote