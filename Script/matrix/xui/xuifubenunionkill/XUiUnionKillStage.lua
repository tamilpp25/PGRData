local XUiUnionKillStage = XLuaUiManager.Register(XLuaUi, "UiUnionKillStage")
local XUiGridUnionStageMember = require("XUi/XUiFubenUnionKill/XUiGridUnionStageMember")
local XUiPanelUnionBuffDetails = require("XUi/XUiFubenUnionKill/XUiPanelUnionBuffDetails")
local XUiPanelUnionDamageDetails = require("XUi/XUiFubenUnionKill/XUiPanelUnionDamageDetails")
local XUiPanelUnionSectionEnd = require("XUi/XUiFubenUnionKill/XUiPanelUnionSectionEnd")
local XUiGridUnionEventStageItem = require("XUi/XUiFubenUnionKill/XUiGridUnionEventStageItem")

local MAX_CHAT_WIDTH = 470
local CHAT_SUB_LENGTH = 18
local WARN_LAST_SEC = 10

function XUiUnionKillStage:OnAwake()
    self:BindHelpBtn(self.BtnHelp, "UnionKillStageHelp")
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnBuff.CallBack = function() self:OnBtnBuffClick() end
    self.BtnChat.CallBack = function() self:OnBtnChatClick() end
    self.BtnBossLcok.CallBack = function() self:OnBtnBossClick() end
    self.BtnTcanchaungBlack.CallBack = function() self:OnBtnDamageDetailClick() end
    self.BtnNotShowToday.CallBack = function() self:OnBtnNotShowTodayClick() end

    self.TxtMessageContent.text = ""
    self.StageTeamMembers = {}

    self.EventStages = {}
    self.IsNotifying = false

    self.BuffDetails = XUiPanelUnionBuffDetails.New(self.PanelTanchuangBuff, self)
    self.DamageDetails = XUiPanelUnionDamageDetails.New(self.PanelTanchuangTongJi, self)
    self.SectionEnd = XUiPanelUnionSectionEnd.New(self.PanelTanChuangEnd, self)

    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshRoomChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILL_BOSSHPCHANGE, self.OnBossHpChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILL_PLAYERINFOCHANGE, self.OnPlayerInfoChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILL_STAGEINFOCHANGE, self.OnSectionInfoChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILL_LEAVEROOM, self.OnPlayerLeaveRoom, self)
    XEventManager.AddEventListener(XEventId.EVENT_UNIONKILL_FIGHTSTATUS, self.OnPlayerFightStatusChanged, self)
end

function XUiUnionKillStage:OnDestroy()
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.StageTeamMembers[i] then
            self.StageTeamMembers[i]:ClearUnuseTimer()
        end
    end
    if self.TempItemResource then
        self.TempItemResource:Release()
    end
    self:StopRoomCountDown()
    self:EndProcessTipMessage()

    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshRoomChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILL_BOSSHPCHANGE, self.OnBossHpChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILL_PLAYERINFOCHANGE, self.OnPlayerInfoChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILL_STAGEINFOCHANGE, self.OnSectionInfoChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILL_LEAVEROOM, self.OnPlayerLeaveRoom, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_UNIONKILL_FIGHTSTATUS, self.OnPlayerFightStatusChanged, self)
end

function XUiUnionKillStage:RefreshRoomChatMsg(chatDataLua)
    if not chatDataLua then return end
    local playerId = chatDataLua.SenderId
    XDataCenter.FubenUnionKillManager.Add2TipQueue(true, playerId, chatDataLua)
    self:RefreshChatMsg(chatDataLua)
end

function XUiUnionKillStage:RefreshChatMsg(chatDataLua)
    local senderName = XDataCenter.SocialManager.GetPlayerRemark(chatDataLua.SenderId, chatDataLua.NickName)
    if chatDataLua.MsgType == ChatMsgType.Emoji then
        self.TxtMessageContent.text = string.format("%s:%s", senderName, CS.XTextManager.GetText("EmojiText"))
    else
        self.TxtMessageContent.text = string.format("%s:%s", senderName, chatDataLua.Content)
    end

    if not string.IsNilOrEmpty(chatDataLua.CustomContent) then
        self.TxtMessageContent.supportRichText = true
    else
        self.TxtMessageContent.supportRichText = false
    end

    if XUiHelper.CalcTextWidth(self.TxtMessageContent) > MAX_CHAT_WIDTH then
        self.TxtMessageContent.text = string.Utf8Sub(self.TxtMessageContent.text, 1, CHAT_SUB_LENGTH) .. [[......]]
    end
end

-- boss血量变化
function XUiUnionKillStage:OnBossHpChanged()
    self:SetBossStageView()
    self:CheckTrialOpen(true)
end

-- 玩家状态变化UpdateByCache
function XUiUnionKillStage:OnPlayerInfoChanged()
    self:SetTeamMembers()
    self:SetEventStagesView()
end

-- 章节变化
function XUiUnionKillStage:OnSectionInfoChanged()
    self:SetEventStagesView()
end

-- 玩家离开房间
function XUiUnionKillStage:OnPlayerLeaveRoom()
    self:CheckStageOver(true)
end

-- 玩家战斗状态
function XUiUnionKillStage:OnPlayerFightStatusChanged(playerId, stageId)
    for i = 1, #self.StageTeamMembers do
        if self.StageTeamMembers[i] then
            self.StageTeamMembers[i]:RefreshFightStatus(playerId, stageId)
        end
    end
end

function XUiUnionKillStage:OnStart()
    self.RoomFightData = XDataCenter.FubenUnionKillManager.GetCurRoomData()
    self.UnionKillInfo = XDataCenter.FubenUnionKillManager.GetUnionKillInfo()

    if self.UnionKillInfo == nil then return end
    if self.UnionKillInfo.CurSectionId == nil or self.UnionKillInfo.CurSectionId == 0 then return end
    self.CurSectionId = self.UnionKillInfo.CurSectionId
    self.CurSectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(self.CurSectionId)
    self.CurSectionConfig = XFubenUnionKillConfigs.GetUnionSectionConfigById(self.CurSectionId)

    self:SetTeamMembers()
    self:SetEventStagesView()
    self:StartRoomCountDown()
    self:PlaySaftyAnimation("AnimStartEnable")
end

function XUiUnionKillStage:OnEnable()
    self:CheckTrialOpen(false)
    self:CheckStageOver(false)

    if self.EventStages then
        for i = 1, #self.EventStages do
            self.EventStages[i]:UpdateEffect()
        end
    end
end

function XUiUnionKillStage:SetTeamMembers()
    if not self.RoomFightData then return end
    local playerInfos = {}
    for _, playerInfo in pairs(self.RoomFightData.UnionKillPlayerInfos or {}) do
        table.insert(playerInfos, playerInfo)
    end
    table.sort(playerInfos, function(playerInfo1, playerInof2)
        return playerInfo1.Position < playerInof2.Position
    end)

    local index = 0
    for _, playerInfo in pairs(playerInfos) do
        index = index + 1

        if not self.StageTeamMembers[index] then
            local ui = CS.UnityEngine.Object.Instantiate(self.PanelHeadPor)
            ui.transform:SetParent(self.TeamItemContent, false)
            self.StageTeamMembers[index] = XUiGridUnionStageMember.New(ui)
        end
        self.StageTeamMembers[index]:Refresh(playerInfo)
    end
    for i = index + 1, #self.StageTeamMembers do
        self.StageTeamMembers[i].GameObject:SetActiveEx(false)
    end
end

-- 设置关卡
function XUiUnionKillStage:SetEventStagesView()
    if not self.CurSectionTemplate then return end
    local prefabPath = self.CurSectionConfig.MainPrefabName
    local itemPrefabPath = self.CurSectionConfig.ItemPrefabName
    self.StagePanel = self.PanelStages:LoadPrefab(prefabPath)
    if self.TempItemResource then
        self.TempItemResource:Release()
    end
    self.TempItemResource = CS.XResourceManager.Load(itemPrefabPath)
    -- 事件关
    local event_length = #self.CurSectionTemplate.EventStageId
    for i = 1, event_length do
        local eventStageId = self.CurSectionTemplate.EventStageId[i]
        if not self.EventStages[i] then
            local parentObj = self.StagePanel.transform:Find(string.format("GuanQia%d", i))
            local tempItemObj = CS.UnityEngine.Object.Instantiate(self.TempItemResource.Asset)
            tempItemObj.transform:SetParent(parentObj, false)
            self.EventStages[i] = XUiGridUnionEventStageItem.New(tempItemObj)
        end
        self.EventStages[i]:Refresh(eventStageId, self.CurSectionTemplate)
    end
    for i = event_length + 1, #self.EventStages do
        self.EventStages[i].GameObject:SetActiveEx(false)
    end

    -- boss关
    self:SetBossStageView()
end

-- 设置boss关
function XUiUnionKillStage:SetBossStageView()
    if not self.RoomFightData then return end
    if not self.CurSectionTemplate then return end

    local isTrialBoss = self.RoomFightData.BossHpLeft <= 0

    self.CurSectionId = self.UnionKillInfo.CurSectionId
    self.CurSectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(self.CurSectionId)
    self.CurSectionConfig = XFubenUnionKillConfigs.GetUnionSectionConfigById(self.CurSectionId)

    local bossIcon = isTrialBoss and self.CurSectionConfig.TrialIcon or self.CurSectionConfig.BossIcon
    self.RImgUnionKillStageBoss:SetRawImage(bossIcon)

    -- 通关限制
    -- 玩家信息
    local isLock = false
    local unlockBossLimit = self.CurSectionTemplate.UnlockBossStageLimit
    local finishEventCount = 0
    local playerInfos = self.RoomFightData.UnionKillPlayerInfos
    if playerInfos and playerInfos[XPlayer.Id] then
        local myPlayerInfo = playerInfos[XPlayer.Id]
        finishEventCount = #myPlayerInfo.FinishEventStage
        isLock = finishEventCount < unlockBossLimit
    end

    self.Locked.gameObject:SetActiveEx(isLock)
    self.UnLocked.gameObject:SetActiveEx(not isLock)
    if self.BossHpGroup then
        self.BossHpGroup.gameObject:SetActiveEx(not isTrialBoss)
    end
    if isLock then
        self.TxtNumber.text = string.format("<color=#26bfff>%d</color>/%d", finishEventCount, unlockBossLimit)
        self.TxtTask.text = CS.XTextManager.GetText("UnionStageCondition", unlockBossLimit)
    else
        -- 分boss关、试炼关
        local totalHp = self.CurSectionTemplate.BossTotalHp
        local leftHp = self.RoomFightData.BossHpLeft or 0
        local hpPercent = leftHp * 1 / totalHp
        self.ImgProgress.fillAmount = hpPercent
        self.TxtProgress.text = leftHp
    end
end

function XUiUnionKillStage:OnBtnBackClick()
    local title = CS.XTextManager.GetText("UnionRoomDialogTitle")
    local content = CS.XTextManager.GetText("UnionRoomExitStage")

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        -- 发送通知
        self:LeaveRoomCheckFightState()
    end)

end

function XUiUnionKillStage:OnBtnMainUiClick()
    local title = CS.XTextManager.GetText("UnionRoomDialogTitle")
    local content = CS.XTextManager.GetText("UnionRoomExitStage")

    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
    end, function()
        -- 发送通知
        self:LeaveRoomCheckFightState()
    end)
end

function XUiUnionKillStage:OnBtnBuffClick()
    if not self.RoomFightData then return end
    local buffInfos = {}
    local playerInfo = self.RoomFightData.UnionKillPlayerInfos[XPlayer.Id]
    local stageInfos = self.RoomFightData.UnionKillStageInfos
    if playerInfo then
        local finishEventStages = playerInfo.FinishEventStage
        for _, eventStageId in pairs(finishEventStages or {}) do
            local eventStageTemplate = XFubenUnionKillConfigs.GetUnionEventStageById(eventStageId)
            local curStageInfo = stageInfos[eventStageId]
            if curStageInfo then
                local totalEventNum = #eventStageTemplate.EventId
                local realEventNum = #curStageInfo.PlayerIds
                local buffIndex = realEventNum > totalEventNum and totalEventNum or realEventNum
                table.insert(buffInfos, eventStageTemplate.EventId[buffIndex])
            end
        end
    end
    self:PlayAnimation("TanchuangBuffEnable")
    self.BuffDetails:Refresh(buffInfos)
end

function XUiUnionKillStage:OnBtnChatClick()
    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Room, ChatChannelType.World)
end

function XUiUnionKillStage:OnBtnBossClick()
    if not self.UnionKillInfo then return end
    if not self.RoomFightData then return end

    self.CurSectionId = self.UnionKillInfo.CurSectionId
    self.CurSectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(self.CurSectionId)
    if not self.CurSectionTemplate then return end

    -- 通关限制
    local isLock = false
    local unlockBossLimit = self.CurSectionTemplate.UnlockBossStageLimit
    local playerInfos = self.RoomFightData.UnionKillPlayerInfos
    if playerInfos and playerInfos[XPlayer.Id] then
        local myPlayerInfo = playerInfos[XPlayer.Id]
        local finishEventCount = #myPlayerInfo.FinishEventStage
        isLock = finishEventCount < unlockBossLimit
    end

    if isLock then
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionStageCondition", unlockBossLimit))
        return
    end

    if self.RoomFightData.BossHpLeft <= 0 then
        -- 试炼关
        XLuaUiManager.Open("UiUnionKillEnterFight", self.CurSectionTemplate.TrialStage, self.CurSectionTemplate, XFubenUnionKillConfigs.UnionKillStageType.TrialStage)
    else
        -- Boss关
        XLuaUiManager.Open("UiUnionKillEnterFight", self.CurSectionTemplate.BossStage, self.CurSectionTemplate, XFubenUnionKillConfigs.UnionKillStageType.BossStage)
    end
end

function XUiUnionKillStage:OnBtnDamageDetailClick()
    if not self.RoomFightData then return end
    local damageInfos = {}
    local playerInfos = self.RoomFightData.UnionKillPlayerInfos
    if playerInfos then
        for _, playerInfo in pairs(playerInfos) do
            if playerInfo.KillBossHp > 0 then
                table.insert(damageInfos, {
                    PlayerId = playerInfo.Id,
                    PlayerName = playerInfo.PlayerName,
                    HeadPortraitId = playerInfo.HeadPortraitId,
                    HeadFrameId = playerInfo.HeadFrameId,
                    PlayerLevel = playerInfo.PlayerLevel,
                    KillBossHp = playerInfo.KillBossHp,
                    Online = playerInfo.Status == 1,
                    Position = playerInfo.Position
                })
            end
        end
        table.sort(damageInfos, function(damage1, damage2)
            return damage1.KillBossHp > damage2.KillBossHp
        end)
    end
    self:PlaySaftyAnimation("TanchuangTongJiEnable")
    self.DamageDetails:Refresh(damageInfos)
end

--[[提示相关]]
-- 每秒检查是否需要提示
function XUiUnionKillStage:CheckTipQueuePerSecond()
    for i = 1, XFubenUnionKillConfigs.MaxTeamCount do
        if self.StageTeamMembers[i] then
            local playerId = self.StageTeamMembers[i].PlayerId
            if playerId and not self.StageTeamMembers[i].IsTiping then
                local tipMsg = XDataCenter.FubenUnionKillManager.GetTipQueueById(playerId)
                if tipMsg then
                    self.StageTeamMembers[i]:ProcessTipMsg(tipMsg)
                end
            end
        end
    end

    if not self.IsNotifying then
        local tip_all_msg = XDataCenter.FubenUnionKillManager.GetTipQueueAll()
        if tip_all_msg and self:IsShowTipMsg() then
            self:ProcessTipMessage(tip_all_msg)
        end
    end
end

-- 不需要计时器，用房间界面的计时器就可以
function XUiUnionKillStage:ProcessTipMessage(allTipMsg)
    self:EndProcessTipMessage()
    self.IsNotifying = true
    ---显示
    local fullMsg = ""
    local playerName = ""
    if allTipMsg.TipsType == XFubenUnionKillConfigs.TipsMessageType.Praise then
        -- 点赞
        local characterName = XMVCA.XCharacter:GetCharacterFullNameStr(allTipMsg.CharacterId)
        fullMsg = CS.XTextManager.GetText(XFubenUnionKillConfigs.PraiseWords, characterName)
    elseif allTipMsg.TipsType == XFubenUnionKillConfigs.TipsMessageType.ResultBorrow then
        -- 刷新纪录
        fullMsg = CS.XTextManager.GetText(XFubenUnionKillConfigs.RefreshHighestPoint)
    end

    local fightInfo = XDataCenter.FubenUnionKillManager.GetCurRoomData()
    if fightInfo then
        local playerInfo = fightInfo.UnionKillPlayerInfos[allTipMsg.PlayerId]
        if playerInfo then
            playerName = XDataCenter.SocialManager.GetPlayerRemark(playerInfo.Id, playerInfo.PlayerName)
        end
    end
    self:TipMessage(fullMsg, playerName)

    self.TipMsgTimer = XScheduleManager.ScheduleOnce(function()
        self:EndProcessTipMessage()
    end, 3000)
end

function XUiUnionKillStage:EndProcessTipMessage()
    if self.TipMsgTimer then
        XScheduleManager.UnSchedule(self.TipMsgTimer)
        self.TipMsgTimer = nil
    end
    self:EndTipMessage()
    self.IsNotifying = false
end

function XUiUnionKillStage:TipMessage(msg, playerName)
    self.TipsGroup.gameObject:SetActiveEx(true)
    self.TxtTipContent.text = playerName
    self.TxtTipText.text = msg
    if XLuaUiManager.IsUiShow("UiUnionKillStage") then
        self:PlaySaftyAnimation("TipsGroupEnable")
    end
end

function XUiUnionKillStage:EndTipMessage()
    self.TipsGroup.gameObject:SetActiveEx(false)
end

function XUiUnionKillStage:OnBtnNotShowTodayClick()
    self:EndTipMessage()
    local now = XTime.GetServerNowTimestamp()
    XDataCenter.FubenUnionKillManager.SaveUnionKillStringPrefs(XFubenUnionKillConfigs.NotShowToday, tostring(now))
end

function XUiUnionKillStage:IsShowTipMsg()
    local recordTime = XDataCenter.FubenUnionKillManager.GetUnionKillStringPrefs(XFubenUnionKillConfigs.NotShowToday, "")
    if recordTime == "" then return true end

    local recored = tonumber(recordTime)
    local dt = CS.XDateUtil.GetGameDateTime(recored + 1 * 60 * 60 * 24)
    dt = dt.Date
    local unlockTime = dt:ToTimestamp() + 5 * 60 * 60
    local now = XTime.GetServerNowTimestamp()
    return now > unlockTime
end


--[[房间开始倒计时]]
function XUiUnionKillStage:StartRoomCountDown()
    self:StopRoomCountDown()
    if not self.RoomFightData then return end

    local now = XTime.GetServerNowTimestamp()
    local endTime = self.RoomFightData.EndTime
    if not endTime then return end

    self.TxtSectionTime.text = XUiHelper.GetTime(endTime - now)

    self.UnionRoomTimer = XScheduleManager.ScheduleForever(function()
        now = XTime.GetServerNowTimestamp()
        if now > endTime then
            self:StopRoomCountDown()
            return
        end
        self:CheckTipQueuePerSecond()
        local sec = endTime - now
        self.TxtSectionTime.text = XUiHelper.GetTime(sec)

        if sec == WARN_LAST_SEC then
            if XLuaUiManager.IsUiShow("UiUnionKillEnterFight") then
                XLuaUiManager.Close("UiUnionKillEnterFight")
            end

            if XLuaUiManager.IsUiShow("UiUnionKillDifficulty") then
                XLuaUiManager.Close("UiUnionKillDifficulty")
            end

            if XLuaUiManager.IsUiShow("UiUnionKillStage") then
                self:PlaySaftyAnimation("TanChuangEndEnable")
            end
            self.SectionEnd.GameObject:SetActiveEx(true)
        elseif sec < WARN_LAST_SEC then
            self.SectionEnd:Refresh(sec)
        end

    end, XScheduleManager.SECOND, 0)
end

-- 关闭房间倒计时
function XUiUnionKillStage:StopRoomCountDown()
    if self.UnionRoomTimer ~= nil then
        XScheduleManager.UnSchedule(self.UnionRoomTimer)
        self.UnionRoomTimer = nil
    end
end

-- 试炼关开启
function XUiUnionKillStage:CheckTrialOpen(isCheckPanel)
    if not self.RoomFightData then return end
    if self.RoomFightData.FirstKillBoss and not CS.XFight.IsRunning then

        if isCheckPanel then
            if not XLuaUiManager.IsUiShow("UiUnionKillStage") then
                return
            end
        end

        local quitCb = function()
            self:LeaveRoomCheckFightState()
        end

        local goTrial = function()
            self:OnBtnBossClick()
        end

        if XLuaUiManager.IsUiShow("UiUnionKillEnterFight") then
            XLuaUiManager.Close("UiUnionKillEnterFight")
        end

        XLuaUiManager.Open("UiUnionKillDifficulty", self.CurSectionConfig, quitCb, goTrial)

        self.RoomFightData.FirstKillBoss = nil
    end
end

function XUiUnionKillStage:RestorePlayerState()
    local teamData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    if teamData and teamData.PlayerDataList then
        local playerData = teamData.PlayerDataList[XPlayer.Id]
        if playerData then
            playerData.State = XFubenUnionKillConfigs.UnionRoomPlayerState.Normal
        end

    end
end

-- 本局挑战是否结束
function XUiUnionKillStage:CheckStageOver(isCheckPanel)
    if not self.RoomFightData then
        self:RestorePlayerState()
        self:Close()
        XUiManager.TipMsg(CS.XTextManager.GetText("UnionLeaveMiddle"))
        return
    end

    if self.RoomFightData.LeaveReson and self.RoomFightData.LeaveReson > 0 and not CS.XFight.IsRunning then
        self:RestorePlayerState()

        if XLuaUiManager.IsUiShow("UiUnionKillEnterFight") then
            XLuaUiManager.Close("UiUnionKillEnterFight")
        end

        if XLuaUiManager.IsUiShow("UiUnionKillDifficulty") then
            XLuaUiManager.Close("UiUnionKillDifficulty")
        end

        local leaveReson = self.RoomFightData.LeaveReson
        if isCheckPanel and XLuaUiManager.IsUiShow("UiUnionKillStage") then
            XDataCenter.FubenUnionKillManager.TipsPlayerleaveReson(leaveReson)
            if XLuaUiManager.IsUiShow("UiChatServeMain") then
                XLuaUiManager.Close("UiChatServeMain")
            end
            XLuaUiManager.Close("UiUnionKillStage")
            return
        end
        XLuaUiManager.Close("UiUnionKillStage")
        XDataCenter.FubenUnionKillManager.TipsPlayerleaveReson(leaveReson)
    end
end

function XUiUnionKillStage:LeaveRoomCheckFightState()
    local teamData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    local hasLeaveRoom = self.RoomFightData and self.RoomFightData.LeaveReson and self.RoomFightData.LeaveReson > 0
    if teamData and teamData.PlayerDataList and not hasLeaveRoom then
        local playerData = teamData.PlayerDataList[XPlayer.Id]
        XDataCenter.FubenUnionKillManager.LeaveFightRoom(function()
            local playerLastState = playerData.State
            playerData.State = XFubenUnionKillConfigs.UnionRoomPlayerState.Normal
            XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_PLAYERSTATE_CHANGED, playerData.Id, playerLastState)
            self:Close()
        end)
    else
        -- 特殊情况刷新
        if teamData and teamData.PlayerDataList then
            local playerData = teamData.PlayerDataList[XPlayer.Id]
            if playerData then
                XEventManager.DispatchEvent(XEventId.EVENT_UNIONKILLROOM_PLAYERSTATE_CHANGED, playerData.Id, playerData.State)
            end
        end
        self:Close()
    end
end

function XUiUnionKillStage:PlaySaftyAnimation(animName, endCb, startCb)
    self:PlayAnimation(animName, function()
        if endCb then
            endCb()
        end
        XLuaUiManager.SetMask(false)
    end,
    function()
        if startCb then
            startCb()
        end
        XLuaUiManager.SetMask(true)
    end)
end