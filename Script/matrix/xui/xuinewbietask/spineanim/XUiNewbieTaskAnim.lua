local XUiNewbieTaskAnim = XClass(nil, "XUiNewbieTaskAnim")
local XNewbieTaskAnimPlayer = require("XEntity/XNewbieTask/XNewbieTaskAnimPlayer")
local XUiMultClickHelper = require("XUi/XUiCommon/XUiMultClickHelper")

local NewbieTaskAnimClickInterval = XUiHelper.GetClientConfig("NewbieTaskAnimClickInterval", XUiHelper.ClientConfigType.Float)
local NewbieTaskAnimMultClickCountLimit = XUiHelper.GetClientConfig("NewbieTaskAnimMultClickCountLimit", XUiHelper.ClientConfigType.Int)
local NewbieTaskAnimDelayInterval = XUiHelper.GetClientConfig("NewbieTaskAnimDelayInterval", XUiHelper.ClientConfigType.Float)

function XUiNewbieTaskAnim:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
    self.PanelLayout.gameObject:SetActiveEx(false)
    
    -- 播放器
    ---@type XNewbieTaskAnimPlayer
    self.AnimPlayer = XNewbieTaskAnimPlayer.New(self, 0, NewbieTaskAnimDelayInterval)
    local playerData = XDataCenter.NewbieTaskManager.GetNewbieTaskAnimPlayerData()
    self.AnimPlayer:SetPlayerData(playerData)

    self.MultClickHelper = XUiMultClickHelper.New(self, NewbieTaskAnimClickInterval, NewbieTaskAnimMultClickCountLimit)

    -- 播放队列只播放优先级最高的动画
    self:SetPlayOne(true)
    
    self:InitIdleTab()
end

function XUiNewbieTaskAnim:LoadSpine()
    local panelSpine = self.RootUi.PanelSpine
    local spinePath = XUiHelper.GetClientConfig("UiNewbieTaskSailika01", XUiHelper.ClientConfigType.String)
    self.Animator = panelSpine:LoadSpinePrefab(spinePath).transform:GetComponent("Animator")
end

function XUiNewbieTaskAnim:InitIdleTab()
    self.IdleTabs = XNewbieTaskConfigs.GetAnimConfigByConditionId(XNewbieEventType.IDLE)
end

function XUiNewbieTaskAnim:OnEnable()
    self:LoadSpine()
    self:StartTimer()

    if self.AnimPlayer then
        self.AnimPlayer:OnEnable()
    end

    if self.MultClickHelper then
        self.MultClickHelper:OnEnable()
    end

    local playList = XDataCenter.NewbieTaskManager.GetPlayElements()
    if not playList then
        return
    end
    
    self.AnimPlayer:SetPlayList(playList)
    
    self.Enable = true
end

function XUiNewbieTaskAnim:OnDisable()
    self:StopTimer()

    if self.AnimPlayer then
        self.AnimPlayer:OnDisable()
    end

    if self.MultClickHelper then
        self.MultClickHelper:OnDisable()
    end

    self:SoundStop()
    
    self.Enable = false
end

function XUiNewbieTaskAnim:OnDestroy()
    self:StopTimer()

    if self.AnimPlayer then
        self.AnimPlayer:OnDestroy()
    end

    if self.MultClickHelper then
        self.MultClickHelper:OnDestroy()
    end
    -- 重置播放数据
    XDataCenter.NewbieTaskManager.ResetPlayerData()
    self.Enable = false
end

function XUiNewbieTaskAnim:Update()
    if not self.Enable then
        return
    end
    
    local dt = CS.UnityEngine.Time.deltaTime

    if self.AnimPlayer then
        self.AnimPlayer:Update(dt)
    end

    if self.MultClickHelper then
        self.MultClickHelper:Update(dt)
    end

    -- 当有多个Idle时，取第一Idle做判断
    if self.IdleTabs and self.IdleTabs[1] then
        local idle = self.IdleTabs[1]
        if self.AnimPlayer and self.AnimPlayer:CheckIsPlayIdle(idle.ConditionParam) then
            -- 根据权重随机取一个Idle
            local config = XDataCenter.NewbieTaskManager.WeightRandomSelect(self.IdleTabs)
            if self.AnimPlayer:Play(config) then
                self.AnimPlayer.LastPlayTime = -1
            end
        end
    end
end

-- 播放
function XUiNewbieTaskAnim:Play(element)
    if not element then
        return
    end
    
    self:ShowContent(element.Config.CvContent)

    if element.Config.CvId and element.Config.CvId > 0 then
        self:PlaySound(element.Config.CvId)
    end
    
    local actionId = element.Config.ActionId
    if actionId then
        self:PlayAnimation(actionId)
    end
    
    local effectPath = element.Config.EffectPath
    if effectPath then
        self:PlayEffect(effectPath)
    end
end

-- 播放动画
function XUiNewbieTaskAnim:PlayAnimation(actionId)
    if not XTool.UObjIsNil(self.Animator) then
        self.Animator:SetTrigger(actionId)
    end
end

-- 播放音频
function XUiNewbieTaskAnim:PlaySound(cvId)
    self:SoundStop()
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cvId)
end

-- 显示对白
function XUiNewbieTaskAnim:ShowContent(content)
    self.PanelLayout.gameObject:SetActiveEx(content ~= nil)
    self.CvContent.text = XUiHelper.ConvertLineBreakSymbol(content)
end

-- 播放特效
function XUiNewbieTaskAnim:PlayEffect(effectPath)
    local panelSpine = self.RootUi.PanelSpine
    self.EffectGo = panelSpine.gameObject:LoadPrefab(effectPath)
end

function XUiNewbieTaskAnim:OnStop()
    self:SoundStop()
    -- 隐藏对白
    self.PanelLayout.gameObject:SetActiveEx(false)
    -- 销毁特效
    if self.EffectGo then
        CS.UnityEngine.GameObject.Destroy(self.EffectGo)
    end
end

function XUiNewbieTaskAnim:SoundStop()
    if self.AudioInfo then
        self.AudioInfo:Stop()
        self.AudioInfo = nil
    end
end

function XUiNewbieTaskAnim:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end,0)
end

function XUiNewbieTaskAnim:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiNewbieTaskAnim:SetPlayOne(bPlayOne)
    self.AnimPlayer:SetPlayOne(bPlayOne)
end

-- 点击
function XUiNewbieTaskAnim:OnBtnClick()
    if self.MultClickHelper then
        self.MultClickHelper:Click()
    end
end

-- 点击回调
function XUiNewbieTaskAnim:OnMultClick(clickTimes)
    local config
    if self.AnimPlayer:IsPlaying() then
        return
    end
    
    config = XDataCenter.NewbieTaskManager.GetPlayElementsByClick(clickTimes)
    self.AnimPlayer:Play(config)
end

-- 主动触发的动画(该方法适用于一个conditionId只有一个动画)
function XUiNewbieTaskAnim:ActiveTriggerAnimation(conditionId)
    local configs
    if self.AnimPlayer:IsPlaying() then
        return
    end
    
    configs = XNewbieTaskConfigs.GetAnimConfigByConditionId(conditionId)
    if XTool.IsTableEmpty(configs) then
        return
    end
    self.AnimPlayer:Play(configs[1])
end

return XUiNewbieTaskAnim