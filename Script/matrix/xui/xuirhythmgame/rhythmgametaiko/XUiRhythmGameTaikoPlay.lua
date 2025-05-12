---@field _Control XRhythmGameControl
---@class XUiRhythmGameTaikoPlay : XLuaUi
local XUiRhythmGameTaikoPlay = XLuaUiManager.Register(XLuaUi, "UiRhythmGameTaikoPlay")
local MathLerp = CS.UnityEngine.Mathf.Lerp

function XUiRhythmGameTaikoPlay:OnAwake()
    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.System) --设为活动按键
    CS.XInputManager.InputMapper:SetIsOpenInputMapSectionCheck(true) -- 打开按键检测冲突
    self.FightClose = function ()
        self:Close()
    end
    CS.XGameEventManager.Instance:RegisterEvent(XEventId.EVENT_ON_FIGHT_EXIT, self.FightClose) -- 战斗结束
    XEventManager.AddEventListener(XEventId.EVENT_RHYTHM_TAIKO_ANIMSHOW, self.EventAnimShowOrHide, self)

    self.ScoreTransformDic = 
    {
        [XEnumConst.RhythmGameTaiko.HitPoint.Score.Miss] = "AnimScoreMiss",
        -- [XEnumConst.RhythmGameTaiko.HitPoint.Score.Bad] = "ScoreBad",
        [XEnumConst.RhythmGameTaiko.HitPoint.Score.Good] = "AnimScoreGood",
        [XEnumConst.RhythmGameTaiko.HitPoint.Score.Perfect] = "AnimScorePerfect",
    }
end

function XUiRhythmGameTaikoPlay:InitButton()
    self.TransmitPosRectTransform = self.TransmitPos:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self.TransmitPosAnchoredPos = self.TransmitPosRectTransform.anchoredPosition
    self.TransmitPosAnchoredPosX = self.TransmitPosRectTransform.anchoredPosition.x
    self.JudgmentAreaAnchoredPos = self.JudgmentArea.anchoredPosition
    self.JudgmentAreaAnchoredPosX = self.JudgmentArea.anchoredPosition.x
    self.Camera = self.Transform:GetComponent("Canvas").worldCamera
    self.TempV2 = CS.UnityEngine.Vector2.zero
    self.ProgressWidth = self.ImgProgressBar:GetComponent(typeof(CS.UnityEngine.RectTransform)).rect.width

    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnContinue, self.OnBtnContinueClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRetry, self.OnBtnRetryClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnPlay, self.OnBtnPlayClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSet, self.OnBtnSetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnPauseClick)
    -- XUiHelper.RegisterClickEvent(self, self.BtnBlueDrum, self.OnBtnBlueDrumClick)
    -- XUiHelper.RegisterClickEvent(self, self.BtnRedDrum, self.OnBtnRedDrumClick)

    self.BtnBlueDrum.CallBack = function ()
        self:OnBtnBlueDrumClick()
    end
    self.BtnRedDrum.CallBack = function ()
        self:OnBtnRedDrumClick()
    end
end

function XUiRhythmGameTaikoPlay:OnBtnBlueDrumClick()
    self:DoJudgmentNote(XEnumConst.RhythmGameTaiko.NoteType.BlueNormal)
end

function XUiRhythmGameTaikoPlay:OnBtnRedDrumClick()
    self:DoJudgmentNote(XEnumConst.RhythmGameTaiko.NoteType.RedNormal)
end

function XUiRhythmGameTaikoPlay:OnBtnContinueClick()
    if not self.XFsm then
        return
    end

    self.PanelPause.gameObject:SetActiveEx(false)
    self.IsPause = false
    self.XFsm["ResumePlaying"]()
end

function XUiRhythmGameTaikoPlay:OnBtnRetryClick()
    self.PanelPause.gameObject:SetActiveEx(false)
    XMVCA.XFSM:SetAutoFSMStop(self.XFsm)
    XLuaAudioManager.StopCurrentBGM()
    self:InitNotesInfo()
    self:InitFSM()
    self.ActiveXNoteQuene:Ergodic(function (xNote, i)
        xNote.Transform.gameObject:SetActiveEx(false)        
    end)
    self.XFsm["ResumePlaying"]()
    self:ShowReady()
end

function XUiRhythmGameTaikoPlay:OnBtnPlayClick()
    self:DoPlayGame()
end

function XUiRhythmGameTaikoPlay:OnBtnSetClick()
    XLuaUiManager.Open("UiSet")
end

function XUiRhythmGameTaikoPlay:OnBtnPauseClick()
    if not self.XFsm then
        self:Close()
        return
    end

    self.PanelPause.gameObject:SetActiveEx(true)
    self.IsPause = true
    self.XFsm["Pause"]()
end

function XUiRhythmGameTaikoPlay:EnterPauseCallByFSM()
    -- 计时暂停了多久
    self.StartPauseTimeStamp = CS.XTimerManager.GetRealTime() * 1000

    if not self.CurMusicInfo then
        return
    end
    self.CurMusicInfo:Pause()
end

function XUiRhythmGameTaikoPlay:LeavePauseCallByFSM()
    self.StopPauseTimeStamp = CS.XTimerManager.GetRealTime() * 1000
    self.TotalPauseElapsedTime = self.TotalPauseElapsedTime + (self.StopPauseTimeStamp - self.StartPauseTimeStamp) + self.PauseOffsetMs

    self:CheckToFixPlayingOffset()

    if not self.CurMusicInfo then
        return
    end
    self.CurMusicInfo:Resume()
end

function XUiRhythmGameTaikoPlay:CheckToFixPlayingOffset()
    -- 暂停误差修正
    if self.LastSongTimeStamp > 0 then
        local nowTime = CS.XTimerManager.GetRealTime() * 1000
        local aTime = nowTime - self.StartTimeStamp - self.TotalPauseElapsedTime
        local bTime = self.CountDownTimeMs + self.LastSongTimeStamp
        self.PlayingFixOffsetMs = bTime -aTime + self.AudioCalibrationOffsetMs
    end
end

function XUiRhythmGameTaikoPlay:EnterPlayCallByFSM()
end

--读取配置数据
--初始化Note/Track等Ui实例
--初始化状态机
function XUiRhythmGameTaikoPlay:OnStart(mapId, playerOffset, isDebug, finishCb, isShowSettle)
    self.MapId = mapId
    self.MapName = "Map"..mapId
    self.PlayerOffset = playerOffset or 0
    self.IsDebug = isDebug
    self.FinishCb = finishCb
    self.IsShowSettle = isShowSettle

    -- 读取本地配置表数据
    local mapConfig = self._Control:GetModelRhythmGameTaikoMapConfig(self.MapName)
    self.MapConfig = mapConfig
    if XTool.IsTableEmpty(mapConfig) then
        XLog.Error("XUiRhythmGameTaikoPlay:InitNotesInfo: mapConfig is empty : ", self.MapName)
        return
    end

    self:InitGame()
    self:InitButton()
    self:ShowReady()
    self.HitErrorIndicator.gameObject:SetActiveEx(isDebug)
end

function XUiRhythmGameTaikoPlay:InitGame()
    self:InitSkin()
    self:InitNotesInfo()
    self:InitEntity()
    self:InitFSM()
end

function XUiRhythmGameTaikoPlay:InitSkin()
    local skinId = tonumber(self.MapConfig["SkinId"].Value)
    if not XTool.IsNumberValid(skinId) then
        skinId = 1
    end
    local skinConfig = self._Control:GetModelRhythmGameTaikoSkin()[skinId]
    if not string.IsNilOrEmpty(skinConfig.SkinPrefabUiPath) then
        self.SkinGo = self.SkinParent:LoadPrefab(skinConfig.SkinPrefabUiPath)
        local uiObj = self.SkinGo:GetComponent(typeof(CS.UiObject))
        if uiObj ~= nil then
            for i = 0, uiObj.NameList.Count - 1 do
                self[uiObj.NameList[i]] = uiObj.ObjList[i]
            end
            local xuiEffectLayer = self.SkinParentEffectLayer
            xuiEffectLayer:Init()
            xuiEffectLayer:ProcessSortingOrder()
        end
    end
    
    self.CursorEffect = self.CursorEffectParent:GetChild(0)
    self.HitEffectGood = self.HitGoodEffectPool:GetChild(0)
    self.HitEffectPerfect = self.HitPerfectEffectPool:GetChild(0)
    
    self.CursorEffectPsRoot = self.CursorEffect:Find("Root")
    self.HitEffectGoodPsRoot = self.HitEffectGood:Find("Root")
    self.HitEffectPerfectRoot = self.HitEffectPerfect:Find("Root")

    self.RedNormalNotesTemplateList = {}
    local redNormalTemplatesParent = self.RedNormalNotePool
    for i = 0, redNormalTemplatesParent.childCount - 1 do
        local item = redNormalTemplatesParent:GetChild(i)
        table.insert(self.RedNormalNotesTemplateList, item)
    end

    self.BlueNormalNotesTemplateList = {}
    local blueNormalTemplatesParent = self.BlueNormalNotePool
    for i = 0, blueNormalTemplatesParent.childCount - 1 do
        local item = blueNormalTemplatesParent:GetChild(i)
        table.insert(self.BlueNormalNotesTemplateList, item)
    end

    -- UI数据
    self.TxtMapName.text = self.MapConfig["Title"].Value
end

function XUiRhythmGameTaikoPlay:InitNotesInfo()
    local mapConfig = self.MapConfig

    --基础数据
    self.IntrinsicOffsetMs = 50 -- 基础固定偏移量
    self.AudioCalibrationOffsetMs = 100 -- 校准音频进度时补偿的偏移量
    self.FinalOffsetMs = self.IntrinsicOffsetMs + self.PlayerOffset -- 最终偏移量，note的时间相关参数都要加上它
    self.Bpm = tonumber(mapConfig["Bpm"].Value)
    self.SpeedSecond = 2.3
    self.SpeedMs = self.SpeedSecond * 1000 --落速毫秒(note出现到需要击打判定消失的时间)
    local cueId = tonumber(mapConfig["CueId"].Value)
    if XTool.IsNumberValid(cueId) then
        local cueTemplate = CS.XAudioManager.GetCueTemplate(cueId)
        self.SongDuration = cueTemplate.Duration
    else
        self.SongDuration = 0
    end

    self.CountDownTimeMs = 4000 -- 倒计时。 所有Note/Track的判定时间，音乐播放时间都要加上这个时间
    self.FinishWaitTimeMs = 1000 -- 游戏结束等待时间
    self.ExtraMoveX = 1000 -- 额外移动距离
  
    self.NotesInfo = {}
    for k, v in pairs(mapConfig) do
        if string.find(k, "Note") then
            local firstPart, secondPart = (v.Value):match("([^|]+)|([^|]+)")
            local judgmentTimeStamp = tonumber(firstPart)
            local type = tonumber(secondPart)
            table.insert(self.NotesInfo, {JudgmentTimeStamp = judgmentTimeStamp, Type = type})
        end
    end
    table.sort(self.NotesInfo, function(a, b) return a.JudgmentTimeStamp < b.JudgmentTimeStamp end)

    -- Note数据
    if not self.AllXNotesQueue then
        self.AllXNotesQueue = XQueue.New(#self.NotesInfo)
    end
    self.AllXNotesQueue:Clear()
    for k = 1, #self.NotesInfo, 1 do
        local v = self.NotesInfo[k]
        local curXNote = self._Control:GetNewEntityXNote()
        curXNote.Index = k
        curXNote.Type = v.Type
        curXNote.JudgmentTimeStamp = v.JudgmentTimeStamp + self.CountDownTimeMs + self.FinalOffsetMs
        curXNote.TransmitTimeStamp = curXNote.JudgmentTimeStamp - self.SpeedMs
        self.AllXNotesQueue:Enqueue(curXNote)

        -- 记录最后一个Note的判定时间
        if k == 1 then
            self.FirstNoteTransmitTimeStamp = curXNote.TransmitTimeStamp
        end
        if k == #self.NotesInfo then
            self.LastNoteJugTimeStamp = curXNote.JudgmentTimeStamp
        end
    end
end

function XUiRhythmGameTaikoPlay:InitEntity()
    local releaseNoteFun = function (item)
        if item and item.Transform then
            item.Transform.gameObject:SetActiveEx(false)  -- 使用完毕后禁用对象
        end
    end

    -- 红Note池子
    self.XRedNormalNotePool = XPool.New(function ()
        local instantiateTameplatePrefab = self.RedNormalNotesTemplateList[math.random(1, #self.RedNormalNotesTemplateList)]
        local prefab = XUiHelper.Instantiate(instantiateTameplatePrefab, self.RedNormalNotePool)
        prefab.gameObject:SetActiveEx(false)
        return {GameObject = prefab, Transform = prefab.transform, RectTransform = prefab:GetComponent(typeof(CS.UnityEngine.RectTransform)), 
            AnimNoteEnable = prefab.transform:FindTransform("AnimNoteEnable"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector)), 
            AnimNoteDisable = prefab.transform:FindTransform("AnimNoteDisable"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector)), 
        } -- 提前缓存
    end, releaseNoteFun, false)

    -- 蓝Note池子
    self.XBlueNormalNotePool = XPool.New(function ()
        local instantiateTameplatePrefab = self.BlueNormalNotesTemplateList[math.random(1, #self.BlueNormalNotesTemplateList)]
        local prefab = XUiHelper.Instantiate(instantiateTameplatePrefab, self.BlueNormalNotePool)
        prefab.gameObject:SetActiveEx(false)
        return {GameObject = prefab, Transform = prefab.transform, RectTransform = prefab:GetComponent(typeof(CS.UnityEngine.RectTransform)), 
            AnimNoteEnable = prefab.transform:FindTransform("AnimNoteEnable"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector)), 
            AnimNoteDisable = prefab.transform:FindTransform("AnimNoteDisable"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector)), 
        } -- 提前缓存
    end, releaseNoteFun, false)

    -- 滑条Note池子
    self.XSliderNotePool = XPool.New(function ()
        local prefab = XUiHelper.Instantiate(self.SliderNote, self.SliderNotePool)
        prefab.gameObject:SetActiveEx(false)
        return {GameObject = prefab, Transform = prefab.transform, RectTransform = prefab:GetComponent(typeof(CS.UnityEngine.RectTransform))} -- 提前缓存
    end, releaseNoteFun, false)

    ---@type table<number, XPool>
    self.NoteTypePoolDic = 
    {
        [1] = self.XRedNormalNotePool,
        [2] = self.XBlueNormalNotePool,
        [3] = self.XSliderNotePool,
        [4] = self.XSliderNotePool,
    }

    -- 每个池子先创建30个对象
    for k, xPool in pairs(self.NoteTypePoolDic) do
        local noteList = {}
        for i = 1, 30, 1 do
            local item = xPool:GetItemFromPool()
            table.insert(noteList, item)
        end

        for k, item in pairs(noteList) do
            xPool:ReturnItemToPool(item)
        end
    end

    -- 特效 --------------
    local releaseEffectFun = function (item)
        item.gameObject:SetActiveEx(false)  -- 使用完毕后禁用对象
    end
    self.XHitEffectPerfectPool = XPool.New(function ()
        local prefab = XUiHelper.Instantiate(self.HitEffectPerfect, self.HitPerfectEffectPool)
        prefab.gameObject:SetActiveEx(false)
        return prefab
    end, releaseEffectFun, false)

    self.XHitEffectGoodPool = XPool.New(function ()
        local prefab = XUiHelper.Instantiate(self.HitEffectGood, self.HitGoodEffectPool)
        prefab.gameObject:SetActiveEx(false)
        return prefab
    end, releaseEffectFun, false)

    ---@type table<number, XPool>
    self.HitEffectTypePoolDic = 
    {
        [XEnumConst.RhythmGameTaiko.HitPoint.Score.Good] = self.XHitEffectGoodPool,
        [XEnumConst.RhythmGameTaiko.HitPoint.Score.Perfect] = self.XHitEffectPerfectPool,
    }

    -- 池子先创建3个对象
    for k, xPool in pairs(self.HitEffectTypePoolDic) do
        local noteList = {}
        for i = 1, 3, 1 do
            local item = xPool:GetItemFromPool()
            table.insert(noteList, item)
        end

        for k, item in pairs(noteList) do
            xPool:ReturnItemToPool(item)
        end
    end
end

function XUiRhythmGameTaikoPlay:InitFSM()
    if not self.XFsm then
        self.XFsm = XMVCA.XFSM:CreateUpdatableFSM("XUi/XUiRhythmGame/Entity/XRhythmGameTaikoController", self)
    end
    XMVCA.XFSM:SetFSMAutoUpdateFlag(self.XFsm, true)
end

function XUiRhythmGameTaikoPlay:OnEnable()
end

function XUiRhythmGameTaikoPlay:FinishGame()
    if self.XFsm then
        XMVCA.XFSM:SetAutoFSMStop(self.XFsm)
    end

    -- 分数计算
    local scoreData = {}
    local missCount = 0
    local goodCount = 0
    local perfectCount = 0
    local ScoreEnum = XEnumConst.RhythmGameTaiko.HitPoint.Score
    for k, xNote in pairs(self.FinishXNoteList) do
        if xNote.Score == ScoreEnum.Perfect then
            perfectCount = perfectCount + 1
        elseif xNote.Score == ScoreEnum.Good then
            goodCount = goodCount + 1
        elseif xNote.Score == ScoreEnum.Miss then
            missCount = missCount + 1
        end
    end
    local acc = 100 * (perfectCount * ScoreEnum.Perfect + goodCount * ScoreEnum.Good) / (#self.FinishXNoteList * ScoreEnum.Perfect)
    local enumAccRank = XEnumConst.RhythmGameTaiko.HitPoint.Rank
    local rankString = nil
    if acc < enumAccRank.B then
        rankString = "C"
    elseif acc < enumAccRank.A then
        rankString = "B"
    elseif acc < enumAccRank.S then
        rankString = "A"
    else
        rankString = "S"
    end
    scoreData.rankString = rankString
    scoreData.acc = acc
    scoreData.perfectCount = perfectCount
    scoreData.goodCount = goodCount
    scoreData.missCount = missCount
    scoreData.maxCombo = self.HistoryMaxCombo
    scoreData.point = perfectCount * ScoreEnum.Perfect + goodCount * ScoreEnum.Good
    -- 
    
    -- 打开结算界面
    if self.IsShowSettle then
        XLuaUiManager.PopThenOpen("UiRhythmGameTaikoSettlement", self.MapId, scoreData)
    else
        self:Close()
    end

    if self.FinishCb then
        self.FinishCb(self.MapId, scoreData)
    end
end

function XUiRhythmGameTaikoPlay:ShowReady()
    local isNeedReady = self.MapConfig["NeedReady"] and self.MapConfig["NeedReady"].Value == "1"
    if isNeedReady then
        self.ImgProgressBar.fillAmount = 0
        self.ProgressEffect.gameObject:SetActiveEx(false)
        self.PanelReady.gameObject:SetActiveEx(true)
        CS.XInputManager.InputMapper:SetInputMapSectionIdActiveState(1, true)
    else
        self:DoPlayGame()
    end
end

function XUiRhythmGameTaikoPlay:DoPlayGame()
    self.PanelReady.gameObject:SetActiveEx(false)
    self.IsPause = false
    CS.XInputManager.InputMapper:SetInputMapSectionIdActiveState(2, true)

    -- 提前同步加载cueSheet 防止io延时
    local cueId = tonumber(self.MapConfig["CueId"].Value)
    if XTool.IsNumberValid(cueId) then
       CS.XAudioManager.AddCueSheetByCueIdSync(cueId)
    end

    -- 初始化相关实例数据结构
    -- 启动状态机
    -- 在轨道中运动的Note队列
    if not self.ActiveXNoteQuene then
        self.ActiveXNoteQuene = XQueue.New(#self.NotesInfo)
        self.ActiveXNoteQuene:SetErgodicFun(function (xNote, i)
            self:MoveNote(xNote, i)
        end)
    end
    self.ActiveXNoteQuene:Clear()
   
    -- 计分note辅助队列，发射后入队，得分后出队，和ActiveXNoteQuene的区别是出队时机不同
    if not self.AuxiliaryScoringQueue then
        self.AuxiliaryScoringQueue = XQueue.New(#self.NotesInfo)
    end
    self.AuxiliaryScoringQueue:Clear()

    self.FinishXNoteList = {}
    self.AllXNotesQueue:Ergodic(function (item, i)
        self.FinishXNoteList[i] = false -- 提前分配内存，避免gc
    end)

    -- 初始化相关时间参数
    self.StartTimeStamp = CS.XTimerManager.GetRealTime() * 1000
    self.PauseOffsetMs = 0 -- 由于暂停带来的按钮延迟，需要减去这个时间
    self.TotalPauseElapsedTime = 0
    self.CurTransmitCount = 0
    self.FinishAllNotesTimeStamp = nil -- 所有Note结算回收完毕的时间戳，标志note结束
    self.FinishMusicTimeStamp = nil -- 音乐播放完毕的时间戳，标志音乐结束
    self.CurTrackElapsedTimeMs = 0
    self.CurSongElapsedTimeMs = 0
    self.PlayingFixOffsetMs = 0 -- 播放时间修正偏移量，用于修正暂停后或音乐出来接轨时的时间偏移
    self.LastSongTimeStamp = 0 -- 上一次的song时间戳，用于计算时间差

    -- 初始化Combo
    self.Combo = 0
    self.HistoryMaxCombo = 0
    self.TxtCombo.text = self.Combo
    self.ComboBg.gameObject:SetActiveEx(false)

    self.SliderMode = false --开启滑条模式必须要等待滑条tail结束
    self.CurMusicInfo = nil
    XLuaAudioManager.StopCurrentBGM()

    -- 启动！
    XMVCA.XFSM:SetAutoFSMPlay(self.XFsm, true)
end

function XUiRhythmGameTaikoPlay:UpdateProgressEffect()
    if self.ImgProgressBar and self.ProgressEffect then
        self.ProgressEffect.gameObject:SetActiveEx(true)
        -- 获取进度条的宽度
        local width = self.ProgressWidth
        
        -- 计算填充前端的位置
        local fillAmount = self.ImgProgressBar.fillAmount
        local fillPositionX = width * fillAmount  -- 计算填充前端的X位置

        -- 更新特效GameObject的位置
        self.TempV2.x = fillPositionX
        self.TempV2.y = self.ProgressEffect.anchoredPosition.y
        self.ProgressEffect.anchoredPosition = self.TempV2
    end
end

function XUiRhythmGameTaikoPlay:PlayingUpdateCallByFSM()
    -- 光标特效
    local touchCount = CS.UnityEngine.Input.touchCount
    if CS.UnityEngine.Input:GetMouseButtonDown(0) or (touchCount >= 1 and CS.UnityEngine.Input:GetTouch(0)) then
        self.CursorEffect.localPosition = XUiHelper.GetScreenClickPosition(self.Transform, self.Camera)
        XUiHelper.PlayAllChildParticleSystem(self.CursorEffectPsRoot, 3)
    end

    -- 时间系统
    local nowTime = CS.XTimerManager.GetRealTime() * 1000
    local elapsedTime = nil  -- 从歌曲开始到现在经过的时间，整个音游的时间都和这个相关
    -- 音乐还没播时用自定义时间
    -- if self.CurMusicInfo and self.CurMusicInfo.Done and self.CurMusicInfo.Pausing ~= true and self.CurMusicInfo.CriAtomExPlayback.timeSyncedWithAudio > 0 then
    if false then -- 暂时弃用Criware时间，用自定义时间
        -- 游玩中
        elapsedTime = self.CurMusicInfo.CriAtomExPlayback.timeSyncedWithAudio + self.CountDownTimeMs + self.PlayingFixOffsetMs
    else
        -- 前/后置倒计时中
        elapsedTime = nowTime - self.StartTimeStamp - self.TotalPauseElapsedTime + self.PlayingFixOffsetMs
    end
    if self.CurMusicInfo and self.CurMusicInfo.CriAtomExPlayback then
        self.LastSongTimeStamp = self.CurMusicInfo.CriAtomExPlayback.timeSyncedWithAudio
    else
        self.LastSongTimeStamp = 0
    end
    self.CurTrackElapsedTimeMs = elapsedTime -- 经过时间（包含倒计时 + 当前的歌曲时间）

    -- 进度条
    local progress = (elapsedTime - self.FirstNoteTransmitTimeStamp) / (self.LastNoteJugTimeStamp - self.FirstNoteTransmitTimeStamp) -- 进度条是从第一个note的发射时间到最后一个note的判定时间
    if self.FinishAllNotesTimeStamp and progress < 0.1 then -- 如果歌曲结束了肯定是1(防止播放器跳变，播放器结束后会立马把播放器的time切为0)
        progress = 1
    end
    self.ImgProgressBar.fillAmount = progress
    self:UpdateProgressEffect(progress)

    -- 播放背景音乐(每次开始只播放一次)
    if elapsedTime > self.CountDownTimeMs and self.AllXNotesQueue:Count() ~= 0 and not self.CurMusicInfo then
        local cueId = tonumber(self.MapConfig["CueId"].Value)
        if XTool.IsNumberValid(cueId) then
            local finCb = function ()
                if self.AllXNotesQueue:Count() ~= 0 then
                    return
                end
                self.CurMusicInfo = nil
                self.FinishMusicTimeStamp = elapsedTime
            end
            self.CurMusicInfo = CS.XAudioManager.PlayRhythmGameMusicWithSyncedTimerExPlayer(cueId, finCb)
        end
    end

    -- 结算
    if self.FinishAllNotesTimeStamp and elapsedTime > (self.FinishAllNotesTimeStamp + 0.5 * self.CountDownTimeMs) then
        self:FinishGame()
        return
    end

    self.ActiveXNoteQuene:Ergodic()

    ---@type XRhythmGameNote
    local nextXNote = self.AllXNotesQueue:Peek()
    if not nextXNote then
        return
    end
    
    if nextXNote.TransmitTimeStamp <= elapsedTime then
        self:TransmitNote()
    end

    -- 卡顿延迟修复
    if self.LastSongTimeStamp > 0 then
        local aTime = nowTime - self.StartTimeStamp - self.TotalPauseElapsedTime + self.PlayingFixOffsetMs
        local bTime = self.CountDownTimeMs + self.LastSongTimeStamp
        local criOffset = math.abs(aTime - bTime)
        if criOffset > self.AudioCalibrationOffsetMs + 20 then
            self:CheckToFixPlayingOffset()
        end
    end
end

-- 移动Note
function XUiRhythmGameTaikoPlay:MoveNote(xNote, i)
    local targetX = nil
    local speedMs = nil
    if xNote.Type == XEnumConst.RhythmGameTaiko.NoteType.SliderHead then
        targetX = self.JudgmentAreaAnchoredPosX - xNote.Width
        speedMs = xNote.NewSpeedMs
    else
        targetX = self.JudgmentAreaAnchoredPosX
        speedMs = self.SpeedMs
    end
    local realTargetX = targetX - self.ExtraMoveX
    
    local xNoteAnchoredPosX = xNote.TempAnchoredPos.x
    local isArrive = xNoteAnchoredPosX <= realTargetX
    if not isArrive then
        local transmitElapsedTime = self.CurTrackElapsedTimeMs - xNote.TransmitTimeStamp
        local totalTime = self.SpeedMs + ((self.ExtraMoveX * self.SpeedMs)/(self.TransmitPosAnchoredPosX - targetX))
        local x = MathLerp(self.TransmitPosAnchoredPosX, realTargetX, (transmitElapsedTime) / (totalTime))
        xNote.TempAnchoredPos.x = x
        xNote.RectTransform.anchoredPosition = xNote.TempAnchoredPos
    else
    end
    
    -- 超过最差得分的判断时间后进行miss判定
    if self.CurTrackElapsedTimeMs > xNote.JudgmentTimeStamp + (XEnumConst.RhythmGameTaiko.HitPoint.JudgmentTimeMs.Bad) then
        self:DoJudgmentNote(nil, true, xNote)
    end

    -- 超过更长时间进行实体回收
    if self.CurTrackElapsedTimeMs > xNote.JudgmentTimeStamp + (XEnumConst.RhythmGameTaiko.HitPoint.JudgmentTimeMs.Bad * 5) then
        self.ActiveXNoteQuene:Dequeue()
        -- 提前缓存并返回对象到池中
        local item = xNote.TempItem
        local xPool = self.NoteTypePoolDic[xNote.Type]
        xPool:ReturnItemToPool(item)

        -- 每次回收后，都检查是否所有Note已经打完，开始进行结算
        if self.ActiveXNoteQuene:Count() == 0 and self.AllXNotesQueue:Count() == 0 then
            self.FinishAllNotesTimeStamp = self.CurTrackElapsedTimeMs
        end
    end
end

-- 判定Note
function XUiRhythmGameTaikoPlay:DoJudgmentNote(clickBtnType, isMiss, xNote)
    ---@type XRhythmGameNote
    local curXNote = xNote or self.AuxiliaryScoringQueue:Peek()
    if not curXNote then 
        return 
    end

    -- 判定是否已经判定过
    if self.FinishXNoteList[curXNote.Index] then
        return
    end
    
    local score
    -- 处理得分逻辑
    if curXNote.Type == clickBtnType then
        local deltaTime = self.CurTrackElapsedTimeMs - curXNote.JudgmentTimeStamp
        local absDeltaTime = math.abs(deltaTime)
        
        if absDeltaTime <= XEnumConst.RhythmGameTaiko.HitPoint.JudgmentTimeMs.Perfect then
            score = XEnumConst.RhythmGameTaiko.HitPoint.Score.Perfect
        elseif absDeltaTime <= XEnumConst.RhythmGameTaiko.HitPoint.JudgmentTimeMs.Good then
            score = XEnumConst.RhythmGameTaiko.HitPoint.Score.Good
        end

        -- 击打误差指示器
        self:UpdateHitErrorIndicator(deltaTime, absDeltaTime)

    elseif isMiss then
        score = curXNote.Type == XEnumConst.RhythmGameTaiko.NoteType.SliderTail 
                and XEnumConst.RhythmGameTaiko.HitPoint.Score.Good 
                or XEnumConst.RhythmGameTaiko.HitPoint.Score.Miss
        if score == XEnumConst.RhythmGameTaiko.HitPoint.Score.Good then
            self.SliderMode = false
        end
    end

    -- 更新分数和Combo
    if score then
        self:ShowHitScore(score)

        local isMiss = score == XEnumConst.RhythmGameTaiko.HitPoint.Score.Miss
        self.Combo = (isMiss) and 0 or (self.Combo + 1)
        self.TxtCombo.text = self.Combo
        self.ComboBg.gameObject:SetActiveEx(self.Combo > 0)
        self.HistoryMaxCombo = math.max(self.HistoryMaxCombo, self.Combo)
        if self.Combo > 0 then
            self.AnimStaticComboText.transform:PlayTimelineAnimation()
        end

        curXNote.Score = score
        curXNote.HitTimeStamp = self.CurTrackElapsedTimeMs

        -- 被击中直接隐藏
        if not isMiss then
            curXNote.TempItem.AnimNoteDisable:Play()
        end

        self.FinishXNoteList[curXNote.Index] = curXNote
        self.AuxiliaryScoringQueue:Dequeue()
    end
end

-- 弹出击打得分
function XUiRhythmGameTaikoPlay:ShowHitScore(score)
    local scoreObjName = self.ScoreTransformDic[score]
    local scoreObj = self[scoreObjName]
    if scoreObj then
        scoreObj.transform:PlayTimelineAnimation()
    end

    -- 特效
    local effectXPool = self.HitEffectTypePoolDic[score]
    if effectXPool then
        local effectObj = effectXPool:GetItemFromPool()
        effectObj.gameObject:SetActiveEx(true)
        XScheduleManager.ScheduleOnce(function ()
            if XTool.UObjIsNil(effectObj) then
                return
            end
            effectXPool:ReturnItemToPool(effectObj)
        end, XScheduleManager.SECOND)
    end
end

-- 更新击打误差指示器
function XUiRhythmGameTaikoPlay:UpdateHitErrorIndicator(deltaTime, absDeltaTime)
    if not self.IsDebug then
        return
    end

    if absDeltaTime <= XEnumConst.RhythmGameTaiko.HitPoint.JudgmentTimeMs.Bad * 2 then
        self.HitErrorText.text = string.format("%.2f", deltaTime)
        local color

        if absDeltaTime <= 15 then
            color = XUiHelper.Hexcolor2Color("7BFAF8")
        elseif absDeltaTime <= 30 then
            color = XUiHelper.Hexcolor2Color("84FB7A")
        elseif absDeltaTime <= 50 then
            color = XUiHelper.Hexcolor2Color("7BFAA9")
        elseif absDeltaTime <= 70 then
            color = XUiHelper.Hexcolor2Color("F7FA7B")
        elseif absDeltaTime <= 100 then
            color = XUiHelper.Hexcolor2Color("F1C063")
        else
            color = XUiHelper.Hexcolor2Color("F16964")
        end

        self.HitErrorText.color = color
    end
end

-- 发射Note
function XUiRhythmGameTaikoPlay:TransmitNote()
    ---@type XRhythmGameNote
    local nextXNote = self.AllXNotesQueue:Dequeue()
    self.CurTransmitCount = nextXNote.Index
    local xPool = self.NoteTypePoolDic[nextXNote.Type]
    local item = xPool:GetItemFromPool()
    local noteTransform = item.Transform
    noteTransform:SetAsLastSibling()
    nextXNote.TempItem = item
    nextXNote.Transform = noteTransform
    nextXNote.RectTransform = item.RectTransform

    if nextXNote.Type == XEnumConst.RhythmGameTaiko.NoteType.SliderHead then
        local rt = nextXNote.RectTransform
        local curSliderTailXNote = self.AllXNotesQueue:Peek()
        if curSliderTailXNote.Type ~= XEnumConst.RhythmGameTaiko.NoteType.SliderTail then
            XLog.Error("SliderHead后面不是SliderTail")
        end
        -- 修改宽度，保持高度不变
        local sliderExsitElapsedTime = curSliderTailXNote.TransmitTimeStamp - nextXNote.TransmitTimeStamp
        local moveDis = self.TransmitPosAnchoredPosX - self.JudgmentAreaAnchoredPosX
        local width = moveDis * sliderExsitElapsedTime / self.SpeedMs
        self.TempV2.x = width
        self.TempV2.y = rt.sizeDelta.y
        rt.sizeDelta = self.TempV2
        nextXNote.Width = width

        -- 保证滑条头到达终点后整个滑条继续往前冲
        -- 新的速度计算
        local targetX = self.JudgmentAreaAnchoredPosX - nextXNote.RectTransform.rect.width
        local remainingDistance = targetX - self.TransmitPosAnchoredPosX
        local newSpeedMs = (self.SpeedMs * remainingDistance) / (self.JudgmentAreaAnchoredPosX - self.TransmitPosAnchoredPosX)
        nextXNote.NewSpeedMs = newSpeedMs

        self.SliderMode = true
    elseif nextXNote.Type == XEnumConst.RhythmGameTaiko.NoteType.SliderTail then
        local rt = nextXNote.RectTransform
        self.TempV2.x = 1
        self.TempV2.y = rt.sizeDelta.y
        rt.sizeDelta = self.TempV2
    end

    nextXNote.RectTransform.anchoredPosition = self.TransmitPosAnchoredPos
    nextXNote.TempAnchoredPos.x = self.TransmitPosAnchoredPos.x
    noteTransform.name = nextXNote.Index
    noteTransform.gameObject:SetActiveEx(true)
    item.AnimNoteEnable:Play()

    self.ActiveXNoteQuene:Enqueue(nextXNote)
    self.AuxiliaryScoringQueue:Enqueue(nextXNote)
end

function XUiRhythmGameTaikoPlay:EventAnimShowOrHide(flag)
    local animShowEnable = self.SkinGo.transform:FindTransform("ShowEnable")
    local animShowDisable = self.SkinGo.transform:FindTransform("ShowDisable")
    if not animShowEnable or not animShowDisable then return end

    if flag then
        animShowEnable:PlayTimelineAnimation()
    else
        animShowDisable:PlayTimelineAnimation()
    end
end

function XUiRhythmGameTaikoPlay:OnDestroy()
    if self.XFsm then
        XMVCA.XFSM:ReleaseFSM(self.XFsm)
    end

    if self.CurMusicInfo and self.CurMusicInfo.Playing then
        self.CurMusicInfo:Stop()
    end

    XDataCenter.InputManagerPc.ResumeCurInputMap() -- 恢复上一套按键方案
    CS.XInputManager.InputMapper:SetIsOpenInputMapSectionCheck(false)
    CS.XGameEventManager.Instance:RemoveEvent(XEventId.EVENT_ON_FIGHT_EXIT, self.FightClose)
    XEventManager.RemoveEventListener(XEventId.EVENT_RHYTHM_TAIKO_ANIMSHOW, self.EventAnimShowOrHide, self)
end

return XUiRhythmGameTaikoPlay