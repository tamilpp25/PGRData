local XGoldenMinerBuffTipData = require("XModule/XGoldenMiner/Data/Game/XGoldenMinerBuffTipData")
local XGoldenMinerReportInfo = require("XModule/XGoldenMiner/Data/Settle/XGoldenMinerReportInfo")
local XGoldenMinerItemChangeInfo = require("XModule/XGoldenMiner/Data/Settle/XGoldenMinerItemChangeInfo")
local XGoldenMinerSettlementInfo = require("XModule/XGoldenMiner/Data/Settle/XGoldenMinerSettlementInfo")
local XUiGoldenMinerItemPanel = require("XUi/XUiGoldenMiner/Panel/XUiGoldenMinerItemPanel")
local XUiGoldenMinerBuffPanel = require("XUi/XUiGoldenMiner/Panel/XUiGoldenMinerBuffPanel")
local XUiGoldenMinerFaceEmojiPanel = require("XUi/XUiGoldenMiner/Game/XUiGoldenMinerFaceEmojiPanel")

---@type UnityEngine.Time
local UnityTime = CS.UnityEngine.Time
---@type UnityEngine.RectTransformUtility
local RectTransformUtility = CS.UnityEngine.RectTransformUtility

local TIME_OFFSET = 0.99     --秒，补足倒计时为0时舍弃的0.9几秒
--玩法倒计时颜色
local TxtTimeColor = {
    [true] = CS.UnityEngine.Color.white,
    [false] = CS.UnityEngine.Color.red
}
local CurAim = {
    None = 0,
    Left = 1 << 0,
    Right = 1 << 1,
}
local EFFECT_CD = 0.5
local NeedCheckEffectCDType = {
    [XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.GRAB] = true,
    [XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.SHIP_GRAB] = true,
}

local GAME_COUNT_DOWN_TIME_CUR_ID = 4971

---黄金矿工 玩法界面
---@class XUiGoldenMinerGameBattle : XLuaUi
---@field _Game XGoldenMinerGameControl
---@field _Control XGoldenMinerControl
---@field BtnMove XGoInputHandler
---@field GoInputHandler XGoInputHandler
---@field BtnShootHandler XGoInputHandler
---@field AimLeftInputHandler XGoInputHandler
---@field AimRightInputHandler XGoInputHandler
---@field ElectromagneticBox XGoInputHandler
local XUiGoldenMinerGameBattle = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerBattle")

function XUiGoldenMinerGameBattle:OnAwake()
    self:AddBtnClickListener()
end

function XUiGoldenMinerGameBattle:OnStart()
    self:InitData()
    self:InitObj()
    self:InitUi()
    self:InitAutoCloseTimer()

    self:AddEventListener()
    self:GameStart()
end

function XUiGoldenMinerGameBattle:OnEnable()
    self:AddPCListener()

    self:RefreshUi()
    self:StartGamePauseAnim()
    self._TickTimer = XScheduleManager.ScheduleForever(handler(self, self._UpdateHandler), 0)
end

function XUiGoldenMinerGameBattle:OnDisable()
    if XTool.IsNumberValid(self._TickTimer) then
        XScheduleManager.UnSchedule(self._TickTimer)
        self._TickTimer = nil
    end
    self:RemovePCListener()
end

function XUiGoldenMinerGameBattle:OnDestroy()
    self:RemoveEventListener()
    if self._Game then
        self._Game:ExitGame()
    end
    self._Game = nil
    self:ReleaseObj()
end

function XUiGoldenMinerGameBattle:_UpdateHandler()
    self:_UpdateEffectCD()
end

--region Activity - AutoClose
function XUiGoldenMinerGameBattle:InitAutoCloseTimer()
    self:SetAutoCloseInfo(self._Control:GetCurActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEndTime()
            return
        end
    end, nil, 0)
end
--endregion

--region Init - Data
function XUiGoldenMinerGameBattle:InitData()
    self._DataDb = self._Control:GetMainDb()
    self._CurStageId, self._CurStageIndex = self._DataDb:GetCurStageId()
    self._MapId = self._DataDb:GetStageMapId(self._CurStageId)
    self._ScoreTarget = self._DataDb:GetCurStageTargetScore()
    self._AddTimeTipPosition = self.TxtAddTimeTip.transform.position
    self._MoveRecordCount = 0

    --Game
    self._OwnBuffList = self._Control:GetOwnBuffDic()
    self._HookType = self:_SetDataHookType()

    --Aim
    self._CurAnim = CurAim.None

    --Settle
    ---@type XGoldenMinerSettlementInfo
    self._SettlementInfo = XGoldenMinerSettlementInfo.New()
    ---@type XGoldenMinerReportInfo
    self._ReportInfo = XGoldenMinerReportInfo.New()
    self._IsCloseBattle = false
    self._IsFinishSuccess = false
    self._IsOpenHideStage = false
    self._IsInSunMoonCD = false
    self._EffectCDWithTypeMap = {}
end

function XUiGoldenMinerGameBattle:_SetDataHookType()
    if XTool.IsTableEmpty(self._OwnBuffList) then
        return XEnumConst.GOLDEN_MINER.HOOK_TYPE.NORMAL
    end
    local type = XEnumConst.GOLDEN_MINER.HOOK_TYPE.NORMAL
    for buffType, params in pairs(self._OwnBuffList) do
        if buffType == XEnumConst.GOLDEN_MINER.BUFF_TYPE.CORD_MODE then
            return params[1]
        elseif buffType == XEnumConst.GOLDEN_MINER.BUFF_TYPE.ROLE_HOOK then
            type = params[1]
        end
    end
    return type
end
--endregion

--region Init - Obj
function XUiGoldenMinerGameBattle:InitObj()
    --Game
    self._Game = self._Control:GetGameControl()

    --Pause
    self._GamePauseAnimTimer = nil
    self._GamePauseTimeAnimTimer = nil

    --Hook
    ---@type UnityEngine.Transform[]
    self.HookObjDir = {
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.NORMAL] = self.NormalRope,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.MAGNETIC] = self.MagneticRope,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.BIG] = self.BigRope,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE] = self.AimHook,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.STORE_PRESS_MAGNETIC] = self.MagneticRope,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.DOUBLE] = self.DoubleHook2,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.HAMMER] = self.Hammer,
    }
    ---@type UnityEngine.Collider2D[]
    self.HookColliderDir = {
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.NORMAL] = self.NormalCordCollider,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.MAGNETIC] = self.MagneticRopeCordCollider,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.BIG] = self.BigRopeCordLeftCollider,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE] = self.NormalCordCollider,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.STORE_PRESS_MAGNETIC] = self.MagneticRopeCordCollider,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.DOUBLE] = self.BigRopeCordLeftCollider,
        [XEnumConst.GOLDEN_MINER.HOOK_TYPE.HAMMER] = self.HammerRopeCord,
    }
    for type, obj in pairs(self.HookObjDir) do
        obj.gameObject:SetActiveEx(false)
        self.HookColliderDir[type].gameObject:SetActiveEx(false)
    end

    --Effect
    self._EffectLayer = XUiHelper.TryGetComponent(self.EffectFull, "", "XUiEffectLayer")
    self._EffectRoot = XUiHelper.Instantiate(self.EffectFull.gameObject, self.EffectFull.transform.parent)
    self._EffectResourcePool = {}
    self._EffectObjDir = {}
end

function XUiGoldenMinerGameBattle:ReleaseObj()
    for path, _ in pairs(self._EffectResourcePool) do
        self._Control:GetLoader():Unload(path)
    end

    self._EffectObjDir = nil
    self._EffectResourcePool = nil
    self.HookObjDir = nil
    self.HookColliderDir = nil
    if self.BtnShootHandler then
        self.BtnShootHandler:RemoveAllListeners()
    end
    if self.AimLeftInputHandler then
        self.AimLeftInputHandler:RemoveAllListeners()
    end
    if self.AimRightInputHandler then
        self.AimRightInputHandler:RemoveAllListeners()
    end
    if self.ElectromagneticBox then
        self.ElectromagneticBox:RemoveAllListeners()
    end
    if self.GoInputHandler then
        self.GoInputHandler:RemoveAllListeners()
    end
    if self.BtnMove then
        self.BtnMove:RemoveAllListeners()
    end
    self.GoInputHandler = nil
    self.BtnShootHandler = nil
    self.ElectromagneticBox = nil
    self.AimLeftInputHandler = nil
    self.AimRightInputHandler = nil
end
--endregion

--region Ui - Refresh
function XUiGoldenMinerGameBattle:InitUi()
    self:InitScore()
    self:InitPlayTime()
    self:InitHideTask()
    self:InitItem()
    self:InitBuff()
    self:InitFaceEmoji()
    self:InitPauseGuideUi()
    self:InitBtn()
    self:InitMouseTip()
    self:InitRelic()
    self:InitSlotsScore()
    self:InitSunAndMoon()
end

function XUiGoldenMinerGameBattle:RefreshUi()
    self:RefreshItem()
    self:RefreshBuff()
    self:RefreshGuidePanel()
    self:RefreshPcText()
end
--endregion

--region Ui - Score
function XUiGoldenMinerGameBattle:InitScore()
    self:_SetCurScore(self._DataDb:GetStageScores())
    self.TargetScore.text = XUiHelper.GetText("GoldenMinerPlayTargetScore", self._ScoreTarget)
    self.TxtNumber.text = XUiHelper.GetText("GoldenMinerCurStage", self._CurStageIndex)
    if self.PanelCurScoreChange then
        self.PanelCurScoreChange.gameObject:SetActiveEx(false)
    end
end

function XUiGoldenMinerGameBattle:RefreshScore()
    if XTool.IsNumberValid(self._Game:GetChangeScore()) then
        self:_PlayScoreChange()
    else
        self:_SetCurScore(self._Game:GetCurScore())
    end
end

function XUiGoldenMinerGameBattle:_SetCurScore(score)
    if XTool.UObjIsNil(self.CurScore) then
        return
    end
    self.CurScore.text = XUiHelper.GetText("GoldenMinerPlayCurScoreRichTxt",
            self._Control:GetClientGameScoreColorCode(score >= self._ScoreTarget),
            score)
end

function XUiGoldenMinerGameBattle:_PlayScoreChange()
    if self._PlayScoreChangeTimer then
        self._ChangeScore = self._ChangeScore + self._Game:GetChangeScore()
    else
        self._OldScore = self._Game:GetOldScore()
        self._ChangeScore = self._Game:GetChangeScore()
    end

    if not self._PlayScoreChangeTimer then
        self.PanelCurScoreChange.gameObject:SetActiveEx(true)
        self:PlayAnimation("BubbleEnable", function()
            self.PanelCurScoreChange.gameObject:SetActiveEx(false)
        end)
    end
    self._PlayScoreChangeTimer = XUiHelper.Tween(1, function(f)
        if not self._Game then
            return
        end
        self:_SetCurScore(math.floor(self._OldScore + self._ChangeScore * f))
    end, function()
        self._PlayScoreChangeTimer = nil
        if not self._Game then
            return
        end
        self:_SetCurScore(self._Game:GetCurScore())
    end)
    self.TxtCurScoreChange.text = "+" .. self._ChangeScore
end
--endregion

--region Ui - PlayTime
function XUiGoldenMinerGameBattle:InitPlayTime()
    local time = self._Control:GetCfgMapTime(self._MapId) + TIME_OFFSET
    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    self.TxtTime.color = TxtTimeColor[true]
end

function XUiGoldenMinerGameBattle:RefreshPlayTime()
    self:_SetTxtTime(self._Game:GetGameData():GetTime())
end

function XUiGoldenMinerGameBattle:AddPlayTime(addTime)
    self:_SetTxtTime(self._Game:GetGameData():GetTime())
    self:_PlayAddPlayTime(addTime)
end

function XUiGoldenMinerGameBattle:_PlayAddPlayTime(addTime)
    self.TxtAddTimeTip.transform.position = self._AddTimeTipPosition
    self.TxtAddTimeTip.gameObject:SetActive(true)
    self.TxtAddTimeTip.text = "+" .. addTime
    local endY = self.TxtAddTimeTip.transform.localPosition.y + self._Control:GetClientTipAnimMoveLength()
    local time = self._Control:GetClientTipAnimTime() / XScheduleManager.SECOND
    self.TxtAddTimeTip.transform:DOLocalMoveY(endY, time)
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.TxtAddTimeTip.gameObject:SetActive(false)
    end, self._Control:GetClientTipAnimTime())
end

local _IsNearEnd
local _IsPlayTimeEnable
function XUiGoldenMinerGameBattle:_SetTxtTime(time)
    if not XTool.IsNumberValid(self._CurNearEndTime) then
        self._CurNearEndTime = time - 1
    end

    _IsPlayTimeEnable = time - self._CurNearEndTime < 0
    _IsNearEnd = time <= self._Control:GetClientGameNearEndTime()

    --临近结束时间后，每隔1秒播放一次动画
    if _IsNearEnd and _IsPlayTimeEnable then
        self._CurNearEndTime = time - 1
        self:PlayAnimation("TimeEnable")
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, GAME_COUNT_DOWN_TIME_CUR_ID)
    end

    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    self.TxtTime.color = TxtTimeColor[not _IsNearEnd]
end
--endregion

--region Ui - HideTask
function XUiGoldenMinerGameBattle:InitHideTask()
    if not self.Task then
        return
    end
    self.Task.gameObject:SetActiveEx(false)
end

---@param hideTaskInfo XGoldenMinerHideTaskInfo
function XUiGoldenMinerGameBattle:HideTaskFinish(hideTaskInfo)
    if not self.Task then
        return
    end
    local progress = hideTaskInfo:IsFinish() and XUiHelper.GetText("GoldenMinerHideTaskComplete") or hideTaskInfo:GetTxtShowProgress()
    self.Task.gameObject:SetActiveEx(true)
    self.Task.text = XUiHelper.GetText("GoldenMinerHideTaskShowTxt", hideTaskInfo:GetCfgDesc(), progress)
end
--endregion

--region Ui - Item
function XUiGoldenMinerGameBattle:InitItem()
    ---@type XUiGoldenMinerItemPanel
    self.ItemPanel = XUiGoldenMinerItemPanel.New(self.PanelSkillParent, self, true)
end

function XUiGoldenMinerGameBattle:RefreshItem()
    self.ItemPanel:UpdateItemColumns()
end

function XUiGoldenMinerGameBattle:AddItem(itemId)
    if not XTool.IsNumberValid(itemId) then
        return
    end
    local itemColumnIndex = self._DataDb:GetEmptyItemIndex()
    if not itemColumnIndex then
        return
    end

    self._DataDb:UpdateItemColumn(itemId, itemColumnIndex)
    self:UpdateItemChangeInfo(itemColumnIndex, XEnumConst.GOLDEN_MINER.ITEM_CHANGE_TYPE.ON_GET)
    self:RefreshItem()
    self:_PlayAddItem(itemId)
end

function XUiGoldenMinerGameBattle:UpdateItemChangeInfo(itemGridIndex, status)
    local itemChangeInfo = XGoldenMinerItemChangeInfo.New()
    local itemDb = self._DataDb:GetItemColumnByIndex(itemGridIndex)
    itemChangeInfo:UpdateData({
        ItemId = itemDb:GetClientItemId(),
        Status = status,
        GridIndex = itemGridIndex
    })
    self._SettlementInfo:InsertSettlementItem(itemChangeInfo)
end

function XUiGoldenMinerGameBattle:_PlayAddItem(itemId)
    self.TxtAddItemTip.gameObject:SetActive(true)
    self.TxtAddItemTip.text = "+1"
    self.TxtAddItemTip.transform.position = self.Humen.transform.position
    self.RImgAddItemIcon:SetRawImage(self._Control:GetCfgItemIcon(itemId))
    local endY = self.TxtAddItemTip.transform.localPosition.y + self._Control:GetClientTipAnimMoveLength()
    local time = self._Control:GetClientTipAnimTime() / XScheduleManager.SECOND
    self.TxtAddItemTip.transform:DOLocalMoveY(endY, time)
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.TxtAddItemTip.gameObject:SetActive(false)
    end, self._Control:GetClientTipAnimTime())
end
--endregion

--region Ui - Buff
function XUiGoldenMinerGameBattle:InitBuff()
    ---@type XUiGoldenMinerBuffPanel
    self.BuffPanel = XUiGoldenMinerBuffPanel.New(self.PanelBuffParent, self)

    ---@type XGoldenMinerBuffTipData[]
    self._NeedTipBuffDir = {}
    ---@type XGoldenMinerBuffTipData
    self._CurBuffEntity = false

    ---@type UnityEngine.Transform
    self.BuffBubble = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Bubble")
    ---@type UnityEngine.Transform
    self.TxtBuffTip = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Bubble/Txt3", "Text")
    if self.BuffBubble then
        self.BuffBubble.gameObject:SetActiveEx(false)
    end
end

function XUiGoldenMinerGameBattle:RefreshBuff()
    self.BuffPanel:UpdateBuff(self._Control:GetShowOwnBuffIdList())
end

function XUiGoldenMinerGameBattle:RefreshGuidePanel()
    if self.TxtGuideDesc then
        self.TxtGuideDesc.text = self._Control:GetClientGuideTipsText(self._Game.SystemHook:CheckHasAimHook())
    end
end

function XUiGoldenMinerGameBattle:RefreshPcText()
    if self.TxtPC then
        self.TxtPC.text = self._Control:GetClientTextPCControl(self._Game.SystemHook:CheckHasAimHook())
    end
end

function XUiGoldenMinerGameBattle:AddBuffTip(itemId)
    if self._Control:GetCfgItemTipsType(itemId) == XEnumConst.GOLDEN_MINER.BUFF_TIP_TYPE.NONE then
        return
    end
    if XTool.IsTableEmpty(self._NeedTipBuffDir) then
        ---@type XGoldenMinerBuffTipData
        self._NeedTipBuffDir[#self._NeedTipBuffDir + 1] = XGoldenMinerBuffTipData.New(itemId)
    else
        local isHave = false
        for _, buffTipEntity in ipairs(self._NeedTipBuffDir) do
            if buffTipEntity.ItemId == itemId then
                buffTipEntity:ResetStatus()
                isHave = true
            end
        end
        if not isHave then
            self._NeedTipBuffDir[#self._NeedTipBuffDir + 1] = XGoldenMinerBuffTipData.New(itemId)
        end
    end
end

function XUiGoldenMinerGameBattle:RefreshBuffTip(time)
    if XTool.IsTableEmpty(self._NeedTipBuffDir) or not self.BuffBubble then
        return
    end
    self:_UpdateBuffTipEntity(time)
    self:_UpdateBuffTip()
end

function XUiGoldenMinerGameBattle:_UpdateBuffTipEntity(time)
    local isDelete = false

    for _, buffTipEntity in ipairs(self._NeedTipBuffDir) do
        if buffTipEntity:GetTipType(self._Control) == XEnumConst.GOLDEN_MINER.BUFF_TIP_TYPE.UNTIL_DIE then
            for uid, _ in pairs(self._Game.SystemBuff:GetBuffUidListByType(buffTipEntity:GetBuffType(self._Control))) do
                local buff = self._Game:GetBuffEntityByUid(uid)
                if buffTipEntity:GetBuffId(self._Control) == buff:GetId() then
                    buffTipEntity.ShowParam = buff.CurTimeTypeParam
                    buffTipEntity.IsDie = buff.Status > XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.ALIVE
                    isDelete = buff.Status > XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.ALIVE
                end
            end
        elseif buffTipEntity:GetTipType(self._Control) == XEnumConst.GOLDEN_MINER.BUFF_TIP_TYPE.ONCE then
            buffTipEntity.CurTime = buffTipEntity.CurTime - time
            if buffTipEntity.CurTime <= 0 then
                buffTipEntity.IsDie = true
                isDelete = true
            end
        end
    end

    if isDelete then
        local newBuffTipEntity = {}
        for _, buffTipEntity in ipairs(self._NeedTipBuffDir) do
            if not buffTipEntity.IsDie then
                newBuffTipEntity[#newBuffTipEntity + 1] = buffTipEntity
            end
        end
        self._NeedTipBuffDir = nil
        self._NeedTipBuffDir = newBuffTipEntity
    end
end

function XUiGoldenMinerGameBattle:_UpdateBuffTip()
    if XTool.IsTableEmpty(self._NeedTipBuffDir) then
        self:_StopBuffTip()
        return
    end
    if self._CurBuffEntity then
        if self._CurBuffEntity ~= self._NeedTipBuffDir[#self._NeedTipBuffDir] or
                self._CurBuffEntity:GetTipType(self._Control) == XEnumConst.GOLDEN_MINER.BUFF_TIP_TYPE.UNTIL_DIE then
            self:_PlayBuffTip()
        end
    else
        self:_PlayBuffTip()
    end
    self:_PlayBuffTip()
end

function XUiGoldenMinerGameBattle:_PlayBuffTip()
    self._CurBuffEntity = self._NeedTipBuffDir[#self._NeedTipBuffDir]
    if self.BuffBubble then
        self.BuffBubble.gameObject:SetActiveEx(true)
        self.TxtBuffTip.text = self._CurBuffEntity:GetBuffTipTxt(self._Control)
    end
end

function XUiGoldenMinerGameBattle:_StopBuffTip()
    self._CurBuffEntity = false
    if self.BuffBubble then
        self.BuffBubble.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - FaceEmoji
function XUiGoldenMinerGameBattle:InitFaceEmoji()
    ---@type XUiGoldenMinerFaceEmojiPanel
    self._FaceEmojiPanel = XUiGoldenMinerFaceEmojiPanel.New(self.PanelEmoticon, self, self._Game)
    self._FaceEmojiPanel:Open()
    self._FaceEmojiPanel:Close()
end

function XUiGoldenMinerGameBattle:RefreshFaceEmoji(time)
    self._FaceEmojiPanel:RefreshFaceEmoji(time)
end

function XUiGoldenMinerGameBattle:_PlayEmoticonAnim(isEnable)
    if isEnable then
        self:PlayAnimation("PanelEmoticonEnable", function()
            self._FaceEmojiPanel:SetIsAfterAnim()
        end)
    else
        self:PlayAnimation("PanelEmoticonDisable", function()
            self._FaceEmojiPanel:SetIsAfterAnim()
        end)
    end
end

---@param type number XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE
function XUiGoldenMinerGameBattle:PlayFaceEmoji(type, faceId)
    self._FaceEmojiPanel:PlayFaceEmoji(type, faceId)
end

function XUiGoldenMinerGameBattle:PlayFaceEmojiByUseItem(itemId)
    self._FaceEmojiPanel:PlayFaceEmojiByUseItem(itemId)
end
--endregion

--region Ui - Pause Dialog
function XUiGoldenMinerGameBattle:InitPauseGuideUi()
    local isPc = XDataCenter.UiPcManager.IsPc()
    if self.PanelGuide then
        self.PanelGuide.gameObject:SetActiveEx(false)
    end
    if self.PanelMP then
        self.PanelMP.gameObject:SetActiveEx(not isPc)
    end
    if self.TxtPC then
        self.TxtPC.gameObject:SetActiveEx(isPc)
    end
    if self.TxtGuideShoot then
        self.TxtGuideShoot.text = self._Control:GetCfgHookButtonTip(self._HookType)
        self.TxtGuideHook.text = self._Control:GetCfgHookShipTip(self._HookType)
    end
    local isSunAndMoonMap = self._Control:CheckIsSunAndMoonMap(self._MapId)
    if self.GuideChangeSunMoonTip then
        self.GuideChangeSunMoonTip.gameObject:SetActiveEx(isSunAndMoonMap)
    end
    if self.GuideChangeSunMoonNoMask then
        self.GuideChangeSunMoonNoMask.gameObject:SetActiveEx(isSunAndMoonMap)
    end
end

function XUiGoldenMinerGameBattle:StartGamePauseAnim()
    self:StopGamePauseAnim()
    local time = self._Control:GetClientGameStopCountdown()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, XEnumConst.GOLDEN_MINER.GAME_PAUSE_TYPE.AUTO)
    self._GamePauseAnimTimer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        if time <= 0 then
            self.PanelGuide.gameObject:SetActiveEx(false)
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, XEnumConst.GOLDEN_MINER.GAME_PAUSE_TYPE.AUTO)
            self:StopGamePauseAnim()
            return
        end

        self.TxtCountdown.text = string.format("%02d", time)
        self.PanelGuide.gameObject:SetActiveEx(true)
        time = time - 1
    end, XScheduleManager.SECOND)
    if not self.ImgBg then
        return
    end
    local pauseTime = self._Control:GetClientGameStopCountdown()
    self._GamePauseTimeAnimTimer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        pauseTime = pauseTime - UnityTime.deltaTime
        self.ImgBg.fillAmount = pauseTime / self._Control:GetClientGameStopCountdown()
    end, 0)
end

function XUiGoldenMinerGameBattle:StopGamePauseAnim()
    if self._GamePauseAnimTimer then
        XScheduleManager.UnSchedule(self._GamePauseAnimTimer)
    end
    self._GamePauseAnimTimer = nil
    if self._GamePauseTimeAnimTimer then
        XScheduleManager.UnSchedule(self._GamePauseTimeAnimTimer)
    end
    self._GamePauseTimeAnimTimer = nil
end

---关卡暂停
function XUiGoldenMinerGameBattle:OpenPauseDialog()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, XEnumConst.GOLDEN_MINER.GAME_PAUSE_TYPE.PLAYER)
    local closeCallback = function()
        self:StartGamePauseAnim()
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, XEnumConst.GOLDEN_MINER.GAME_PAUSE_TYPE.PLAYER)
        self.BtnStop:SetButtonState(CS.UiButtonState.Normal)
    end
    local sureCallback = handler(self, self._OnExitStage)

    self.BtnStop:SetButtonState(CS.UiButtonState.Select)
    if self.ImgBg then
        self.ImgBg.fillAmount = 1
    end
    XLuaUiManager.Open("UiGoldenMinerSuspend", closeCallback, sureCallback)
end

---放弃关卡
function XUiGoldenMinerGameBattle:_OnExitStage()
    local SaveGame = function()
        self._Control:RecordSaveStage(XEnumConst.GOLDEN_MINER.CLIENT_RECORD_UI.UI_STAGE)
        self._Control:RequestGoldenMinerSaveStage(self._CurStageId)
    end
    local SettleGame = function()
        self:UpdateSettlementInfo(true)
        self._Control:RequestGoldenMinerExitGame(self._CurStageId, function()
            XLuaUiManager.PopThenOpen("UiGoldenMinerMain")
        end, self._SettlementInfo, self._Game:GetCurScore(), self._Game:GetGameData():GetAllScore())
    end
    local ResumeGame = function()
        self:OpenPauseDialog()
    end
    self._Control:OpenGiveUpGameDialog(XUiHelper.GetText("GoldenMinerQuickTipsTitle"),
            XUiHelper.GetText("GoldenMinerQuickTipsDesc"),
            ResumeGame,
            SaveGame,
            SettleGame,
            false)
end

---程序暂停
function XUiGoldenMinerGameBattle:ApplicationPause(isPause)
    if isPause and self._Game:IsRunning() then
        self:OpenPauseDialog()
    end
end
--endregion

--region Ui - Relic
---@class GMGridRelic
---@field RImgBgOff UnityEngine.UI.RawImage
---@field RImgBgOn UnityEngine.UI.RawImage

function XUiGoldenMinerGameBattle:InitRelic()
    if not self.PanelLaba then
        return
    end

    if not self._Control:CheckIsCanOpenRelicModule(self._MapId) then
        self.PanelLaba.gameObject:SetActiveEx(false)
        return
    end

    self._RelicGridList = {
        XTool.InitUiObjectByUi({}, self.GridLaba),
        XTool.InitUiObjectByUi({}, XUiHelper.Instantiate(self.GridLaba, self.PanelLaba)),
        XTool.InitUiObjectByUi({}, XUiHelper.Instantiate(self.GridLaba, self.PanelLaba)),
    }
    self.PanelLaba.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerGameBattle:RefreshRelicProcess(curProcess, allProcess)
    XMVCA.XGoldenMiner:DebugWarning("遗迹碎片进度：", curProcess, allProcess)
    if not self.PanelLaba then
        return
    end
    self.PanelLaba.gameObject:SetActiveEx(true)
    for i = 1, allProcess do
        if not self._RelicGridList[i] then
            self._RelicGridList[i] = XTool.InitUiObjectByUi({}, XUiHelper.Instantiate(self.GridLaba, self.PanelLaba))
        end
        self._RelicGridList[i].RImgBgOff.gameObject:SetActiveEx(curProcess < i)
        self._RelicGridList[i].RImgBgOn.gameObject:SetActiveEx(curProcess >= i)
    end
end
--endregion

--region Ui - SlotsScore

function XUiGoldenMinerGameBattle:InitSlotsScore()
    if not self.PanelSlotMachine then
        return
    end
    if not self._Control:CheckIsCanOpenSlotsScore(self._MapId) then
        self.PanelSlotMachine.gameObject:SetActiveEx(false)
        return
    else
        self.PanelSlotMachine.gameObject:SetActiveEx(true)
    end

    self.PanelSlotScore = require("XUi/XUiGoldenMiner/Panel/XUiGoldenMinerSlotScorePanel").New(self.PanelSlotMachine, self)
end



--endregion

--region Ui - SunAndMoon

function XUiGoldenMinerGameBattle:InitSunAndMoon()
    if not self.BtnSwitch then
        return
    end

    if self._Control:CheckIsSunAndMoonMap(self._MapId) then
        self.BtnSwitch.gameObject:SetActiveEx(true)
        local mapSunMoonInitialType = self._Control:GetMapSunMoonInitialType(self._MapId)
        if mapSunMoonInitialType == XEnumConst.GOLDEN_MINER.MAP_SUN_MOON_TYPE.SUN then
            self.BtnSwitchSunRoot.gameObject:SetActiveEx(false)
            self.BtnSwitchMoonRoot.gameObject:SetActiveEx(true)
        else
            self.BtnSwitchSunRoot.gameObject:SetActiveEx(true)
            self.BtnSwitchMoonRoot.gameObject:SetActiveEx(false)
        end
    else
        self.BtnSwitch.gameObject:SetActiveEx(false)
    end
end

function XUiGoldenMinerGameBattle:OnSunMoonCDChanged(isInCD)
    if self.ImgSwitchCD then
        self.ImgSwitchCD.gameObject:SetActiveEx(isInCD)
    end

    self._IsInSunMoonCD = isInCD
end

function XUiGoldenMinerGameBattle:RefreshBtnSwitchState()
    local mapSunMoonType = self._Game.SystemMap:GetSunMoonCurType()
    if mapSunMoonType == XEnumConst.GOLDEN_MINER.MAP_SUN_MOON_TYPE.SUN then
        self.BtnSwitchSunRoot.gameObject:SetActiveEx(false)
        self.BtnSwitchMoonRoot.gameObject:SetActiveEx(true)
    else
        self.BtnSwitchSunRoot.gameObject:SetActiveEx(true)
        self.BtnSwitchMoonRoot.gameObject:SetActiveEx(false)
    end
end

function XUiGoldenMinerGameBattle:RefreshBtnSunMoonCD(deltaTime)
    if not self._IsInSunMoonCD then
        return
    end

    if not self.ImgSwitchCD then
        return
    end

    self.ImgSwitchCD.fillAmount = self._Game.SystemMap:GetSunMoonChangedCDProgress()
end

--endregion

--region Ui - Btn
function XUiGoldenMinerGameBattle:InitBtn()
    -- shoot
    self.BtnShootHandler = self.BtnChange:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.BtnShootHandler) then
        self.BtnShootHandler = self.BtnChange.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    if self.BtnShootHandler then
        self.BtnShootHandler:AddPointerDownListener(function()
            self:OnBtnShootPressDown()
        end)
        self.BtnShootHandler:AddPointerUpListener(function()
            self:OnBtnShootPressUp()
        end)
        self.BtnShootHandler:AddFocusExitListener(function()
            self:OnFocusExit()
        end)
    end
    -- ChangeSunAndMoon
    self.BtnSwitch.CallBack = function(isCheck)
        self:OnBtnSwitchClick(isCheck)
    end

    -- PcKey
    self.PcBtnShootShow = XUiHelper.TryGetComponent(self.BtnChange.transform, "BtnChangePC", "XUiPcCustomKey")
    if self.PcBtnShootShow then
        self.PcBtnShootShow:SetKey(CS.XInputMapId.ActivityGame, XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Shoot, CS.XInputManager.XOperationType.ActivityGame)
        self.PcBtnShootShow.gameObject:SetActiveEx(XDataCenter.UiPcManager.IsPc())
    end

    self.PcBtnChangeSunMoonShow = XUiHelper.TryGetComponent(self.BtnSwitch.transform, "Normal/BtnSwitchPC", "XUiPcCustomKey")
    if self.PcBtnChangeSunMoonShow then
        self.PcBtnChangeSunMoonShow:SetKey(CS.XInputMapId.ActivityGame, XEnumConst.GOLDEN_MINER.GAME_PC_KEY.ChangeSunAndMoon, CS.XInputManager.XOperationType.ActivityGame)
        self.PcBtnChangeSunMoonShow.gameObject:SetActiveEx(XDataCenter.UiPcManager.IsPc())
    end
end

function XUiGoldenMinerGameBattle:RefreshShootBtn()
    local url = self._Control:GetClientBtnShootIconUrl(false)
    if not self._Game or self.BtnChange.RawImageList.Count == 0 or string.IsNilOrEmpty(url) then
        return
    end
    self.BtnChange:SetRawImage(url)
end

function XUiGoldenMinerGameBattle:RefreshQteBtn()
    local url = self._Control:GetClientBtnShootIconUrl(true)
    if not self._Game or self.BtnChange.RawImageList.Count == 0 or string.IsNilOrEmpty(url) then
        return
    end
    self.BtnChange:SetRawImage(url)
end
--endregion

--region Ui - MouseTip
function XUiGoldenMinerGameBattle:InitMouseTip()
    if not self.RImgCatRight then
        return
    end
    --存值减少每次访问Position创建新增的Vector3变量
    self._MouseEndRightTipX = CS.UnityEngine.Screen.width
    self._MouseEndLeftTipX = 0
    self._LeftMouseTipList = { self.RImgCatLeft }
    self._RightMouseTipList = { self.RImgCatRight }
end

---定春预警
function XUiGoldenMinerGameBattle:RefreshMouseTip()
    if not self.RImgCatRight or self._Game:IsEnd() then
        return
    end
    local mouseList = self._Game:GetStoneEntityUidDirByType(XEnumConst.GOLDEN_MINER.STONE_TYPE.MOUSE)
    local leftCount = 0
    local rightCount = 0
    local tempPos
    for uid, _ in pairs(mouseList) do
        local mouseEntity = self._Game:GetStoneEntityByUid(uid)
        if mouseEntity:IsAlive() then
            local mousePosition = mouseEntity:GetTransform().anchoredPosition
            -- 定春 右->左
            if mouseEntity:GetComponentMove().CurDirection < 0 and mousePosition.x > self._MouseEndRightTipX then
                rightCount = rightCount + 1
                if not self._RightMouseTipList[rightCount] then
                    self._RightMouseTipList[rightCount] = XUiHelper.Instantiate(self._RightMouseTipList[1].gameObject, self._RightMouseTipList[1].transform.parent)
                end
                tempPos = self._RightMouseTipList[rightCount].transform.position
                self._RightMouseTipList[rightCount].gameObject:SetActiveEx(true)
                self._RightMouseTipList[rightCount].transform.position = Vector3(tempPos.x, mouseEntity:GetTransform().position.y, tempPos.z)
            end
            -- 定春 左->右
            if mouseEntity:GetComponentMove().CurDirection > 0 and mousePosition.x < self._MouseEndLeftTipX then
                leftCount = leftCount + 1
                if not self._LeftMouseTipList[leftCount] then
                    self._LeftMouseTipList[leftCount] = XUiHelper.Instantiate(self._LeftMouseTipList[1].gameObject, self._LeftMouseTipList[1].transform.parent)
                end
                tempPos = self._LeftMouseTipList[leftCount].transform.position
                self._LeftMouseTipList[leftCount].gameObject:SetActiveEx(true)
                self._LeftMouseTipList[leftCount].transform.position = Vector3(tempPos.x, mouseEntity:GetTransform().position.y, tempPos.z)
            end
        end
    end
    -- 没有猫猫需要提示则隐藏提示
    for i = leftCount + 1, #self._LeftMouseTipList do
        self._LeftMouseTipList[i].gameObject:SetActiveEx(false)
    end
    for i = rightCount + 1, #self._RightMouseTipList do
        self._RightMouseTipList[i].gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - Effect
function XUiGoldenMinerGameBattle:_UpdateEffectCD()
    if XTool.IsTableEmpty(self._EffectCDWithTypeMap) then
        return
    end

    for type, cd in pairs(self._EffectCDWithTypeMap) do
        if cd > 0 then
            self._EffectCDWithTypeMap[type] = cd - UnityTime.deltaTime
            if self._EffectCDWithTypeMap[type] <= 0 then
                self._EffectCDWithTypeMap[type] = 0
            end
        end
    end
end

---@param type number XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE
---@param transform UnityEngine.Transform
function XUiGoldenMinerGameBattle:PlayEffect(type, transform, path)
    if string.IsNilOrEmpty(path) then
        return
    end
    if self:CheckIsEffectInCDWithType(type) then
        return
    end
    if type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.GRAB then
        self:_PlayEffect(path, transform)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.STONE_BOOM
            or type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.GRAB_BOOM
            or type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.TYPE_BOOM
            or type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.TO_GOLD
            or type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.SHIP_GRAB
    then
        self:_PlayEffect(path, transform, true)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.TIME_STOP then
        self:_PlayOnlyOneEffect(type, path)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.TIME_RESUME then
        self:_PlayOnlyOneEffect(type, path)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.WEIGHT_FLOAT then
        self:_PlayOnlyOneEffect(type, path)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.WEIGHT_RESUME then
        local effect = self:GetOnlyOnceEffect(XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.WEIGHT_FLOAT, path)
        if effect then
            effect:SetActiveEx(false)
        end
    elseif type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.QTE_CLICK then
        self:_PlayOnlyOneEffect(type, path, transform)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.QTE_COMPLETE then
        self:_PlayOnlyOneEffect(type, path, transform)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.CHANGE_TO_SUN
            or type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.CHANGE_TO_MOON then
        self:_PlayOnlyOneEffect(type, path)
    elseif type == XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.RADAR_RANDOM_ITEM then
        self:_PlayEffect(path, transform)
    end
end

---@param posTransform UnityEngine.Transform
function XUiGoldenMinerGameBattle:_PlayOnlyOneEffect(type, path, posTransform, isEffectRoot)
    if XTool.IsTableEmpty(self._EffectObjDir[type]) then
        self._EffectObjDir[type] = {}
    end
    if not self._EffectObjDir[type][path] then
        self._EffectObjDir[type][path] = self:_PlayEffect(path, posTransform, isEffectRoot)
    end
    self._EffectObjDir[type][path]:SetActiveEx(false)
    self._EffectObjDir[type][path]:SetActiveEx(true)
end

function XUiGoldenMinerGameBattle:GetOnlyOnceEffect(type, path)
    if XTool.IsTableEmpty(self._EffectObjDir[type]) then
        return false
    end
    if path then
        return self._EffectObjDir[type][path]
    end
    return self._EffectObjDir[type]
end

---@return UnityEngine.GameObject
function XUiGoldenMinerGameBattle:_PlayEffect(path, transform, isEffectRoot)
    local resource = self._EffectResourcePool[path]
    if not resource then
        resource = self._Control:GetLoader():Load(path)
        self._EffectResourcePool[path] = resource
    end

    if resource == nil then
        XLog.Error(string.format("XGoldenMinerGame:LoadStone加载资源，路径：%s", path))
        return
    end

    local parent = not isEffectRoot and transform or self._EffectRoot.transform
    local effect = XUiHelper.Instantiate(resource, parent)
    effect.transform:SetParent(self.EffectFull)
    if self._EffectLayer then
        self._EffectLayer:Init()
        self._EffectLayer:ProcessSortingOrder()
    end
    if transform then
        effect.transform.position = transform.position
    end
    effect.transform:SetParent(parent)
    return effect
end

function XUiGoldenMinerGameBattle:CheckIsEffectInCDWithType(type, isOnlyCheck)
    isOnlyCheck = isOnlyCheck or false

    if not NeedCheckEffectCDType[type] then
        return false
    end

    if isOnlyCheck then
        return self._EffectCDWithTypeMap[type] and self._EffectCDWithTypeMap[type] > 0
    else
        local isInCD = self._EffectCDWithTypeMap[type] and self._EffectCDWithTypeMap[type] > 0
        if not isInCD then
            self._EffectCDWithTypeMap[type] = EFFECT_CD
        end
        return isInCD
    end

    return false
end
--endregion

--region Audio - Sound
--播放使用道具音效
function XUiGoldenMinerGameBattle:PlayUseItemSound(itemId)
    local soundId = self._Control:GetCfgItemUseSoundId(itemId)
    if not XTool.IsNumberValid(soundId) then
        return
    end

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, soundId)
end
--endregion

--region Game - Init
function XUiGoldenMinerGameBattle:GameStart()
    self:_GameInit()
    self._Game:EnterGame()
end

function XUiGoldenMinerGameBattle:_GameInit()
    local data = self._Game:CreateGameData(self._MapId)
    local hookTypeList = self:_GetHookTypeList(self._HookType)
    data:SetMapScore(0)
    data:SetAllScore(self._DataDb:GetStageScores())
    data:SetHookTypeList(hookTypeList)
    data:SetTime(self._Control:GetCfgMapTime(self._MapId) + TIME_OFFSET)
    data:SetCurPassStageList(self._DataDb._FinishStageIdDir)
    data:SetCurCharacterId(self._Control:GetUseCharacterId())
    data:SetInitBuffIdList(self._Control:GetCurInitBuffIdList())

    ---@type XGoldenMinerGameInitObjDir
    local objDir = {}
    objDir.RectSize = self._Control:GetRectSize()
    objDir.MapRoot = self.PanelStone
    objDir.HookObjDir = self:_GetHookObjDir(hookTypeList)
    objDir.PartnerRoot = self.PartnerRoot
    objDir.HumanRoot = self.Humen
    objDir.ElectromagneticBox = self.ElectromagneticBox
    -- 弹射反射墙
    objDir.ReflectEdgeRoot = self.ReflectEdgeRoot
    objDir.ReflectEdges = {
        [XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.TOP] = self.ReflectTopEdge,
        [XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.BOTTOM] = self.ReflectBottomEdge,
        [XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.LEFT] = self.ReflectLeftEdge,
        [XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.RIGHT] = self.ReflectRightEdge,
    }
    objDir.ReflectAimRopeRoot = self.ReflectAimRopeRoot

    --OnUpdate Battle界面的更新是通过游戏控制器的UpdateEx驱动的，界面本身不更新
    local updateExFunc = function(deltaTime)
        self:RefreshPlayTime()
        self:RefreshFaceEmoji(deltaTime)
        -- 4.0不再出现猫猫提示
        --self:RefreshMouseTip()
        self:RefreshBuffTip(deltaTime)
        self:RefreshBtnSunMoonCD(deltaTime)
    end

    self._Game:PrepareGame(data, objDir, updateExFunc)

    self:InitWall()
end

---@return number[]
function XUiGoldenMinerGameBattle:_GetHookTypeList(hookType)
    local result = {}
    if hookType == XEnumConst.GOLDEN_MINER.HOOK_TYPE.DOUBLE then
        result[#result + 1] = XEnumConst.GOLDEN_MINER.HOOK_TYPE.NORMAL
    end
    result[#result + 1] = hookType
    return result
end

---@return UnityEngine.Transform[]
function XUiGoldenMinerGameBattle:_GetHookObjDir(hookTypeList)
    local result = {}
    for _, type in ipairs(hookTypeList) do
        if self._HookType == XEnumConst.GOLDEN_MINER.HOOK_TYPE.DOUBLE
                and type == XEnumConst.GOLDEN_MINER.HOOK_TYPE.NORMAL then
            result[type] = self.DoubleHook1
            self.DoubleHook1.gameObject:SetActiveEx(true)
        else
            result[type] = self.HookObjDir[type]
            self.HookObjDir[type].gameObject:SetActiveEx(true)
            self.HookColliderDir[type].gameObject:SetActiveEx(true)
        end
    end
    return result
end

---@return UnityEngine.Collider2D[]
function XUiGoldenMinerGameBattle:_GetHookColliderDir(hookTypeList)
    local result = {}
    for _, type in ipairs(hookTypeList) do
        result[type] = self.HookColliderDir[type]
    end
    return result
end
--endregion

--region Game - Wall
function XUiGoldenMinerGameBattle:InitWall()
    self.RectSize = XUiHelper.TryGetComponent(self.Ui.Transform, "SafeAreaContentPane", "RectTransform").rect.size
    local exWidth = self._Control:GetClientGameWallExAreaValue(true)
    local exHeight = self._Control:GetClientGameWallExAreaValue(false)
    local width, height = self.RectSize.x + exWidth * 2,
    self.RectSize.y + exHeight * 2
    self.EdgeLeftBox.size = Vector2(self.EdgeLeftBox.size.x, height)
    self.EdgeRightBox.size = Vector2(self.EdgeRightBox.size.x, height)
    self.EdgeTopBox.size = Vector2(width, self.EdgeTopBox.size.y)
    self.EdgeBottomBox.size = Vector2(width, self.EdgeBottomBox.size.y)

    self.EdgeLeftBox.transform.localPosition = Vector3(
            self.EdgeLeftBox.transform.localPosition.x - exWidth,
            self.EdgeLeftBox.transform.localPosition.y,
            self.EdgeLeftBox.transform.localPosition.z)
    self.EdgeRightBox.transform.localPosition = Vector3(
            self.EdgeRightBox.transform.localPosition.x + exWidth,
            self.EdgeRightBox.transform.localPosition.y,
            self.EdgeRightBox.transform.localPosition.z)
    self.EdgeTopBox.transform.localPosition = Vector3(
            self.EdgeTopBox.transform.localPosition.x,
            self.EdgeTopBox.transform.localPosition.y + exHeight,
            self.EdgeTopBox.transform.localPosition.z)
    self.EdgeBottomBox.transform.localPosition = Vector3(
            self.EdgeBottomBox.transform.localPosition.x,
            self.EdgeBottomBox.transform.localPosition.y - exHeight,
            self.EdgeBottomBox.transform.localPosition.z)
end
--endregion

--region Game - Settle
function XUiGoldenMinerGameBattle:GameSettle(isSkip)
    self._Game:GameSettle(isSkip)
    self:UpdateSettlementInfo(isSkip)
    local curMapScore = self._Game:GetCurScore()
    local lastTimeScore = isSkip and 0 or self._Game:GetGameData():GetTimeScore()
    local closeCb = handler(self, self.CheckGameIsWin)
    local isCloseFunc = handler(self, self.GetIsCloseBattle)

    self._ReportInfo:SetMapId(self._MapId)
    self._ReportInfo:SetStageId(self._CurStageId)
    self._ReportInfo:SetStageIndex(self._CurStageIndex)
    self._ReportInfo:SetBeforeScore(self._Game:GetGameData():GetAllScore())
    self._ReportInfo:SetTargetScore(self._ScoreTarget)
    self._ReportInfo:SetLastTimeScore(lastTimeScore)
    self._ReportInfo:SetPartnerRadarScore(self._Game:GetGameData():GetPartnerRadarScore())
    self._ReportInfo:SetMapScore(curMapScore)
    self._ReportInfo:SetLastTime(math.floor(self._Game:GetGameData():GetTime()))
    self._ReportInfo:SetReportGrabStoneDataDir(self._Game:GetGameData():GetReportGrabStoneDataDir())
    self._ReportInfo:SetSlotScoreHandleCountMap(self._Game:GetGameData():GetSlotScoreHandleCountMap())
    self._Game:GameOver()

    self._Control:RequestGoldenMinerFinishStage(self._CurStageId,
            self._SettlementInfo,
            curMapScore + lastTimeScore,
            function(isFinishSuccess, isOpenHideStage)
                local dataDb = self._Control:GetMainDb()
                self._IsCloseBattle = true
                self._IsFinishSuccess = isFinishSuccess
                self._IsOpenHideStage = isOpenHideStage
                self._ReportInfo:SetFinishHideTaskCount(dataDb:GetFinishHideTaskCount())
                XLuaUiManager.Open("UiGoldenMinerReport", self._ReportInfo, closeCb, isCloseFunc)
            end,
            self._ReportInfo:IsWin())
end

function XUiGoldenMinerGameBattle:UpdateSettlementInfo(isGiveUpTimeScore)
    local mapTime = self._Control:GetCfgMapTime(self._MapId)
    local time = self._Game:GetGameData():GetTime()
    local addScore = self._Game:GetGameData():GetMapScore()
    if not isGiveUpTimeScore then
        -- 3.0取消时间分数
        addScore = addScore
    end

    self._SettlementInfo:SetMoveCount(self._MoveRecordCount)
    self._SettlementInfo:SetScores(addScore)
    self._SettlementInfo:SetCostTime(math.floor(mapTime - time))
    self._SettlementInfo:UpdateGrabDataInfos(self._Game:GetGameData():GetSettleGrabStoneDataDir())
    self._SettlementInfo:UpdateHideTaskInfoList(self._Game:GetGameData():GetHideTaskInfoList())

    local slotScoreHandleCountMap = self._Game:GetGameData():GetSlotScoreHandleCountMap()
    if not XTool.IsTableEmpty(slotScoreHandleCountMap) then
        local slotMachineScore = 0
        for slotScoreType, count in pairs(slotScoreHandleCountMap) do
            local slotScoreTypeScore = self._Control:GetClientSlotsScores(slotScoreType)
            slotMachineScore = slotMachineScore + slotScoreTypeScore * count
        end
        self._SettlementInfo:SetSlotMachineScore(slotMachineScore)
        self._SettlementInfo:SetSlotMachineCount(slotScoreHandleCountMap[XEnumConst.GOLDEN_MINER.SLOT_SCORE_TYPE.Triple])
    end
end

function XUiGoldenMinerGameBattle:CheckGameIsWin()
    local nextStageId = self._DataDb:GetCurStageId()
    if (not self._ReportInfo:IsWin() or not nextStageId) or (not self._IsFinishSuccess and self._CurStageIndex == 1) then
        XLuaUiManager.PopThenOpen("UiGoldenMinerMain")
        return
    end

    self._Control:OpenGameUi()
end

function XUiGoldenMinerGameBattle:GetIsCloseBattle()
    return self._IsCloseBattle
end
--endregion

--region Game - ItemUse
---@param itemGrid XUiGoldenMinerItemGrid
function XUiGoldenMinerGameBattle:OnUseItem(itemGrid)
    local itemColumn = itemGrid:GetItemColumn()
    local itemGridIndex = itemColumn:GetGridIndex()
    local itemId = itemColumn:GetItemId()
    if self._Control:CheckUseItemIsInCD(itemGridIndex) then
        return
    end
    if not self._Game:CheckItemCanUse(itemId) then
        XMVCA.XGoldenMiner:DebugLog("当前道具不可用！")
        return
    end

    itemGrid:SetRImgIconActive(false)
    self:PlayUseItemSound(itemId)
    self:PlayFaceEmojiByUseItem(itemId)
    self:AddBuffTip(itemId)
    self:UpdateItemChangeInfo(itemGridIndex, XEnumConst.GOLDEN_MINER.ITEM_CHANGE_TYPE.ON_USE)
    self._Game:UseItemToAddBuff(itemId)
    self._DataDb:UseItem(itemGridIndex)
end

function XUiGoldenMinerGameBattle:OnKeyClickUseItem(index)
    self.ItemPanel:UseItemByIndex(index)
end
--endregion

--region Game - Hook
function XUiGoldenMinerGameBattle:OnAimAnglePointDown(eventData)
    if self._HookType ~= XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE then
        return
    end
    local hasValue, position = RectTransformUtility.ScreenPointToLocalPointInRectangle(self.BtnMove.transform, eventData.position, eventData.pressEventCamera)
    local eventPosX = hasValue and position.x or 0
    if eventPosX < 0 then
        --向左瞄准
        self:OnAimLeftAngleDown()
    else
        --向右瞄准
        self:OnAimRightAngleDown()
    end
end

function XUiGoldenMinerGameBattle:OnAimAnglePointDrag(eventData)
    if self._HookType ~= XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE then
        return
    end
    local hasValue, position = RectTransformUtility.ScreenPointToLocalPointInRectangle(self.BtnMove.transform, eventData.position, eventData.pressEventCamera)
    local eventPosX = hasValue and position.x or 0
    if eventPosX < 0 then
        --向左瞄准
        self:OnAimLeftAngleDown()
    else
        --向右瞄准
        self:OnAimRightAngleDown()
    end
end

function XUiGoldenMinerGameBattle:OnAimAnglePointUp()
    if self._HookType ~= XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE then
        return
    end
    self._CurAnim = CurAim.None
    self:_SetAim()
end

function XUiGoldenMinerGameBattle:OnAimLeftAngleDown()
    if self._HookType ~= XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE then
        return
    end
    -- 上锁防按键同时按
    self._CurAnim = self._CurAnim | CurAim.Left
    self._Game:HookAimLeft()
end

function XUiGoldenMinerGameBattle:OnAimRightAngleDown()
    if self._HookType ~= XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE then
        return
    end
    self._CurAnim = self._CurAnim | CurAim.Right
    self._Game:HookAimRight()
end

function XUiGoldenMinerGameBattle:OnAimLeftAnglePointUp()
    if self._HookType ~= XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE then
        return
    end
    self._CurAnim = self._CurAnim & (~CurAim.Left)
    self:_SetAim()
end

function XUiGoldenMinerGameBattle:OnAimRightAnglePointUp()
    if self._HookType ~= XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE then
        return
    end
    self._CurAnim = self._CurAnim & (~CurAim.Right)
    self:_SetAim()
end

function XUiGoldenMinerGameBattle:OnHookShoot()
    if self._Game:CheckBuffStatusByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.ELECTROMAGNETIC, XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.BE_DIE) then
        return
    end
    -- 记录使用钩爪数
    if self._Game.SystemHook:CheckSystemIsIdle() then
        self._SettlementInfo:AddLaunchingClawCount()
    end
    self._Game:HookShoot()
end

function XUiGoldenMinerGameBattle:_SetAim()
    if self._CurAnim & CurAim.Left ~= CurAim.None then
        self._Game:HookAimLeft()
    elseif self._CurAnim & CurAim.Right ~= CurAim.None then
        self._Game:HookAimRight()
    else
        self._Game:HookAimIdle()
    end
end
--endregion

--region Game - Partner
function XUiGoldenMinerGameBattle:InitPartnerScanLineProcess()
    if self.PanelUiGoldenMinerJd then
        self.PanelUiGoldenMinerJd.gameObject:SetActiveEx(true)
    end
end

function XUiGoldenMinerGameBattle:UpdatePartnerScanLineProcess(curProcess, allProcess)
    XMVCA.XGoldenMiner:DebugWarning("扫描线进度更新：", curProcess, allProcess)
    local img = self._Control:GetClientScanLineProgressImgByPro(curProcess)
    if self.PanelUiGoldenMinerJd and not string.IsNilOrEmpty(img) then
        self.PanelUiGoldenMinerJd:SetSprite(img)
    end
end
--endregion

--region Event - Listener
function XUiGoldenMinerGameBattle:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_APPLICATION_PAUSE, self.ApplicationPause, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_EXIT_CLICK, self.OnEscClick, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_TIMEOUT, self.GameSettle, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_STONE_CLEAR, self.GameSettle, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_SCORE, self.RefreshScore, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_TIME, self.AddPlayTime, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_ITEM, self.AddItem, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT, self.PlayEffect, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HIDE_TASK, self.HideTaskFinish, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE, self.PlayFaceEmoji, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_FACE_ANIM, self._PlayEmoticonAnim, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_USE_ITEM, self.OnUseItem, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, self.RefreshQteBtn, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_END, self.RefreshShootBtn, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_GET_RELIC_FRAG, self.RefreshRelicProcess, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PARTNER_SCAN_INIT, self.InitPartnerScanLineProcess, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PARTNER_SCAN_PRECESS, self.UpdatePartnerScanLineProcess, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_SUN_MOON_CD_CHANGED, self.OnSunMoonCDChanged, self)
end

function XUiGoldenMinerGameBattle:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_APPLICATION_PAUSE, self.ApplicationPause, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_EXIT_CLICK, self.OnEscClick, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_TIMEOUT, self.GameSettle, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_STONE_CLEAR, self.GameSettle, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_SCORE, self.RefreshScore, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_TIME, self.AddPlayTime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_ADD_ITEM, self.AddItem, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT, self.PlayEffect, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HIDE_TASK, self.HideTaskFinish, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE, self.PlayFaceEmoji, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_FACE_ANIM, self._PlayEmoticonAnim, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_USE_ITEM, self.OnUseItem, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, self.RefreshQteBtn, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_END, self.RefreshShootBtn, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_GET_RELIC_FRAG, self.RefreshRelicProcess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PARTNER_SCAN_INIT, self.InitPartnerScanLineProcess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_PARTNER_SCAN_PRECESS, self.UpdatePartnerScanLineProcess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_SUN_MOON_CD_CHANGED, self.OnSunMoonCDChanged, self)
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerGameBattle:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnStop, self.OnBtnStopClick)
    self:RegisterClickEvent(self.BtneExit, self.OnBtnNextStageClick)

    if self.AimLeftInputHandler and not self.BtnMove then
        self.AimLeftInputHandler:AddPointerDownListener(function()
            if self._Game.SystemHook:CheckHasAimHook() then
                self:OnAimLeftAngleDown()
            else
                self:OnShipMoveLeftPCDown()
            end
        end)
        self.AimLeftInputHandler:AddPointerUpListener(function()
            if self._Game.SystemHook:CheckHasAimHook() then
                self:OnAimLeftAnglePointUp()
            else
                self:OnShipMovePointerUp(true)
            end
        end)
    end
    if self.AimRightInputHandler and not self.BtnMove then
        self.AimRightInputHandler:AddPointerDownListener(function()
            if self._Game.SystemHook:CheckHasAimHook() then
                self:OnAimRightAngleDown()
            else
                self:OnShipMoveRightPCDown()
            end
        end)
        self.AimRightInputHandler:AddPointerUpListener(function()
            if self._Game.SystemHook:CheckHasAimHook() then
                self:OnAimRightAnglePointUp()
            else
                self:OnShipMovePointerUp(false)
            end
        end)
    end
    --self.GoInputHandler:AddPointerDownListener(function(eventData) self:OnShipMovePointerDown(eventData) end)
    --self.GoInputHandler:AddPointerUpListener(function() self:OnShipMovePointerUp() end)
    if self.BtnMove then
        self.BtnMove:AddPointerDownListener(function(eventData)
            if self._Game.SystemHook:CheckHasAimHook() then
                self:OnAimAnglePointDown(eventData)
            else
                self:OnShipMovePointerDown(eventData)
            end
        end)

        self.BtnMove:AddDragListener(function(eventData)
            if self._Game.SystemHook:CheckHasAimHook() then
                self:OnAimAnglePointDrag(eventData)
            else
                self:OnShipMovePointerDown(eventData, true)
            end
        end)

        self.BtnMove:AddPointerUpListener(function()
            if self._Game.SystemHook:CheckHasAimHook() then
                self:OnAimAnglePointUp()
            else
                self:OnShipMovePointerUp()
            end
        end)
    end
end

function XUiGoldenMinerGameBattle:AddPCListener()
    XDataCenter.InputManagerPc.IncreaseLevel()
    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.ActivityGame)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Left, handler(self, self.OnGameLeftPointerDown))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyUpFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Left, handler(self, self.OnGameLeftPointerUp))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Right, handler(self, self.OnGameRightPointerDown))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyUpFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Right, handler(self, self.OnGameRightPointerUp))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Shoot, handler(self, self.OnPCShootKeyPressDown))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyUpFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Shoot, handler(self, self.OnPCShootKeyPressUp))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Item1, function()
        self:OnKeyClickUseItem(1)
    end)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Item2, function()
        self:OnKeyClickUseItem(2)
    end)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Item3, function()
        self:OnKeyClickUseItem(3)
    end)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.ExitGame, handler(self, self.OnBtnExitGameClick))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.ChangeSunAndMoon, handler(self, self.OnBtnSwitchClick))
end

function XUiGoldenMinerGameBattle:RemovePCListener()
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Left)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyUp(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Left)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Right)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyUp(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Right)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Shoot)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyUp(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Shoot)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Item1)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Item2)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.Item3)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.ExitGame)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.ChangeSunAndMoon)
    XDataCenter.InputManagerPc.DecreaseLevel()
    XDataCenter.InputManagerPc.ResumeCurInputMap()
end

function XUiGoldenMinerGameBattle:OnBtnShootPressDown()
    if not self._Game then
        return
    end
    if self._HookType ~= XEnumConst.GOLDEN_MINER.HOOK_TYPE.STORE_PRESS_MAGNETIC then
        return
    else
        self:OnHookShoot()
    end
end

function XUiGoldenMinerGameBattle:OnBtnShootPressUp()
    if not self._Game then
        return
    end
    if self._Game:IsQTE() then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_CLICK)
    elseif self._HookType ~= XEnumConst.GOLDEN_MINER.HOOK_TYPE.STORE_PRESS_MAGNETIC then
        self:OnHookShoot()
    else
        self._Game:HookRevokeAll()
    end
end

function XUiGoldenMinerGameBattle:OnPCShootKeyPressDown()
    if not self._Game then
        return
    end
    self:OnHookShoot()
end

function XUiGoldenMinerGameBattle:OnPCShootKeyPressUp()
    if not self._Game then
        return
    end
    if self._Game:IsQTE() then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_CLICK)
    elseif self._HookType == XEnumConst.GOLDEN_MINER.HOOK_TYPE.STORE_PRESS_MAGNETIC then
        self._Game:HookRevokeAll()
    end
end

function XUiGoldenMinerGameBattle:OnFocusExit()
    if self._Game and self._Game.SystemHook:CheckSystemIsUsing()
            and self._HookType == XEnumConst.GOLDEN_MINER.HOOK_TYPE.STORE_PRESS_MAGNETIC
    then
        self._Game:HookRevokeAll(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.SHOOTING)
    end
end

function XUiGoldenMinerGameBattle:OnBtnStopClick()
    if self._Game:IsRunning() then
        self:OpenPauseDialog()
    end
end

function XUiGoldenMinerGameBattle:OnBtnNextStageClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, XEnumConst.GOLDEN_MINER.GAME_PAUSE_TYPE.PLAYER)
    self.BtneExit:SetButtonState(CS.UiButtonState.Select)

    if self._Game:GetGameData():GetCurScore() >= self._ScoreTarget then
        self:GameSettle(true)
        return
    end
    local closeCb = function()
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, XEnumConst.GOLDEN_MINER.GAME_PAUSE_TYPE.PLAYER)
        self.BtneExit:SetButtonState(CS.UiButtonState.Normal)
        self:StartGamePauseAnim()
    end
    local sureCb = function()
        self:GameSettle(true)
    end
    XLuaUiManager.Open("UiGoldenMinerDialog",
            XUiHelper.GetText("GoldenMinerSkipStageTitle"),
            XUiHelper.GetText("GoldenMinerSkipStageContent"),
            closeCb,
            sureCb)
end

function XUiGoldenMinerGameBattle:OnEscClick()
    if self._Game:IsRunning() then
        self:OpenPauseDialog()
    end
end

function XUiGoldenMinerGameBattle:OnGameLeftPointerDown()
    if self._Game.SystemHook:CheckHasAimHook() then
        self:OnAimLeftAngleDown()
    else
        self:OnShipMoveLeftPCDown()
    end
end

function XUiGoldenMinerGameBattle:OnGameRightPointerDown()
    if self._Game.SystemHook:CheckHasAimHook() then
        self:OnAimRightAngleDown()
    else
        self:OnShipMoveRightPCDown()
    end
end

function XUiGoldenMinerGameBattle:OnGameLeftPointerUp()
    if self._Game.SystemHook:CheckHasAimHook() then
        self:OnAimLeftAnglePointUp()
    else
        self:OnShipMovePointerUp(true)
    end
end

function XUiGoldenMinerGameBattle:OnGameRightPointerUp()
    if self._Game.SystemHook:CheckHasAimHook() then
        self:OnAimRightAnglePointUp()
    else
        self:OnShipMovePointerUp(false)
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGoldenMinerGameBattle:OnShipMovePointerDown(eventData, isIgnoreRecord)
    --local _Screen = CS.UnityEngine.Screen
    local _Screen = self.BtnMove.transform.rect.size
    if not self._Game.SystemHook:CheckSystemIsIdle() and not self._Game:CheckBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHIP_SPEED_MOVE) then
        return
    end
    local hasValue, position = RectTransformUtility.ScreenPointToLocalPointInRectangle(self.BtnMove.transform, eventData.position, eventData.pressEventCamera)
    local eventPosX = hasValue and position.x or 0
    if eventPosX < 0 then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_SHIP_MOVE, XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.LEFT)
    else
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_SHIP_MOVE, XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.RIGHT)
    end
    if isIgnoreRecord then
        return
    end
    self._MoveRecordCount = self._MoveRecordCount + 1
end

function XUiGoldenMinerGameBattle:OnShipMoveLeftPCDown()
    if not self._Game.SystemHook:CheckSystemIsIdle() and not self._Game:CheckBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHIP_SPEED_MOVE) then
        return
    end

    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_SHIP_MOVE, XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.LEFT)
    self._MoveRecordCount = self._MoveRecordCount + 1
end

function XUiGoldenMinerGameBattle:OnShipMoveRightPCDown()
    if not self._Game.SystemHook:CheckSystemIsIdle() and not self._Game:CheckBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.SHIP_SPEED_MOVE) then
        return
    end

    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_SHIP_MOVE, XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.RIGHT)
    self._MoveRecordCount = self._MoveRecordCount + 1
end

function XUiGoldenMinerGameBattle:OnShipMovePointerUp(isLeft)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_SHIP_MOVE, XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.NONE, isLeft)
end

function XUiGoldenMinerGameBattle:OnBtnExitGameClick()
    self:OnBtnStopClick()
end

function XUiGoldenMinerGameBattle:OnBtnSwitchClick()
    if self._IsInSunMoonCD then
        return
    end

    self._Game.SystemMap:SetSunMoonChange()
    self:RefreshBtnSwitchState()
end
--endregion