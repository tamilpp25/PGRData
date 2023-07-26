local XGoldenMinerGame = require("XUi/XUiGoldenMiner/Game/XGoldenMinerGame")
local XGoldenMinerGameData = require("XEntity/XGoldenMiner/Game/XGoldenMinerGameData")
local XGoldenMinerFaceEmojiDataEntity = require("XEntity/XGoldenMiner/Game/XGoldenMinerFaceEmojiDataEntity")
local XGoldenMinerBuffTipEntity = require("XEntity/XGoldenMiner/Game/XGoldenMinerBuffTipEntity")
local XGoldenMinerReportInfo = require("XEntity/XGoldenMiner/Settle/XGoldenMinerReportInfo")
local XGoldenMinerItemChangeInfo = require("XEntity/XGoldenMiner/Settle/XGoldenMinerItemChangeInfo")
local XGoldenMinerSettlementInfo = require("XEntity/XGoldenMiner/Settle/XGoldenMinerSettlementInfo")
local XUiItemPanel = require("XUi/XUiGoldenMiner/Panel/XUiItemPanel")
local XUiBuffPanel = require("XUi/XUiGoldenMiner/Panel/XUiBuffPanel")

---@type UnityEngine.Time
local UnityTime = CS.UnityEngine.Time

local TIME_OFFSET = 0.99     --秒，补足倒计时为0时舍弃的0.9几秒
local GAME_NEAR_END_TIME = XGoldenMinerConfigs.GetGameNearEndTime() --临近结束的时间（单位：秒）
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

---黄金矿工3.0玩法界面
---@class XUiGoldenMinerGameBattle : XLuaUi
local XUiGoldenMinerGameBattle = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerBattle")

function XUiGoldenMinerGameBattle:OnAwake()
    self:AddBtnClickListener()
end

function XUiGoldenMinerGameBattle:OnStart()
    self:InitData()
    self:InitObj()
    self:InitUi()
    self:InitAutoCloseTimer()
    
    self:GameStart()
end

function XUiGoldenMinerGameBattle:OnEnable()
    XUiGoldenMinerGameBattle.Super.OnEnable(self)
    self:AddEventListener()
    self:AddPCListener()

    self:RefreshUi()
    self:StartGamePauseAnim()
end

function XUiGoldenMinerGameBattle:OnDisable()
    XUiGoldenMinerGameBattle.Super.OnDisable(self)
    self:RemoveEventListener()
    self:RemovePCListener()
end

function XUiGoldenMinerGameBattle:OnDestroy()
    if self._Game then
        self._Game:Destroy()
    end
    self._Game = nil

    for _, resource in pairs(self._EffectResourcePool) do
        resource:Release()
    end
    self._EffectObjDir = {}
end

--region Activity - AutoClose
function XUiGoldenMinerGameBattle:InitAutoCloseTimer()
    self:SetAutoCloseInfo(XDataCenter.GoldenMinerManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XDataCenter.GoldenMinerManager.HandleActivityEndTime()
            return
        end
    end, nil, 0)
end
--endregion

--region Init - Data
function XUiGoldenMinerGameBattle:InitData()
    self._DataDb = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    self._CurStageId, self._CurStageIndex = self._DataDb:GetCurStageId()
    self._MapId = self._DataDb:GetStageMapId(self._CurStageId)
    self._ScoreTarget = self._DataDb:GetCurStageTargetScore()
    self._AddTimeTipPosition = self.TxtAddTimeTip.transform.position
    
    --Game
    self._OwnBuffList = XDataCenter.GoldenMinerManager.GetOwnBuffDic()
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
end

function XUiGoldenMinerGameBattle:_SetDataHookType()
    if XTool.IsTableEmpty(self._OwnBuffList) then
        return XGoldenMinerConfigs.FalculaType.Normal
    end
    local type = XGoldenMinerConfigs.FalculaType.Normal
    for buffType, params in pairs(self._OwnBuffList) do
        if buffType == XGoldenMinerConfigs.BuffType.GoldenMinerCordMode then
            return params[1]
        elseif buffType == XGoldenMinerConfigs.BuffType.GoldenMinerRoleHook then
            type = params[1]
        end
    end
    return type
end
--endregion

--region Init - Obj
function XUiGoldenMinerGameBattle:InitObj()
    --Game
    ---@type XGoldenMinerGame
    self._Game = XGoldenMinerGame.New()
    self._GameTimer = nil
    
    --Pause
    self._GamePauseAnimTimer = nil
    self._GamePauseTimeAnimTimer = nil
    
    --Hook
    ---@type UnityEngine.Transform[]
    self.HookObjDir = {
        [XGoldenMinerConfigs.FalculaType.Normal] = self.NormalRope,
        [XGoldenMinerConfigs.FalculaType.Magnetic] = self.MagneticRope,
        [XGoldenMinerConfigs.FalculaType.Big] = self.BigRope,
        [XGoldenMinerConfigs.FalculaType.AimingAngle] = self.AimHook,
        [XGoldenMinerConfigs.FalculaType.StorePressMagnetic] = self.MagneticRope,
        [XGoldenMinerConfigs.FalculaType.Double] = self.DoubleHook2,
    }
    ---@type UnityEngine.Collider2D[]
    self.HookColliderDir = {
        [XGoldenMinerConfigs.FalculaType.Normal] = self.NormalCordCollider,
        [XGoldenMinerConfigs.FalculaType.Magnetic] = self.MagneticRopeCordCollider,
        [XGoldenMinerConfigs.FalculaType.Big] = self.BigRopeCordLeftCollider,
        [XGoldenMinerConfigs.FalculaType.AimingAngle] = self.NormalCordCollider,
        [XGoldenMinerConfigs.FalculaType.StorePressMagnetic] = self.MagneticRopeCordCollider,
        [XGoldenMinerConfigs.FalculaType.Double] = self.BigRopeCordLeftCollider,
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
    self:InitShip()
end

function XUiGoldenMinerGameBattle:RefreshUi()
    self:RefreshItem()
    self:RefreshBuff()
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
            XGoldenMinerConfigs.GetGameScoreColorCode(score >= self._ScoreTarget),
            score)
end

function XUiGoldenMinerGameBattle:_PlayScoreChange()
    local changeScore = self._Game:GetChangeScore()
    local oldScore = self._Game:GetOldScore()
    local curScore = self._Game:GetCurScore()
    if self._PlayScoreChangeTimer then
        XScheduleManager.UnSchedule(self._PlayScoreChangeTimer)
    end

    self._PlayScoreChangeTimer = XUiHelper.Tween(1, function(f)
        self:_SetCurScore(math.floor(oldScore + changeScore * f))
    end, function()
        self:_SetCurScore(curScore)
    end)
    if self.TxtCurScoreChange then
        self.TxtCurScoreChange.text = "+" .. changeScore
    end
    if self.PanelCurScoreChange then
        self.PanelCurScoreChange.gameObject:SetActiveEx(true)
        self:PlayAnimation("BubbleEnable")
    end
end
--endregion

--region Ui - PlayTime
function XUiGoldenMinerGameBattle:InitPlayTime()
    local time = XGoldenMinerConfigs.GetMapTime(self._MapId) + TIME_OFFSET
    self.TxtTime.text = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    self.TxtTime.color = TxtTimeColor[true]
end

function XUiGoldenMinerGameBattle:RefreshPlayTime()
    self:_SetTxtTime(self._Game:GetData():GetTime())
end

function XUiGoldenMinerGameBattle:AddPlayTime(addTime)
    self:_SetTxtTime(self._Game:GetData():GetTime())
    self:_PlayAddPlayTime(addTime)
end

function XUiGoldenMinerGameBattle:_PlayAddPlayTime(addTime)
    self.TxtAddTimeTip.transform.position = self._AddTimeTipPosition
    self.TxtAddTimeTip.gameObject:SetActive(true)
    self.TxtAddTimeTip.text = "+" .. addTime
    local endY = self.TxtAddTimeTip.transform.localPosition.y + XGoldenMinerConfigs.GetTipAnimMoveLength()
    local time = XGoldenMinerConfigs.GetTipAnimTime() / XScheduleManager.SECOND
    self.TxtAddTimeTip.transform:DOLocalMoveY(endY, time)
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.TxtAddTimeTip.gameObject:SetActive(false)
    end, XGoldenMinerConfigs.GetTipAnimTime())
end

local _IsNearEnd
local _IsPlayTimeEnable
function XUiGoldenMinerGameBattle:_SetTxtTime(time)
    if not XTool.IsNumberValid(self._CurNearEndTime) then
        self._CurNearEndTime = time - 1
    end

    _IsPlayTimeEnable = time - self._CurNearEndTime < 0
    _IsNearEnd = time <= GAME_NEAR_END_TIME

    --临近结束时间后，每隔1秒播放一次动画
    if _IsNearEnd and _IsPlayTimeEnable then
        self._CurNearEndTime = time - 1
        self:PlayAnimation("TimeEnable")
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
    self.Task.text = XUiHelper.GetText("GoldenMinerHideTaskShowTxt", XGoldenMinerConfigs.GetHideTaskDesc(hideTaskInfo:GetId()), progress)
end
--endregion

--region Ui - Item
function XUiGoldenMinerGameBattle:InitItem()
    ---@type XUiGoldenMinerItemPanel
    self.ItemPanel = XUiItemPanel.New(self.PanelSkillParent, true)
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
    self:UpdateItemChangeInfo(itemColumnIndex, XGoldenMinerConfigs.ItemChangeType.OnGet)
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
    self.RImgAddItemIcon:SetRawImage(XGoldenMinerConfigs.GetItemIcon(itemId))
    local endY = self.TxtAddItemTip.transform.localPosition.y + XGoldenMinerConfigs.GetTipAnimMoveLength()
    local time = XGoldenMinerConfigs.GetTipAnimTime() / XScheduleManager.SECOND
    self.TxtAddItemTip.transform:DOLocalMoveY(endY, time)
    XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self.TxtAddItemTip.gameObject:SetActive(false)
    end, XGoldenMinerConfigs.GetTipAnimTime())
end
--endregion

--region Ui - Buff
function XUiGoldenMinerGameBattle:InitBuff()
    ---@type XUiGoldenMinerBuffPanel
    self.BuffPanel = XUiBuffPanel.New(self.PanelBuffParent, self)
    
    ---@type XGoldenMinerBuffTipEntity[]
    self._NeedTipBuffDir = {}
    ---@type XGoldenMinerBuffTipEntity
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
    self.BuffPanel:UpdateBuff(XDataCenter.GoldenMinerManager.GetOwnBuffIdList())
end

function XUiGoldenMinerGameBattle:AddBuffTip(itemId)
    if XGoldenMinerConfigs.GetItemTipsType(itemId) == XGoldenMinerConfigs.BuffTipType.None then
        return
    end
    if XTool.IsTableEmpty(self._NeedTipBuffDir) then
        ---@type XGoldenMinerBuffTipEntity
        self._NeedTipBuffDir[#self._NeedTipBuffDir + 1] = XGoldenMinerBuffTipEntity.New(itemId)
    else
        local isHave = false
        for _, buffTipEntity in ipairs(self._NeedTipBuffDir) do
            if buffTipEntity.ItemId == itemId then
                buffTipEntity:ResetStatus()
                isHave = true
            end
        end
        if not isHave then
            self._NeedTipBuffDir[#self._NeedTipBuffDir + 1] = XGoldenMinerBuffTipEntity.New(itemId)
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
    local BuffList = self._Game:GetBuffDir()
    local isDelete = false
    
    for _, buffTipEntity in ipairs(self._NeedTipBuffDir) do
        if buffTipEntity:GetTipType() == XGoldenMinerConfigs.BuffTipType.UntilDie then
            for _, buff in ipairs(BuffList[buffTipEntity:GetBuffType()]) do
                if buffTipEntity:GetBuffId() == buff.Id then
                    buffTipEntity.ShowParam = buff.CurTimeTypeParam
                    buffTipEntity.IsDie = buff.Status > XGoldenMinerConfigs.GAME_BUFF_STATUS.ALIVE
                    isDelete = buff.Status > XGoldenMinerConfigs.GAME_BUFF_STATUS.ALIVE
                end
            end
        elseif buffTipEntity:GetTipType() == XGoldenMinerConfigs.BuffTipType.Once then
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
                self._CurBuffEntity:GetTipType() == XGoldenMinerConfigs.BuffTipType.UntilDie then
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
        self.TxtBuffTip.text = self._CurBuffEntity:GetBuffTipTxt()
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
    self:PlayAnimation("PanelEmoticonDisable")
    ---@type XGoldenMinerFaceEmojiDataEntity
    self.FaceEmojiDataEntity = XGoldenMinerFaceEmojiDataEntity.New()
    self:SetFaceEmojiEntityStatus(XGoldenMinerConfigs.GAME_FACE_PLAY_STATUS.NONE)
    self.FaceEmojiDataEntity.PlayDuration = XGoldenMinerConfigs.GetFaceEmojiShowTime()
end

function XUiGoldenMinerGameBattle:SetFaceEmojiEntityStatus(status)
    self.FaceEmojiDataEntity.BeStatusFaceId = false
    self.FaceEmojiDataEntity.Status = status
end

function XUiGoldenMinerGameBattle:RefreshFaceEmoji(time)
    -- 动画播放中跳过
    if self.FaceEmojiDataEntity.IsAim then
        return
    end
    local bePlayFaceId = self.FaceEmojiDataEntity.CurPlayQueue:Peek()
    -- 优先播放普通表情
    if bePlayFaceId then
        -- 播放
        if not self.FaceEmojiDataEntity.CurFaceId then
            self:PlayFaceAnim(bePlayFaceId)
            return
        end
        if self.FaceEmojiDataEntity.CurFaceId ~= bePlayFaceId then
            self:StopFaceAnim()
            return
        end
        -- 持续
        if self.FaceEmojiDataEntity.CurPlayDuration > 0 then
            self.FaceEmojiDataEntity.CurPlayDuration = self.FaceEmojiDataEntity.CurPlayDuration - time
            -- 结束
            if self.FaceEmojiDataEntity.CurPlayDuration <= 0 then
                self.FaceEmojiDataEntity.CurPlayQueue:Dequeue()
                self:StopFaceAnim()
            end
        end
        return
    end
    
    -- 播放状态表情
    -- 切换
    if self.FaceEmojiDataEntity.StatusFaceId ~= self.FaceEmojiDataEntity.BeStatusFaceId then
        self.FaceEmojiDataEntity.StatusFaceId = self.FaceEmojiDataEntity.BeStatusFaceId
    end
    if self.FaceEmojiDataEntity.CurFaceId and self.FaceEmojiDataEntity.StatusFaceId ~= self.FaceEmojiDataEntity.CurFaceId
            or not self.FaceEmojiDataEntity.StatusFaceId and self.FaceEmojiDataEntity.CurFaceId
    then
        -- 结束状态表情
        self:StopFaceAnim()
    elseif not self.FaceEmojiDataEntity.CurFaceId then
        -- 播放状态表情
        self:PlayFaceAnim(self.FaceEmojiDataEntity.StatusFaceId)
    end
end

function XUiGoldenMinerGameBattle:PlayFaceAnim(faceId)
    if not XTool.IsNumberValid(faceId) then
        return
    end

    self.PanelEmoticon.gameObject:SetActiveEx(true)
    self.FaceEmojiDataEntity.CurFaceId = faceId
    self.FaceEmojiDataEntity.CurPlayDuration = self.FaceEmojiDataEntity.PlayDuration
    self.FaceEmojiDataEntity.IsAim = true
    
    local img = XGoldenMinerConfigs.GetFaceImage(faceId)
    if not XTool.UObjIsNil(self.RImgHate) then
        self.RImgHate:SetRawImage(img)
    end
    self:PlayAnimation("PanelEmoticonEnable", function()
        self.FaceEmojiDataEntity.IsAim = false
    end)
end

function XUiGoldenMinerGameBattle:StopFaceAnim()
    self.FaceEmojiDataEntity.CurFaceId = false
    self.FaceEmojiDataEntity.IsAim = true
    self:PlayAnimation("PanelEmoticonDisable", function()
        self.FaceEmojiDataEntity.IsAim = false
    end)
end

function XUiGoldenMinerGameBattle:CheckHasFace()
    return false
end

---@param type number XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE
function XUiGoldenMinerGameBattle:PlayFaceEmoji(type, faceId)
    if not XTool.IsNumberValid(faceId) then
        return
    end
    
    if type == XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.NONE then
        self:SetFaceEmojiEntityStatus(XGoldenMinerConfigs.GAME_FACE_PLAY_STATUS.NONE)
    elseif type == XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.SHOOTING then
        self:SetFaceEmojiEntityStatus(XGoldenMinerConfigs.GAME_FACE_PLAY_STATUS.SHOOTING)
        
        self.FaceEmojiDataEntity.BeStatusFaceId = faceId
    elseif type == XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.GRAB_STONE
            or type == XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.GRAB_NONE
    then
        self:SetFaceEmojiEntityStatus(XGoldenMinerConfigs.GAME_FACE_PLAY_STATUS.NONE)
        self.FaceEmojiDataEntity.CurPlayQueue:Enqueue(faceId)
    elseif type == XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.REVOKING then
        self:SetFaceEmojiEntityStatus(XGoldenMinerConfigs.GAME_FACE_PLAY_STATUS.REVOKING)
        
        local stoneEntityList = self._Game:GetHookGrabEntity(nil, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING)
        if XTool.IsTableEmpty(stoneEntityList) then
            return
        end
        -- 拉回根据重量
        faceId = self:_GetFaceIdByGroupIdByWeight(faceId, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING)
        self.FaceEmojiDataEntity.BeStatusFaceId = faceId
    elseif type == XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.GRABBED then
        self:SetFaceEmojiEntityStatus(XGoldenMinerConfigs.GAME_FACE_PLAY_STATUS.NONE)
        
        -- 当抓取物为1时，抓到特殊物品时
        local stoneEntityList = self._Game:GetHookGrabEntity(nil, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED)
        if #stoneEntityList == 1 then
            for _, stoneEntity in pairs(stoneEntityList) do
                local stoneGrabFaceId = XGoldenMinerConfigs.GetStoneTypeGrabFaceId(stoneEntity.Data:GetType())
                if XTool.IsNumberValid(stoneGrabFaceId) then
                    self.FaceEmojiDataEntity.CurPlayQueue:Enqueue(stoneGrabFaceId)
                    return
                end
            end
        end
        -- 非特殊物品和抓取物为复数时
        faceId = self:_GetFaceIdByGroupIdByScore(faceId, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED)
        self.FaceEmojiDataEntity.CurPlayQueue:Enqueue(faceId)
    elseif type == XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.USE_ITEM then
        -- 使用普通道具
        self.FaceEmojiDataEntity.CurPlayQueue:Enqueue(faceId)
    elseif type == XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.USE_BY_WEIGHT then
        self.FaceEmojiDataEntity.CurPlayQueue:Enqueue(faceId)
        local secondFaceId = self:_GetFaceIdByGroupIdByWeight(faceId, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING)
        if faceId ~= secondFaceId then
            self.FaceEmojiDataEntity.CurPlayQueue:Enqueue(secondFaceId)
        end
    elseif type == XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.USE_BY_SCORE then
        self.FaceEmojiDataEntity.CurPlayQueue:Enqueue(faceId)
        -- 使用需要根据价值区分表情的道具
        local secondFaceId = self:_GetFaceIdByGroupIdByScore(faceId, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING)
        if faceId ~= secondFaceId then
            self.FaceEmojiDataEntity.CurPlayQueue:Enqueue(secondFaceId)
        end
    end
end

function XUiGoldenMinerGameBattle:PlayFaceEmojiByUseItem(itemId)
    local buffId = XGoldenMinerConfigs.GetItemBuffId(itemId)
    local type = XGoldenMinerConfigs.GetBuffType(buffId)
    local faceId = XGoldenMinerConfigs.GetItemUseFaceId(itemId)
    if type == XGoldenMinerConfigs.BuffType.GoldenMinerStoneChangeGold 
            or type == XGoldenMinerConfigs.BuffType.GoldenMinerBoom
    then
        self:PlayFaceEmoji(XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.USE_BY_SCORE, faceId)
        return
    end
    self:PlayFaceEmoji(XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.USE_ITEM, faceId)
end

function XUiGoldenMinerGameBattle:_GetFaceIdByGroupIdByWeight(faceId, stoneStatus)
    if not XTool.IsNumberValid(faceId) then
        return faceId
    end
    local faceGroupId = XGoldenMinerConfigs.GetFaceGroup(faceId)
    if not XTool.IsNumberValid(faceGroupId) then
        return faceId
    end
    local weight = self._Game:GetHookGrabWeight(stoneStatus)
    return XGoldenMinerConfigs.GetFaceIdByGroup(faceGroupId, weight)
end

function XUiGoldenMinerGameBattle:_GetFaceIdByGroupIdByScore(faceId, stoneStatus)
    if not XTool.IsNumberValid(faceId) then
        return faceId
    end
    local faceGroupId = XGoldenMinerConfigs.GetFaceGroup(faceId)
    if not XTool.IsNumberValid(faceGroupId) then
        return faceId
    end
    local score = self._Game:GetHookGrabScore(stoneStatus)
    return XGoldenMinerConfigs.GetFaceIdByGroup(faceGroupId, score)
end
--endregion

--region Ui - Pause Dialog
function XUiGoldenMinerGameBattle:InitPauseGuideUi()
    local isAimHook = self._HookType == XGoldenMinerConfigs.FalculaType.AimingAngle
    local isPc = XDataCenter.UiPcManager.IsPc()
    if self.PanelGuide then
        self.PanelGuide.gameObject:SetActiveEx(false)
    end
    if self.PanelMP then
        self.PanelMP.gameObject:SetActiveEx(isAimHook and not isPc)
    end
    if self.TxtPC then
        self.TxtPC.gameObject:SetActiveEx(isAimHook and isPc)
    end
    if self.TxtGuideShoot then
        self.TxtGuideShoot.text = XGoldenMinerConfigs.GetFalculaButtonTip(self._HookType)
        self.TxtGuideHook.text = XGoldenMinerConfigs.GetFalculaShipTip(self._HookType)
    end
end

function XUiGoldenMinerGameBattle:StartGamePauseAnim()
    self:StopGamePauseAnim()
    local time = XGoldenMinerConfigs.GetGameStopCountdown()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, XGoldenMinerConfigs.GAME_PAUSE_TYPE.AUTO)
    self._GamePauseAnimTimer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.GameObject) then return end
        if time <= 0 then
            self.PanelGuide.gameObject:SetActiveEx(false)
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, XGoldenMinerConfigs.GAME_PAUSE_TYPE.AUTO)
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
    local pauseTime = XGoldenMinerConfigs.GetGameStopCountdown()
    self._GamePauseTimeAnimTimer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.GameObject) then return end
        pauseTime = pauseTime - UnityTime.deltaTime
        self.ImgBg.fillAmount = pauseTime / XGoldenMinerConfigs.GetGameStopCountdown()
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
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, XGoldenMinerConfigs.GAME_PAUSE_TYPE.PLAYER)
    local closeCallback = function()
        self:StartGamePauseAnim()
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, XGoldenMinerConfigs.GAME_PAUSE_TYPE.PLAYER)
        self.BtnStop:SetButtonState(CS.UiButtonState.Normal)
    end
    local sureCallback = handler(self, self._OnExitStage)
    
    self.BtnStop:SetButtonState(CS.UiButtonState.Select)
    if self.ImgBg then
        self.ImgBg.fillAmount = 1
    end
    XLuaUiManager.Open("UiGoldenMinerSuspend", self._DataDb:GetDisplayData(), closeCallback, sureCallback)
end

---放弃关卡
function XUiGoldenMinerGameBattle:_OnExitStage()
    local SaveGame = function()
        XDataCenter.GoldenMinerManager.RequestGoldenMinerSaveStage(self._CurStageId)
        XDataCenter.GoldenMinerManager.RecordSaveStage(XGoldenMinerConfigs.CLIENT_RECORD_UI.UI_STAGE)
    end
    local SettleGame = function()
        self:UpdateSettlementInfo(true)
        XDataCenter.GoldenMinerManager.RequestGoldenMinerExitGame(self._CurStageId, function()
            XLuaUiManager.PopThenOpen("UiGoldenMinerMain")
        end, self._SettlementInfo, self._Game:GetCurScore(), self._Game:GetData():GetAllScore())
    end
    local ResumeGame = function() self:OpenPauseDialog() end
    XDataCenter.GoldenMinerManager:OpenGiveUpGameDialog(XUiHelper.GetText("GoldenMinerQuickTipsTitle"),
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

--region Ui - Btn
function XUiGoldenMinerGameBattle:InitBtn()
    -- shoot
    self.BtnShootHandler = self.BtnChange:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.BtnShootHandler) then
        self.BtnShootHandler = self.BtnChange.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    if self.BtnShootHandler then
        self.BtnShootHandler:AddPointerDownListener(function() self:OnBtnShootPressDown() end)
        self.BtnShootHandler:AddPointerUpListener(function() self:OnBtnShootPressUp() end)
        self.BtnShootHandler:AddFocusExitListener(function() self:OnFocusExit() end)
    end
    -- PcKey
    self.PcBtnShootShow = XUiHelper.TryGetComponent(self.BtnChange.transform, "BtnChangePC", "XUiPcCustomKey")
    if self.PcBtnShootShow then
        self.PcBtnShootShow:SetKey(CS.XOperationType.ActivityGame, XGoldenMinerConfigs.GAME_PC_KEY.Space)
        self.PcBtnShootShow.gameObject:SetActiveEx(XDataCenter.UiPcManager.IsPc())
    end
end

function XUiGoldenMinerGameBattle:RefreshShootBtn()
    local url = XGoldenMinerConfigs.GetBtnShootIconUrl(false)
    if not self._Game or self.BtnChange.RawImageList.Count == 0 or string.IsNilOrEmpty(url) then
        return
    end
    self.BtnChange:SetRawImage(url)
end

function XUiGoldenMinerGameBattle:RefreshQteBtn()
    local url = XGoldenMinerConfigs.GetBtnShootIconUrl(true)
    if not self._Game or self.BtnChange.RawImageList.Count == 0 or string.IsNilOrEmpty(url) then
        return
    end
    self.BtnChange:SetRawImage(url)
end
--endregion

--region Ui - Ship
function XUiGoldenMinerGameBattle:InitShip()
    local humanImageObj = XUiHelper.TryGetComponent(self.Humen.transform, "Humen", "RawImage")
    if not humanImageObj then
        return
    end
    
    local upgradeList = self._DataDb:GetAllUpgradeStrengthenList()
    local totalNum = 0
    local shipKey = XGoldenMinerConfigs.ShipAppearanceKey.DefaultShip

    --设置飞船外观
    for _, strengthenDb in ipairs(upgradeList) do
        if not string.IsNilOrEmpty(strengthenDb:GetLvMaxShipKey()) and strengthenDb:IsMaxLv() then
            totalNum = totalNum + 1
            shipKey = strengthenDb:GetLvMaxShipKey()
        end
    end
    if totalNum >= XGoldenMinerConfigs.GetFinalShipMaxCount() then
        shipKey = XGoldenMinerConfigs.ShipAppearanceKey.FinalShip
    end
    humanImageObj:SetRawImage(XGoldenMinerConfigs.GetShipImagePath(shipKey))
    --设置飞船大小
    local shipSizeWidth, shipSizeHeight
    if shipKey == XGoldenMinerConfigs.ShipAppearanceKey.MaxSpeedShip then
        shipSizeWidth, shipSizeHeight = XGoldenMinerConfigs.GetShipSize(XGoldenMinerConfigs.ShipAppearanceSizeKey.MaxSpeedShipSize)
    elseif shipKey == XGoldenMinerConfigs.ShipAppearanceKey.MaxClampShip then
        shipSizeWidth, shipSizeHeight = XGoldenMinerConfigs.GetShipSize(XGoldenMinerConfigs.ShipAppearanceSizeKey.MaxClampShipSize)
    elseif shipKey == XGoldenMinerConfigs.ShipAppearanceKey.FinalShip then
        shipSizeWidth, shipSizeHeight = XGoldenMinerConfigs.GetShipSize(XGoldenMinerConfigs.ShipAppearanceSizeKey.FinalShipSize)
    else
        shipSizeWidth, shipSizeHeight = XGoldenMinerConfigs.GetShipSize(XGoldenMinerConfigs.ShipAppearanceSizeKey.DefaultShipSize)
    end

    humanImageObj.transform:GetComponent("RectTransform").rect.size = Vector2(shipSizeWidth, shipSizeHeight)
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
    self._LeftMouseTipList = {self.RImgCatLeft}
    self._RightMouseTipList = {self.RImgCatRight}
end

---定春预警
function XUiGoldenMinerGameBattle:RefreshMouseTip()
    if not self.RImgCatRight then
        return
    end
    local mouseList = self._Game:GetStoneEntityList(XGoldenMinerConfigs.StoneType.Mouse)
    local leftCount = 0
    local rightCount = 0
    local tempPos
    for _, mouseEntity in pairs(mouseList) do
        if mouseEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE then
            local mousePosition = mouseEntity.Stone.Transform.anchoredPosition
            -- 定春 右->左
            if mouseEntity.Move.CurDirection < 0 and mousePosition.x > self._MouseEndRightTipX then
                rightCount = rightCount + 1
                if not self._RightMouseTipList[rightCount] then
                    self._RightMouseTipList[rightCount] = XUiHelper.Instantiate(self._RightMouseTipList[1].gameObject, self._RightMouseTipList[1].transform.parent)
                end
                tempPos = self._RightMouseTipList[rightCount].transform.position
                self._RightMouseTipList[rightCount].gameObject:SetActiveEx(true)
                self._RightMouseTipList[rightCount].transform.position = Vector3(tempPos.x, mouseEntity.Stone.Transform.position.y, tempPos.z)
            end
            -- 定春 左->右
            if mouseEntity.Move.CurDirection > 0 and mousePosition.x < self._MouseEndLeftTipX then
                leftCount = leftCount + 1
                if not self._LeftMouseTipList[leftCount] then
                    self._LeftMouseTipList[leftCount] = XUiHelper.Instantiate(self._LeftMouseTipList[1].gameObject, self._LeftMouseTipList[1].transform.parent)
                end
                tempPos = self._LeftMouseTipList[leftCount].transform.position
                self._LeftMouseTipList[leftCount].gameObject:SetActiveEx(true)
                self._LeftMouseTipList[leftCount].transform.position = Vector3(tempPos.x, mouseEntity.Stone.Transform.position.y, tempPos.z)
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
---@param type number XGoldenMinerConfigs.GAME_EFFECT_TYPE
---@param transform UnityEngine.Transform
function XUiGoldenMinerGameBattle:PlayEffect(type, transform, path)
    if string.IsNilOrEmpty(path) then
        return
    end
    if type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.GRAB then
        self:_PlayEffect(path, transform)
    elseif type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.STONE_BOOM
            or type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.GRAB_BOOM
            or type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.TYPE_BOOM
            or type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.TO_GOLD
    then
        self:_PlayEffect(path, transform, true)
    elseif type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.TIME_STOP then
        self:_PlayOnlyOneEffect(type, path)
    elseif type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.TIME_RESUME then
        self:_PlayOnlyOneEffect(type, path)
    elseif type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.WEIGHT_FLOAT then
        self:_PlayOnlyOneEffect(type, path)
    elseif type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.WEIGHT_RESUME then
        local effect = self:GetOnlyOnceEffect(XGoldenMinerConfigs.GAME_EFFECT_TYPE.WEIGHT_FLOAT, path)
        if effect then
            effect:SetActiveEx(false)
        end
    elseif type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.QTE_CLICK then
        self:_PlayOnlyOneEffect(type, path, transform)
    elseif type == XGoldenMinerConfigs.GAME_EFFECT_TYPE.QTE_COMPLETE then
        self:_PlayOnlyOneEffect(type, path, transform)
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
        resource = CS.XResourceManager.Load(path)
        self._EffectResourcePool[path] = resource
    end

    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XGoldenMinerGame:LoadStone加载资源，路径：%s", path))
        return
    end

    local parent = not isEffectRoot and transform or self._EffectRoot.transform
    local effect = XUiHelper.Instantiate(resource.Asset, parent)
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
--endregion

--region Audio - Sound
--播放使用道具音效
function XUiGoldenMinerGameBattle:PlayUseItemSound(itemId)
    local soundId = XGoldenMinerConfigs.GetItemUseSoundId(itemId)
    if not XTool.IsNumberValid(soundId) then
        return
    end

    XSoundManager.PlaySoundByType(soundId, XSoundManager.SoundType.Sound)
end
--endregion

--region Game - Init
function XUiGoldenMinerGameBattle:GameStart()
    self:GameInit()
    if not self._GameTimer then
        self._GameTimer = XScheduleManager.ScheduleForever(function()
            if not self.GameObject or not self.GameObject:Exist() then
                return
            end
            self:GameUpdate()
        end, 0)
    end
end

function XUiGoldenMinerGameBattle:GameInit()
    ---@type XGoldenMinerGameData
    local data = XGoldenMinerGameData.New(self._MapId)
    local areaPanel = XUiHelper.TryGetComponent(self.Ui.Transform, "SafeAreaContentPane")
    local hookTypeList = self:_GetHookTypeList(self._HookType)
    data:SetMapScore(0)
    data:SetAllScore(self._DataDb:GetStageScores())
    data:SetHookTypeList(hookTypeList)
    data:SetTime(XGoldenMinerConfigs.GetMapTime(self._MapId) + TIME_OFFSET)
    data:SetCurPassStageList(self._DataDb._FinishStageId)
    data:SetCurCharacterId(XDataCenter.GoldenMinerManager.GetUseCharacterId())
    self._Game:SetData(data)
    self._Game:SetMapObjRoot(self.PanelStone)
    self._Game:SetRectSize(areaPanel:GetComponent("RectTransform").rect.size)
    self._Game:SetHookObjDir(self:_GetHookObjDir(hookTypeList))
    self._Game:SetHookColliderDir(self.Humen)
    self._Game:SetBuffIdList(XDataCenter.GoldenMinerManager.GetCurBuffIdList())
    self._Game:Init()

    self:InitWall()
end

---@return number[]
function XUiGoldenMinerGameBattle:_GetHookTypeList(hookType)
    local result = {}
    if hookType == XGoldenMinerConfigs.FalculaType.Double then
        result[#result + 1] = XGoldenMinerConfigs.FalculaType.Normal
    end
    result[#result + 1] = hookType
    return result
end

---@return UnityEngine.Transform[]
function XUiGoldenMinerGameBattle:_GetHookObjDir(hookTypeList)
    local result = {}
    for _, type in ipairs(hookTypeList) do
        if self._HookType == XGoldenMinerConfigs.FalculaType.Double
                and type == XGoldenMinerConfigs.FalculaType.Normal then
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

--region Game - Update
function XUiGoldenMinerGameBattle:GameUpdate()
    local deltaTime = UnityTime.deltaTime
    self._Game:Update(deltaTime)
    if self._Game:IsPause() then
        return
    end
    self:RefreshPlayTime()
    self:RefreshFaceEmoji(deltaTime)
    self:RefreshMouseTip()
    self:RefreshBuffTip(deltaTime)
end
--endregion

--region Game - Wall
function XUiGoldenMinerGameBattle:InitWall()
    self.RectSize = XUiHelper.TryGetComponent(self.Ui.Transform, "SafeAreaContentPane", "RectTransform").rect.size
    local width, height =
        self.RectSize.x + XGoldenMinerConfigs.GetGameWallExAreaValue(true) * 2, 
        self.RectSize.y + XGoldenMinerConfigs.GetGameWallExAreaValue(false) * 2
    self.EdgeLeftBox.size = Vector2(self.EdgeLeftBox.size.x, height)
    self.EdgeRightBox.size = Vector2(self.EdgeRightBox.size.x, height)
    self.EdgeTopBox.size = Vector2(width, self.EdgeTopBox.size.y)
    self.EdgeBottomBox.size = Vector2(width, self.EdgeBottomBox.size.y)

    self.EdgeLeftBox.transform.localPosition = Vector3(
            self.EdgeLeftBox.transform.localPosition.x - XGoldenMinerConfigs.GetGameWallExAreaValue(true), 
            self.EdgeLeftBox.transform.localPosition.y,
            self.EdgeLeftBox.transform.localPosition.z)
    self.EdgeRightBox.transform.localPosition = Vector3(
            self.EdgeRightBox.transform.localPosition.x + XGoldenMinerConfigs.GetGameWallExAreaValue(true),
            self.EdgeRightBox.transform.localPosition.y,
            self.EdgeRightBox.transform.localPosition.z)
    self.EdgeTopBox.transform.localPosition = Vector3(
            self.EdgeTopBox.transform.localPosition.x,
            self.EdgeTopBox.transform.localPosition.y + XGoldenMinerConfigs.GetGameWallExAreaValue(false),
            self.EdgeTopBox.transform.localPosition.z)
    self.EdgeBottomBox.transform.localPosition = Vector3(
            self.EdgeBottomBox.transform.localPosition.x,
            self.EdgeBottomBox.transform.localPosition.y - XGoldenMinerConfigs.GetGameWallExAreaValue(false),
            self.EdgeBottomBox.transform.localPosition.z)
end
--endregion

--region Game - Settle
function XUiGoldenMinerGameBattle:GameSettle(isSkip)
    self:UpdateSettlementInfo(isSkip)
    local curMapScore = self._Game:GetCurScore()
    -- 3.0取消时间分数
    local lastTimeScore = 0--isSkip and 0 or XDataCenter.GoldenMinerManager.GetTimeScore(self._Game:GetData():GetTime())
    local closeCb = handler(self, self.CheckGameIsWin)
    local isCloseFunc = handler(self, self.GetIsCloseBattle)

    self._ReportInfo:SetMapId(self._MapId)
    self._ReportInfo:SetStageId(self._CurStageId)
    self._ReportInfo:SetStageIndex(self._CurStageIndex)
    self._ReportInfo:SetBeforeScore(self._Game:GetData():GetAllScore())
    self._ReportInfo:SetTargetScore(self._ScoreTarget)
    self._ReportInfo:SetLastTimeScore(lastTimeScore)
    self._ReportInfo:SetMapScore(curMapScore + lastTimeScore)
    self._ReportInfo:SetLastTime(math.floor(self._Game:GetData():GetTime()))
    self._ReportInfo:SetGrabObjList(self._Game:GetGrabbedStoneEntityList())
    self._ReportInfo:SetGrabObjScoreDir(self._Game:GetGrabbedScoreDir())
    self._Game:GameOver()
    
    XDataCenter.GoldenMinerManager.RequestGoldenMinerFinishStage(self._CurStageId,
            self._SettlementInfo,
            curMapScore + lastTimeScore,
            function(isFinishSuccess, isOpenHideStage)
                self._IsCloseBattle = true
                self._IsFinishSuccess = isFinishSuccess
                self._IsOpenHideStage = isOpenHideStage
                XLuaUiManager.Open("UiGoldenMinerReport", self._ReportInfo, closeCb, isCloseFunc)
            end,
            self._ReportInfo:IsWin())
end

function XUiGoldenMinerGameBattle:UpdateSettlementInfo(isGiveUpTimeScore)
    local mapTime = XGoldenMinerConfigs.GetMapTime(self._MapId)
    local time = self._Game:GetData():GetTime()
    local addScore = self._Game:GetData():GetMapScore()
    if not isGiveUpTimeScore then
        -- 3.0取消时间分数
        addScore = addScore-- + XDataCenter.GoldenMinerManager.GetTimeScore(time)
    end
    
    self._SettlementInfo:SetScores(addScore)
    self._SettlementInfo:SetCostTime(math.floor(mapTime - time))
    self._SettlementInfo:UpdateGrabDataInfosByEntityList(self._Game:GetGrabbedStoneEntityList())
    self._SettlementInfo:UpdateHideTaskInfoList(self._Game:GetData():GetHideTaskInfoList())
end

function XUiGoldenMinerGameBattle:CheckGameIsWin()
    local nextStageId = self._DataDb:GetCurStageId()
    if (not self._ReportInfo:IsWin() or not nextStageId) or (not self._IsFinishSuccess and self._CurStageIndex == 1) then
        XLuaUiManager.PopThenOpen("UiGoldenMinerMain")
        return
    end

    if XTool.IsTableEmpty(self._DataDb:GetMinerShopDbs()) then
        local stageId = self._DataDb:GetCurStageId()
        XDataCenter.GoldenMinerManager.RequestGoldenMinerEnterStage(stageId, function()
            XLuaUiManager.PopThenOpen("UiGoldenMinerBattle")
        end)
    else
        XLuaUiManager.PopThenOpen("UiGoldenMinerShop")
    end
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
    if not XDataCenter.GoldenMinerManager.IsUseItem(itemGridIndex) then
        return
    end
    if not self._Game:CheckItemCanUse(itemId) then
        --XGoldenMinerConfigs.DebugLog("当前道具不可用！")
        return
    end
    
    itemGrid:SetRImgIconActive(false)
    self:PlayUseItemSound(itemId)
    self:PlayFaceEmojiByUseItem(itemId)
    self:AddBuffTip(itemId)
    self:UpdateItemChangeInfo(itemGridIndex, XGoldenMinerConfigs.ItemChangeType.OnUse)
    self._Game:UseItemToAddBuff(itemId)
    self._DataDb:UseItem(itemGridIndex)
end

function XUiGoldenMinerGameBattle:OnKeyClickUseItem(index)
    self.ItemPanel:UseItemByIndex(index)
end

function XUiGoldenMinerGameBattle:OpenItemUsePanel()
    
end

function XUiGoldenMinerGameBattle:HideItemUsePanel()

end
--endregion

--region Game - Hook
function XUiGoldenMinerGameBattle:OnAnimAnglePointDown(eventData)
    if self._HookType ~= XGoldenMinerConfigs.FalculaType.AimingAngle then
        return
    end
    local eventPosX = eventData.position.x
    if eventPosX < CS.UnityEngine.Screen.width / 2 then
        --向左瞄准
        self:OnAimLeftAngleDown()
    else
        --向右瞄准
        self:OnAimRightAngleDown()
    end
end

function XUiGoldenMinerGameBattle:OnAimLeftAngleDown()
    if self._HookType ~= XGoldenMinerConfigs.FalculaType.AimingAngle then
        return
    end
    -- 上锁防按键同时按
    self._CurAnim = self._CurAnim | CurAim.Left
    self._Game:HookAimLeft()
end

function XUiGoldenMinerGameBattle:OnAimRightAngleDown()
    if self._HookType ~= XGoldenMinerConfigs.FalculaType.AimingAngle then
        return
    end
    self._CurAnim = self._CurAnim | CurAim.Right
    self._Game:HookAimRight()
end

function XUiGoldenMinerGameBattle:OnAimLeftAnglePointUp()
    if self._HookType ~= XGoldenMinerConfigs.FalculaType.AimingAngle then
        return
    end
    self._CurAnim = self._CurAnim & (~CurAim.Left)
    self:_SetAim()
end

function XUiGoldenMinerGameBattle:OnAimRightAnglePointUp()
    if self._HookType ~= XGoldenMinerConfigs.FalculaType.AimingAngle then
        return
    end
    self._CurAnim = self._CurAnim & (~CurAim.Right)
    self:_SetAim()
end

function XUiGoldenMinerGameBattle:OnHookShoot()
    -- 记录使用钩爪数
    if self._Game.HookEntityStatus == XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS.IDLE then
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
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_USE_ITEM, self.OnUseItem, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, self.RefreshQteBtn, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_END, self.RefreshShootBtn, self)
    if self._Game then
        self._Game:AddEventListener()
    end
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
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_USE_ITEM, self.OnUseItem, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, self.RefreshQteBtn, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_END, self.RefreshShootBtn, self)
    if self._Game then
        self._Game:RemoveEventListener()
    end
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerGameBattle:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnStop, self.OnBtnStopClick)
    self:RegisterClickEvent(self.BtneExit, self.OnBtnNextStageClick)

    if self.AimLeftInputHandler then
        self.AimLeftInputHandler:AddPointerDownListener(function() self:OnAimLeftAngleDown() end)
        self.AimLeftInputHandler:AddPointerUpListener(function() self:OnAimLeftAnglePointUp() end)
    end
    if self.AimRightInputHandler then
        self.AimRightInputHandler:AddPointerDownListener(function() self:OnAimRightAngleDown() end)
        self.AimRightInputHandler:AddPointerUpListener(function() self:OnAimRightAnglePointUp() end)
    end
end

function XUiGoldenMinerGameBattle:AddPCListener()
    XDataCenter.InputManagerPc.IncreaseLevel()
    XDataCenter.InputManagerPc.SetCurOperationType(CS.XOperationType.ActivityGame)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XGoldenMinerConfigs.GAME_PC_KEY.A, handler(self, self.OnAimLeftAngleDown))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyUpFunc(XGoldenMinerConfigs.GAME_PC_KEY.A, function() self:OnAimLeftAnglePointUp() end)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XGoldenMinerConfigs.GAME_PC_KEY.D, handler(self, self.OnAimRightAngleDown))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyUpFunc(XGoldenMinerConfigs.GAME_PC_KEY.D, function() self:OnAimRightAnglePointUp() end)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XGoldenMinerConfigs.GAME_PC_KEY.Space, handler(self, self.OnBtnShootPressDown))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyUpFunc(XGoldenMinerConfigs.GAME_PC_KEY.Space, handler(self, self.OnBtnShootPressUp))
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XGoldenMinerConfigs.GAME_PC_KEY.Q, function() self:OnKeyClickUseItem(1) end)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XGoldenMinerConfigs.GAME_PC_KEY.W, function() self:OnKeyClickUseItem(2) end)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XGoldenMinerConfigs.GAME_PC_KEY.E, function() self:OnKeyClickUseItem(3) end)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XGoldenMinerConfigs.GAME_PC_KEY.R, function() self:OnKeyClickUseItem(4) end)
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XGoldenMinerConfigs.GAME_PC_KEY.T, function() self:OnKeyClickUseItem(5) end)
end

function XUiGoldenMinerGameBattle:RemovePCListener()
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XGoldenMinerConfigs.GAME_PC_KEY.A)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyUp(XGoldenMinerConfigs.GAME_PC_KEY.A)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XGoldenMinerConfigs.GAME_PC_KEY.D)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyUp(XGoldenMinerConfigs.GAME_PC_KEY.D)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XGoldenMinerConfigs.GAME_PC_KEY.Space)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyUp(XGoldenMinerConfigs.GAME_PC_KEY.Space)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XGoldenMinerConfigs.GAME_PC_KEY.Q)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XGoldenMinerConfigs.GAME_PC_KEY.W)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XGoldenMinerConfigs.GAME_PC_KEY.E)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XGoldenMinerConfigs.GAME_PC_KEY.R)
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XGoldenMinerConfigs.GAME_PC_KEY.T)
    XDataCenter.InputManagerPc.DecreaseLevel()
    XDataCenter.InputManagerPc.ResumeCurOperationType()
end

function XUiGoldenMinerGameBattle:OnBtnShootPressDown()
    if not self._Game then
        return
    end
    if self._HookType ~= XGoldenMinerConfigs.FalculaType.StorePressMagnetic then
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
        self._Game:QTEClick()
    elseif self._HookType ~= XGoldenMinerConfigs.FalculaType.StorePressMagnetic then
        self:OnHookShoot()
    else
        for _, hookEntity in ipairs(self._Game.HookEntityList) do
            self._Game:HookRevoke(hookEntity)
        end
    end
end

function XUiGoldenMinerGameBattle:OnFocusExit()
    if self._Game and self._Game.HookEntityStatus == XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS.USING
            and self._HookType == XGoldenMinerConfigs.FalculaType.StorePressMagnetic
    then
        for _, hookEntity in ipairs(self._Game.HookEntityList) do
            if hookEntity.Hook.Status == XGoldenMinerConfigs.GAME_HOOK_STATUS.SHOOTING then
                self._Game:HookRevoke(hookEntity)
            end
        end
    end
end

function XUiGoldenMinerGameBattle:OnBtnStopClick()
    self:OpenPauseDialog()
end

function XUiGoldenMinerGameBattle:OnBtnNextStageClick()
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PAUSE, XGoldenMinerConfigs.GAME_PAUSE_TYPE.PLAYER)
    self.BtneExit:SetButtonState(CS.UiButtonState.Select)
    
    if self._Game:GetData():GetCurScore() >= self._ScoreTarget then
        self:GameSettle(true)
        return
    end
    local closeCb = function()
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_RESUME, XGoldenMinerConfigs.GAME_PAUSE_TYPE.PLAYER)
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
--endregion