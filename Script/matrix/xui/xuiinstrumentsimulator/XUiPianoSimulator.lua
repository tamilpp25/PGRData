---@field _Control XInstrumentSimulatorControl
---@class XUiPianoSimulator : XLuaUi
local XUiPianoSimulator = XLuaUiManager.Register(XLuaUi, "UiPianoSimulator")

function XUiPianoSimulator:OnAwake()
    self.InstrumentFurnitureId = XEnumConst.InstrumentSimulator.InstrumentFurnitureId.Piano
    self.BtnPianoKeyDic = {}
    self.BtnPsDic = {} -- 存放特效
    self.PianoKeyAudioInfoSyncAuxiliaryCheckDic = {} -- 检测按键转发用的辅助字典，按下后设置值，转发后清空，可以作为当前时间内是否有按键按下的依据(每50ms更新一次)
    self:InitButton()
    XDataCenter.InputManagerPc.SetCurInputMap(CS.XInputMapId.ActivityGame)
end

function XUiPianoSimulator:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.ToggleSceneMusic, self.OnToggleSceneMusicClick)
    XUiHelper.RegisterClickEvent(self, self.ToggleInstrumentMusic, self.OnToggleInstrumentMusicClick)

    local keyCount = self.KeysParent.transform.childCount
    self.AllKeyMapConfigs = {}
    for index = 1, keyCount, 1 do
        local config = XMVCA.XInstrumentSimulator:GetModelInstrumentKeyMapConfigByFurnitureIdAndIndex(self.InstrumentFurnitureId, index)
        self.AllKeyMapConfigs[index] = config
        local btnParent = self.PanelPiano:FindTransform("Key" .. index)
        local btnTrans = index == 1 and self.BtnKey or XUiHelper.Instantiate(self.BtnKey)
        btnTrans.transform:SetParent(btnParent)
        btnTrans.transform:Reset()
        local xBtn = btnTrans:GetComponent(typeof(CS.XUiComponent.XUiButton))
        xBtn:SetRawImage(config.Icon)
        XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(config.KeyCode, function ()
            self:OnPianoClick(index)
            xBtn:SetButtonState(CS.UiButtonState.Press)
        end)
        XDataCenter.InputManagerPc.RegisterActivityGameKeyUpFunc(config.KeyCode, function ()
            xBtn:SetButtonState(CS.UiButtonState.Normal) -- pc Key也要能触发button press效果
            self:OnKeyPressUpCb(xBtn)
        end)
        xBtn.CallBack = function()
            self:OnPianoClick(index)
        end
        local uguiEvenlsn = btnTrans:GetComponent(typeof(CS.XUguiEventListener))
        uguiEvenlsn.OnUp = function ()
            self:OnKeyPressUpCb(xBtn)
        end
        if XDataCenter.UiPcManager.IsPc() then
            local XUiPcCustomKey = btnTrans:GetComponent(typeof(CS.XUiPc.XUiPcCustomKey))
            XUiPcCustomKey:SetKey(CS.XInputMapId.ActivityGame, CS.XInputMapId.ActivityGame, config.KeyCode, CS.XInputManager.XOperationType.ActivityGame)
            XUiPcCustomKey:Refresh()
        end
        self.BtnPianoKeyDic[index] = xBtn
    end
    self.BtnKey.transform:Reset()

    -- esc注册
    XDataCenter.InputManagerPc.RegisterActivityGameKeyDownFunc(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.ExitGame, function ()
        XDataCenter.UiPcManager.OnUiDisable()
    end)
end

function XUiPianoSimulator:OnKeyPressUpCb(xBtn)
    local allPs = self.BtnPsDic[xBtn:GetInstanceID()]
    if not allPs then
        local psTrans = xBtn.TagObj
        allPs = psTrans:GetComponentsInChildren(typeof(CS.UnityEngine.ParticleSystem), true)
        self.BtnPsDic[xBtn:GetInstanceID()] = allPs
    end

    for i = 0, allPs.Length - 1, 1 do
        local ps = allPs[i]
        ps:Play()
    end
end

function XUiPianoSimulator:OnBtnBackClick()
    XEventManager.DispatchEvent(XEventId.EVENT_INSTRUMENT_SIMULATOR_DO_CLICK_BTNBACK, self.InstrumentFurnitureId)
    self:Close()
end

function XUiPianoSimulator:OnPianoClick(index)
    local config = self.AllKeyMapConfigs[index]
    local finCb = function()
        local count = XTool.GetTableCount(self.PianoKeyAudioInfoSyncAuxiliaryCheckDic)
        if count > 0 then
            return
        end
        XMVCA.XInstrumentSimulator:SetInstrumentPlayingState(self.InstrumentFurnitureId, false)
    end
    local info = XMVCA.XInstrumentSimulator:PlayInstrumentKeyAudio(config.CueId, finCb)
    XMVCA.XInstrumentSimulator:SetInstrumentPlayingState(self.InstrumentFurnitureId, true)
    self.PianoKeyAudioInfoSyncAuxiliaryCheckDic[index] = info
end

function XUiPianoSimulator:OnToggleSceneMusicClick()
    XDataCenter.GuildDormManager.SetGuildSceneCDMusicMute(not self.ToggleSceneMusic.isOn)
end

function XUiPianoSimulator:OnToggleInstrumentMusicClick()
    XMVCA.XInstrumentSimulator:MuteInstrumentSimulator(not self.ToggleInstrumentMusic.isOn)
end

function XUiPianoSimulator:OnStart()
    -- 刷新Toggle状态
    self.ToggleSceneMusic.isOn = XDataCenter.GuildDormManager.GetToggleSceneMusicCache()
    self.ToggleInstrumentMusic.isOn = XDataCenter.GuildDormManager.GetToggleInstrumentMusicCache()
    -- 根据toggle状态屏蔽声音
    self:OnToggleSceneMusicClick()
    self:OnToggleInstrumentMusicClick()

    self.CheckTimeId = XScheduleManager.ScheduleForever(function()
        self:CheckPianoKeyPressToSync()
    end, 50, 0)
end

function XUiPianoSimulator:CheckPianoKeyPressToSync()
    local resIntNote = 0
    for i, info in pairs(self.PianoKeyAudioInfoSyncAuxiliaryCheckDic) do
        local isPress = info.Playing
        if isPress then
            resIntNote = resIntNote | (1 << (i - 1))
            self.PianoKeyAudioInfoSyncAuxiliaryCheckDic[i] = nil
        end
    end

    if XDataCenter.GuildDormManager.GetIsRunning() then
        XDataCenter.GuildDormManager.GuildDormPlayNoteRequest(resIntNote)
    end
end

function XUiPianoSimulator:OnDestroy()
    XDataCenter.InputManagerPc.ResumeCurInputMap()
    for index, config in pairs(self.AllKeyMapConfigs) do
        XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(config.KeyCode)
        XDataCenter.InputManagerPc.UnregisterActivityGameKeyUp(config.KeyCode)
    end
    XDataCenter.InputManagerPc.UnregisterActivityGameKeyDown(XEnumConst.GOLDEN_MINER.GAME_PC_KEY.ExitGame)

    XDataCenter.GuildDormManager.SaveToggleSceneMusicCache(self.ToggleSceneMusic.isOn and 1 or 0)
    XDataCenter.GuildDormManager.SaveToggleInstrumentMusicCache(self.ToggleInstrumentMusic.isOn and 1 or 0)

    if self.CheckTimeId then
        XScheduleManager.UnSchedule(self.CheckTimeId)
        self.CheckTimeId = nil
    end

    XMVCA.XInstrumentSimulator:SetInstrumentPlayingState(self.InstrumentFurnitureId, false)
end

function XUiPianoSimulator:OnEnable()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_UI_SETTING, false)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_UI_SETTING_RIGHT, false)
end

function XUiPianoSimulator:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_UI_SETTING, true)
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_UI_SETTING_RIGHT, true)
end

return XUiPianoSimulator