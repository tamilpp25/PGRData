XUiPanelSignBoard = XClass(nil, "XUiPanelSignBoard")

XUiPanelSignBoard.SignBoardOpenType = {
    MAIN = 1,
    FAVOR = 2
}

local DEFAULT_CV_TYPE = CS.XGame.Config:GetInt("DefaultCvType")

function XUiPanelSignBoard:Ctor(ui, parent, openType)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.Parent = parent
    self.OpenType = openType

    self.ClickTrigger = true
    self.CanBreakTrigger = false

    self.OperateTrigger = true
    self.DialogTrigger = true
    self.CvTrigger = true

    self:InitAutoScript()
    self:Init()
end

function XUiPanelSignBoard:Init()
    --模型
    local clearUiChildren = self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN
    self.RoleModel = XUiPanelRoleModel.New(self.Parent.UiModel.UiModelParent, self.Parent.Name, true, false, false, nil, nil, function()
        if self.Parent.PlayChangeActionEffect then
            self.Parent:PlayChangeActionEffect()
        end
    end, clearUiChildren)

    self.DisplayCharacterId = -1
    self.AutoPlay = true
    --播放器
    self.Acceleration = self.GameObject:GetComponent(typeof(CS.XInputAcceleration))
    if not self.Acceleration then
        self.Acceleration = self.GameObject:AddComponent(typeof(CS.XInputAcceleration))
    end
    self.Acceleration.EndAction = handler(self, self.OnRoll)
    local signBoardPlayer = require("XCommon/XSignBoardPlayer").New(self, CS.XGame.ClientConfig:GetInt("SignBoardPlayInterval"), CS.XGame.ClientConfig:GetFloat("SignBoardDelayInterval"))
    local playerData = XDataCenter.SignBoardManager.GetSignBoardPlayerData()
    signBoardPlayer:SetPlayerData(playerData)
    self.SignBoardPlayer = signBoardPlayer

    local signBoardClickInterval = CS.XGame.ClientConfig:GetFloat("SignBoardClickInterval")
    local signBoardMultClickCountLimit = CS.XGame.ClientConfig:GetInt("SignBoardMultClickCountLimit")

    local multClickHelper = require("XUi/XUiCommon/XUiMultClickHelper").New(self, signBoardClickInterval, signBoardMultClickCountLimit)
    self.MultClickHelper = multClickHelper
    self.PanelLayout.gameObject:SetActiveEx(false)
    if XUiManager.IsHideFunc then
        self.BtnCommunication.gameObject:SetActiveEx(false)
    end

    -- 播放队列只播放权重最高的动画
    self:SetPlayOne(true)

    --用于驱动播放器和连点检测
    --事件
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_RESULT, handler(self, self.OnNotify))
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FAVORABILITY_GIFT, handler(self, self.OnNotify))

end

function XUiPanelSignBoard:SetDisplayCharacterId(displayCharacterId)
    self.DisplayCharacterId = displayCharacterId
    self.IdleTab = XSignBoardConfigs.GetSignBoardConfigByRoldIdAndCondition(self.DisplayCharacterId, XSignBoardEventType.IDLE)

    self.IdleTab = XDataCenter.SignBoardManager.FitterPlayElementByFavorLimit(self.IdleTab, displayCharacterId)
    self.IdleTab = XDataCenter.SignBoardManager.FitterCurLoginPlayed(self.IdleTab)
    self.IdleTab = XDataCenter.SignBoardManager.FitterDailyPlayed(self.IdleTab)
end

function XUiPanelSignBoard:RefreshCharModel()
    self.DisplayState = XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModel, self.DisplayCharacterId)
end

function XUiPanelSignBoard:RefreshCharacterModelById(templateId)
    XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModel, templateId)
end

function XUiPanelSignBoard:OnNotify(event, ...)
    XDataCenter.SignBoardManager.OnNotify(event, ...)
end

--晃动手机
function XUiPanelSignBoard:OnRoll(time)
    if self.SignBoardPlayer:IsPlaying() and not self.CanBreakTrigger then
        return
    end

    self.CanBreakTrigger = false

    local config = XDataCenter.SignBoardManager.GetRandomPlayElementsByRoll(time, self.DisplayCharacterId)
    self.SignBoardPlayer:ForcePlay(config, nil, true)
end

function XUiPanelSignBoard:ResetPlayList()

    local playList = XDataCenter.SignBoardManager.GetPlayElements(self.DisplayCharacterId)
    if not playList then
        return
    end

    self.SignBoardPlayer:SetPlayList(playList)
end

function XUiPanelSignBoard:OnEnable()

    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 0)

    self:RefreshCharModel()

    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnEnable()
    end

    if self.MultClickHelper then
        self.MultClickHelper:OnEnable()
    end

    local playList = XDataCenter.SignBoardManager.GetPlayElements(self.DisplayCharacterId)
    if not playList then
        return
    end

    self.SignBoardPlayer:SetPlayList(playList)

    self.Enable = true
end

function XUiPanelSignBoard:OnDisable()

    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnDisable()
    end

    if self.MultClickHelper then
        self.MultClickHelper:OnDisable()
    end

    if self.PlayingCv then
        self.PlayingCv:Stop()
        self.PlayingCv = nil
    end

    XDataCenter.SignBoardManager.SetStandType(0)

    self.Enable = false
end

function XUiPanelSignBoard:OnDestroy()
    if self.Timer ~= nil then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end

    if self.SignBoardPlayer then
        self.SignBoardPlayer:OnDestroy()
    end

    if self.MultClickHelper then
        self.MultClickHelper:OnDestroy()
    end

    self.Enable = false
end

function XUiPanelSignBoard:Update()
    if not self.Enable then
        return
    end

    local dt = CS.UnityEngine.Time.deltaTime
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Update(dt)
    end

    if self.IdleTab and self.IdleTab[1] then
        local idle = self.IdleTab[1]
        local bBeyondignBoardWaitInterval = XTime.GetServerNowTimestamp() - self.SignBoardPlayer.LastPlayTime >= idle.ConditionParam
        local standType = XDataCenter.SignBoardManager.GetStandType()

        if self.SignBoardPlayer.Status == 0 and self.SignBoardPlayer.LastPlayTime > 0 and standType == 0 and bBeyondignBoardWaitInterval and self.AutoPlay then
            self.SignBoardPlayer:ForcePlay(idle, nil, true)

            if idle.ShowType ~= XDataCenter.SignBoardManager.ShowType.Normal then
                -- 该idle动作限制每次登录或者每天只播放一次
                table.remove(self.IdleTab, 1)
            end

            self.SignBoardPlayer.LastPlayTime = -1
            self.CanBreakTrigger = true
        end
    end

    if self.MultClickHelper then
        self.MultClickHelper:Update(dt)
    end
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelSignBoard:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelSignBoard:AutoInitUi()
    --self.BtnRole = self.Transform:Find("BtnRole"):GetComponent("Button")
    self.PanelLayout = self.Transform:Find("PanelLayout")
    self.PanelChat = self.Transform:Find("PanelLayout/PanelChat")
    self.TxtContent = self.Transform:Find("PanelLayout/PanelChat/Image/TxtContent"):GetComponent("Text")
    self.PanelOpration = self.Transform:Find("PanelLayout/PanelOpration")
    self.BtnReplace = self.Transform:Find("PanelLayout/PanelOpration/BtnReplace"):GetComponent("Button")
    self.BtnCoating = self.Transform:Find("PanelLayout/PanelOpration/BtnCoating"):GetComponent("Button")
    self.BtnCommunication = self.Transform:Find("PanelLayout/PanelOpration/BtnCommunication"):GetComponent("Button")
end

function XUiPanelSignBoard:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelSignBoard:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelSignBoard:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelSignBoard:AutoAddListener()
    self:RegisterClickEvent(self.BtnRole, self.OnBtnRoleClick)
    self:RegisterClickEvent(self.BtnReplace, self.OnBtnReplaceClick)
    self:RegisterClickEvent(self.BtnCoating, self.OnBtnCoatingClick)
    self:RegisterClickEvent(self.BtnCommunication, self.OnBtnCommunicationClick)
end
-- auto
function XUiPanelSignBoard:OnBtnReplaceClick()
    XLuaUiManager.OpenWithCallback("UiFavorabilityLineRoomCharacter", function()
        self.SignBoardPlayer:Stop()
    end)
end

function XUiPanelSignBoard:OnBtnCoatingClick()
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FavorabilityMain) then
        XUiManager.TipMsg(CS.XTextManager.GetText("FunctionalMaintain"))
        return
    end
    XLuaUiManager.OpenWithCallback("UiFashion", function()
        self.SignBoardPlayer:Stop()
    end, self.DisplayCharacterId)
end

function XUiPanelSignBoard:OnBtnCommunicationClick()
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FavorabilityMain) then
        XUiManager.TipMsg(CS.XTextManager.GetText("FunctionalMaintain"))
        return
    end
    self.PanelLayout.gameObject:SetActiveEx(false)
    XLuaUiManager.Open("UiFavorabilityNew")
end

--播放
function XUiPanelSignBoard:Play(element)
    if not element then
        return
    end

    --用CvId与CvType来索引Cv.tab,从而获得Content
    local content
    if element.CvType then
        --播放动作页签下的动作，使用页签选择的语言类型
        content = XFavorabilityConfigs.GetCvContentByIdAndType(element.SignBoardConfig.CvId, element.CvType)
    else
        --播放看板交互的动作，使用设置项的语言
        local cvType = CS.UnityEngine.PlayerPrefs.GetInt("CV_TYPE", DEFAULT_CV_TYPE)
        content = XFavorabilityConfigs.GetCvContentByIdAndType(element.SignBoardConfig.CvId, cvType)
    end
    self.TxtContent.text = content

    self:ShowNormalContent(element.SignBoardConfig.Content ~= nil and self.DialogTrigger)
    self.PanelOpration.gameObject:SetActiveEx(element.SignBoardConfig.ShowButton ~= nil and self.OperateTrigger)

    --self.BtnPhoto.gameObject:SetActiveEx(false)
    --self.BtnInteractive.gameObject:SetActiveEx(false)
    -- self.BtnActivity.gameObject:SetActiveEx(false)
    -- if element.SignBoardConfig.ShowButton ~= nil then
    --     local btnIds = string.Split(element.SignBoardConfig.ShowButton, "|")
    --     if btnIds and #btnIds > 0 then
    --         for i, v in ipairs(btnIds) do
    --             if v == "1" then
    --                 self.BtnPhoto.gameObject:SetActiveEx(not self.DisplayPanel.IsShow and self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN)
    --             end
    --             if v == "2" then
    --                 self.BtnInteractive.gameObject:SetActiveEx(self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN)
    --             end
    --             if v == "3" then
    --                 self.BtnActivity.gameObject:SetActiveEx(true)
    --             end
    --         end
    --     end
    -- end
    if element.SignBoardConfig.CvId and element.SignBoardConfig.CvId > 0 and self.CvTrigger then
        if element.CvType then
            self:PlayCvWithCvType(element.SignBoardConfig.CvId, element.CvType)
        else
            self:PlayCv(element.SignBoardConfig.CvId)
        end
    end

    local actionId = element.SignBoardConfig.ActionId
    if actionId then
        self:PlayAnima(actionId)
        self.RoleModel:LoadCharacterUiEffect(tonumber(element.SignBoardConfig.RoleId), actionId)
    end

    if self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN then
        self.Parent:PlayAnimation("AnimOprationBegan")
    end
end

--显示对白
function XUiPanelSignBoard:ShowNormalContent(show)
    self.PanelLayout.gameObject:SetActiveEx(show)
    if show then -- 海外修改(打开操作看板操作按钮时，重置按钮转态，规避长按按钮消失BUG)
        self.BtnReplace:SetButtonState(0)
        self.BtnCoating:SetButtonState(0)
        self.BtnCommunication:SetButtonState(0)
    end
end


--显示操作按钮
function XUiPanelSignBoard:ShowOprationBtn()
    self.PanelOpration.gameObject:SetActiveEx(self.OperateTrigger)
end

--显示对白
function XUiPanelSignBoard:ShowContent(content)
    self.PanelLayout.gameObject:SetActiveEx(content ~= nil)
    self.TxtContent.text = content
end

--播放CV
function XUiPanelSignBoard:PlayCv(cvId)
    self.PlayingCv = CS.XAudioManager.PlayCv(cvId)
end

function XUiPanelSignBoard:PlayCvWithCvType(cvId, cvType)
    if self.PlayingAudio then
        --正在播放语音页签下的语音，播放新动作需要打断语音并播放打断特效
        self.Parent.FavorabilityMain.FavorabilityAudio:UnScheduleAudio()
        self.Parent:PlayChangeActionEffect()
        self.PlayingAudio = false
    end

    self.PlayingCv = CS.XAudioManager.PlayCvWithCvType(cvId, cvType)
end

--是否在播放看板系统下语音页签的语音
function XUiPanelSignBoard:SetPlayingAudio(value)
    self.PlayingAudio = value
end

--播放动作
function XUiPanelSignBoard:PlayAnima(actionId)
    self.RoleModel:PlayAnima(actionId, self.FromBegin)
    self.FromBegin = nil
end

--暂停
function XUiPanelSignBoard:Pause()
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Pause()
    end
end

--冻结
function XUiPanelSignBoard:Freeze()
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Freeze()
    end
end

--恢复播放
function XUiPanelSignBoard:Resume()
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Resume()
    end
end

--停止
function XUiPanelSignBoard:Stop()
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Stop()
    end
end

--停止
function XUiPanelSignBoard:CvStop()

    if self.SignBoardPlayer then
        self.SignBoardPlayer:Stop()
    end

    if self.PlayingCv then
        self.PlayingCv:Stop()
        self.PlayingCv = nil
    end

    self:ShowNormalContent(false)
end

--停止
function XUiPanelSignBoard:OnStop(playingElement)
    if self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN then
        if not self.Parent.GameObject.activeSelf then
            return
        end
        self.Parent:PlayAnimation("AnimOprationEnd")
    end

    if self.PlayingCv then
        self.PlayingCv:Stop()
        self.PlayingCv = nil
    end

    self:ShowNormalContent(false)

    if playingElement then
        local isChanged = XDataCenter.SignBoardManager.ChangeStandType(playingElement.SignBoardConfig.ChangeToStandType)
        if isChanged then
            self:ResetPlayList()
        end
        self.RoleModel:StopAnima(playingElement.SignBoardConfig.ActionId)
        self.RoleModel:LoadCurrentCharacterDefaultUiEffect()
    end
end

--点击
function XUiPanelSignBoard:OnBtnRoleClick()
    if self.ClickTrigger then
        self.MultClickHelper:Click()
    end
end

-- 强制播放
-- 当动作页签调用时，会传入当前选择的CvType
-- isRecord决定是否记录当前播放的动作
function XUiPanelSignBoard:ForcePlay(playId, cvType, fromBegin, isRecord)
    local config = XSignBoardConfigs.GetSignBoardConfigById(playId)

    -- 从头开始播放动画，避免重复播放同一动画时继承上一个动画的进度
    self.FromBegin = fromBegin
    self.SignBoardPlayer:ForcePlay(config, cvType, isRecord)
end

function XUiPanelSignBoard:IsPlaying()
    return self.SignBoardPlayer:IsPlaying()
end

--多点回调
function XUiPanelSignBoard:OnMultClick(clickTimes)

    local config
    if self.SignBoardPlayer:IsPlaying() and not self.CanBreakTrigger then
        return
    end

    self.CanBreakTrigger = false

    config = XDataCenter.SignBoardManager.GetRandomPlayElementsByClick(clickTimes, self.DisplayCharacterId)

    -- 从头开始播放动画，避免重复播放同一动画时继承上一个动画的进度
    self.FromBegin = true
    self.SignBoardPlayer:ForcePlay(config, nil, true)
end

--设置自动播放
function XUiPanelSignBoard:SetAutoPlay(bAutoPlay)
    self.AutoPlay = bAutoPlay
    self.SignBoardPlayer:SetAutoPlay(bAutoPlay)
end

-- 播放队列是否只播放权重最高的动画
function XUiPanelSignBoard:SetPlayOne(bPlayOne)
    self.PlayOne = bPlayOne
    self.SignBoardPlayer:SetPlayOne(bPlayOne)
end

--操作开关
function XUiPanelSignBoard:SetOperateTrigger(bTriggeer)
    self.OperateTrigger = bTriggeer
    if not bTriggeer then
        self.PanelOpration.gameObject:SetActiveEx(false)
    end
end

--对话开关
function XUiPanelSignBoard:SetDialogTrigger(bTriggeer)
    self.DialogTrigger = bTriggeer
    if not bTriggeer then
        self.PanelLayout.gameObject:SetActiveEx(false)
    end
end

--点击开关
function XUiPanelSignBoard:SetClickTrigger(bTriggeer)
    self.ClickTrigger = bTriggeer
end

---====================
--- 设置是否检测陀螺仪摇晃
---@param value boolean
---====================
function XUiPanelSignBoard:SetRoll(value)
    self.Acceleration.enabled = value
end

return XUiPanelSignBoard