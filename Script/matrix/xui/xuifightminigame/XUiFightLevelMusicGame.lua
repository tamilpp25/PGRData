---@class XUiFightLevelMusicGame : XLuaUi
---@field TrackPanel UnityEngine.RectTransform
---@field Track UnityEngine.RectTransform
---@field TrackSuccessful UnityEngine.RectTransform
---@field GridTrackUnit UnityEngine.RectTransform
---@field NotePanel UnityEngine.RectTransform
---@field GridNote UnityEngine.RectTransform
---@field AreaPointPanel UnityEngine.RectTransform
---@field GridAreaPoint UnityEngine.RectTransform
---@field EffectPanel UnityEngine.RectTransform
---@field EffectTrigger UnityEngine.RectTransform
---@field ImgBgCommon UnityEngine.RectTransform
---@field ImgBgCommonA UnityEngine.RectTransform
---@field ImgBgCommonB UnityEngine.RectTransform
---@field BtnNoteA1 XUiComponent.XUiButton
---@field BtnNoteB1 XUiComponent.XUiButton
---@field AnimEnable UnityEngine.Playables.PlayableDirector
---@field CloseDisable UnityEngine.Playables.PlayableDirector
---@field SuccessAnimDisable UnityEngine.Playables.PlayableDirector
---@field _Control XFightLevelMusicGameControl
local XUiFightLevelMusicGame = XLuaUiManager.Register(XLuaUi, "UiFightLevelMusicGame")

function XUiFightLevelMusicGame:OnAwake()
    self._AnimTime = self.AnimEnable and self.AnimEnable.duration or 0
    self._IsPause = false
    self._TrackDistance = self.Track.rect.width
    ---@type XUiFightLevelMusicGridNote[]
    self._GridNoteList = {}
    ---@type XUiFightLevelMusicGridTrackUnit[]
    self._GridTrackUnitList = {}
    ---@type XUiFightLevelMusicGridAreaPoint[]
    self._GridAreaPointList = {}
    ---@type XUiComponent.XUiButton[]
    self._BtnTypeDir = {
        [XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A] = self.BtnNoteA1,
        [XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B] = self.BtnNoteB1
    }
    ---@type UnityEngine.RectTransform[]
    self._BtnTypeEffectDir = {
        [XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A] = XUiHelper.TryGetComponent(self.BtnNoteA1.transform, "EffectTrigger"),
        [XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B] = XUiHelper.TryGetComponent(self.BtnNoteB1.transform, "EffectTrigger"),
    }
    self.ImgBgCommon = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/ImgBgCommon")
    self.ImgBgCommonA = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/ImgBgCommonA")
    self.ImgBgCommonB = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/ImgBgCommonB")
    self.ImgBlurAnimation = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/ImgBlur/Animation")
    self.CloseDisable = XUiHelper.TryGetComponent(self.Transform, "Animation/CloseDisable", "PlayableDirector")
    self.SuccessAnimDisable = XUiHelper.TryGetComponent(self.Transform, "Animation/SuccessAnimDisable", "PlayableDirector")
    self.OnPcClickCb = handler(self, self.OnPcClick)
    
    self:AddBtnListener()
end

function XUiFightLevelMusicGame:OnStart(mapId)
    self._MapId = mapId
end

function XUiFightLevelMusicGame:OnEnable(mapId)
    -- 在战斗中属于子Ui 于Enable刷新数据确保每次打开刷新
    self:InitGameLogicData(self._MapId or mapId)
    self:InitGameCurRLObj()
    self:InitUi()
    
    self:_PauseFight()
    self:Update(0)
    
    self:StartGameTimer()
    self:AddEventListener()
    self:RegisterPCClickEvent()
    if CS.XFight.Instance.IsReplay then 
        self:Close()
    end
end

function XUiFightLevelMusicGame:OnDisable()
    self:StopGameTimer()
    self:RemoveEventListener()
    self:UnRegisterPCClickEvent()

    self:_ResumeFight()
end

function XUiFightLevelMusicGame:OnDestroy()
    self._Game = false
end

--region Game - Init
function XUiFightLevelMusicGame:InitGameLogicData(mapId)
    -- Logic
    self._Game = self._Control:GetGame(mapId)
    
    -- RendererLogic
    self._Game:RefreshAreaPointRLData(self._TrackDistance)
    
    --self._Game:_LogString()
end

function XUiFightLevelMusicGame:InitGameCurRLObj()
    if not self._Game then
        return
    end
    local curTrackLength = self._Game:GetCurTrackLength()
    
    -- Track
    local XUiFightLevelMusicGridTrackUnit = require("XUi/XUiFightMiniGame/XUiFightLevelMusicGridTrackUnit")
    for i, unit in ipairs(self._Game:GetCurTrack():GetUnitList()) do
        if not self._GridTrackUnitList[i] then
            local obj = i == 1 and self.GridTrackUnit or XUiHelper.Instantiate(self.GridTrackUnit, self.GridTrackUnit.parent)
            self._GridTrackUnitList[i] = XUiFightLevelMusicGridTrackUnit.New(obj, self)
        end
        self._GridTrackUnitList[i]:Refresh(unit, self._TrackDistance, curTrackLength)
    end
    
    -- Note
    local XUiFightLevelMusicGridNote = require("XUi/XUiFightMiniGame/XUiFightLevelMusicGridNote")
    local noteTypeList = {}
    for i, note in pairs(self._Game:GetCurNoteList()) do
        self:_InitGridNote(XUiFightLevelMusicGridNote, i, note, curTrackLength)
        noteTypeList[note:GetType()] = true
    end
    
    -- TriggerBtn
    self:_UpdateBtnShow(noteTypeList)
    
    -- AreaPoint
    local XUiFightLevelMusicGridAreaPoint = require("XUi/XUiFightMiniGame/XUiFightLevelMusicGridAreaPoint")
    for i, areaPoint in pairs(self._Game:GetAreaPointList()) do
        if not self._GridAreaPointList[i] then
            local obj = i == 1 and self.GridAreaPoint or XUiHelper.Instantiate(self.GridAreaPoint, self.GridAreaPoint.parent)
            self._GridAreaPointList[i] = XUiFightLevelMusicGridAreaPoint.New(obj, self)
        end
        self._GridAreaPointList[i]:Refresh(areaPoint)
    end
    
    -- Effect
    self.EffectTrigger.gameObject:SetActiveEx(false)
end

function XUiFightLevelMusicGame:InitUi()
    -- Anim
    if self.ImgBlurAnimation then
        self.ImgBlurAnimation.gameObject:SetActiveEx(false)
    end
    -- 战斗ui是子ui, disable动画之后要重新置回
    if self.CloseDisable then
        self.CloseDisable:Evaluate()
        self.CloseDisable:Stop()
        self.SuccessAnimDisable:Evaluate()
        self.SuccessAnimDisable:Stop()
    end
    
    -- Btn
    if self.BtnHelp then
        self.BtnTanchuangCloseBig.gameObject:SetActiveEx(false)
        self.BtnHelp.gameObject:SetActiveEx(false)
    end
end

---@param note XFightLevelMusicNote
function XUiFightLevelMusicGame:_InitGridNote(class, noteIndex, note, curTrackLength)
    if not self._GridNoteList[noteIndex] then
        local obj = noteIndex == 1 and self.GridNote or XUiHelper.Instantiate(self.GridNote, self.GridNote.parent)
        self._GridNoteList[noteIndex] = class.New(obj, self)
    end
    self._GridNoteList[noteIndex]:Refresh(note, self._TrackDistance, curTrackLength)
    self._GridNoteList[noteIndex]:Open()
    self._GridNoteList[noteIndex]:PlayInitAnim()
end
--endregion

--region Game - Control
function XUiFightLevelMusicGame:StartGameTimer()
    self._GameTimer = XScheduleManager.ScheduleForever(function()
        if not self._Game then
            self:StopGameTimer()
            return
        end
        if self._Game:IsGameStop() then
            self:StopGameTimer()
            return
        end
        if self._IsPause then
            return
        end
        local deltaTime = CS.UnityEngine.Time.deltaTime
        if self._AnimTime > 0 then
            self._AnimTime = self._AnimTime - deltaTime
            return
        end
        self:Update(deltaTime)
    end, 0)
end

function XUiFightLevelMusicGame:StopGameTimer()
    if self._GameTimer then
        XScheduleManager.UnSchedule(self._GameTimer)
    end
    self._Game = false
    self._GameTimer = false
end

function XUiFightLevelMusicGame:PauseGame()
    self._IsPause = true
end

function XUiFightLevelMusicGame:ResumeGame()
    self._IsPause = false
end
--endregion

--region Game - Update
function XUiFightLevelMusicGame:Update(time)
    if not self._Game then
        return
    end

    if self._Game:IsGaming() then
        self:_UpdateRLAreaPoint(time)
        self:_UpdateRLBtnShow()
    end
    self._Game:Update(time)
end

function XUiFightLevelMusicGame:_UpdateRLAreaPoint(time)
    local areaPointList = self._Game:GetAreaPointList()
    for i, gridAreaPoint in pairs(self._GridAreaPointList) do
        gridAreaPoint:Update(time, areaPointList[i])
    end
end

function XUiFightLevelMusicGame:_UpdateRLTrack(changeTime)
    if not self._Game or not self._Game:GetCurTrack() or self._Game:IsGameStop() then
        return
    end
    
    -- 切轨动画
    self:PlayAnimation("TrackPanelAnimReload")
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 4716)
    
    -- note加载
    XScheduleManager.ScheduleOnce(function()
        local XUiFightLevelMusicGridNote = require("XUi/XUiFightMiniGame/XUiFightLevelMusicGridNote")
        local curTrackLength = self._Game:GetCurTrackLength()
        local noteTypeList = {}
        
        -- 刷新Note
        for i, note in pairs(self._Game:GetCurNoteList()) do
            self:_InitGridNote(XUiFightLevelMusicGridNote, i, note, curTrackLength)
            noteTypeList[note:GetType()] = true
        end
        -- 刷新按钮
        self:_UpdateBtnShow(noteTypeList)
        -- 刷新按钮背景
    end, changeTime * XScheduleManager.SECOND)
end

---Miss状态按钮置灰
function XUiFightLevelMusicGame:_UpdateRLBtnShow()
    if not self._Game then
        return
    end
    for _, btn in pairs(self._BtnTypeDir) do
        btn:SetDisable(self._Game:IsMiss())
    end
end

---刷新按钮
function XUiFightLevelMusicGame:_UpdateBtnShow(noteTypeList)
    for type, btn in pairs(self._BtnTypeDir) do
        btn.gameObject:SetActiveEx(noteTypeList[type])
    end
    for _, btn in pairs(self._BtnTypeEffectDir) do
        btn.gameObject:SetActiveEx(false)
    end
    if not self.ImgBgCommon then
        return
    end
    self.ImgBgCommon.gameObject:SetActiveEx(noteTypeList[XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A]
            and noteTypeList[XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B])
    self.ImgBgCommonA.gameObject:SetActiveEx(noteTypeList[XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A]
            and not noteTypeList[XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B])
    self.ImgBgCommonB.gameObject:SetActiveEx(not noteTypeList[XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A]
            and noteTypeList[XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B])
end
--endregion

--region Game - Action
function XUiFightLevelMusicGame:Trigger(noteType, areaPointIndex)
    if not self._Game or self._Game:IsMiss() then   -- MISS状态不给trigger
        return
    end
    local triggerResult, noteIndex = self._Game:Trigger(noteType, areaPointIndex)
    -- 按钮特效
    if self._BtnTypeEffectDir[noteType] then
        self._BtnTypeEffectDir[noteType].gameObject:SetActiveEx(false)
        self._BtnTypeEffectDir[noteType].gameObject:SetActiveEx(true)
    end
    
    --local areaPoint = self._Game:GetAreaPoint(areaPointIndex)
    --local checkTriggerUnitList = areaPoint:GetCurTriggerUnitIndexList()
    --for _, unitIndex in ipairs(checkTriggerUnitList) do
    --    self._GridTrackUnitList[unitIndex]:ShowTriggerArea()
    --end
    if triggerResult == XEnumConst.FIGHT_LEVEL_MUSIC.TRIGGER_RESULT.CLEAR and self._GridNoteList[noteIndex] then
        self._GridNoteList[noteIndex]:PlayTriggerAnim(noteType)
        self._GridAreaPointList[areaPointIndex]:PlayTriggerClearAnim(noteType, self._GridNoteList[noteIndex])
    elseif triggerResult == XEnumConst.FIGHT_LEVEL_MUSIC.TRIGGER_RESULT.MISS then
        self._GridAreaPointList[areaPointIndex]:PlayTriggerFail(noteType)
        --XUiManager.TipError("Miss")
    end
end

function XUiFightLevelMusicGame:Win()
    self:StopGameTimer()
    self:_OnWinBack()

    self.EffectTrigger.gameObject:SetActiveEx(true)
    if self.ImgBgCommon then
        self.ImgBgCommon.gameObject:SetActiveEx(false)
        self.ImgBgCommonA.gameObject:SetActiveEx(false)
        self.ImgBgCommonB.gameObject:SetActiveEx(false)
    end
    if self.BtnHelp then
        self.BtnTanchuangCloseBig.gameObject:SetActiveEx(false)
        self.BtnHelp.gameObject:SetActiveEx(false)
    end
    self:PlayAnimation("SuccessAnimDisable", function()
        self:Close()
    end)
end

function XUiFightLevelMusicGame:Fail()
    self:StopGameTimer()
    self:_OnFailBack()
    XLog.Error("Wait Fail Effect")
    XUiManager.TipError("Game Fail")
end
--endregion

--region Fight
function XUiFightLevelMusicGame:_PauseFight()
    if CS.XFight.IsRunning then
        CS.XFight.Instance:Pause()
    end
end

function XUiFightLevelMusicGame:_ResumeFight()
    if CS.XFight.IsRunning then
        CS.XFight.Instance:Resume()
    end
end
--endregion

--region Ui - BtnListener
local XNpcOperationClickKey = CS.XNpcOperationClickKey
function XUiFightLevelMusicGame:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnOpenTutorial)
    self.BtnNoteA1.CallBack = function()
        self:Trigger(XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A, 1)
    end
    self.BtnNoteB1.CallBack = function()
        self:Trigger(XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B, 1)
    end
end

function XUiFightLevelMusicGame:OnBtnBackClick()
    if self._Game and self._Game:IsGameStop() then
        return
    end
    ---@type XFight
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
    end
    self:PlayAnimation("CloseDisable", function()
        self:Close()
    end)
end

function XUiFightLevelMusicGame:_OnWinBack()
    ---@type XFight
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyUp)
    end
end

function XUiFightLevelMusicGame:_OnFailBack()
    ---@type XFight
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(XNpcOperationClickKey.HackerFail, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(XNpcOperationClickKey.HackerFail, CS.XOperationClickType.KeyUp)
    end
    self:PlayAnimation("CloseDisable", function()
        self:Close()
    end)
end

function XUiFightLevelMusicGame:OnOpenTutorial()
    if not self._Game or self._Game:IsGameStop() then
        return
    end
    if not XTool.IsNumberValid(self._Game:GetTutorialId()) then
        return
    end
    local fight = CS.XFight.Instance
    if not fight then
        XLog.Error("FightLevelMusicGame 教程需要在战斗中打开!")
        return
    end
    local uiFight = fight.UiManager:GetUi(typeof(CS.XUiFight))
    if not uiFight.GameObject or not uiFight.GameObject.activeInHierarchy then
        return
    end
    uiFight:OpenChildUi("UiFightTutorial", self._Game:GetTutorialId())
end
--endregion

--region Pc
function XUiFightLevelMusicGame:RegisterPCClickEvent()
    CS.XInputManager.RegisterOnClick(CS.XInputManager.XOperationType.Fight, self.OnPcClickCb)
end

function XUiFightLevelMusicGame:UnRegisterPCClickEvent()
    CS.XInputManager.UnregisterOnClick(CS.XInputManager.XOperationType.Fight, self.OnPcClickCb)
end

function XUiFightLevelMusicGame:OnPcClick(inputDeviceType, key, clickType, operationType)
    if clickType == CS.XOperationClickType.KeyUp then
        if key == 130 then
            self:Trigger(XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.A, 1)
        elseif key == 131 then
            self:Trigger(XEnumConst.FIGHT_LEVEL_MUSIC.NOTE_TYPE.B, 1)
        end
    end
end
--endregion

--region Event
function XUiFightLevelMusicGame:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LEVEL_MUSIC_TRACK_CHANGE, self._UpdateRLTrack, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LEVEL_MUSIC_WIN, self.Win, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LEVEL_MUSIC_FAIL, self.Fail, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_UI_TUTORIAL_OPEN, self.PauseGame, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_UI_TUTORIAL_CLOSE, self.ResumeGame, self)
end

function XUiFightLevelMusicGame:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LEVEL_MUSIC_TRACK_CHANGE, self._UpdateRLTrack, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LEVEL_MUSIC_WIN, self.Win, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LEVEL_MUSIC_FAIL, self.Fail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_UI_TUTORIAL_OPEN, self.PauseGame, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_UI_TUTORIAL_CLOSE, self.ResumeGame, self)
end
--endregion

return XUiFightLevelMusicGame