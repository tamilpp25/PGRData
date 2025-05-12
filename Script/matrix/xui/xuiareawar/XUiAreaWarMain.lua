local XUiPanelArea = require("XUi/XUiMission/XUiPanelArea")
---@class XUiAreaWarMain : XLuaUi
---@field Canvas UnityEngine.Canvas
---@field Canvas3D UnityEngine.Canvas
---@field DragMove XDragMove
---@field IdleAnims XAreaWarAnimArea[]
---@field FarFraming Cinemachine.CinemachineFramingTransposer
---@field NearFraming Cinemachine.CinemachineFramingTransposer
---@field AllGrids UnityEngine.Transform[]
---@field BtnBuff XUiComponent.XUiButton
---@field Trail UnityEngine.Transform
local XUiAreaWarMain = XLuaUiManager.Register(XLuaUi, "UiAreaWarMain")

local AUTO_REQ_ACTIVITY_DATA_INTERVAL = 2 * 60 * 1000 --界面打开后自动请求最新活动数据时间间隔(ms)

local CameraType = {
    Normal = 1,
    Detail = 2,
}

local CsMathFClamp = CS.UnityEngine.Mathf.Clamp

local CsEase = CS.DG.Tweening.Ease

function XUiAreaWarMain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiAreaWarMain:OnStart()
    self:InitView()
    -- 等待开始动画播放完
    XScheduleManager.ScheduleOnce(function()
        if not CS.XAreaWarManager.Instance then
            return
        end
        CS.XAreaWarManager.Instance.ForceUpdateCamera = false
    end, XScheduleManager.SECOND * 2)
    XEventManager.AddEventListener(XEventId.EVNET_AREA_WAR_QUEST_FINISH, self.OnQuestFinish, self)
    XEventManager.AddEventListener(XEventId.EVENT_AREA_WAR_QUEST_REFRESH, self.RefreshQuests, self)
end

function XUiAreaWarMain:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateView()

    --事件注册
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG, self.UpdateChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.UpdateChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, self.UpdateChatMsg, self)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_CLOSE, self.OnChatClose, self)
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX ..
            XDataCenter.ItemManager.ItemId.AreaWarPersonalExp, self.OnExpChanged, self)

    CS.XAreaWarManager.Instance:ResumeUnlockAnim()

    
end

function XUiAreaWarMain:OnDisable()
    --事件移除
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG, self.UpdateChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_RECEIVE_CHAT, self.UpdateChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG, self.UpdateChatMsg, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_CLOSE, self.OnChatClose, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX ..
            XDataCenter.ItemManager.ItemId.AreaWarPersonalExp, self.OnExpChanged, self)

    CS.XAreaWarManager.Instance:PauseUnlockAnim()
end

function XUiAreaWarMain:OnDestroy()
    self:StopActivityDataTimer()
    self.BlockList3DPanel:OnDispose()
    self.DragMove:DelZoomBehaviour(self.ZoomHandler)

    --释放红点
    XRedPointManager.RemoveRedPointEvent(self.ProfitRedPoint)
    XRedPointManager.RemoveRedPointEvent(self.TaskRedPoint)
    --XRedPointManager.RemoveRedPointEvent(self.ShopRedPoint)
    XRedPointManager.RemoveRedPointEvent(self.BuffRedPoint)
    XRedPointManager.RemoveRedPointEvent(self.RoleRedPoint)

    --清除记录
    XDataCenter.AreaWarManager.SaveLastWarLogTabIndex(1)

    if self.PlateTimer then
        XScheduleManager.UnSchedule(self.PlateTimer)
        self.PlateTimer = nil
    end

    XEventManager.RemoveEventListener(XEventId.EVNET_AREA_WAR_QUEST_FINISH, self.OnQuestFinish, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_AREA_WAR_QUEST_REFRESH, self.RefreshQuests, self)

    XAreaWarConfigs.Clear()
end

function XUiAreaWarMain:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_REMIND_CHANGE,
        XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE,
        XEventId.EVENT_AREA_WAR_SELF_BLOCK_PURIFICATION_CHANGE,
        XEventId.EVENT_AREA_WAR_ACTIVITY_END,
        XEventId.EVENT_AREA_WAR_PURIFICATION_LEVEL_CHANGE,
        XEventId.EVENT_AREA_WAR_FOCUS_BLOCK,
        XEventId.EVENT_AREA_WAR_FOCUS_QUEST,
        CS.XEventId.EVENT_UI_DESTROY,
    }
end

function XUiAreaWarMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_REMIND_CHANGE then
        self:UpdateHangUp()
    elseif evt == XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE then
        self:UpdateRepeatChallenge()
        self:UpdateSpecialRole()
        self:UpdateProgress()
        --self:UpdateBlocks()
        self:UpdatePlate()
        self:CheckPopups()
    elseif evt == XEventId.EVENT_AREA_WAR_SELF_BLOCK_PURIFICATION_CHANGE then
        --self:UpdateBlocks()
        self:UpdatePlate()
    elseif evt == XEventId.EVENT_AREA_WAR_PURIFICATION_LEVEL_CHANGE then
        self:UpdatePurificationLevel()
        self:CheckPopups()
    elseif evt == XEventId.EVENT_AREA_WAR_ACTIVITY_END then
        XDataCenter.AreaWarManager.OnActivityEnd()
    elseif evt == XEventId.EVENT_AREA_WAR_FOCUS_BLOCK then
        --引导行为树需要
        if self.BlockList3DPanel then
            local args = { ... }
            self.BlockList3DPanel:FocusTargetBlock(tonumber(args[1]))
        end
    elseif evt == XEventId.EVENT_AREA_WAR_FOCUS_QUEST then
        if self.BlockList3DPanel then
            local args = { ... }
            local focusType = tonumber(args[1])
            local questId
            local personal = XDataCenter.AreaWarManager.GetPersonal()
            -- 参数为1时，聚焦战斗、被救援模块
            if focusType == 1 then
                local list = personal:GetDailyQuestList(false)
                questId = list[1]
            else --聚焦救援模块
                local list = personal:GetRescueQuestList(false)
                questId = list[1]
            end
            
            self.BlockList3DPanel:FocusTargetQuest(questId)
        end
    elseif evt == CS.XEventId.EVENT_UI_DESTROY then
        self:OnUiDestroy(...)
    end
end

function XUiAreaWarMain:InitUi()
    --文本初始化
    self.RepeatChallengeCountDown = XAreaWarConfigs.GetEndTimeTip(1)
    --设置层级
    self.Canvas = self.Transform:GetComponent("Canvas")
    self.Canvas3D = self.UiModelGo.transform:FindTransform("3DUiCanvas"):GetComponent("Canvas")

    --3D场景
    local root = self.UiModelGo.transform
    local panelRank = root:FindTransform("PanelRank")
    local stageList = root:FindTransform("PanelStageList")
    local dynamic = self.UiSceneInfo.Transform:FindTransform("GroupDynamic")

    dynamic:LoadPrefab(XAreaWarConfigs.GetPrefabPath())

    local type, duration, offsetY, maxDistance = XAreaWarConfigs.GetUnlockAnimationInfo()
    CS.XAreaWarManager.Instance:InitUnlockAnim(type, duration, offsetY, maxDistance)

    self.PlateOffsetY, self.PlateDuration = XAreaWarConfigs.GetPlateLiftUpInfo()
    
    CS.XAreaWarManager.Instance.ForceUpdateCamera = true

    --取消呼吸动画
    --local anims = regionRoot.gameObject:GetComponentsInChildren(typeof(CS.XAreaWarAnimArea))
    --
    --self.IdleAnims = {}
    --type, duration, offsetY = XAreaWarConfigs.GetIdleAnimationInfo()
    --for i = 0, anims.Length - 1 do
    --    local area = anims[i]
    --    local plate = area.transform:GetComponent(typeof(CS.XAreaWarPlateArea))
    --    if plate then
    --        area:InitAnimation(type, duration, offsetY)
    --        table.insert(self.IdleAnims, {
    --            Anim = area,
    --            Plate = plate
    --        })
    --    end
    --end

    ---@type XDragMove
    local dragMove = stageList.transform:GetComponent("XDragMove")
    self.ZoomHandler = handler(self, self.OnCameraZoom)
    dragMove:AddZoomBehaviour(self.ZoomHandler)
    dragMove.ZoomSpeed = XAreaWarConfigs.GetCameraZoomSpeed()
    self.DragMove = dragMove

    --虚拟相机
    self.VirtualCameraMap = {
        --普通状态
        Normal = {
            Type = CameraType.Normal,

            Camera = {
                root:FindTransform("UiCamFarMain1"):GetComponent("CinemachineVirtualCamera"),
                root:FindTransform("UiCamNearMain1"):GetComponent("CinemachineVirtualCamera")
            }

        },
        --关卡详情
        StageDetail = {
            Type = CameraType.Detail,

            Camera = {
                root:FindTransform("UiCamFarMain2"):GetComponent("CinemachineVirtualCamera"),
                root:FindTransform("UiCamNearMain2"):GetComponent("CinemachineVirtualCamera")
            }
        }
    }

    self.FarFraming = self.VirtualCameraMap.Normal.Camera[1]:GetCinemachineComponent(
            CS.Cinemachine.CinemachineCore.Stage.Body, typeof(CS.Cinemachine.CinemachineFramingTransposer))

    self.NearFraming = self.VirtualCameraMap.Normal.Camera[2]:GetCinemachineComponent(
            CS.Cinemachine.CinemachineCore.Stage.Body, typeof(CS.Cinemachine.CinemachineFramingTransposer))

    self.MinDistance, self.MaxDistance = XAreaWarConfigs.GetCameraMinAndMaxDistance()
    -- y = kx + b
    self.FactorK = 1 / (self.MinDistance - self.MaxDistance)
    self.ConstantB = (-1 * self.MaxDistance) / (self.MinDistance - self.MaxDistance)
    self.SmallDisRatio = XAreaWarConfigs.GetCameraSmallDisRatio()

    ---@type XUiPanelAreaWarMainRank3D
    self.RankPanel = require("XUi/XUiAreaWar/XUiPanelAreaWarMainRank3D").New(panelRank)
    self.RankPanel:Hide()

    CS.XAreaWarManager.Instance:InitCamera(self.UiModel.UiNearCamera, self.UiModel.UiFarCamera)
    ---@type XUiPanelAreaWarMainBlockList3D
    self.BlockList3DPanel = require("XUi/XUiAreaWar/XUiPanelAreaWarMainBlockList3D").New(stageList, self)

    self.ChatOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SocialChat)

    self.IsPlayMovie = XDataCenter.AreaWarManager.IsPlayMovieOnEnter()
    
    self.TxtRefreshTime.gameObject:SetActiveEx(true)
    
    self:UpdateVirtualCamera(self.VirtualCameraMap.Normal)
    
    self:RandomDailyQuest()
    self:RandomRescueQuest()
end

function XUiAreaWarMain:InitCb()
    self:BindHelpBtn(self.BtnHelp, "AreaWarMain")
    self:BindExitBtns()

    self.BtnProgress.CallBack = function()
        self:OnClickBtnProgress()
    end
    self.BtnProfit.CallBack = function()
        self:OnClickBtnProfit()
    end
    self.BtnTask.CallBack = function()
        self:OnClickBtnTask()
    end
    self.BtnShop.CallBack = function()
        self:OnClickBtnShop()
    end
    self.BtnBuff.CallBack = function()
        self:OnClickBtnBuff()
    end
    self.BtnRole.CallBack = function()
        self:OnClickBtnRole()
    end
    self.BtnLocation.CallBack = function()
        self:OnClickBtnLocation()
    end
    self.BtnChat.CallBack = function()
        self:OnClickBtnChat()
    end
    self.BtnRank.CallBack = function()
        self:OnClickBtnRank()
    end
    self.ScaleSlider.onValueChanged:AddListener(function(value)
        self:OnCameraZoomBySlider(value)
    end)

    self.OnCheckShopCb = function(result)
        self.BtnShop:ShowReddot(result)
    end

    self.BtnCheck.CallBack = function()
        self:BtnCheckClick()
    end

    self.BtnRescue.CallBack = function()
        self:BtnRescueClick()
    end

    --self.OnUnlockAnimEndCb = handler(self, self.OnBlockUnlockAnimEnd)

    self.OnPlayUnlockAnim = handler(self, self.PlayBlockUnlock)

    self.OnPlayPlateAnim = handler(self, self.OnRefreshPlate)
    
    self.SyncOnExpChangedCb = handler(self, self.SyncOnExpChanged)
end

--region   ------------------界面更新 start-------------------

function XUiAreaWarMain:InitView()

    XDataCenter.AreaWarManager.MarkNewChapterOpen()

    self.ScaleSlider.value = self:CalSliderPercent(self.NearFraming.m_CameraDistance)

    self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe({
        XDataCenter.ItemManager.ItemId.AreaWarCoin,
        XDataCenter.ItemManager.ItemId.AreaWarActionPoint
    }, self.PanelSpecialTool, self, nil, nil, {
        XDataCenter.ItemManager.ItemId.AreaWarActionPoint
    })
    
    self.AssetActivityPanel:Open()

    self.TxtTitle.text = XDataCenter.AreaWarManager.GetActivityName()

    local endTime = XDataCenter.AreaWarManager.GetEndTime()
    self.EndTime = endTime
    self.TomorrowFreshTime = XTime.GetSeverTomorrowFreshTime()
    local timeOfNow = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(self.EndTime - timeOfNow, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtRefreshTime.text = XUiHelper.GetTime(self.TomorrowFreshTime - timeOfNow, XUiHelper.TimeFormatType.CHATEMOJITIMER)
    self:SetAutoCloseInfo(endTime, handler(self, self.OnCheckActivity))

    --红点
    self.ProfitRedPoint = XRedPointManager.AddRedPointEvent(self.BtnProfit, self.OnCheckProfitRedPoint, self,
            { XRedPointConditions.Types.XRedPointConditionAreaWarHangUpReward }, nil, false)
    self.TaskRedPoint = XRedPointManager.AddRedPointEvent(self.BtnTask, self.OnCheckTaskRedPoint, self,
            { XRedPointConditions.Types.XRedPointConditionAreaWarTask }, nil, false)
    --self.ShopRedPoint = XRedPointManager.AddRedPointEvent(self.BtnShop, self.OnCheckShopRedPoint, self,
    --        { XRedPointConditions.Types.XRedPointConditionAreaWarCanBuy }, nil, false)
    self.BuffRedPoint = XRedPointManager.AddRedPointEvent(self.BtnBuff, self.OnCheckBuffRedPoint, self,
            { XRedPointConditions.Types.XRedPointConditionAreaWarPluginToUnlock }, nil, false)
    self.RoleRedPoint = XRedPointManager.AddRedPointEvent(self.BtnRole, self.OnCheckRoleRedPoint, self,
            { XRedPointConditions.Types.XRedPointConditionAreaWarSpecialRoleReward }, nil, false)
    
    self:StartActivityDataTimer()
end

function XUiAreaWarMain:UpdateView()
    self:UpdateChatMsg(XDataCenter.ChatManager.GetLatestChatData())
    self:UpdateRepeatChallenge()
    self:UpdateProgress()
    self:UpdateQuestProgress()
    self:UpdateSpecialRole()
    self:UpdateHangUp()
    self:UpdateTask()
    self:UpdateShop()
    self:UpdatePlate()
    self:UpdatePurificationLevel()
    self:CheckPopups()
    self:UpdatePersonal()
end

--板块
function XUiAreaWarMain:UpdatePlate()
    self:UpdateBlocks()

    if not self.PlateTimer then
        self.PlayPlates = {}
        local instance = CS.XAreaWarManager.Instance
        local ids = instance.PlateIds
        local count = ids and ids.Length or 0
        for i = 0, count - 1 do
            local id = ids[i]
            local unlock = XDataCenter.AreaWarManager.IsPlateUnlock(id)
            if unlock and XDataCenter.AreaWarManager.CheckIsPlayPlateAnim(id) and not self.IsPlayMovie then
                instance:ShowPlateArea(id, self.PlateOffsetY)
                table.insert(self.PlayPlates, id)
            else
                instance:SetPlateVisible(id, unlock)
            end
        end
        self:PlayPlateLiftAnim()
        self.IsPlayMovie = false
    end
end

--鞭尸期(重复挑战)
function XUiAreaWarMain:UpdateRepeatChallenge()
    local isRepeatChallenge = XDataCenter.AreaWarManager.IsRepeatChallengeTime()
    if self.IsRepeatChallenge ~= isRepeatChallenge then
        self.IsRepeatChallenge = isRepeatChallenge
        self.IsAllChapterOpen = XDataCenter.AreaWarManager.IsAllChapterOpen()
    end

    self.PanelRepeat.gameObject:SetActiveEx(self.IsRepeatChallenge)
    if not isRepeatChallenge then
        self.ChapterStartTime = nil
        return
    elseif self.IsAllChapterOpen then
        --全开放 & 鞭尸期 无需倒计时
        self.ChapterStartTime = XDataCenter.AreaWarManager.GetEndTime()
    else
        local chapterId = XDataCenter.AreaWarManager.GetFirstNotOpenChapterId()
        local timeId = XAreaWarConfigs.GetChapterTimeId(chapterId)
        self.ChapterStartTime = XFunctionManager.GetStartTimeByTimeId(timeId)

        --倒计时
        local remainder = math.max(0, self.ChapterStartTime - XTime.GetServerNowTimestamp())
        self.TxtRepeatTime.text = string.format(self.RepeatChallengeCountDown, XUiHelper.GetTime(remainder, XUiHelper.TimeFormatType.SHOP_REFRESH))
    end
    self.TxtRepeat.gameObject:SetActiveEx(true)
    self.TxtRepeatTime.gameObject:SetActiveEx(self.ChapterStartTime ~= nil)
end

--全服进度
function XUiAreaWarMain:UpdateProgress()
    local clearCount, totalCount = XDataCenter.AreaWarManager.GetBlockProgress()

    self.TxtJd.text = clearCount
    local totalStr = "/" .. totalCount
    self.TxtJdTotal.text = totalStr
    self.ImgJdFillAmount.fillAmount = totalCount ~= 0 and clearCount / totalCount or 1
    self.BtnLocation:SetNameByGroup(0, clearCount)
    self.BtnLocation:SetNameByGroup(1, totalStr)
    self:OnCheckWarLogRedPoint()
end

function XUiAreaWarMain:UpdateQuestProgress()
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    local dailyFinish, _ = personal:GetDailyQuestCount()
    local rescueFinish, rescueUndone = personal:GetRescueQuestCount()
    local rescueTotal = XAreaWarConfigs.GetDailyHelpNum()
    local dailyTotal = XAreaWarConfigs.GetDailyBattleNum()

    rescueFinish = rescueTotal - rescueUndone
    self.BtnCheck:SetDisable(dailyFinish >= dailyTotal)

    self.BtnCheck:SetNameByGroup(0, dailyFinish)
    self.BtnCheck:SetNameByGroup(1, string.format("/%s", dailyTotal))

    local curFinish = rescueFinish >= rescueTotal
    local isMax = personal:IsMaxRescueRefresh()
    local finishRescue = isMax and curFinish
    local showTag =  (not isMax and curFinish) or (rescueFinish == 0 and rescueUndone == 0)
    self.BtnRescue:SetDisable(finishRescue)
    self.BtnRescue:ShowTag(showTag)
    self.BtnRescue:SetNameByGroup(0, rescueFinish)
    self.BtnRescue:SetNameByGroup(1, string.format("/%s", rescueTotal))
    if showTag then
        --self.BtnRescue:SetNameByGroup(2, string.format("%d/%d", personal:GetRescueRefreshCount()))
        self.BtnRescue:SetNameByGroup(2, "")
    end
    self.BtnRescue:ShowReddot(XDataCenter.AreaWarManager.CheckTodayRescueQuestRedPoint())
    self.BtnCheck:ShowReddot(XDataCenter.AreaWarManager.CheckTodayDailyQuestRedPoint())
end

--挂机收益
function XUiAreaWarMain:UpdateHangUp()
    if not XDataCenter.AreaWarManager.IsHangUpUnlock() then
        self.BtnProfit:SetDisable(true)
        return
    end
    self.BtnProfit:SetDisable(false)
    XRedPointManager.Check(self.ProfitRedPoint)
end

--任务目标
function XUiAreaWarMain:UpdateTask()
    local text = XDataCenter.AreaWarManager.GetNextTaskProgressTip()
    if not string.IsNilOrEmpty(text) then
        self.BtnTask:SetNameByGroup(0, text)
        self.BtnTask:SetDisable(false)
    else
        self.BtnTask:SetDisable(true)
    end
    XRedPointManager.Check(self.TaskRedPoint)
end

--商店
function XUiAreaWarMain:UpdateShop()
    XDataCenter.AreaWarManager.CheckShopRedPoint(self.OnCheckShopCb)
end

--净化加成
function XUiAreaWarMain:UpdatePurificationLevel()
    --local unlock = XDataCenter.AreaWarManager.GetPluginUnlockCount()
    --self.BtnBuff:SetNameByGroup(0, unlock)

    --if not XDataCenter.AreaWarManager.IsPurificationLevelUnlock() then
    --    self.BtnBuff:SetDisable(true)
    --    return
    --end
    --self.BtnBuff:SetDisable(false)

    --XRedPointManager.Check(self.BuffRedPoint)
end

--特攻角色
function XUiAreaWarMain:UpdateSpecialRole()
    local unlockCount = XDataCenter.AreaWarManager.GetUnlockSpecialRoleCount()
    self.BtnRole:SetNameByGroup(0, unlockCount)

    if not XDataCenter.AreaWarManager.IsAnySpecialRoleUnlock() then
        self.BtnRole:SetDisable(true)
        return
    end
    self.BtnRole:SetDisable(false)

    XRedPointManager.Check(self.RoleRedPoint)
end

--区块展示
function XUiAreaWarMain:UpdateBlocks()
    self.Canvas3D.sortingOrder = self.Canvas.sortingOrder + 1

    self.RankPanel:Refresh()
    self.BlockList3DPanel:Refresh(self.IsRepeatChallenge)
    --更新区块详情

    if XTool.IsNumberValid(self.StageDetailBlockId) then
        self:OnOpenStageDetail(self.StageDetailBlockId)
    end
end

--打脸弹窗
function XUiAreaWarMain:CheckPopups()
    if self.Popping then
        return
    end
    self.Popping = true

    --打脸优先级
    -- 1.区块净化进度
    -- 2.净化等级变更
    -- 3.特攻角色解锁
    -- 4.挂机收益功能解锁
    -- 5.活动奖励弹窗

    local asyncOpenUi = asynTask(XLuaUiManager.Open)
    local asyncRequest = asynTask(XDataCenter.AreaWarManager.AreaWarGetActivityDataRequest)
    --local asynLetsLift = asynTask(self.BlockList3DPanel.LetsLift, self.BlockList3DPanel)

    local asyncPlayUnlock = asynTask(self.OnPlayUnlockAnim)

    local playId, ids = XDataCenter.AreaWarManager.GetNotPlayUnlockAnimBlockIds()

    local isGuide = XDataCenter.AreaWarManager.IsMainUiGuideFinish()
    
    RunAsyn(function()
        local popped = false

        --区块净化进度弹窗
        if XDataCenter.AreaWarManager.CheckHasNewClearBlockId() and isGuide then
            asyncOpenUi("UiAreaWarSszbTips")
            popped = true
        end

        --净化等级变更弹窗
        if XDataCenter.AreaWarManager.CheckHasRecordPfLevel() and isGuide then
            asyncOpenUi("UiAreaWarJingHuaTips")
            popped = true
        end

        --特攻角色解锁弹窗
        if XDataCenter.AreaWarManager.CheckHasRecordSpecialRole() and isGuide then
            asyncOpenUi("UiAreaWarTegongjsTips")
            popped = true
        end

        --挂机收益功能解锁弹窗
        if XDataCenter.AreaWarManager.CheckHangUpUnlockPopUp() and isGuide then
            asyncOpenUi("UiAreaWarHangUpJs")
            XDataCenter.AreaWarManager.SetHangUpUnlockPopUpCookie()
            popped = true
        end

        if XDataCenter.AreaWarManager.CheckNeedPopReward() and isGuide then
            asyncOpenUi("UiAreaWarGift")
            XDataCenter.AreaWarManager.MarkPopReward()
        end

        if XDataCenter.AreaWarManager.GetPersonal():IsLevelUp() and isGuide then
            asyncOpenUi("UiAreaWarCheckLvUp")
            XDataCenter.AreaWarManager.GetPersonal():UpdateLevelCache()
        end

        if popped then
            asyncRequest()
            --通知服务端更新历史记录
            XDataCenter.AreaWarManager.AreaWarPopupRequest()
        end

        --如果正在播放上升动画，则不播解锁动画
        self:TryFocusBlock(playId, ids, asyncPlayUnlock)

        --更新新解锁区块的状态
        self.BlockList3DPanel:RefreshNewUnlockBlocks()


        --清除已经弹窗展示过的最新记录
        XDataCenter.AreaWarManager.ClearNewRecord()

        self.Popping = nil
    end)
end

--虚拟相机更新
function XUiAreaWarMain:UpdateVirtualCamera(showGroup)
    for _, group in pairs(self.VirtualCameraMap) do
        for _, camera in pairs(group.Camera) do
            camera.gameObject:SetActiveEx(false)
        end
    end
    showGroup = showGroup or {}
    for _, camera in pairs(showGroup.Camera) do
        camera.gameObject:SetActiveEx(true)
    end
    self.CameraType = showGroup.Type
end

function XUiAreaWarMain:IsNormalCamera()
    return self.CameraType == CameraType.Normal
end

--- 聊天更新
---@param chatData XChatData
--------------------------
function XUiAreaWarMain:UpdateChatMsg(chatData)
    self.BtnChat:SetNameByGroup(0, "")
    if not chatData then
        return
    end
    if not self.ChatOpen then
        return
    end

    local name = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)
    local content
    if chatData.MsgType == ChatMsgType.Emoji then
        content = string.format("%s:%s", name, XUiHelper.GetText("EmojiText"))
    elseif chatData.MsgType == ChatMsgType.System and chatData.ChannelType == ChatChannelType.Guild then
        content = string.format("%s：%s", XUiHelper.GetText("GuildChannelTypeAll"), chatData.Content)
    else
        content = string.format("%s:%s", name, chatData.Content)
    end
    self.BtnChat:SetNameByGroup(0, content)
end

function XUiAreaWarMain:PlayBlockUnlock(blockId, cb)
    if CS.XAreaWarManager.Instance.IsUnlockPlaying then
        return
    end

    local position = self.BlockList3DPanel:GetBlockWorldPoint(blockId)
    CS.XAreaWarManager.Instance:PlayUnlockAnim(position.x, position.y, position.z,
            function()
                if self.StageDetailBlockId == nil then
                    if self.StageDetailQuestId ~= nil then
                        self:OnCloseQuestDetail(self.StageDetailQuestId)
                    end
                    self.BlockList3DPanel:FocusTargetBlock(blockId)
                end
                self.BlockList3DPanel:RefreshLineState(false)
                self:_UpdateSafeAreaState(false)
            end, function(value)
                if self.StageDetailBlockId == nil and self.StageDetailQuestId == nil then
                    self:_UpdateSafeAreaState(true)
                end
                self.BlockList3DPanel:RefreshLineState(self:IsNormalCamera())
                self.BlockList3DPanel:ResetLinePosition()
                if cb then
                    cb()
                end
            end
    )
end

function XUiAreaWarMain:UpdatePersonal()
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    self.BtnBuff:SetFillAmount(personal:GetExpProgress())
    self.BtnBuff:SetNameByGroup(1, personal:GetLevelName())
end

function XUiAreaWarMain:OnExpChanged()
    RunAsyn(self.SyncOnExpChangedCb)
end

function XUiAreaWarMain:SyncOnExpChanged()
    --等待其他协议返回
    asynWaitSecond(0.8)
    --等待奖励弹窗关闭
    while true do
        if not XLuaUiManager.IsUiShow("UiObtain") then
            break
        end
        asynWaitSecond(0.2)
    end

    local syncPlayTrail = asynTask(function(cb)
        self:PlayTrail(cb)
    end)
    
    syncPlayTrail()
    
    if XDataCenter.AreaWarManager.GetPersonal():IsLevelUp() then
        self:CheckPopups()
    end
end

--endregion------------------界面更新 finish------------------


--region   ------------------UI事件 start-------------------

function XUiAreaWarMain:OnClickBtnProgress()
    XDataCenter.AreaWarManager.RequestWarLog(function()
        XLuaUiManager.Open("UiAreaWarLogbuch")
    end)
end

function XUiAreaWarMain:OnClickBtnProfit()
    XDataCenter.AreaWarManager.OpenUiHangUp()
end

function XUiAreaWarMain:OnClickBtnTask()
    XLuaUiManager.Open("UiAreaWarTask")
end

function XUiAreaWarMain:OnClickBtnShop()
    XDataCenter.AreaWarManager.OpenUiShop()
    self.BtnShop:ShowReddot(false)
end

function XUiAreaWarMain:OnClickBtnBuff()
    --XDataCenter.AreaWarManager.OpenUiPurificationLevel()
    XDataCenter.AreaWarManager.OpenUiGrowLevel()
end

function XUiAreaWarMain:OnClickBtnRole()
    XDataCenter.AreaWarManager.OpenUiSpecialRole()
end

function XUiAreaWarMain:OnClickBtnLocation()
    local nextFightBlockId = XDataCenter.AreaWarManager.GetNextFightingBlockId(self.NextFightingBlockId)
    if not XTool.IsNumberValid(nextFightBlockId) then
        XUiManager.TipText("AreaWarNoBlockFighting")
        return
    end
    self.NextFightingBlockId = nextFightBlockId
    self.BlockList3DPanel:FocusTargetBlock(self.NextFightingBlockId)
end

function XUiAreaWarMain:BtnCheckClick()
    if XDataCenter.AreaWarManager.GetPersonal():IsFinishDailyQuest() then
        XUiManager.TipMsg(XAreaWarConfigs.GetFinishAllQuestTip(1))
        return
    end
    local nextUndoneQuestId = XDataCenter.AreaWarManager.GetNextUndoneQuestId(true, self.NextDailyQuestId)
    if not XTool.IsNumberValid(nextUndoneQuestId) then
        return
    end
    self.NextDailyQuestId = nextUndoneQuestId
    self.BlockList3DPanel:FocusTargetQuest(nextUndoneQuestId)
end

function XUiAreaWarMain:BtnRescueClick()
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    local _, undone = personal:GetRescueQuestCount()
    
    -- 还有未完成的，聚焦对应的模块
    if undone > 0 then
        local nextUndoneQuestId = XDataCenter.AreaWarManager.GetNextUndoneQuestId(false, self.NextRescueQuestId)
        if not XTool.IsNumberValid(nextUndoneQuestId) then
            return
        end
        self.NextRescueQuestId = nextUndoneQuestId
        self.BlockList3DPanel:FocusTargetQuest(nextUndoneQuestId)
        return
    end
    --已经完成，并且已经达到最大刷新次数
    if personal:IsMaxRescueRefresh() then
        XUiManager.TipMsg(XAreaWarConfigs.GetFinishAllQuestTip(2))
        return
    end
    
    local questList = XDataCenter.AreaWarManager.GetPersonal():GetRescueQuestList(true)
    XDataCenter.AreaWarManager.RequestRefreshRescueQuest(function()
        --先将旧的进行移除
        for _, questId in ipairs(questList) do
            self:RemoveQuest(questId)
        end
        
        self:RandomRescueQuest()
        
        self.BlockList3DPanel:UpdateRescueQuest()
        
        self:UpdateQuestProgress()
    end)
end

function XUiAreaWarMain:OnClickBtnChat()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialChat) then
        return
    end
    self:_UpdateSafeAreaState(false)
    XDataCenter.AreaWarManager.OpenUiChat()
end

function XUiAreaWarMain:OnClickBtnRank()
    XLuaUiManager.Open("UiAreaWarInformation")
end

--打开关卡详情
function XUiAreaWarMain:OnOpenStageDetail(blockId, hideRankPanel)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    self.StageDetailBlockId = blockId

    --相机推进
    self:UpdateVirtualCamera(self.VirtualCameraMap.StageDetail)

    --锁定区块
    self.BlockList3DPanel:FocusBlockDetail(blockId)

    if not hideRankPanel then
        --更新区块排行榜, 并挂载到对应区块父节点上，然后打开
        self.RankPanel:Refresh(blockId)
        self.BlockList3DPanel:SetAsBlockChild(self.RankPanel.Transform, blockId)
        self.RankPanel:Show()
    end

    --隐藏2DUI
    self:_UpdateSafeAreaState(false)
end

--关闭关卡详情
function XUiAreaWarMain:OnCloseStageDetail(blockId)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.StageDetailBlockId = nil

    --关闭区块排行榜
    self.RankPanel:Hide()

    --相机恢复
    self:UpdateVirtualCamera(self.VirtualCameraMap.Normal)

    --还原相机跟随目标
    self.BlockList3DPanel:FocusTargetBlock(blockId)

    --播放格子的远景动画
    self.BlockList3DPanel:PlayGridFarAnim(blockId)

    --显示2DUI
    self:_UpdateSafeAreaState(true)
end

--打开探索详情
function XUiAreaWarMain:OnOpenQuestDetail(questId)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.StageDetailQuestId = questId

    --相机推进
    self:UpdateVirtualCamera(self.VirtualCameraMap.StageDetail)

    --锁定区块
    self.BlockList3DPanel:FocusQuestDetail(questId)

    --隐藏2DUI
    self:_UpdateSafeAreaState(false)
end

function XUiAreaWarMain:OnCloseQuestDetail(questId)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.StageDetailQuestId = nil

    --相机恢复
    self:UpdateVirtualCamera(self.VirtualCameraMap.Normal)

    --还原相机跟随目标
    self.BlockList3DPanel:FocusTargetQuest(questId)

    --播放格子的远景动画
    self.BlockList3DPanel:PlayQuestFarAnim(questId)

    --显示2DUI
    self:_UpdateSafeAreaState(true)
end

--区域被点击
function XUiAreaWarMain:OnClickBlock(blockId)
    if CS.XAreaWarManager.Instance.IsUnlockPlaying then
        return
    end

    if XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.WorldBoss) then
        --世界Boss类型区块有独立的主UI
        local asynOpenUi = asynTask(XDataCenter.AreaWarManager.OpenUiWorldBoss)
        local asynPlayAnimation = asynTask(self.PlayAnimationWithMask, self)
        RunAsyn(
                function()
                    self:StopActivityDataTimer()
                    self:OnOpenStageDetail(blockId, true)
                    asynPlayAnimation("DarkEnable")
                    asynOpenUi(blockId)
                    asynWaitSecond(0) --等待UI完全重新打开之后再播放动画
                    self:OnCloseStageDetail(blockId)
                    asynPlayAnimation("DarkDisable")
                    self:StartActivityDataTimer()
                end
        )
    elseif XAreaWarConfigs.CheckBlockShowType(blockId, XAreaWarConfigs.BlockShowType.Mystery) then
        --神秘类型区块只播放剧情
        local movieId = XAreaWarConfigs.GetBlockMovieId(blockId)
        XDataCenter.MovieManager.PlayMovie(movieId)
    else
        --打开区块详情界面
        XLuaUiManager.Open("UiAreaWarStageDetail", false, blockId, self.IsRepeatChallenge, handler(self, self
                .OnCloseStageDetail))
        self:OnOpenStageDetail(blockId)
    end
end

--探索被点击
function XUiAreaWarMain:OnClickQuest(questId)
    if CS.XAreaWarManager.Instance.IsUnlockPlaying then
        return
    end
    --打开区块详情界面
    XLuaUiManager.Open("UiAreaWarStageDetail", true, questId, handler(self, self.OnCloseQuestDetail))
    self:OnOpenQuestDetail(questId)
end

--缩放回调 -（双指 + 鼠标）
function XUiAreaWarMain:OnCameraZoom(value)
    if CS.XAreaWarManager.Instance.IsUnlockPlaying then
        return
    end
    if not self:IsNormalCamera() then
        return
    end
    value = CsMathFClamp(self.NearFraming.m_CameraDistance - value, self.MinDistance, self.MaxDistance)
    self.ScaleSlider.value = self:CalSliderPercent(value)
end

--缩放回调 - UI滑动
function XUiAreaWarMain:OnCameraZoomBySlider(value)
    self.BlockList3DPanel:PlayScaleAnim(value <= self.SmallDisRatio)
    if CS.XAreaWarManager.Instance.IsUnlockPlaying then
        return
    end

    if not self:IsNormalCamera() then
        return
    end

    value = (self.MaxDistance - self.MinDistance) * (1 - value) + self.MinDistance
    self.NearFraming.m_CameraDistance = value
    self.FarFraming.m_CameraDistance = value
end

--计算Slider的值， value [min,max]
function XUiAreaWarMain:CalSliderPercent(value)
    return CS.UnityEngine.Mathf.Clamp01(self.FactorK * value + self.ConstantB)
end

--聊天界面关闭
function XUiAreaWarMain:OnChatClose()
    self:_UpdateSafeAreaState(true)
end

--刷新主界面UI状态
function XUiAreaWarMain:_UpdateSafeAreaState(state)
    state = state and self.GameObject.activeInHierarchy
    self.SafeAreaContentPane.gameObject:SetActiveEx(state)
    if state then
        self.AssetActivityPanel:Open()
    else
        self.AssetActivityPanel:Close()
    end
    local animName = state and "UiEnable" or "UiDisable"
    self:PlayAnimationWithMask(animName)
end

function XUiAreaWarMain:PlayPlateLiftAnim(finishCb)
    if self.PlateTimer then
        return
    end
    local newFinish = function()
        self:StopPlateLiftAnim()
        if finishCb then
            finishCb()
        end
    end
    self.BlockList3DPanel:RefreshLineState(false)
    self.PlateTimer = XUiHelper.Tween(self.PlateDuration, self.OnPlayPlateAnim, newFinish)
end

function XUiAreaWarMain:StopPlateLiftAnim()
    if not self.PlateTimer then
        return
    end
    self:OnStopPlateLiftAnim()
    XScheduleManager.UnSchedule(self.PlateTimer)
    self.PlateTimer = nil

    local playId, ids = XDataCenter.AreaWarManager.GetNotPlayUnlockAnimBlockIds()

    if XTool.IsNumberValid(playId) then
        local asyncPlayUnlock = asynTask(self.OnPlayUnlockAnim)

        RunAsyn(function()
            asynWaitSecond(0.3)
            XLuaUiManager.SetMask(true)
            --播放格子解锁动画
            asyncPlayUnlock(playId)

            --标记
            for _, blockId in ipairs(ids) do
                XDataCenter.AreaWarManager.MarkPlayUnlockAnimBlockId(blockId)
            end

            XLuaUiManager.SetMask(false)
        end)
    end


end

function XUiAreaWarMain:OnRefreshPlate(time)
    if XTool.IsTableEmpty(self.PlayPlates) then
        self:StopPlateLiftAnim()
        return
    end

    CS.XAreaWarManager.Instance:RevertPositionGroup(self.PlayPlates, time)
end

function XUiAreaWarMain:OnStopPlateLiftAnim()
    local instance = CS.XAreaWarManager.Instance
    for _, plateId in ipairs(self.PlayPlates) do
        instance:RevertPosition(plateId, 1)
        XDataCenter.AreaWarManager.MarkPlayPlateAnim(plateId)
    end
    self.PlayPlates = {}

    self.BlockList3DPanel:RefreshLineState(self:IsNormalCamera())
    self.BlockList3DPanel:ResetLinePosition()
end

function XUiAreaWarMain:OnUiDestroy(ui)
    if not XDataCenter.AreaWarManager.IsFirstOpenHelp() then
        return
    end
    if not ui or not ui.UiData then
        return
    end
    local uiName = ui.UiData.UiName
    if uiName == "UiHelp" then
        self:CheckPopups()
        XDataCenter.AreaWarManager.MarkFirstOpenHelp()
    elseif uiName == "UiAreaWarLogbuch" then
        self:OnCheckWarLogRedPoint()
    end

end
--endregion------------------UI事件 finish------------------


--region   ------------------定时器 start-------------------

--检查活动是否结束，每秒执行一次
function XUiAreaWarMain:OnCheckActivity(isClose)
    if isClose then
        XDataCenter.AreaWarManager.OnActivityEnd()
        return
    end
    local timeOfNow = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(self.EndTime - timeOfNow, XUiHelper.TimeFormatType.ACTIVITY)
    if self.IsRepeatChallenge and self.ChapterStartTime then
        --倒计时
        local remainder = math.max(0, self.ChapterStartTime - timeOfNow)
        self.TxtRepeatTime.text = string.format(self.RepeatChallengeCountDown, XUiHelper.GetTime(remainder, XUiHelper.TimeFormatType.SHOP_REFRESH))
        if remainder <= 0 then
            self:UpdateRepeatChallenge()
        end
    end
    local countDown = self.TomorrowFreshTime - timeOfNow
    if countDown <= 0 then
        self.TomorrowFreshTime = XTime.GetSeverTomorrowFreshTime()
        countDown = self.TomorrowFreshTime - timeOfNow
    end
    self.TxtRefreshTime.text = XUiHelper.GetTime(countDown, XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XUiAreaWarMain:StartActivityDataTimer()
    if self.ActivityDataTimer then
        return
    end
    self.ActivityDataTimer = XScheduleManager.ScheduleForever(function()
        XDataCenter.AreaWarManager.AreaWarGetActivityDataRequest()
    end, AUTO_REQ_ACTIVITY_DATA_INTERVAL)
end

function XUiAreaWarMain:StopActivityDataTimer()
    if not XTool.IsNumberValid(self.ActivityDataTimer) then
        return
    end
    XScheduleManager.UnSchedule(self.ActivityDataTimer)
    self.ActivityDataTimer = nil
end

--endregion------------------定时器 finish------------------


--region   ------------------红点检查 start-------------------

function XUiAreaWarMain:OnCheckProfitRedPoint(count)
    self.BtnProfit:ShowReddot(count >= 0)
end

function XUiAreaWarMain:OnCheckTaskRedPoint(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiAreaWarMain:OnCheckShopRedPoint(count)
    self.BtnShop:ShowReddot(count >= 0)
end

function XUiAreaWarMain:OnCheckBuffRedPoint(count)
    self.BtnBuff:ShowReddot(count >= 0)
end

function XUiAreaWarMain:OnCheckRoleRedPoint(count)
    self.BtnRole:ShowReddot(count >= 0)
end

function XUiAreaWarMain:OnCheckWarLogRedPoint()
    XDataCenter.AreaWarManager.RequestWarLog(function()
        local hasNew = XDataCenter.AreaWarManager.CheckIsNewUnlockArticle()
        self.BtnProgress:ShowReddot(hasNew)
    end)
end

--endregion------------------红点检查 finish------------------



--region   ------------------探索任务 start-------------------

function XUiAreaWarMain:RemoveQuest(questId, isRescue)
    local list = isRescue and self.RescueTransformList or self.DailyTransformList

    if list and list.Count > 0 then
        local index
        for i = 0, list.Count - 1 do
            if self.BlockList3DPanel:IsQuestTransform(questId, list[i]) then
                index = i
                break
            end
        end

        if index then
            list:RemoveAt(index)
        end
    end
    self.BlockList3DPanel:RemoveQuest(questId)
end

function XUiAreaWarMain:OnQuestFinish(questId, isRescue)
    self:RemoveQuest(questId, isRescue)
    self:UpdateQuestProgress()
end


function XUiAreaWarMain:RandomDailyQuest()
    local count = XAreaWarConfigs.GetDailyBattleNum()
    self.DailyTransformList = self:RandomQuest(count, false, nil)
end

function XUiAreaWarMain:RandomRescueQuest()
    local count = XAreaWarConfigs.GetDailyHelpNum()
    self.RescueTransformList = self:RandomQuest(count, true, self.DailyTransformList)
end

function XUiAreaWarMain:RandomQuest(questCount, isRescue, exclude)
    if questCount <= 0 then
        return
    end
    
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    local randomSeed = XDataCenter.AreaWarManager.GetRandomSeed(isRescue)
    local randomBlockIds = personal:GetRandomBlockIds()
    local radius = XAreaWarConfigs.GetRandomRadius(randomBlockIds)
    
    local instance = CS.XAreaWarManager.Instance
    local plateIds = XAreaWarConfigs.GetPlateIdsByBlockIds(randomBlockIds)
    local questTransformList = instance:RandomBlock(randomBlockIds, plateIds, questCount, randomSeed, radius, exclude)
    while (questTransformList.Count < questCount) do
        local preIds = {}
        for _, blockId in ipairs(randomBlockIds) do
            preIds = XTool.MergeArray(preIds, XAreaWarConfigs.GetAllPreBlockIds(blockId))
        end
        randomBlockIds = XTool.MergeArray(randomBlockIds, preIds)

        radius = XAreaWarConfigs.GetRandomRadius(randomBlockIds)
        plateIds = XAreaWarConfigs.GetPlateIdsByBlockIds(randomBlockIds)
        questTransformList = instance:RandomBlock(randomBlockIds, plateIds, questCount, randomSeed, radius, exclude)
    end
    personal:TrySetRandomBlockIds(randomBlockIds)
    return questTransformList
end

function XUiAreaWarMain:RefreshQuests(refreshType, listDaily, listRescue)
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    if refreshType == XAreaWarConfigs.RefreshQuestType.All then
        personal:TryClearLocal()
        for _, questId in ipairs(listDaily) do
            self:RemoveQuest(questId, false)
        end
        for _, questId in ipairs(listRescue) do
            self:RemoveQuest(questId, true)
        end
        
        self:RandomDailyQuest()
        self:RandomRescueQuest()
        self.BlockList3DPanel:UpdateDailyQuest()
        self.BlockList3DPanel:UpdateRescueQuest()
    elseif refreshType == XAreaWarConfigs.RefreshQuestType.Daily then
        if not XTool.IsTableEmpty(listDaily) then
            for _, questId in ipairs(listDaily) do
                self:RemoveQuest(questId)
            end
        end
        self:RandomDailyQuest()
        self.BlockList3DPanel:UpdateDailyQuest()
    elseif refreshType == XAreaWarConfigs.RefreshQuestType.Rescue then
        if not XTool.IsTableEmpty(listRescue) then
            for _, questId in ipairs(listRescue) do
                self:RemoveQuest(questId)
            end
        end
        self:RandomRescueQuest()
        self.BlockList3DPanel:UpdateRescueQuest()
    end

    self:UpdateQuestProgress()
end

function XUiAreaWarMain:TryFocusBlock(newOpenId, newOpenIds, syncPlayUnlock)
    -- 引导中聚焦
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    -- 如果今天没有聚焦过关联关卡
    local personal = XDataCenter.AreaWarManager.GetPersonal()
    if personal:CheckTodayFocus() then
        local randomBlockIds = personal:GetRandomBlockIds()
        if not XTool.IsTableEmpty(randomBlockIds) then
            XLuaUiManager.SetMask(true)
            self.BlockList3DPanel:FocusTargetBlock(randomBlockIds[1])
            XLuaUiManager.SetMask(false)
        end
        personal:MarkTodayFocus()
        
        return
    end
    
    --如果有新增关卡
    if XTool.IsNumberValid(newOpenId) and not self.PlateTimer then
        XLuaUiManager.SetMask(true)
        syncPlayUnlock(newOpenId)

        for _, blockId in ipairs(newOpenIds) do
            XDataCenter.AreaWarManager.MarkPlayUnlockAnimBlockId(blockId)
        end
        XLuaUiManager.SetMask(false)
    end
end

function XUiAreaWarMain:TryGetQuestTransform(isDaily, index)
    local list = isDaily and self.DailyTransformList or self.RescueTransformList
    if not list then
        return
    end
    local count = list.Count
    if count <= index then
        local log = string.format("获取任务节点的Transform出错 战斗任务：%s 下标：%s", tostring(isDaily), index)
        XLog.Error(log)
        return
    end
    return list[index]
end

--endregion------------------探索任务 finish------------------

function XUiAreaWarMain:PlayTrail(cb)
    if self.IsTrailRunning then
        return
    end
    if not self.Trail then
        local trail = self.EffectRoot.transform:LoadPrefab(XAreaWarConfigs.GetTrailEffectUrl())
        local effectLayer = self.EffectRoot.gameObject:GetComponent("XUiEffectLayer")
        if effectLayer then
            effectLayer:Init()
        end
        trail.transform.localPosition = Vector3.zero
        self.Trail = trail
    end

    if XTool.UObjIsNil(self.Trail) then
        return
    end
    
    self.IsTrailRunning = true
    self.Trail.gameObject:SetActiveEx(true)
    self.Trail.transform:DOMove(self.BtnBuff.transform.position, 0.7):SetEase(CsEase.OutQuart):OnComplete(function() 
        self:OnTrailArrived(cb)
    end)
end

function XUiAreaWarMain:OnTrailArrived(cb)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    
    if cb then cb() end
    
    --策划想要界面打开时，特效才绽放
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        if XTool.UObjIsNil(self.BtnBuff) then
            return
        end
        self.BtnBuff:ShowTag(false)
        self.BtnBuff:ShowTag(true)
        
        if XTool.UObjIsNil(self.Trail) then
            return
        end
        self.Trail.gameObject:SetActiveEx(false)
        self.Trail.transform.localPosition = Vector3.zero
        self:UpdatePersonal()
    end, 100)
    
    XScheduleManager.ScheduleOnce(function()
        self.IsTrailRunning = false
        
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        
        if XTool.UObjIsNil(self.BtnBuff) then
            return
        end
        self.BtnBuff:ShowTag(false)
    end, 2100)
end