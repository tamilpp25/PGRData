local XUiMultiplayerRoom = XLuaUiManager.Register(XLuaUi, "UiMultiplayerRoom")
local XUiGridMultiplayerRoomChar = require("XUi/XUiMultiplayerRoom/XUiGridMulitiplayerRoomChar")
local XUiGridMultiplayerDifficultyItem = require("XUi/XUiMultiplayerRoom/XUiGridMultiplayerDifficultyItem")
local XUiPanelChangeStage = require("XUi/XUiMultiplayerRoom/XUiPanelChangeStage")
local XUiPanelActiveBuffMian = require("XUi/XUiMultiplayerRoom/XUiPanelActiveBuffMian")
local XUiPanelActiveBuff = require("XUi/XUiMultiplayerRoom/XUiPanelActiveBuff")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiPanelMultiDimRoomReward = require("XUi/XUiMultiDim/XUiPanelMultiDimRoomReward")
local XUiPanelMultiDimRecommendCareer = require("XUi/XUiMultiDim/XUiPanelMultiDimRecommendCareer")
local CSXTextManagerGetText = CS.XTextManager.GetText
local MAX_CHAT_WIDTH = 450
local CHAT_SUB_LENGTH = 18
local IsFirstFriendEffect = "LocalValue_IsFirstFriendEffect"--是否是第一次在联机页面开启队友特效
------------------------------ tips类 ---------------------------
local XUiTips = XClass(nil, "XUiTips")
function XUiTips:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiTips:SetText(desc)
    self.TxtTips.text = desc
end

function XUiTips:SetActiveEx(enable)
    self.GameObject:SetActiveEx(enable)
end
---------------------------------------------------------
local MAX_PLAYER_COUNT = 3

local ButtonState = {
    ["Waiting"] = 1,
    ["Fight"] = 2,
    ["Ready"] = 3,
    ["CancelReady"] = 4,
}

local DifficultyType = {
    ["Normal"] = 1,
    ["Hart"] = 2,
    ["Nightmare"] = 3,
}

local TipsType = {
    ["LevelTips"] = 1, --关卡提示
    ["ChuzhanTips"] = 2, --出战提示
    ["TongTiaoTips"] = 3, --同调提示
}
function XUiMultiplayerRoom:OnAwake()
    if not XDataCenter.RoomManager.RoomData then
        self:Close()
        return
    end
    
    self.RoomKickCountDownTime = CS.XGame.Config:GetInt("RoomKickCountDownTime")
    self.RoomKickCountDownShowTime = CS.XGame.Config:GetInt("RoomKickCountDownShowTime")

    local root = self.UiModelGo.transform
    self.RoleModelList = {}
    for i = 1, MAX_PLAYER_COUNT do
        self.RoleModelList[i] = {}
        local case = root:FindTransform("PanelModelCase" .. i)
        local effectObj = root:FindTransform("ImgEffectTongDiao" .. i)
        local roleModel = XUiPanelRoleModel.New(case, self.Name, nil, true)
        self.RoleModelList[i].RoleModel = roleModel
        self.RoleModelList[i].EffectObj = effectObj
    end

    self.InFSetAbilityLimit = self.InFSetAbilityLimit:GetComponent("InputField")

    self:RegisterClickEvent(self.ToggleQuickMatch, self.OnToggleQuickMatchClick)
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick)
    self:RegisterClickEvent(self.BtnCancelReady, self.OnBtnCancelReadyClick)
    self:RegisterClickEvent(self.BtnReady, self.OnBtnReadyClick)
    self:RegisterClickEvent(self.BtnChat, self.OnBtnChatClick)
    self:RegisterClickEvent(self.BtnChangeDifficulty, self.OnBtnChangeDifficultyClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnDifficultySelect, self.OnBtnDifficultySelectClick)
    self:RegisterClickEvent(self.BtnCloseDifficulty, self.OnBtnCloseDifficultyClick)
    self:RegisterClickEvent(self.BtnMapSelect, self.OnBtnMapsSelectClick)
    --2.6取消模式切换，只有合作模式
    --self:RegisterClickEvent(self.BtnSummerEpisode, self.OnBtnSummerEpisodeClick)
    self:RegisterClickEvent(self.BtnActionPointAdd, function () XUiManager.OpenBuyAssetPanel(XDataCenter.ItemManager.ItemId.ActionPoint) end)
    self.BtnSetAbilityLimit.CallBack = handler(self, self.OnBtnSetAbilityLimitClick)
    self.BtnCloseAbilityLimit.CallBack = handler(self, self.OnBtnCloseAbilityLimitClick)
    self.BtnCancel.CallBack = handler(self, self.OnBtnCloseAbilityLimitClick)
    self.BtnConfirmSetAbilityLimit.CallBack = handler(self, self.OnBtnConfirmSetAbilityLimitClick)
    self.BtnAutoMatch.CallBack = handler(self, self.OnBtnAutoMatchClick)
    self.BtnSpecialEffects.CallBack = handler(self, self.OnBtnSpecialEffectsClick)
    self.BtnChangeStage.CallBack = handler(self, self.OnBtnChangeStageClick)
    self.BtnMusic.CallBack = handler(self, self.OnBtnMusicClick)
    self.BtnSnowGame.CallBack = handler(self, self.OnBtnSnowSelectClick)
    self.BtnYuanXiao.CallBack = handler(self, self.OnBtnRhythmSelectClick)
    self.BtnPattern.CallBack = handler(self, self.OnBtnPatternClick)
    local actionIcon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.ActionPoint)
    self.RImgActionIcon:SetRawImage(actionIcon)
    self.BtnGroup = {
        [ButtonState.Waiting] = self.BtnWaiting.gameObject,
        [ButtonState.Fight] = self.BtnFight.gameObject,
        [ButtonState.Ready] = self.BtnReady.gameObject,
        [ButtonState.CancelReady] = self.BtnCancelReady.gameObject,
    }

    self:InitCharItems()

    self:InitDifficultyButtons()

    self:InitSpecialEffectsButton()

    self:InitSummerEpisodeMapSelectBtn()

    self:InitSpecialTrainMusicBtn()

    self:InitSpecialTrainSnowBtn()
    
    self:InitSpecialTrainRhythmBtn()
    
    self.TipsList = {
        XUiTips.New(self.PanelTips)
    }

    self.PanelDifficulty.gameObject:SetActiveEx(false)
    self.PanelChangeDifficulty.gameObject:SetActiveEx(false)
    self.PanelAbilityLimit.gameObject:SetActiveEx(false)

    self.ChangeStagePanel = XUiPanelChangeStage.New(self.PanelChangeStage)
    self.ActiveBuffMainPanel = XUiPanelActiveBuffMian.New(self.PanelActiveBuffMain, self)
    self.ActiveBuffPanel = XUiPanelActiveBuff.New(self.PanelActiveBuff)



    self:InitFun()
end

function XUiMultiplayerRoom:OnStart()
    self.GridMap = {}
    self.TipsFuns = {}
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_REFRESH, self.OnRoomRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.ActionPoint, self.OnActionPointUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_PLAYER_LEAVE, self.OnPlayerLevel, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, self.OnPlayerStageRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, self.OnPlayerNpcRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_AUTO_MATCH_CHANGE, self.OnRoomAutoMatchChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_STAGE_LEVEL_CHANGE, self.OnRoomStageLevelChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_STAGE_CHANGE, self.OnRoomStageChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_STAGE_ABILITY_LIMIT_CHANGE, self.OnRoomAbilityLimitChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CHANGE_STAGE, self.OnStageChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CHANGE_STAGE_SUMMER_EPISODE, self.OnStageChangeSummerEpisode, self)

    -- 开启自动关闭检查
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then
        return
    end
    if XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Rhythm) then
        local endTime = XDataCenter.FubenSpecialTrainManager.GetActivityEndTime()
        self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.FubenSpecialTrainManager.HandleActivityEndTime()
            end
        end)
    end
end

function XUiMultiplayerRoom:OnEnable()
    XUiMultiplayerRoom.Super.OnEnable(self)
    self:Refresh()
end

function XUiMultiplayerRoom:OnDisable()
    XUiMultiplayerRoom.Super.OnDisable(self)
end

function XUiMultiplayerRoom:OnDestroy()
    self:StopTimer()
    self:StopCharTimer()
    self:CloseAllOperationPanel()
    self.IsAlreadyTip = nil

    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_REFRESH, self.OnRoomRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_KICKOUT, self.OnKickOut, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.ActionPoint, self.OnActionPointUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_PLAYER_ENTER, self.OnPlayerEnter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_PLAYER_LEAVE, self.OnPlayerLevel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_PLAYER_STAGE_REFRESH, self.OnPlayerStageRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_PLAYER_NPC_REFRESH, self.OnPlayerNpcRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_AUTO_MATCH_CHANGE, self.OnRoomAutoMatchChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_STAGE_LEVEL_CHANGE, self.OnRoomStageLevelChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_STAGE_CHANGE, self.OnRoomStageChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_STAGE_ABILITY_LIMIT_CHANGE, self.OnRoomAbilityLimitChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, self.RefreshChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CHANGE_STAGE, self.OnStageChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CHANGE_STAGE_SUMMER_EPISODE, self.OnStageChangeSummerEpisode, self)
end

function XUiMultiplayerRoom:InitFun()
    self.RoomInfoActiveTipFun = function(arg) self:RoomInfoActiveTip(arg) end
    self.RoomInfoContenttextTipFun = function(arg) self:RoomInfoContenttextTip(arg) end
    self.RoomInfoFightSuccesstextTipFun = function(arg) self:RoomInfoFightSuccesstextTip(arg) end
    self.ShowRoomTipsFun = function() self:ShowRoomTips() end
end

function XUiMultiplayerRoom:OnRoomRefresh()
    self:RefreshChars()
end

function XUiMultiplayerRoom:OnKickOut()
    XLuaUiManager.Remove("UiDialog")
    XLuaUiManager.Remove("UiReport")
    XLuaUiManager.Remove("UiRoomCharacter")
    XLuaUiManager.Remove("UiPlayerInfo")
    XLuaUiManager.Remove("UiChatServeMain")

    if XUiManager.CheckTopUi(CsXUiType.Normal, self.Name) then
        self:Close()
    else
        self:Remove()
    end
end

function XUiMultiplayerRoom:OnActionPointUpdate()
    self.TxtActionPoint.text = XDataCenter.ItemManager.GetItem(XDataCenter.ItemManager.ItemId.ActionPoint).Count
end

-- 有玩家进入房间
function XUiMultiplayerRoom:OnPlayerEnter(playerData)
    local grid = self:GetGrid(playerData.Id)
    self.ActiveBuffMainPanel:Refresh()
    self:InitGridCharData(grid, playerData)
    self:RefreshButtonStatus()
    self:CheckLeaderCountDown()
    self:RefreshTips()
    self:RefreshSameCharTips()
    self:RefreshCharActiveEffct()
    self:RefreshCharacterLimit()
end

-- 有玩家离开房间
function XUiMultiplayerRoom:OnPlayerLevel(playerId)
    local grid = self:GetGrid(playerId)
    self.ActiveBuffMainPanel:Refresh()
    grid:InitEmpty()
    self:RefreshButtonStatus()
    self.GridMap[playerId] = nil
    self:CheckLeaderCountDown()
    self:RefreshTips()
    self:RefreshSameCharTips()
    self:RefreshCharActiveEffct()
    self:RefreshCharacterLimit()
end

-- 玩家状态刷新
function XUiMultiplayerRoom:OnPlayerStageRefresh(playerData)
    local grid = self:GetGrid(playerData.Id)
    self:RefreshGridPlayer(grid, playerData)
    self:RefreshButtonStatus()
    self:CheckLeaderCountDown()
    self:RefreshCharacterLimit()
end

-- 玩家Npc信息刷新
function XUiMultiplayerRoom:OnPlayerNpcRefresh(playerData)
    local grid = self:GetGrid(playerData.Id)
    self.ActiveBuffMainPanel:Refresh()
    self:InitGridCharData(grid, playerData)
    self:RefreshButtonStatus()
    self:CheckLeaderCountDown()
    self:RefreshTips()
    self:RefreshSameCharTips()
    self:RefreshCharActiveEffct()
    self:RefreshChangeStageBtn()
    self:RefreshCharacterLimit()
end

-- 刷新玩家同调特效
function XUiMultiplayerRoom:RefreshCharActiveEffct()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData or not roomData.StageId then
        return
    end

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(roomData.StageId)
    if stageInfo.Type ~= XDataCenter.FubenManager.StageType.ArenaOnline then
        return
    end

    for _, grid in pairs(self.GridMap) do
        grid:CheckOpenEffctObje()
    end
end

-- 房间自动修改
function XUiMultiplayerRoom:OnRoomAutoMatchChange()
    self:RefreshButtonStatus()
    self:RefreshDifficultyPanel()
    self:CheckLeaderCountDown()
end

-- 房间难度等级修改
function XUiMultiplayerRoom:OnRoomStageLevelChange(lastLevel, curLevel)
    self:RefreshButtonStatus()
    self:RefreshDifficultyPanel()
    self:PlayStageLevelChange(lastLevel, curLevel)
    self.PanelDifficulty.gameObject:SetActiveEx(false)
    self:CheckLeaderCountDown()
end

-- 房间状态修改
function XUiMultiplayerRoom:OnRoomStageChange()
    self:CheckLeaderCountDown()
end

-- 房间战力限制修改
function XUiMultiplayerRoom:OnRoomAbilityLimitChange()
    self:RefreshAbilityLimit()
end

-- 夏活关卡改变
function XUiMultiplayerRoom:OnStageChangeSummerEpisode()
    local roomData = XDataCenter.RoomManager.RoomData
    self.TxtMap.text = XDataCenter.FubenManager.GetStageName(roomData.StageId)
    self.TxtTitle.text = XDataCenter.FubenManager.GetStageName(roomData.StageId)
    local isHell = XFubenSpecialTrainConfig.IsHellStageId(roomData.StageId)
    --2.6取消模式切换，只有合作模式
    --self.BtnSummerEpisode:SetButtonState(isHell and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiMultiplayerRoom:PlayStageLevelChange(lastLevel, curLevel)
    local roomData = XDataCenter.RoomManager.RoomData
    local levelControl = XDataCenter.FubenManager.GetStageMultiplayerLevelControl(roomData.StageId, curLevel)
    self.TxtChangeAdditionDest.text = levelControl.AdditionDest

    local level
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(roomData.StageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        level = roomData.ChallengeLevel
    else
        level = roomData.StageLevel
    end

    --设置显隐
    for k, v in pairs(self.DifficultyIconGroup) do
        if k == lastLevel then
            v.gameObject:SetActiveEx(true)
        elseif k == level then
            v.gameObject:SetActiveEx(true)
        else
            v.gameObject:SetActiveEx(false)
        end
    end

    --设置位置
    self.DifficultyIconGroup[lastLevel].localPosition = self.ChangeDifficultyCase1.localPosition
    self.DifficultyIconGroup[level].localPosition = self.ChangeDifficultyCase2.localPosition

    if XLuaUiManager.IsUiShow("UiMultiplayerRoom") then
        local begin = function()
            XLuaUiManager.SetMask(true)
        end

        local finished = function()
            XLuaUiManager.SetMask(false)
            self.PanelChangeDifficulty.gameObject:SetActiveEx(false)
        end

        self:PlayAnimation("AnimChangeDifficulty", finished, begin)
    end
end

----------------------- 界面方法 -----------------------
function XUiMultiplayerRoom:SwitchButtonState(state)
    for k, v in pairs(self.BtnGroup) do
        v:SetActiveEx(k == state)
    end
end

function XUiMultiplayerRoom:SwitchDifficultyState(diff)
    local showBtn = false
    for k, v in pairs(self.DifficultyImageGroup) do
        v.gameObject:SetActiveEx(k == diff)
        if k == diff then
            showBtn = true
        end
    end

    self.BtnDifficultySelect.gameObject:SetActiveEx(showBtn)
end

function XUiMultiplayerRoom:GetCurRole()
    local roomData = XDataCenter.RoomManager.RoomData

    if not roomData then
        return nil
    end

    for _, v in pairs(roomData.PlayerDataList) do
        if v.Id == XPlayer.Id then
            return v
        end
    end
end

function XUiMultiplayerRoom:CheckPeopleEnough()
    local roomData = XDataCenter.RoomManager.RoomData

    if not roomData then
        return 0
    end

    local count = 0
    for _, v in pairs(roomData.PlayerDataList) do
        count = count + 1
    end

    local stageId = roomData.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local leastPlayer = stageCfg.OnlinePlayerLeast <= 0 and 1 or stageCfg.OnlinePlayerLeast

    if count < leastPlayer then
        XUiManager.TipMsg(string.format(CS.XTextManager.GetText("OnlineRoomLeastPlayer"), leastPlayer))
        return false
    end

    return true
end

function XUiMultiplayerRoom:GetLeaderRole()
    local roomData = XDataCenter.RoomManager.RoomData
    for _, v in pairs(roomData.PlayerDataList) do
        if v.Leader then
            return v
        end
    end
end

function XUiMultiplayerRoom:CheckAllReady()
    local roomData = XDataCenter.RoomManager.RoomData
    for _, v in pairs(roomData.PlayerDataList) do
        if not v.Leader and v.State ~= XDataCenter.RoomManager.PlayerState.Ready then
            return false
        end
    end
    return true
end

function XUiMultiplayerRoom:CheckListFullAndAllReady()
    local roomData = XDataCenter.RoomManager.RoomData
    return roomData.State == 0 and #roomData.PlayerDataList == MAX_PLAYER_COUNT and self:CheckAllReady()
end

-- 界面刷新
function XUiMultiplayerRoom:Refresh()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then
        return
    end
    local stageId = roomData.StageId
    local challengeId = roomData.ChallengeId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)

    self.TxtTitle.text = stageCfg.Name

    --体力&门票
    if XDataCenter.FubenManager.CheckCanFlop(stageId) and stageInfo.Type == XDataCenter.FubenManager.StageType.BossOnline then
        self.TxtActionConsume.text = XDataCenter.FubenManager.GetStageActionPointConsume(stageId)
        local itemId = XDataCenter.FubenManager.GetFlopConsumeItemId(stageId)
        local item = XDataCenter.ItemManager.GetItem(itemId)
        local count = item and item:GetCount() or 0
        self.TxtTicket.text = count
        local flopIcon = XDataCenter.ItemManager.GetItemIcon(itemId)
        self.RImgFlopIcon:SetRawImage(flopIcon)
        self.PanelFlopItem.gameObject:SetActiveEx(true)
        self.PanelStaminaCost.gameObject:SetActiveEx(false)
        self.PanelArenaOnlineTip.gameObject:SetActiveEx(false)
        self.TxtLv.gameObject:SetActiveEx(false)
        self.PanelConsume.gameObject:SetActiveEx(true)
    elseif stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        self.PanelFlopItem.gameObject:SetActiveEx(false)
        self.PanelStaminaCost.gameObject:SetActiveEx(true)
        self.PanelArenaOnlineTip.gameObject:SetActiveEx(stageInfo.Passed)
        self.PanelConsume.gameObject:SetActiveEx(false)
        local arenaStageCfg = XDataCenter.ArenaOnlineManager.GetArenaOnlineStageCfgStageId(challengeId)
        local arenaChapterCfg = XDataCenter.ArenaOnlineManager.GetCurChapterCfg()
        local cost = stageInfo.Passed and 0 or arenaStageCfg.EnduranceCost
        self.TxtStamina.text = cost
        self.TxtLv.text = CS.XTextManager.GetText("ArenaOnlineChapterLevel", arenaChapterCfg.MinLevel, arenaChapterCfg.MaxLevel)
        self.ActiveBuffMainPanel:Show(stageId)
    elseif stageInfo.Type == XDataCenter.FubenManager.StageType.MultiDimOnline then
        self.TxtActionConsume.text = XDataCenter.FubenManager.GetRequireActionPoint(stageId)
        self.PanelFlopItem.gameObject:SetActiveEx(false)
        self.PanelStaminaCost.gameObject:SetActiveEx(false)
        self.PanelArenaOnlineTip.gameObject:SetActiveEx(false)
        self.TxtLv.gameObject:SetActiveEx(false)
        self.PanelConsume.gameObject:SetActiveEx(false)
        self.BtnSpecialEffects.gameObject:SetActiveEx(false)
        self.BtnIntelligenceMatch.gameObject:SetActiveEx(false)
    else
        self.TxtActionConsume.text = XDataCenter.FubenManager.GetRequireActionPoint(stageId)
        self.PanelFlopItem.gameObject:SetActiveEx(false)
        self.PanelStaminaCost.gameObject:SetActiveEx(false)
        self.PanelArenaOnlineTip.gameObject:SetActiveEx(false)
        self.TxtLv.gameObject:SetActiveEx(false)
        self.PanelConsume.gameObject:SetActiveEx(true)
    end
    self.TxtActionPoint.text = XDataCenter.ItemManager.GetItem(XDataCenter.ItemManager.ItemId.ActionPoint).Count

    --按钮状态
    self:RefreshButtonStatus()

    self:RefreshChangeStageBtn()

    self:RefreshChars()

    self:RefreshTips()

    self:RefreshSameCharTips()

    self:RefreshDifficultyPanel()

    self:RefreshAbilityLimit()

    self:RefreshMusicBtnText()

    self:InitSpecialTrainSnowBtn()
    
    self:InitSpecialTrainRhythmBtn()

    self:InitSpecialEffectsButton()
    
    self:InitMultiDim()

    self:RoomInfoTip()
    
    self:RefreshCharacterLimit()
end

function XUiMultiplayerRoom:CloseAllOperationPanel(exceptIndex)
    for k, v in pairs(self.GridList or {}) do
        if not exceptIndex or k ~= exceptIndex then
            v:CloseOperationPanelAndInvitePanel()
        end
    end
end

-- 角色面板初始化
function XUiMultiplayerRoom:InitCharItems()
    local caseList = {
        self.RoomCharCase1,
        self.RoomCharCase2,
        self.RoomCharCase3,
    }

    self.GridList = {}
    for i = 1, MAX_PLAYER_COUNT do
        local ui
        if i == 1 then
            ui = self.GridMulitiplayerRoomChar
        else
            ui = CS.UnityEngine.GameObject.Instantiate(self.GridMulitiplayerRoomChar)
        end
        ui.transform:SetParent(caseList[i], false)
        ui.transform:Reset()
        local params = {}
        local roomData = XDataCenter.RoomManager.RoomData
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(roomData.StageId)
        if stageInfo.Type == XDataCenter.FubenManager.StageType.MultiDimSingle or stageInfo.Type == XDataCenter.FubenManager.StageType.MultiDimOnline then
            params.IsMultiDim = true
            local recommendList = XMultiDimConfig.GetMultiDimRecommendCareerList(roomData.StageId)
            params.MultiDimCareer = recommendList[i]
        end
        local grid = XUiGridMultiplayerRoomChar.New(ui, self, i, self.RoleModelList[i].RoleModel, self.RoleModelList[i].EffectObj,params)
        self.GridList[i] = grid
    end
end

function XUiMultiplayerRoom:InitSpecialEffectsButton()

    local val = XSaveTool.GetData(XSetConfigs.FriendEffect) or XSetConfigs.FriendEffectEnum.Open

    if val == XSetConfigs.FriendEffectEnum.Open then
        self.BtnSpecialEffects:SetButtonState(XUiButtonState.Select)

        if not CS.UnityEngine.PlayerPrefs.HasKey(IsFirstFriendEffect) then
            CS.UnityEngine.PlayerPrefs.SetString(IsFirstFriendEffect, "false")
            XSaveTool.SaveData(XSetConfigs.IsFirstFriendEffect, nil)
            local title = CS.XTextManager.GetText("TipTitle")
            local friendEffectMsg = CS.XTextManager.GetText("OnlineFriendEffectMsg")
            XUiManager.DialogTip(title, friendEffectMsg, XUiManager.DialogType.Normal, nil,
            function()
                XDataCenter.SetManager.SaveFriendEffect(XSetConfigs.FriendEffectEnum.Close)
                XDataCenter.SetManager.SetAllyEffect(false)
                self.BtnSpecialEffects:SetButtonState(XUiButtonState.Normal)
            end)
        end
    else
        self.BtnSpecialEffects:SetButtonState(XUiButtonState.Normal)
    end
end

function XUiMultiplayerRoom:InitDifficultyButtons()
    self.DifficultyImageGroup = {
        [DifficultyType.Normal] = self.ImgDifficultyNormal,
        [DifficultyType.Hart] = self.ImgDifficultyHart,
        [DifficultyType.Nightmare] = self.ImgDifficultyNightmare,
    }
    self.DifficultyButtonGroup = {
        [DifficultyType.Normal] = XUiGridMultiplayerDifficultyItem.New(self.GridDifficultyNormal, DifficultyType.Normal, handler(self, self.SelectDifficulty)),
        [DifficultyType.Hart] = XUiGridMultiplayerDifficultyItem.New(self.GridDifficultyHart, DifficultyType.Hart, handler(self, self.SelectDifficulty)),
        [DifficultyType.Nightmare] = XUiGridMultiplayerDifficultyItem.New(self.GridDifficultyNightmare, DifficultyType.Nightmare, handler(self, self.SelectDifficulty)),
    }

    self.DifficultyIconGroup = { self.IconNormal, self.IconHart, self.IconNightmare }
end

function XUiMultiplayerRoom:InitSummerEpisodeMapSelectBtn()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then
        return
    end
    if not XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Photo) then
        return
    end
    self.TxtMap.text = XDataCenter.FubenManager.GetStageName(roomData.StageId)
    local isHell = XFubenSpecialTrainConfig.IsHellStageId(roomData.StageId)
    --2.6取消模式切换，只有合作模式
    --self.BtnSummerEpisode:SetButtonState(isHell and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiMultiplayerRoom:InitSpecialTrainMusicBtn()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then
        return
    end
    if not XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Music) then
        return
    end
    local stageName = XFubenConfigs.GetStageName(roomData.StageId)
    self.BtnMusic:SetName(stageName)
    local isHell = XFubenSpecialTrainConfig.IsHellStageId(roomData.StageId)
    self.BtnPattern:SetButtonState(isHell and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiMultiplayerRoom:InitSpecialTrainSnowBtn()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then
        return
    end
    if not XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Snow) then
        return
    end
    local stageName = XDataCenter.FubenManager.GetStageName(roomData.StageId)
    self.BtnSnowGame:SetName(stageName)
end

function XUiMultiplayerRoom:InitSpecialTrainRhythmBtn()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then
        return
    end
    if not XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Rhythm) then
        return
    end
    local stageName = XDataCenter.FubenManager.GetStageName(roomData.StageId)
    self.BtnYuanXiao:SetName(stageName)
    local isHell = XFubenSpecialTrainConfig.IsHellStageId(roomData.StageId)
    self.BtnPattern:SetButtonState(isHell and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiMultiplayerRoom:InitMultiDim()
    local roomData = XDataCenter.RoomManager.RoomData
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(roomData.StageId)
    local isMultiDim = stageInfo.Type == XDataCenter.FubenManager.StageType.MultiDimSingle or stageInfo.Type == XDataCenter.FubenManager.StageType.MultiDimOnline
    --if not self.MultiDimRewardPanel then
    --    self.MultiDimRewardPanel = XUiPanelMultiDimRoomReward.New(self.PanelMultiDimReward,self)
    --end
    if not self.MultiDimRecommendCareerPanel then
        self.MultiDimRecommendCareerPanel = XUiPanelMultiDimRecommendCareer.New(self.PanelRecommendType)
    end
    if isMultiDim then
        --self.MultiDimRewardPanel:Refresh(roomData.StageId)
        self.MultiDimRecommendCareerPanel:Refresh(roomData.StageId)
        local difficultyCfg = XMultiDimConfig.GetMultiDimDifficultyStageData(roomData.StageId)
        --local hasReward = XDataCenter.MultiDimManager.CheckThemeIsFirstPassOpen(difficultyCfg.ThemeId)
        self.PanelMultiDimReward.gameObject:SetActiveEx(false)
        self:RefreshMultiDimButton(roomData.StageId)
        self.BtnMultiDimDifficultySelect.CallBack = function()
            local leader = self:GetLeaderRole()
            if leader.Id == XPlayer.Id then
                XLuaUiManager.Open("UiMultiDimSelectDifficult", difficultyCfg.ThemeId, difficultyCfg.DifficultyId, function(difficultyId, stageId)
                    XDataCenter.RoomManager.SetStageIdRequest(stageId, function(newStageId)
                        self:RefreshMultiDimButton(newStageId)
                    end)
                end)
            end
        end
    end
    self.MultiDimRecommendCareerPanel:SetActive(isMultiDim)
    self.BtnMultiDimDifficultySelect.gameObject:SetActiveEx(isMultiDim)
end

function XUiMultiplayerRoom:RefreshMultiDimButton(stageId)
    local difficultyCfg = XMultiDimConfig.GetMultiDimDifficultyStageData(stageId)
    self.DifficultyInfoDetail = XDataCenter.MultiDimManager.GetDifficultyDetailInfo(difficultyCfg.ThemeId, difficultyCfg.DifficultyId)
    self.BtnMultiDimDifficultySelect:SetNameByGroup(1, self.DifficultyInfoDetail.Name)
    for _,group in pairs(self.BtnMultiDimDifficultySelect.TxtGroupList) do
        for _,txtCom in pairs(group.TxtList) do
            txtCom.color = XUiHelper.Hexcolor2Color(self.DifficultyInfoDetail.Color)
        end
    end
end

function XUiMultiplayerRoom:GetGrid(playerId)
    local grid = self.GridMap[playerId]
    if not grid then
        if playerId == XPlayer.Id then
            grid = self.GridList[1]
            self.GridMap[playerId] = grid
        else
            for i = 2, MAX_PLAYER_COUNT do
                if not self.GridList[i].PlayerData then
                    grid = self.GridList[i]
                    self.GridMap[playerId] = grid
                    break
                end
            end
        end
    end
    if not grid then
        XLog.Error("XUiMultiplayerRoom:GetGrid error, there is no empty grid。XPlayer.Id:" .. tostring(XPlayer.Id) .. " playerId:" .. tostring(playerId))
    end
    return grid
end

function XUiMultiplayerRoom:RefreshButtonStatus()
    local roomData = XDataCenter.RoomManager.RoomData
    local role = self:GetCurRole()
    if role and role.Leader then
        if self:CheckAllReady() then
            self:SwitchButtonState(ButtonState.Fight)
        else
            self:SwitchButtonState(ButtonState.Waiting)
        end
    else
        if role.State == XDataCenter.RoomManager.PlayerState.Ready then
            self:SwitchButtonState(ButtonState.CancelReady)
        else
            self:SwitchButtonState(ButtonState.Ready)
        end
    end

    if XDataCenter.FubenManager.CheckMultiplayerLevelControl(roomData.StageId) then
        self:SwitchDifficultyState(roomData.StageLevel)
    else
        self:SwitchDifficultyState(0)
    end
    self.BtnMapSelect.gameObject:SetActiveEx(XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Photo))
    --2.6取消模式切换，只有合作模式
    if self.BtnSummerEpisode then
        self.BtnSummerEpisode.gameObject:SetActiveEx(false)
        --self.BtnSummerEpisode.gameObject:SetActiveEx(XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Photo))
    end
    local isShowSpecial = XDataCenter.FubenSpecialTrainManager.CheckSpecialTrainShowSpecial(roomData.StageId)
    local isMultiDim = XDataCenter.MultiDimManager.IsMultiDimStage(roomData.StageId)
    self.PanelLimit.gameObject:SetActiveEx(isShowSpecial)
    self.PanelConsume.gameObject:SetActiveEx(isShowSpecial and (not isMultiDim))
    self.BtnMusic.gameObject:SetActiveEx(XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Music))
    self.BtnPattern.gameObject:SetActiveEx(XDataCenter.FubenSpecialTrainManager.CheckSpecialTrainShowPattern(roomData.StageId))
    self.BtnAutoMatch.ButtonState = roomData.AutoMatch and CS.UiButtonState.Select or CS.UiButtonState.Normal
    --self.BtnSnowGame.gameObject:SetActiveEx(XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Snow))
    --self.BtnYuanXiao.gameObject:SetActiveEx(XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Rhythm))
end

function XUiMultiplayerRoom:RefreshChars()
    local roomData = XDataCenter.RoomManager.RoomData
    for _, v in pairs(roomData.PlayerDataList) do
        local grid = self:GetGrid(v.Id)
        self:InitGridCharData(grid, v)
    end

    for _, v in pairs(self.GridList) do
        if not v.PlayerData then
            v:InitEmpty()
        end
    end
    self:RefreshCharacterLimit()
end

function XUiMultiplayerRoom:RefreshChangeStageBtn()
    local roomData = XDataCenter.RoomManager.RoomData
    local stageId = roomData.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)

    if stageInfo.Type ~= XDataCenter.FubenManager.StageType.ArenaOnline then
        self.BtnChangeStage.gameObject:SetActiveEx(false)
        return
    end

    local leader = self:GetLeaderRole()
    if not leader then
        self.BtnChangeStage.gameObject:SetActiveEx(false)
        return
    end

    self.BtnChangeStage.gameObject:SetActiveEx(leader.Id == XPlayer.Id)
end

function XUiMultiplayerRoom:RefreshDifficultyPanel()
    local roomData = XDataCenter.RoomManager.RoomData
    if XDataCenter.FubenManager.CheckMultiplayerLevelControl(roomData.StageId) then
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(roomData.StageId)
        if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
            local cfg = XArenaOnlineConfigs.GetStageById(roomData.ChallengeId)
            if cfg and cfg.Difficulty then
                local difficultyIds = cfg.Difficulty
                for k, id in pairs(difficultyIds) do
                    local levelControl = XFubenConfigs.GetStageMultiplayerLevelControlCfgById(id)
                    if levelControl then
                        local item = self.DifficultyButtonGroup[k]
                        if item then
                            item:Refresh(levelControl)
                            item:SetSelected(roomData.ChallengeLevel == k)
                        end
                    end
                end
            end
        else
            for k, v in pairs(self.DifficultyButtonGroup) do
                local levelControl = XDataCenter.FubenManager.GetStageMultiplayerLevelControl(roomData.StageId, k)
                v:Refresh(levelControl)
                v:SetSelected(roomData.StageLevel == k)
            end
        end
        local levelControl = XDataCenter.FubenManager.GetStageMultiplayerLevelControl(roomData.StageId, roomData.StageLevel)
        self.TxtAdditionDest.text = levelControl.AdditionDest
        self.TxtRecommend.text = CS.XTextManager.GetText("MultiplayerRoomRecommendAbility", levelControl.RecommendAbility)
    else
        self.TxtAdditionDest.gameObject:SetActiveEx(false)
        self.TxtRecommend.gameObject:SetActiveEx(false)
    end
end

function XUiMultiplayerRoom:RefreshAbilityLimit()
    local roomData = XDataCenter.RoomManager.RoomData
    self.TxtAbilityLimit.text = roomData.AbilityLimit
    self.TxtCurAbilityLimit.text = roomData.AbilityLimit
end

function XUiMultiplayerRoom:RefreshAbilityLimitPanel()
    local roomData = XDataCenter.RoomManager.RoomData
    local levelControl = XDataCenter.FubenManager.GetStageMultiplayerLevelControl(roomData.StageId, roomData.StageLevel)
    local defaultAbilityLimit = roomData.AbilityLimit > 0 and roomData.AbilityLimit or levelControl and levelControl.RecommendAbility or 0
    self.InFSetAbilityLimit.text = defaultAbilityLimit
    self.TxtCurAbilityLimit.text = roomData.AbilityLimit
end

function XUiMultiplayerRoom:CheckSameCharacterByMyself()
    local roomData = XDataCenter.RoomManager.RoomData
    local curRole = self:GetCurRole()
    if not curRole then
        return false
    end
    local isAllowRepeatChar = XDataCenter.FubenManager.CheckIsStageAllowRepeatChar(roomData.StageId)
    if isAllowRepeatChar then
        return false
    end

    for _, v in pairs(roomData.PlayerDataList) do
        if v.Id ~= curRole.Id
        and (v.Leader or v.State == XDataCenter.RoomManager.PlayerState.Ready)
        and v.FightNpcData.Character.Id == curRole.FightNpcData.Character.Id then
            return true
        end
    end
end

function XUiMultiplayerRoom:RefreshChatMsg(chatDataLua)
    local senderName = XDataCenter.SocialManager.GetPlayerRemark(chatDataLua.SenderId, chatDataLua.NickName)
    if chatDataLua.MsgType == ChatMsgType.Emoji then
        self.TxtMessageContent.text = string.format("%s:%s", senderName, CSXTextManagerGetText("EmojiText"))
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

    local grid = self:GetGrid(chatDataLua.SenderId)
    grid:RefreshChat(chatDataLua)
end

----------------------- 职业提示 -----------------------
function XUiMultiplayerRoom:RefreshTips()
    for _, v in pairs(self.TipsList) do
        v:SetActiveEx(false)
    end

    local roomData = XDataCenter.RoomManager.RoomData
    local stageTemplate = XDataCenter.FubenManager.GetStageCfg(roomData.StageId)

    if stageTemplate.NeedJobType then
        local needJobCount = {}
        for _, v in pairs(stageTemplate.NeedJobType) do
            if not needJobCount[v] then
                needJobCount[v] = 0
            end
            needJobCount[v] = needJobCount[v] + 1
        end

        local index = 0
        for k, v in pairs(needJobCount) do
            local jobCount = self:GetJopCount(k)
            if jobCount < v then
                index = index + 1
                local tips = self.TipsList[index]
                if not tips then
                    local ui = CS.UnityEngine.GameObject.Instantiate(self.PanelTips, self.PanelTipsContainer)
                    tips = XUiTips.New(ui)
                    self.TipsList[index] = tips
                end
                tips:SetActiveEx(true)
                tips:SetText(self:GetJobTips(k, v - jobCount))
            end
        end
    end
end

function XUiMultiplayerRoom:RefreshSameCharTips()
    local roomData = XDataCenter.RoomManager.RoomData
    local isAllowRepeatChar = XDataCenter.FubenManager.CheckIsStageAllowRepeatChar(roomData.StageId)
    for _, v in pairs(roomData.PlayerDataList) do
        local grid = self:GetGrid(v.Id)
        grid:ShowSameCharTips(false)
        if not isAllowRepeatChar then
            for _, v2 in pairs(roomData.PlayerDataList) do
                if v.Id ~= v2.Id and v.FightNpcData.Character.Id == v2.FightNpcData.Character.Id then
                    grid:ShowSameCharTips(true)
                    break
                end
            end
        end
    end
end

function XUiMultiplayerRoom:RefreshMusicBtnText()
    local roomData = XDataCenter.RoomManager.RoomData
    if not roomData then
        return
    end
    if not XFubenSpecialTrainConfig.IsSpecialTrainStage(roomData.StageId, XFubenSpecialTrainConfig.StageType.Music) then
        return
    end
    local stageName = XFubenConfigs.GetStageName(roomData.StageId)
    self.BtnMusic:SetName(stageName)
    local isHell = XFubenSpecialTrainConfig.IsHellStageId(roomData.StageId)
    self.BtnPattern:SetButtonState(isHell and XUiButtonState.Select or XUiButtonState.Normal)
end

function XUiMultiplayerRoom:RefreshCharacterLimit()
    local roomData = XDataCenter.RoomManager.RoomData
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(roomData.StageId)
    if stageInfo.Type ~= XDataCenter.FubenManager.StageType.MultiDimOnline then
        self.PanelCharacterLimit.gameObject:SetActiveEx(false)
        return
    end

    local limitType = XFubenConfigs.GetStageCharacterLimitType(roomData.StageId)
    local isShow = XFubenConfigs.IsStageCharacterLimitConfigExist(limitType)
    self.PanelCharacterLimit.gameObject:SetActiveEx(isShow or false)
    if not isShow then return end
    -- 图标
    self.ImgCharacterLimit:SetSprite(XFubenConfigs.GetStageCharacterLimitImageTeamEdit(limitType))
    -- 文案
     if limitType == XFubenConfigs.CharacterLimitType.IsomerDebuff or
            limitType == XFubenConfigs.CharacterLimitType.NormalDebuff then
        self.TxtCharacterLimit.text = XFubenConfigs.GetStageMixCharacterLimitTips(limitType
        , self:GetTeamCharacterTypes())
        return
    end
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(roomData.StageId)
    self.TxtCharacterLimit.text = XFubenConfigs.GetStageCharacterLimitTextTeamEdit(limitType
    , nil, limitBuffId)
end

function XUiMultiplayerRoom:GetTeamCharacterTypes()
    local roomData = XDataCenter.RoomManager.RoomData
    local result = {}
    for _,playerData in pairs(roomData.PlayerDataList) do
        local characterType = XCharacterConfigs.GetCharacterType(playerData.FightNpcData.Character.Id)
        table.insert(result,characterType)
    end
    return result
end

function XUiMultiplayerRoom:StopCharTimer()
    for _, grid in pairs(self.GridMap) do
        grid:StopTimer()
    end
end

function XUiMultiplayerRoom:GetJopCount(type)
    local count = 0
    local roomData = XDataCenter.RoomManager.RoomData
    for _, v in pairs(roomData.PlayerDataList) do
        local charId = v.FightNpcData.Character.Id
        local quality = v.FightNpcData.Character.Quality
        local npcId = XCharacterConfigs.GetCharNpcId(charId, quality)
        local tempType = XCharacterConfigs.GetCharacterCareerType(npcId)
        if type == tempType then
            count = count + 1
        end
    end
    return count
end

function XUiMultiplayerRoom:GetJobTips(type, count)
    if type == 1 then
        return CS.XTextManager.GetText("CharacterLackDps", count)
    elseif type == 2 then
        return CS.XTextManager.GetText("CharacterLackTank", count)
    elseif type == 3 then
        return CS.XTextManager.GetText("CharacterLackCure", count)
    end
end

function XUiMultiplayerRoom:SelectDifficulty(diff)
    XDataCenter.RoomManager.SetStageLevel(diff)
end

----------------------- 倒计时 -----------------------
function XUiMultiplayerRoom:CheckLeaderCountDown()
    if self.Timer then
        if not self:CheckListFullAndAllReady() then
            self:StopTimer()
        end
    else
        if self:CheckListFullAndAllReady() then
            self:StartTimer()
        end
    end
end

function XUiMultiplayerRoom:StartTimer()
    self.StartTime = XTime.GetServerNowTimestamp()
    self.Timer = XScheduleManager.ScheduleForever(handler(self, self.UpdateTimer), XScheduleManager.SECOND)
    local role = self:GetLeaderRole()
    self.CurCountDownGrid = self:GetGrid(role.Id)
    self:UpdateTimer()
end

function XUiMultiplayerRoom:StopTimer()
    if self.CurCountDownGrid then
        self.CurCountDownGrid:ShowCountDownPanel(false)
        self.CurCountDownGrid = nil
    end
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMultiplayerRoom:UpdateTimer()
    local elapseTime = XTime.GetServerNowTimestamp() - self.StartTime
    if elapseTime > self.RoomKickCountDownShowTime and elapseTime <= self.RoomKickCountDownTime then
        self.CurCountDownGrid:ShowCountDownPanel(true)
        local leftTime = self.RoomKickCountDownTime - elapseTime
        self.CurCountDownGrid:SetCountDownTime(leftTime)
    end
end

----------------------- 按钮回调 -----------------------
function XUiMultiplayerRoom:OnToggleQuickMatchClick()
    XDataCenter.RoomManager.Ready()
end

function XUiMultiplayerRoom:OnBtnFightClick()
    local role = self:GetCurRole()
    if not role or not role.Leader then
        return
    end

    if not self:CheckPeopleEnough() then
        return
    end
    if self:CheckSameCharacterByMyself() then
        local msg = CS.XTextManager.GetText("MultiplayerRoomTeamHasSameCharacter")
        XUiManager.TipMsg(msg)
        return
    end

    XDataCenter.RoomManager.Enter(function(response)
        if response.Code ~= XCode.Success then
            XUiManager.TipCode(response.Code)
            return
        end
    end)
end

function XUiMultiplayerRoom:OnBtnCancelReadyClick()
    XDataCenter.RoomManager.CancelReady(function(code)
        XUiManager.TipCode(code)
        if code ~= XCode.Success then
            return
        end
        self.BtnReady.gameObject:SetActiveEx(true)
        self.BtnCancelReady.gameObject:SetActiveEx(false)
    end)
end

function XUiMultiplayerRoom:OnBtnReadyClick()
    if self:CheckSameCharacterByMyself() then
        local msg = CS.XTextManager.GetText("MultiplayerRoomTeamHasSameCharacter")
        XUiManager.TipMsg(msg)
        return
    end
    XDataCenter.RoomManager.Ready()
end

function XUiMultiplayerRoom:OnBtnChatClick()
    XLuaUiManager.Open("UiChatServeMain", false, ChatChannelType.Room, ChatChannelType.World)
end

function XUiMultiplayerRoom:OnBtnChangeDifficultyClick()

end

function XUiMultiplayerRoom:PcClose()
    if self.PanelDifficulty.gameObject.activeSelf then
        self:OnBtnCloseDifficultyClick()
        return
    end
    if self.PanelAbilityLimit.gameObject.activeSelf then
        self:OnBtnCloseAbilityLimitClick()
        return
    end
    if self.PanelActiveBuff.gameObject.activeSelf then
        self.PanelActiveBuff.gameObject:SetActiveEx(false)
        return
    end
    if self.PanelChangeStage.gameObject.activeSelf then
        self.PanelChangeStage.gameObject:SetActiveEx(false)
        return
    end
    
    self:OnBtnBackClick()
end

function XUiMultiplayerRoom:OnBtnBackClick()
    self:OnQuitRoomDialogTip(function()
        XDataCenter.RoomManager.CloseMultiPlayerRoom()
    end)
end

function XUiMultiplayerRoom:OnBtnMainUiClick()
   self:OnQuitRoomDialogTip(function()
       XLuaUiManager.RunMain()
   end)
end

function XUiMultiplayerRoom:OnQuitRoomDialogTip(cb)
    if not XDataCenter.RoomManager.RoomData then
        self:Close()
        return
    end

    self:CloseAllOperationPanel()
    local title = CS.XTextManager.GetText("TipTitle")
    local cancelMatchMsg

    local stageId = XDataCenter.RoomManager.RoomData.StageId
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        cancelMatchMsg = CS.XTextManager.GetText("ArenaOnlineInstanceQuitRoom")
    else
        cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceQuitRoom")
    end

    XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.RoomManager.Quit(cb)
    end)
end

function XUiMultiplayerRoom:OnBtnMapsSelectClick()
    local leader = self:GetLeaderRole()
    if leader.Id ~= XPlayer.Id then return end
    XLuaUiManager.Open("UiSummerEpisodeMap", XDataCenter.RoomManager.RoomData.StageId, false, function()
        self:PlayAnimation("BtnMapSelectEnable")
    end,true)
end

--2.6取消模式切换，只有合作模式
--[[
function XUiMultiplayerRoom:OnBtnSummerEpisodeClick()
    local leader = self:GetLeaderRole()
    if leader.Id ~= XPlayer.Id then
        XUiManager.TipText("MultiplayerRoomOnlyLeaderTip")
        local isHell = not self.BtnSummerEpisode:GetToggleState()
        self.BtnSummerEpisode:SetButtonState(isHell and XUiButtonState.Select or XUiButtonState.Normal)
        return 
    end
    local isHell = self.BtnSummerEpisode:GetToggleState()
    local roomData = XDataCenter.RoomManager.RoomData
    local stageId = isHell and XFubenSpecialTrainConfig.GetHellStageId(roomData.StageId) or XFubenSpecialTrainConfig.GetStageIdByHellId(roomData.StageId) 
    XDataCenter.RoomManager.PhotoChangeMapRequest(stageId, function()
        self:Refresh()
    end)
end
--]]
function XUiMultiplayerRoom:OnBtnDifficultySelectClick()
    self:CloseAllOperationPanel()
    local curRole = self:GetCurRole()
    if not curRole or not curRole.Leader then
        local msg = CS.XTextManager.GetText("MultiplayerRoomCanNotSelectDifficulty")
        XUiManager.TipMsg(msg)
        return
    end
    self.PanelDifficulty.gameObject:SetActiveEx(true)
    self:PlayAnimation("DifficultyEnable")
    self:RefreshDifficultyPanel()
end

function XUiMultiplayerRoom:OnBtnCloseDifficultyClick()
    self.PanelDifficulty.gameObject:SetActiveEx(false)
end

function XUiMultiplayerRoom:OnBtnSetAbilityLimitClick()
    self:CloseAllOperationPanel()
    local curRole = self:GetCurRole()
    if not curRole or not curRole.Leader then
        local msg = CS.XTextManager.GetText("MultiplayerRoomCanNotSetAbilityLimit")
        XUiManager.TipMsg(msg)
        return
    end
    self.PanelAbilityLimit.gameObject:SetActiveEx(true)
    self:PlayAnimation("AbilityLimitEnable")
    self:RefreshAbilityLimitPanel()
end

function XUiMultiplayerRoom:OnBtnCloseAbilityLimitClick()
    self.PanelAbilityLimit.gameObject:SetActiveEx(false)
end

--队友特效开关
function XUiMultiplayerRoom:OnBtnSpecialEffectsClick(val)
    if val > 0 then
        XDataCenter.SetManager.SaveFriendEffect(XSetConfigs.FriendEffectEnum.Open)
        XDataCenter.SetManager.SetAllyEffect(true)
    else
        XDataCenter.SetManager.SaveFriendEffect(XSetConfigs.FriendEffectEnum.Close)
        XDataCenter.SetManager.SetAllyEffect(false)
    end
end

function XUiMultiplayerRoom:OnBtnAutoMatchClick()
    self:CloseAllOperationPanel()
    local curRole = self:GetCurRole()
    if not curRole or not curRole.Leader then
        local msg = CS.XTextManager.GetText("MultiplayerRoomCanNotChangeAutoMatch")
        XUiManager.TipMsg(msg)
        -- 重置按钮状态
        local roomData = XDataCenter.RoomManager.RoomData
        self.BtnAutoMatch.ButtonState = roomData.AutoMatch and CS.UiButtonState.Select or CS.UiButtonState.Normal
        return
    end
    local roomData = XDataCenter.RoomManager.RoomData
    XDataCenter.RoomManager.SetAutoMatch(not roomData.AutoMatch)
end

function XUiMultiplayerRoom:OnBtnConfirmSetAbilityLimitClick()
    local abilityLimit = tonumber(self.InFSetAbilityLimit.text)
    if not abilityLimit or abilityLimit < 0 then
        local msg = CS.XTextManager.GetText("MultiplayerRoomAbilityNotLegal")
        XUiManager.TipMsg(msg)
        return
    end
    abilityLimit = math.floor(abilityLimit)
    XDataCenter.RoomManager.SetAbilityLimit(abilityLimit, function()
        self.PanelAbilityLimit.gameObject:SetActiveEx(false)
    end)
end

-- 改变关卡
function XUiMultiplayerRoom:OnBtnChangeStageClick()
    local roomData = XDataCenter.RoomManager.RoomData
    local stageId = roomData.StageId

    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        stageId = roomData.ChallengeId
    end

    self.ChangeStagePanel:Show(stageId)
    self:PlayAnimation("ChangeStageEnable")
end

function XUiMultiplayerRoom:OnBtnMusicClick()
    local leader = self:GetLeaderRole()
    if leader.Id ~= XPlayer.Id then
        XUiManager.TipText("MultiplayerRoomOnlyLeaderTip")
        return
    end
    XLuaUiManager.Open("UiSpecialTrainMusicMapSelect", XDataCenter.RoomManager.RoomData.StageId, function()
        self:PlayAnimation("BtnMapSelectEnable")
    end)
end

function XUiMultiplayerRoom:OnBtnSnowSelectClick()
    local leader = self:GetLeaderRole()
    if leader.Id ~= XPlayer.Id then
        XUiManager.TipText("MultiplayerRoomOnlyHomeownerTip")
        return
    end
    XLuaUiManager.Open("UiFubenSnowGameMapTips", XDataCenter.RoomManager.RoomData.StageId, handler(self, self.SnowSelectCallback))
end

function XUiMultiplayerRoom:SnowSelectCallback(stageId)
    if stageId ~= XDataCenter.RoomManager.RoomData.StageId then
        XDataCenter.RoomManager.SetStageIdRequest(stageId)
    end
end

function XUiMultiplayerRoom:OnBtnRhythmSelectClick()
    local leader = self:GetLeaderRole()
    if leader.Id ~= XPlayer.Id then
        XUiManager.TipText("MultiplayerRoomOnlyHomeownerTip")
        return
    end
    XLuaUiManager.Open("UiFubenYuanXiaoMapTips", XDataCenter.RoomManager.RoomData.StageId, false, handler(self, self.RhythmSelectCallback))
end

function XUiMultiplayerRoom:RhythmSelectCallback(stageId)
    if stageId ~= XDataCenter.RoomManager.RoomData.StageId then
        XDataCenter.RoomManager.SetStageIdRequest(stageId)
    end
end

function XUiMultiplayerRoom:OnBtnPatternClick()
    local leader = self:GetLeaderRole()
    if leader.Id ~= XPlayer.Id then
        XUiManager.TipText("MultiplayerRoomOnlyLeaderTip")
        local isHell = not self.BtnPattern:GetToggleState()
        self.BtnPattern:SetButtonState(isHell and XUiButtonState.Select or XUiButtonState.Normal)
        return
    end
    local isHell = self.BtnPattern:GetToggleState()
    local roomData = XDataCenter.RoomManager.RoomData
    local stageId = isHell and XFubenSpecialTrainConfig.GetHellStageId(roomData.StageId) or XFubenSpecialTrainConfig.GetStageIdByHellId(roomData.StageId)
    XDataCenter.RoomManager.SetStageIdRequest(stageId, function()
        self:Refresh()
    end)
end

-- 打开同调详情
function XUiMultiplayerRoom:PanelActiveBuffShow(activeBuffCfg)
    self.ActiveBuffPanel:Show(activeBuffCfg)
    self:PlayAnimation("ActiveBuffEnable")
end

-- 检查同调开启
function XUiMultiplayerRoom:CheckActiveOn(playerId)
    return self.ActiveBuffMainPanel:CheckActiveOn(playerId)
end

-- 房间信息提示
function XUiMultiplayerRoom:RoomInfoTip()
    if self.IsAlreadyTip then
        return
    end

    self.IsAlreadyTip = true
    local roomData = XDataCenter.RoomManager.RoomData
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(roomData.StageId)
    if XDataCenter.FubenManager.CheckMultiplayerLevelControl(roomData.StageId) then
        local levelControl = XDataCenter.FubenManager.GetStageMultiplayerLevelControl(roomData.StageId, roomData.StageLevel)
        self.Contenttext = CS.XTextManager.GetText("ArenaOnlineStageInfoTip", stageCfg.Name, levelControl.DifficultyDesc)
        self:InsertTips(TipsType.LevelTips, self.RoomInfoContenttextTipFun)
    end
end

function XUiMultiplayerRoom:InsertTips(tipstype, cb)
    table.insert(self.TipsFuns, {["TipsType"] = tipstype, ["TipsFun"] = cb })
    table.sort(self.TipsFuns, function(a, b)
        return a.TipsType > b.TipsType
    end)

    if self.TipsDelayTimerId then
        XScheduleManager.UnSchedule(self.TipsDelayTimerId)
    end
    self.TipsDelayTimerId = XScheduleManager.ScheduleOnce(function()
        self:ShowRoomTips()
        self.TipsDelayTimerId = nil
    end, 500)
end

function XUiMultiplayerRoom:InsertFightSuccessTips()
    self:InsertTips(TipsType.ChuzhanTips, self.RoomInfoFightSuccesstextTipFun)
end

function XUiMultiplayerRoom:InsertActiveTips(tip)
    self.ActiveTip = tip
    self:InsertTips(TipsType.TongTiaoTips, self.RoomInfoActiveTipFun)
end

function XUiMultiplayerRoom:RoomInfoActiveTip(cb)
    XUiManager.TipMsg(self.ActiveTip, nil, cb)
end

function XUiMultiplayerRoom:RoomInfoContenttextTip(cb)
    XUiManager.TipMsg(self.Contenttext, nil, cb)
end

function XUiMultiplayerRoom:RoomInfoFightSuccesstextTip(cb)
    local text = CS.XTextManager.GetText("OnlineFightSuccess")
    XUiManager.TipMsg(text, nil, cb)
end

function XUiMultiplayerRoom:ShowRoomTips()
    local curtips = table.remove(self.TipsFuns)
    if not curtips or not curtips.TipsFun then
        return
    end

    local fun = curtips.TipsFun
    fun(self.ShowRoomTipsFun)
end

-- 关卡改变
function XUiMultiplayerRoom:OnStageChange()
    self:Refresh()
    local leader = self:GetLeaderRole()
    if leader.Id == XPlayer.Id then
        -- return
    end

    local roomData = XDataCenter.RoomManager.RoomData


    local stageCfg = XDataCenter.FubenManager.GetStageCfg(roomData.StageId)
    if not CS.XFight.IsRunning and not XLuaUiManager.IsUiLoad("UiLoading") then
        local contenttext = CS.XTextManager.GetText("ArenaOnlineStageChangeInfo", stageCfg.Name)
        XUiManager.TipMsg(contenttext)
    end
end

-- 区域联机周刷新
function XUiMultiplayerRoom:OnArenaOnlineWeekRefrsh()
    local roomData = XDataCenter.RoomManager.RoomData
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(roomData.StageId)

    if stageInfo.Type == XDataCenter.FubenManager.StageType.ArenaOnline then
        XDataCenter.ArenaOnlineManager.RunMain()
    end
end

function XUiMultiplayerRoom:InitGridCharData(grid, charData)
    grid:InitCharData(charData)
end

function XUiMultiplayerRoom:RefreshGridPlayer(grid, playerData)
    grid:RefreshPlayer(playerData)
end

return XUiMultiplayerRoom