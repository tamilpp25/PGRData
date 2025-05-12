-- V3.2节奏音游QTE界面
-- 这个UI只用一次，再次启用请小心谨慎，有很多特殊不符合常理的逻辑。 
---@field _Control XRhythmGameControl
---@class XUiFightRhythmQteV3P2 : XLuaUi
local XUiFightRhythmQteV3P2 = XLuaUiManager.Register(XLuaUi, "UiFightRhythmQteV3P2")

local CSXInputManager = CS.XInputManager

local PC_OPERATION_KEY = {
    Left = 100004,
    Middle = 100003,
    Right = 100005
}

local XRhythmmQteState = { --本地持久化Key(持久化数据跟着活动ID走 更换活动ID时 清空数据)
    Stop = 1,
    Run = 2,
    Loading = 3
}
--初始化数据和其他东西
function XUiFightRhythmQteV3P2:OnAwake()
    --数据初始化
    self.TemplateName = ""
    self.State = XRhythmmQteState.Stop;
    self.ResetDelta = 0.1; --多少差异时 表现层同步播放进度 
    
    self.JudgeDelay = 1.5; --出生到判定区间末尾所需时间
    self.JudgeZone = 0.5; --判定区间长度(左区间值
    self.JudgeZoneDelay = 0.5; --判定区间长度(右区间值
    
    self.CurrentProgress = 0; --当前播放进度
    self.Duration = 0; --当前歌曲总长度
    self.AudioInfo = nil; --音频数据
    self.RhythmConfig = nil; --节奏游戏配置
    self.GetNoteData = nil; --获取节点数据
    self.PanelCombo.gameObject:SetActive(false); --隐藏Combo面板

    --三条轨道数据
    -- 即将判定节点Index
    self.CurNote = {
        1,
        1,
        1,
    }
    -- 即将出生节点Index
    self.CurBornNode = {
        1,
        1,
        1,
    }
    -- 判定轨道时间
    self.ListTrackJudge = {
        {},
        {},
        {},
    }
    -- 出生轨道时间
    self.ListTrackBron = {
        {},
        {},
        {},
    }
    -- 每条轨道事件
    self.BtnTrackEvent= {
        0,
        0,
        0,
    }

    self.UiObjectLeft = {}
    self.UiObjectMiddle = {}
    self.UiObjectRight = {}
    
    XTool.InitUiObjectByInstance(self.BtnLeft, self.UiObjectLeft)
    XTool.InitUiObjectByInstance(self.BtnMiddle, self.UiObjectMiddle)
    XTool.InitUiObjectByInstance(self.BtnRight, self.UiObjectRight)

    self.UiObjectLeft.Button.ExitCheck = false
    self.UiObjectMiddle.Button.ExitCheck = false
    self.UiObjectRight.Button.ExitCheck = false

    XUiHelper.RegisterClickEvent(self, self.UiObjectLeft.Button, function() self:OnClickBtn(1) end)
    XUiHelper.RegisterClickEvent(self, self.UiObjectMiddle.Button, function() self:OnClickBtn(2) end)
    XUiHelper.RegisterClickEvent(self, self.UiObjectRight.Button, function() self:OnClickBtn(3) end)
    
    --标记该UI是显示还是隐藏
    self.ShowState = true

    if XDataCenter.UiPcManager.IsPc() then
        self:AddPCKeyListener()
    end


    --策划要求该UI默认隐藏
    self.PanelGame.gameObject:SetActiveEx(false)
end

function XUiFightRhythmQteV3P2:OnStart()
end

function XUiFightRhythmQteV3P2:OnEnable()
    --self:PlayShowAnim()
    if self.AudioInfo then
        self.AudioInfo:Resume()
    end
end

function XUiFightRhythmQteV3P2:OnDisable()
    --self:PlayHideAnim()
    if self.AudioInfo and self.AudioInfo.Playing then
        self.AudioInfo:Pause()
    end
end

function XUiFightRhythmQteV3P2:OnDestroy()
    if XDataCenter.UiPcManager.IsPc() then
        self:RemovePCKeyListener()
    end

    if self.AudioInfo and self.AudioInfo.Playing then
        self.AudioInfo:Stop()
    end
end

--region PC操作
function XUiFightRhythmQteV3P2:AddPCKeyListener()
    self.OnPcClickCb = handler(self, self.OnPcClick)
    CSXInputManager.RegisterOnClick(CS.XInputManager.XOperationType.FightRhythmQteV3P2, self.OnPcClickCb)

    self.KeyDownMap = {
        [PC_OPERATION_KEY.Left] = function(clickType)
            self:OnPcClickBtn(1, clickType)
        end,
        [PC_OPERATION_KEY.Middle] = function(clickType)
            self:OnPcClickBtn(2, clickType)
        end,
        [PC_OPERATION_KEY.Right] = function(clickType)
            self:OnPcClickBtn(3, clickType)
        end
    }
end

function XUiFightRhythmQteV3P2:OnPcClickBtn(trackIndex, clickType)
    local btn = self:GetBtn(trackIndex)
    if not btn or btn.ButtonState == CS.UiButtonState.Disable then
        return
    end

    -- 刷新按钮状态
    if clickType == CS.XOperationClickType.KeyDown then
        btn:SetButtonState(CS.UiButtonState.Press)
    else
        btn:SetButtonState(CS.UiButtonState.Normal)
        return
    end
    
    self:OnClickBtn(trackIndex)
end

function XUiFightRhythmQteV3P2:GetBtn(trackIndex)
    if trackIndex == 1 then
        return self.UiObjectLeft.Button
    elseif trackIndex == 2 then
        return self.UiObjectMiddle.Button
    elseif trackIndex == 3 then
        return self.UiObjectRight.Button
    end
end

function XUiFightRhythmQteV3P2:RemovePCKeyListener()
    CSXInputManager.UnregisterOnClick(CS.XInputManager.XOperationType.FightRhythmQteV3P2, self.OnPcClickCb)
end

function XUiFightRhythmQteV3P2:OnPcClick(inputDeviceType, operationKey, clickType, operationType)
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    local func = self.KeyDownMap[operationKey]
    if func then func(clickType) end
end
--endregion

function XUiFightRhythmQteV3P2:GameStart(MapName)
    self.State = XRhythmmQteState.Loading;
    self.RhythmConfig = self._Control:GetModelRhythmGameFallingMapConfig(MapName)
    self.TemplateName = MapName
    if(self.RhythmConfig == nil) then
        XLog.Error("不存在乐谱数据:" .. MapName)
        GameStop();
        return
    end
    local cueId = self:GetCueId()
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, cueId)
    if(self.AudioInfo == nil) then
        GameStop();
        return
    end

end

function XUiFightRhythmQteV3P2:OnMusicPlay()
    local cueId = self:GetCueId()
    self.State = XRhythmmQteState.Run;
    local audioTemplate = CS.XAudioManager.GetCueTemplate(cueId);
    self.Duration = audioTemplate.Duration / 1000
    if(self.Duration <= 0) then
        XLog.Error("音频时长不正确:" .. self.Duration .. " MapId:" .. self.TemplateName .. " CueId:" .. cueId)
        self:GameStop();
        return
    end
    self:InitNoteData()

    self.CurrentProgress = 0;
    -- 即将判定节点Index
    self.CurNote = {
        1,
        1,
        1,
    }
    -- 即将出生节点Index
    self.CurBornNode = {
        1,
        1,
        1,
    }
end

function XUiFightRhythmQteV3P2:GameStop()
    self.State = XRhythmmQteState.Stop;
    self.CurrentProgress = 0;
    self.Duration = 0;
    CS.XFight.Instance.InputControl:OnSpecialOperation(13, 64);
end

function XUiFightRhythmQteV3P2:OnClickBtn(trackIndex)
    if not self.ShowState then
        return
    end
    while (self.CurNote[trackIndex] < #self.ListTrackJudge[trackIndex] and self.CurrentProgress > self.ListTrackJudge[trackIndex][self.CurNote[trackIndex]] - self.JudgeZone) do
        self.BtnTrackEvent[trackIndex] = self.BtnTrackEvent[trackIndex] | 4;
        self.CurNote[trackIndex] = self.CurNote[trackIndex] + 1
        if trackIndex == 1 then
            self.UiObjectLeft.FxUiClick.gameObject:SetActiveEx(false)
            self.UiObjectLeft.FxUiClick.gameObject:SetActiveEx(true)
        elseif trackIndex == 2 then
            self.UiObjectMiddle.FxUiClick.gameObject:SetActiveEx(false)
            self.UiObjectMiddle.FxUiClick.gameObject:SetActiveEx(true)
        elseif trackIndex == 3 then
            self.UiObjectRight.FxUiClick.gameObject:SetActiveEx(false)
            self.UiObjectRight.FxUiClick.gameObject:SetActiveEx(true)
        end
    end
end

--检查进度是否吻合 如果不吻合 同步音频位置
function XUiFightRhythmQteV3P2:CheckSynAudio()
    if not self.AudioInfo.Playing then
        return
    end
    local delta = math.abs(self.CurrentProgress - self.AudioInfo.Time/1000);
    if (delta > self.ResetDelta) then
        XLog.Debug("XUiFightRhythmQteV3P2 错位重播")
        self.AudioInfo = CS.XAudioManager.ReplayAudioInfoByStartTime(self.AudioInfo, self.CurrentProgress)
    end
end

--获取音频ID  保证self.RhythmConfig已经初始化
function XUiFightRhythmQteV3P2:GetCueId()
    local cueId = tonumber(self.RhythmConfig["CueId"].Value)
    return cueId
end

-- 解析成的NotesInfo数据  保证self.RhythmConfig已经初始化
function XUiFightRhythmQteV3P2:InitNoteData()
    --初始化数据
    -- 判定轨道时间戳
    self.ListTrackJudge = {
        {},
        {},
        {},
    }
    -- 出生轨道时间戳
    self.ListTrackBron = {
        {},
        {},
        {},
    }
    local stamp = {}
    local tableInsert = table.insert
    for k, v in pairs(self.RhythmConfig) do
        if string.find(k, "Note") then
            local splitStrArr = string.Split(v.Value)
            local judgmentTimeStamp = tonumber(splitStrArr[1])
            local judgmentTime = (judgmentTimeStamp - judgmentTimeStamp % 50) / 1000
            local trackIndex = tonumber(splitStrArr[3])
            
            
            tableInsert(self.ListTrackJudge[trackIndex], judgmentTime)
        end
    end
    for i=1,3 do
        table.sort(self.ListTrackJudge[i], function(a, b)
            return a < b
        end)
        for index, note in ipairs(self.ListTrackJudge[i]) do
            tableInsert(self.ListTrackBron[i], note - self.JudgeDelay)
        end
    end
end

--设置按钮是否显示
function XUiFightRhythmQteV3P2:SetButtonEnable(index, enable)
    if index == 1 then
        if enable and self.UiObjectLeft.Button.ButtonState == CS.UiButtonState.Disable then
            self.UiObjectLeft.Button:SetButtonState(CS.UiButtonState.Normal)
        elseif not enable and self.UiObjectLeft.Button.ButtonState == CS.UiButtonState.Normal then
            self.UiObjectLeft.Button:SetButtonState(CS.UiButtonState.Disable)
        end
    elseif index == 2 then
        if enable and self.UiObjectMiddle.Button.ButtonState == CS.UiButtonState.Disable then
            self.UiObjectMiddle.Button:SetButtonState(CS.UiButtonState.Normal)
        elseif not enable and self.UiObjectMiddle.Button.ButtonState == CS.UiButtonState.Normal then
            self.UiObjectMiddle.Button:SetButtonState(CS.UiButtonState.Disable)
        end
    elseif index == 3 then
        if enable and self.UiObjectRight.Button.ButtonState == CS.UiButtonState.Disable then
            self.UiObjectRight.Button:SetButtonState(CS.UiButtonState.Normal)
        elseif not enable and self.UiObjectRight.Button.ButtonState == CS.UiButtonState.Normal then
            self.UiObjectRight.Button:SetButtonState(CS.UiButtonState.Disable)
        end
    end
end

--同步操作至逻辑层
function XUiFightRhythmQteV3P2:SyncSpecialOperation()
    CS.XFight.Instance.InputControl:OnSpecialOperation(13, self.BtnTrackEvent[1]);
    CS.XFight.Instance.InputControl:OnSpecialOperation(14, self.BtnTrackEvent[2]);
    CS.XFight.Instance.InputControl:OnSpecialOperation(15, self.BtnTrackEvent[3]);
    self.BtnTrackEvent[1] = 0
    self.BtnTrackEvent[2] = 0
    self.BtnTrackEvent[3] = 0
end

--逻辑层Update
function XUiFightRhythmQteV3P2:FightUpdate()
    --刷新UI动画
    if not self.Loop.state == 1 then
        if self.UIShow.state == 1 and self.UIShow.time >= self.UIShow.duration then
            self.UIShow:Stop()
            self.Loop:Play()
        end
        if self.UIHide.state == 1 and self.UIHide.time >= self.UIHide.duration then
            self.UIHide:Stop()
            self.Loop:Play()
        end
    end
    

    if(self.State == XRhythmmQteState.Loading) then
    if (self.AudioInfo.Done) then
    self:OnMusicPlay()
    end
    elseif (self.State == XRhythmmQteState.Run) then
    if (self.CurrentProgress > self.Duration) then
    --结束
    self:GameStop()
    return;
    end
    --创建新节点
    for i=1,3 do
    while (self.CurBornNode[i] < #self.ListTrackBron[i] and self.CurrentProgress >= self.ListTrackBron[i][self.CurBornNode[i]]) do
    self.BtnTrackEvent[i] = self.BtnTrackEvent[i] | 1;
    self.CurBornNode[i] = self.CurBornNode[i] + 1;
    end
    end

    --判定失败
    for i=1,3 do
    while (self.CurNote[i] < #self.ListTrackJudge[i] and self.CurrentProgress >= self.ListTrackJudge[i][self.CurNote[i]] + self.JudgeZoneDelay) do
    self.BtnTrackEvent[i] = self.BtnTrackEvent[i] | 2;
    self.CurNote[i] = self.CurNote[i] + 1;
    end
    end

    ----刷新按键状态 经探讨后不需要设置按钮状态
    --for i=1,3 do
    --    if (self.CurNote[i] < #self.ListTrackJudge[i] and self.CurrentProgress > self.ListTrackJudge[i][self.CurNote[i]] - self.JudgeZone) then
    --        self:SetButtonEnable(i, true)
    --    else
    --        self:SetButtonEnable(i, false)
    --    end
    --end

    self.CurrentProgress = self.CurrentProgress + 0.05;
    self:CheckSynAudio();
    self:SyncSpecialOperation();
    end

    
end

--region 策划调用接口
--播放渐显动画
function XUiFightRhythmQteV3P2:PlayShowAnim()
    self.Loop:Stop()
    self.UIHide:Stop()
    self.UIShow:Play()
    self.ShowState = true
    self.PanelGame.gameObject:SetActiveEx(true)
end
--播放渐隐动画
function XUiFightRhythmQteV3P2:PlayHideAnim()
    self.Loop:Stop()
    self.UIShow:Stop()
    self.UIHide:Play()
    self.ShowState = false
end
--设置UI高度
function XUiFightRhythmQteV3P2:SetUiHeight(height)
    self.PanelGame.Padding.top = -height
    self.PanelGame.Padding.bottom = height
end
--设置文字
function XUiFightRhythmQteV3P2:SetTextTitle(content)
    self.TxtTitle.text = content
end
--endregion

return XUiFightRhythmQteV3P2