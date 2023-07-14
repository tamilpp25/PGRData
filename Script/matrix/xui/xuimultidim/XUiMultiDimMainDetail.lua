local XUiMultiDimMainDetail = XClass(nil, "XUiMultiDimMainDetail")

function XUiMultiDimMainDetail:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    
    self:RegisterUiEvents()
    self:InitView()
    self.RewardGridList = {}
    self.CareerGridList = {}
end

function XUiMultiDimMainDetail:InitView()
    self.BtnMatching.gameObject:SetActiveEx(false)
    self.Grid256New.gameObject:SetActiveEx(false)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
end

function XUiMultiDimMainDetail:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
end

--region 按钮相关

function XUiMultiDimMainDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnPreset, self.OnBtnPresetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMatch, self.OnBtnMatchClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCreateRoom, self.OnBtnCreateRoomClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDifficultySelect, self.OnBtnDifficultySelectClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBossInfo, self.OnBtnBossInfoClick)
end
-- 预设
function XUiMultiDimMainDetail:OnBtnPresetClick()
    XLuaUiManager.Open("UiMultiDimPresetRoleTip", self.StageId)
end
-- 快速匹配
function XUiMultiDimMainDetail:OnBtnMatchClick()
    self:CheckNetworkDelay(function()
        if not XDataCenter.MultiDimManager.CheckTeamIsOpen(true) then
            return
        end

        self:Match(true)
    end)
end
-- 创建房间
function XUiMultiDimMainDetail:OnBtnCreateRoomClick()
    self:CheckNetworkDelay(function()
        if not XDataCenter.MultiDimManager.CheckTeamIsOpen(true) then
            return
        end

        XLuaUiManager.Open("UiMultiDimCreateRoomTip", self.StageId)
    end)
end
-- 难度选择
function XUiMultiDimMainDetail:OnBtnDifficultySelectClick()
    XLuaUiManager.Open("UiMultiDimSelectDifficult", self.CurrentThemeId, self.CurrentDifficulty, handler(self, self.RefreshDifficulty))
end
-- 查看机制
function XUiMultiDimMainDetail:OnBtnBossInfoClick()
    XLuaUiManager.Open("UiMultiDimDetails", self.StageId)
end

function XUiMultiDimMainDetail:CheckNetworkDelay(callBack)
    -- 检测用户当前网速，若网速不佳，延迟＞100ms，出现弹窗提示
    local pingTime = XTime.GetPingTime() -- 网络延时 单位ms
    local delay = XMultiDimConfig.GetMultiDimConfigValue("NetworkDelay") -- 配置延迟时间 单位ms
    if pingTime > tonumber(delay) then
        local title = CSXTextManagerGetText("MultiDimTeamNetworkPingTitle")
        local content = CSXTextManagerGetText("MultiDimTeamNetworkPingContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal,
                nil, function()
                    if callBack then
                        callBack()
                    end
                end)
    else
        if callBack then
            callBack()
        end
    end
end

function XUiMultiDimMainDetail:SelectCareerRequest(careerId, cb)
    local difficultyInfo = XMultiDimConfig.GetMultiDimDifficultyStageData(self.StageId)
    -- 发送所选的职业
    XDataCenter.MultiDimManager.MultiDimSelectCareerRequest(difficultyInfo.Id, careerId, function()
        if cb then
            cb()
        end
    end)
end

function XUiMultiDimMainDetail:OnBeginMatch()
    self.BtnMatching.gameObject:SetActiveEx(true)
    self.BtnMatch.gameObject:SetActiveEx(false)
    self.Mask.gameObject:SetActiveEx(true)
end

function XUiMultiDimMainDetail:OnCancelMatch()
    self.BtnMatching.gameObject:SetActiveEx(false)
    self.BtnMatch.gameObject:SetActiveEx(true)
    self.Mask.gameObject:SetActiveEx(false)
end

function XUiMultiDimMainDetail:Match(needMatchCountCheck)
    XDataCenter.RoomManager.Match(self.StageId, function()
        self:OnBeginMatch()
        XLuaUiManager.Open("UiOnLineMatching")
    end, needMatchCountCheck)
end

--匹配人数过多
function XUiMultiDimMainDetail:OnMatchPlayers()
    self:OnCancelMatch()
    XUiManager.DialogTip(CS.XTextManager.GetText("MultiDimMainDetailMatchTipTitle"), CS.XTextManager.GetText("MultiDimMainDetailMatchTipContent"), XUiManager.DialogType.Normal,
            function()
                self:Match(false)
            end, function()
                --根据服务端下发的id创建房间
                XLuaUiManager.Open("UiMultiDimCreateRoomTip", self.StageId)
            end)
end

function XUiMultiDimMainDetail:RefreshDifficulty(currentDifficulty)
    self:Refresh(self.CurrentThemeId, currentDifficulty)
end

--endregion

function XUiMultiDimMainDetail:Refresh(currentThemeId, currentDifficulty)
    self.CurrentDifficulty = currentDifficulty or 1
    self.CurrentThemeId = currentThemeId
    -- 选择难度
    local difficultyInfoDetail = XDataCenter.MultiDimManager.GetDifficultyDetailInfo(self.CurrentThemeId, self.CurrentDifficulty)
    self.BtnDifficultySelect:SetNameAndColorByGroup(0, CSXTextManagerGetText("MultiDimThemeSelectDifficultyText"), XUiHelper.Hexcolor2Color(difficultyInfoDetail.Color))
    self.BtnDifficultySelect:SetNameAndColorByGroup(1, difficultyInfoDetail.Name, XUiHelper.Hexcolor2Color(difficultyInfoDetail.Color))
    -- 关卡信息
    self.StageId = XDataCenter.MultiDimManager.GetDifficultyStageId(self.CurrentThemeId, self.CurrentDifficulty)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    -- 名称
    self.TxtBossName.text = stageCfg.Name
    -- 建议
    self.TxtRecommend.text = stageCfg.Description
    -- 推荐人数
    local leastPlayer = stageCfg.OnlinePlayerLeast <= 0 and 1 or stageCfg.OnlinePlayerLeast
    self.TxtTeamNumber.text = CSXTextManagerGetText("MultiDimMainDetailTeamNumber", leastPlayer)
    -- 排行和最高分只有最高难度才显示
    local isOnRank = XMultiDimConfig.GetDifficultIsOnRank(self.CurrentThemeId, self.CurrentDifficulty)
    self.PanelIntegral.gameObject:SetActiveEx(isOnRank == 1)
    if isOnRank == 1 then
        -- 排行
        self.TxtRank.gameObject:SetActiveEx(false)
        self.TxtNoneRank.gameObject:SetActiveEx(true)
        -- 获取排行信息
        XDataCenter.MultiDimManager.MultiDimOpenRankRequest(XMultiDimConfig.RANK_MODEL.SINGLE_RANK, self.CurrentThemeId, function()
            local isActive, text = XDataCenter.MultiDimManager.GetCurrentRankMsg(XMultiDimConfig.RANK_MODEL.SINGLE_RANK, self.CurrentThemeId)
            self.TxtRank.text = text
            self.TxtRank.gameObject:SetActiveEx(isActive)
            self.TxtNoneRank.gameObject:SetActiveEx(not isActive)
        end)
        -- 历史最高
        local point = XDataCenter.MultiDimManager.GetFightRecordPoint(self.CurrentThemeId)
        local isPointShow = XTool.IsNumberValid(point)
        self.TxtTopNumber.text = point
        self.TxtTopNumber.gameObject:SetActiveEx(isPointShow)
        self.TxtNonePoint.gameObject:SetActiveEx(not isPointShow)
    end
    
    -- 首通奖励
    self:RefreshRewards()
    -- 选择职业
    self:RefreshCareer()
end

function XUiMultiDimMainDetail:RefreshRewards()
    local rewardId = XDataCenter.MultiDimManager.GetDifficultyFirstPassReward(self.CurrentThemeId, self.CurrentDifficulty)
    local rewards = XRewardManager.GetRewardList(rewardId)

    if XTool.IsTableEmpty(rewards) then
        for i = 1, #self.RewardGridList do
            self.RewardGridList[i].GameObject:SetActiveEx(false)
        end
        return
    end
    local difficultyInfo = XMultiDimConfig.GetMultiDimDifficultyStageData(self.StageId)
    local isPass = XDataCenter.MultiDimManager.CheckTodayIsPass(difficultyInfo.Id)
    for i = 1, #rewards do
        local panel = self.RewardGridList[i]
        if not panel then
            local go = #self.RewardGridList == 0 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelDropContent)
            panel = XUiGridCommon.New(self.RootUi, go)
            table.insert(self.RewardGridList, panel)
        end
        panel:Refresh(rewards[i])
        panel:SetReceived(isPass)
    end
    for i = #rewards + 1, #self.RewardGridList do
        self.RewardGridList[i].GameObject:SetActiveEx(false)
    end
end

function XUiMultiDimMainDetail:RefreshCareer()
    self.CareerIds = {}
    local multiDimCareerInfo = XDataCenter.MultiDimManager.GetMultiDimCareerInfo()
    
    local typeGroup = {}
    for i = 1, #multiDimCareerInfo do
        local careerConfig = multiDimCareerInfo[i]
        local btn = self.CareerGridList[i]
        if not btn then
            local go = #self.CareerGridList == 0 and self.BtnType or XUiHelper.Instantiate(self.BtnType, self.PanelList.transform)
            btn = go:GetComponent("XUiButton")
            table.insert(self.CareerGridList, btn)
        end
        btn:SetRawImage(careerConfig.Icon)
        typeGroup[i] = btn
        self.CareerIds[i] = careerConfig.Career
    end
    
    for i = #typeGroup + 1, #self.CareerGridList do
        self.CareerGridList[i].GameObject:SetActiveEx(false)
    end
    self.PanelList:Init(typeGroup, function(typeIndex)
        self:OnClickTypeCallBack(typeIndex)
    end)
    -- 记录玩家上一次的选择
    local defaultCareerId = self:GetDefaultCareerId()
    self.CurrentType = table.indexof(self.CareerIds, defaultCareerId)
    self.PanelList:SelectIndex(self.CurrentType or 1)
end

-- 获取默认的职业 如果已有保存的职业返回保存的职业
--[[
条件 ： a.选择天赋点数量最多的职业类型
       b.若存在相同，取相同类型中，角色最高战力较高的职业
       c.若战力亦相同，按职业id，优先选择id较小者
]]
function XUiMultiDimMainDetail:GetDefaultCareerId()
    local difficultyInfo = XMultiDimConfig.GetMultiDimDifficultyStageData(self.StageId)
    local presetCareerId = XDataCenter.MultiDimManager.GetPresetCareerId(difficultyInfo.Id)
    if XTool.IsNumberValid(presetCareerId) then
        return presetCareerId  -- 返回已保存的
    end

    local defaultCareerInfo = {}

    for _, careerId in pairs(self.CareerIds) do
        local data = {}
        data.CareerId = careerId
        -- 获取天赋点数
        local talentPoint = XDataCenter.MultiDimManager.GetTalentPoint(careerId)
        data.TalentPoint = talentPoint
        -- 最高战力
        local highAbility = XDataCenter.MultiDimManager.GetHighAbility(careerId)
        data.HighAbility = highAbility
        table.insert(defaultCareerInfo, data)
    end

    table.sort(defaultCareerInfo, function(a, b)
        -- 天赋点数
        if a.TalentPoint ~= b.TalentPoint then
            return a.TalentPoint > b.TalentPoint
        end
        -- 最高战力
        if a.HighAbility ~= b.HighAbility then
            return a.HighAbility > b.HighAbility
        end
        -- 职业id
        return a.CareerId < b.CareerId
    end)
    -- 获取到默认的职业时通知服务端
    local careerId = defaultCareerInfo[1].CareerId
    self:SelectCareerRequest(careerId)
    
    return careerId
end

function XUiMultiDimMainDetail:OnClickTypeCallBack(typeIndex)
    if self.CurrentType and self.CurrentType == typeIndex then
        return
    end

    self.CurrentType = typeIndex
    local careerId = self.CareerIds[typeIndex]
    -- 切换职业时通知服务端
    self:SelectCareerRequest(careerId, function()
        -- 点击后选中并淡出提示：“选择进攻/装甲/辅助型进行匹配”
        local typeName = XDataCenter.MultiDimManager.GetMultiDimCareerName(careerId)
        local msg = CSXTextManagerGetText("MultiDimMainDetailNeedJobTypeTip", typeName)
        XUiManager.TipMsg(msg)
    end)
end

return XUiMultiDimMainDetail