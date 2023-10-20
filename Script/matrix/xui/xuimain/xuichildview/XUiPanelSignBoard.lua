---@class XUiPanelSignBoard
local XUiPanelSignBoard = XClass(nil, "XUiPanelSignBoard")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

XUiPanelSignBoard.SignBoardOpenType = {
    MAIN = 1,
    FAVOR = 2
}
local UiMainMenuType = {
    Main = 1,
    Second = 2,
}

local DEFAULT_CV_TYPE = CS.XGame.Config:GetInt("DefaultCvType")

function XUiPanelSignBoard:Ctor(ui, parent, openType, playCb, StopCb)
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

    self.PlayCb = playCb
    self.StopCb = StopCb

    self:InitAutoScript()
    self:Init()
end

function XUiPanelSignBoard:Init()
    --模型
    local clearUiChildren = self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN
    ---@type XUiPanelRoleModel
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
    local playerData = XMVCA.XFavorability:GetSignBoardPlayerData()
    signBoardPlayer:SetPlayerData(playerData)
    self.SignBoardPlayer = signBoardPlayer

    local signBoardClickInterval = CS.XGame.ClientConfig:GetFloat("SignBoardClickInterval")
    local signBoardMultClickCountLimit = CS.XGame.ClientConfig:GetInt("SignBoardMultClickCountLimit")

    local multClickHelper = require("XUi/XUiCommon/XUiMultClickHelper").New(self, signBoardClickInterval, signBoardMultClickCountLimit)
    self.MultClickHelper = multClickHelper
    -- 分段播放文本内容
    self.TxtSplitCvContent = require("XUi/XUiMain/XUiChildView/XUiTxtSplitCvContent").New(self.TxtContent)
    self:SetPanelLayoutActive(false)
    if XUiManager.IsHideFunc then
        self.BtnCommunication.gameObject:SetActiveEx(false)
    end

    -- 播放队列只播放权重最高的动画
    self:SetPlayOne(true)

    --用于驱动播放器和连点检测
    --事件
    self.OnAnimationEnterCb = handler(self, self.OnAnimationEnter)
    self.OnNotifyCb = handler(self, self.OnNotify)
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FIGHT_RESULT, self.OnNotifyCb)
    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_FAVORABILITY_GIFT, self.OnNotifyCb)
    CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_HOMECHAR_ACTION_ENTER, self.OnAnimationEnterCb)
end

function XUiPanelSignBoard:SetDisplayCharacterId(displayCharacterId)
    self.DisplayCharacterId = displayCharacterId
    self.IdleTab = XMVCA.XFavorability:GetSignBoardConfigByRoldIdAndCondition(self.DisplayCharacterId, XEnumConst.Favorability.XSignBoardEventType.IDLE)

    self.IdleTab = XMVCA.XFavorability:FitterPlayElementByFavorLimit(self.IdleTab, displayCharacterId)
    self.IdleTab = XMVCA.XFavorability:FitterCurLoginPlayed(self.IdleTab)
    self.IdleTab = XMVCA.XFavorability:FitterDailyPlayed(self.IdleTab)
end

function XUiPanelSignBoard:RefreshCharModel()
    self.DisplayState = XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModel, self.DisplayCharacterId)
--[[    local face = self.DisplayState.Model.gameObject:FindTransform("R3WeilaMd010011Face")--ZStest
    self.FaceSkinnedMeshRenderer = face and face:GetComponent("SkinnedMeshRenderer")--ZStest
    local path = CS.XGame.ClientConfig:GetString("WeiLaStoryFace")
    local resource = CS.XResourceManager.Load(path)
    if self.FaceSkinnedMeshRenderer and resource then
        self.FaceSkinnedMeshRenderer.sharedMesh = resource.Asset
    end
    ]]
end

function XUiPanelSignBoard:RefreshCharacterModelById(templateId)
    XDataCenter.DisplayManager.UpdateRoleModel(self.RoleModel, templateId)
    self.RoleModel:SetXPostFaicalControllerActive(true)
end

function XUiPanelSignBoard:OnNotify(event, ...)
    XMVCA.XFavorability:OnNotify(event, ...)
end

--晃动手机
function XUiPanelSignBoard:OnRoll(time)
    if self.SignBoardPlayer:IsPlaying() and not self.CanBreakTrigger then
        return
    end

    self.CanBreakTrigger = false

    local config = XMVCA.XFavorability:GetRandomPlayElementsByRoll(time, self.DisplayCharacterId)
    if config ~= nil then self:ForcePlay(config.Id, nil, self.FromBegin, true) end
end

function XUiPanelSignBoard:ResetPlayList()

    local playList = XMVCA.XFavorability:GetPlayElements(self.DisplayCharacterId)
    if not playList then
        return
    end

    self.SignBoardPlayer:SetPlayList(playList)
end

function XUiPanelSignBoard:CheckBtnReplaceDisable()
    local curDisChar = XDataCenter.DisplayManager.GetDisplayChar()

    -- 当前助理队列只有1人
    local isOnlyOneCharInDisList = #XPlayer.DisplayCharIdList <= 1  

    -- 当前助理是否开启了涂装随机功能
    local isCurListHaveCharRandom = curDisChar.RandomFashion

    -- 当前助理随机涂装数量是否大于1
    local isCurCharHaveOneFashionInRandomList = #XDataCenter.FashionManager.GetCharacterAllRandomFashionList(curDisChar.Id) == 1
    local isDisable = (isOnlyOneCharInDisList and not isCurListHaveCharRandom) or (isOnlyOneCharInDisList and isCurCharHaveOneFashionInRandomList)
    return isDisable
end

function XUiPanelSignBoard:RefreshUiShow()
    self.BtnReplace:SetDisable(self:CheckBtnReplaceDisable())
    if self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN then
        self.PanelOpration.gameObject:SetActiveEx(false)
    end
end

function XUiPanelSignBoard:OnEnable()
    self:RefreshUiShow()

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

    local playList = XMVCA.XFavorability:GetPlayElements(self.DisplayCharacterId)
    if not playList then
        return
    end

    self.SignBoardPlayer:SetPlayList(playList)

    self.Enable = true

    self.RoleModel:SetXPostFaicalControllerActive(true)
end

function XUiPanelSignBoard:OnDisable()
    self:StopTimerShow()
    if self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN then
        self.PanelOpration.gameObject:SetActiveEx(false)
    end

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

    XMVCA.XFavorability:SetStandType(0)

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
    self.Parent = nil

    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_FIGHT_RESULT, self.OnNotifyCb)
    CsXGameEventManager.Instance:RemoveEvent(XEventId.EVENT_FAVORABILITY_GIFT, self.OnNotifyCb)
    CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_HOMECHAR_ACTION_ENTER, self.OnAnimationEnterCb)
    
    self.OnNotifyCb = nil
    self.OnAnimationEnterCb = nil
end

function XUiPanelSignBoard:StopTimerShow()
    if self.TimerShow then
        XScheduleManager.UnSchedule(self.TimerShow)
    end
    self.TimerShow = nil
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
        local standType = XMVCA.XFavorability:GetStandType()

        if self.SignBoardPlayer.Status == 0 and self.SignBoardPlayer.LastPlayTime > 0 and standType == 0 and bBeyondignBoardWaitInterval and self.AutoPlay then
            self:ForcePlay(idle.Id, nil, self.FromBegin, true)

            if idle.ShowType ~= XEnumConst.Favorability.ShowTimesType.Normal then
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
    self.TxtContent = self.Transform:Find("PanelLayout/PanelChat/TxtList/Viewport/Content/TxtContent"):GetComponent("Text")
    self.PanelOpration = self.Transform:Find("PanelLayout/PanelOpration")
    self.BtnReplace = self.Transform:Find("PanelLayout/PanelOpration/BtnReplace"):GetComponent("Button")
    self.BtnCoating = self.Transform:Find("PanelLayout/PanelOpration/BtnCoating"):GetComponent("Button")
    local btnSceneObj=self.Transform:Find('PanelLayout/PanelOpration/BtnScene')
    if btnSceneObj then
        self.BtnScene=btnSceneObj:GetComponent('Button')
    end
    self.BtnCommunication = self.Transform:Find("PanelLayout/PanelOpration/BtnCommunication"):GetComponent("Button")
    
    self.LayoutContent = self.PanelLayout:Find("PanelChat/TxtList/Viewport/Content"):GetComponent("RectTransform")
    self.LayoutContentOriginPos = XTool.Clone(self.LayoutContent.localPosition)

    self.BtnCoating.gameObject:SetActiveEx(not XUiManager.IsHideFunc)
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
    if self.BtnScene then
        self:RegisterClickEvent(self.BtnScene,self.OnBtnSceneClick)
    end
    self:RegisterClickEvent(self.BtnCommunication, self.OnBtnCommunicationClick)
end

function XUiPanelSignBoard:OnBtnFaceClick(CvId)--ZStest
    local behaviour = self.RoleModel.Transform:GetComponent(typeof(CS.XLuaBehaviour))
    if not behaviour then
        behaviour = self.RoleModel.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    else
        behaviour.enabled = true
    end

    local mouthDataList = XMouthAnimeConfigs.GetMouthDataDic()[CvId]

    if self.CVInfo then
        self.CVInfo:Stop()
        self.CVInfo = nil
    end
    self.CVInfo = CS.XAudioManager.PlayCv(CvId)

    local count = 1
    local startTime = CS.XProfiler.Stopwatch.ElapsedMilliseconds
    behaviour.LuaUpdate = function()
        local useTime = math.max(CS.XProfiler.Stopwatch.ElapsedMilliseconds - startTime, 1)

        local group = math.ceil(useTime / XMouthAnimeConfigs.FrameUnit) * XMouthAnimeConfigs.FrameUnit
        local mouthDataGroup = mouthDataList[group]
        local data
        for _, mouthData in pairs(mouthDataGroup or {}) do
            if useTime <= mouthData.Msec then
                data = mouthData
                break
            end
        end

        if data and self.FaceSkinnedMeshRenderer then
            local indexA = self.FaceSkinnedMeshRenderer.sharedMesh:GetBlendShapeIndex("a")
            local indexI = self.FaceSkinnedMeshRenderer.sharedMesh:GetBlendShapeIndex("i")
            local indexU = self.FaceSkinnedMeshRenderer.sharedMesh:GetBlendShapeIndex("u")
            local indexE = self.FaceSkinnedMeshRenderer.sharedMesh:GetBlendShapeIndex("e")
            local indexO = self.FaceSkinnedMeshRenderer.sharedMesh:GetBlendShapeIndex("o")

            self.FaceSkinnedMeshRenderer:SetBlendShapeWeight(indexA, data.A * 100)
            self.FaceSkinnedMeshRenderer:SetBlendShapeWeight(indexI, data.I * 100)
            self.FaceSkinnedMeshRenderer:SetBlendShapeWeight(indexU, data.U * 100)
            self.FaceSkinnedMeshRenderer:SetBlendShapeWeight(indexE, data.E * 100)
            self.FaceSkinnedMeshRenderer:SetBlendShapeWeight(indexO, data.O * 100)

            count = count + 1
        else
            behaviour.enabled = false
        end
    end
end

-- auto 随机替换
function XUiPanelSignBoard:OnBtnReplaceClick()
    -- if not XPlayer.DisplayCharIdList or #XPlayer.DisplayCharIdList <= 1 then
    --     XUiManager.TipMsg(XUiHelper.GetText("AssistOnlyOne"))
    --     return
    -- end
    if self:CheckBtnReplaceDisable() then
        XUiManager.TipMsg(XUiHelper.GetText("AssistAndCoatingOnlyOne"))
        return
    end
    

    -- 随机角色
    local displayCharacterId = XDataCenter.DisplayManager.GetRandomDisplayCharByList().Id
    XDataCenter.DisplayManager.SetNextDisplayChar(nil)

    -- 刷新
    local refreshFun = function ()
        self:SetDisplayCharacterId(displayCharacterId)
        self:RefreshCharModel()
        if self.Parent.PlayChangeModelEffect then
            self.Parent:PlayChangeModelEffect()
        end
        self.SignBoardPlayer:Stop()
    end

    -- 随机涂装
    XDataCenter.FashionManager.SetCharacterRandomFashion(displayCharacterId, refreshFun)
end

function XUiPanelSignBoard:OnBtnCoatingClick()
    -- if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FavorabilityMain) then
    --     XUiManager.TipMsg(CS.XTextManager.GetText("FunctionalMaintain"))
    --     return
    -- end
    -- XLuaUiManager.OpenWithCallback("UiFashion", function()
    --     self.SignBoardPlayer:Stop()
    -- end, self.DisplayCharacterId)
    XLuaUiManager.OpenWithCallback("UiFavorabilityLineRoomCharacter", function()
        self.SignBoardPlayer:Stop()
    end)
end

function XUiPanelSignBoard:OnBtnSceneClick()
    XDataCenter.PhotographManager.OpenUiSceneSetting(UiMainMenuType.Main)
end

function XUiPanelSignBoard:OnBtnCommunicationClick()
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FavorabilityMain) then
        XUiManager.TipMsg(CS.XTextManager.GetText("FunctionalMaintain"))
        return
    end
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.FavorabilityMain) then
        return
    end
    self:SetPanelLayoutActive(false)
    XLuaUiManager.Open("UiFavorabilityNew")
end

--播放
function XUiPanelSignBoard:Play(element)
    if not element then
        return
    end

    if self.PlayCb then
        self.PlayCb()
    end

    --用CvId与CvType来索引Cv.tab,从而获得Content
    local content
    local cvId = element.SignBoardConfig.CvId
    local cvType
    if element.CvType then
        cvType = element.CvType
        --播放动作页签下的动作，使用页签选择的语言类型
        content = XMVCA.XFavorability:GetCvContentByIdAndType(cvId, element.CvType)
    else
        --播放看板交互的动作，使用设置项的语言
        cvType = CS.UnityEngine.PlayerPrefs.GetInt("CV_TYPE", DEFAULT_CV_TYPE)
        content = XMVCA.XFavorability:GetCvContentByIdAndType(cvId, cvType)
    end
    self.TxtSplitCvContent:ShowContent(cvId, cvType, content)

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
        self:StopTimerShow()
        self.TimerShow = XScheduleManager.ScheduleOnce(function()
            self.Parent:PlayAnimation("AnimOprationEnd")
            self.PanelOpration.gameObject:SetActiveEx(false)
        end, CS.XGame.ClientConfig:GetInt("Interactionbuttonshowtime"))
    end
end

-- v1.32 播放角色特殊动作场景动画
function XUiPanelSignBoard:PlaySceneAnim(element)
    if not element or not self.Parent.UiModelGo then
        return
    end
    local animRoot = self.Parent.UiModelGo.transform
    local cameraFar = self.Parent:FindVirtualCamera("CamFarMain")
    local cameraNear = self.Parent:FindVirtualCamera("CamNearMain")
    if not cameraFar or not cameraNear then
        return
    end
    XMVCA.XFavorability:LoadSceneAnim(animRoot, cameraFar, cameraNear, XDataCenter.PhotographManager.GetCurSceneId(), element.SignBoardConfig.Id, self.Parent)
    XMVCA.XFavorability:SceneAnimPlay()
end

-- v1.32 播放角色特殊动作播放动画
function XUiPanelSignBoard:PlayUiAnim()
    if not self.Parent.UiModelGo then
        return
    end
    -- 隐藏助理面板
    self.PanelOpration.gameObject:SetActiveEx(false)
end

function XUiPanelSignBoard:PlayCross(element)
    if not element then
        return
    end

    if self.PlayCb then
        self.PlayCb()
    end

    --用CvId与CvType来索引Cv.tab,从而获得Content
    local content
    local cvId = element.SignBoardConfig.CvId
    local cvType
    if element.CvType then
        cvType = element.CvType
        --播放动作页签下的动作，使用页签选择的语言类型
        content = XMVCA.XFavorability:GetCvContentByIdAndType(cvId, element.CvType)
    else
        --播放看板交互的动作，使用设置项的语言
        cvType = CS.UnityEngine.PlayerPrefs.GetInt("CV_TYPE", DEFAULT_CV_TYPE)
        content = XMVCA.XFavorability:GetCvContentByIdAndType(cvId, cvType)
    end
    self.TxtSplitCvContent:ShowContent(cvId, cvType, content)

    self:ShowNormalContent(element.SignBoardConfig.Content ~= nil and self.DialogTrigger)
    self.PanelOpration.gameObject:SetActiveEx(element.SignBoardConfig.ShowButton ~= nil and self.OperateTrigger)

    if element.SignBoardConfig.CvId and element.SignBoardConfig.CvId > 0 and self.CvTrigger then
        if element.CvType then
            self:PlayCvWithCvType(element.SignBoardConfig.CvId, element.CvType)
        else
            self:PlayCv(element.SignBoardConfig.CvId)
        end
    end

    local actionId = element.SignBoardConfig.ActionId
    if actionId then
        self:PlayAnimaCross(actionId)
        self.RoleModel:LoadCharacterUiEffect(tonumber(element.SignBoardConfig.RoleId), actionId)
    end

    if self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN then
        self.Parent:PlayAnimation("AnimOprationBegan")
        self:StopTimerShow()
        self.TimerShow = XScheduleManager.ScheduleOnce(function()
            self.Parent:PlayAnimation("AnimOprationEnd")
            self.PanelOpration.gameObject:SetActiveEx(false)
        end, CS.XGame.ClientConfig:GetInt("Interactionbuttonshowtime"))
    end
end

--显示对白
function XUiPanelSignBoard:ShowNormalContent(show)
    self:SetPanelLayoutActive(show)
    self.BtnReplace:SetButtonState(CS.UiButtonState.Normal)
    -- local isDisable = not XPlayer.DisplayCharIdList or #XPlayer.DisplayCharIdList <= 1
    self.BtnReplace:SetDisable(self:CheckBtnReplaceDisable())
    self.BtnCoating:SetButtonState(CS.UiButtonState.Normal)
    self.BtnCommunication:SetButtonState(CS.UiButtonState.Normal)
end


--显示操作按钮
function XUiPanelSignBoard:ShowOprationBtn()
    -- self.PanelOpration.gameObject:SetActiveEx(self.OperateTrigger)
end

--显示对白
function XUiPanelSignBoard:ShowContent(cvId, cvType)
    local content = XMVCA.XFavorability:GetCvContentByIdAndType(cvId, cvType)
    if self.LayoutContent then
        self.LayoutContent.localPosition = self.LayoutContentOriginPos
    end
    self:SetPanelLayoutActive(content ~= nil)
    self.TxtSplitCvContent:ShowContent(cvId, cvType, content)
end

--播放CV
function XUiPanelSignBoard:PlayCv(cvId)
    self.PlayingCv = CS.XAudioManager.PlayCv(cvId)
end

function XUiPanelSignBoard:PlayCvWithCvType(cvId, cvType)
    if self.PlayingAudio then
        --正在播放语音页签下的语音，播放新动作需要打断语音并播放打断特效
        self.Parent.FavorabilityMain.FavorabilityShow:UnScheduleAudioPlay()
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

function XUiPanelSignBoard:PlayAnimaCross(actionId)
    self.RoleModel:PlayAnimaCross(actionId, self.FromBegin)
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
function XUiPanelSignBoard:Stop(force)
    if self.SignBoardPlayer then
        self.SignBoardPlayer:Stop(force)
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
function XUiPanelSignBoard:OnStop(playingElement, force)
    if self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN then
        if not self.Parent.GameObject.activeSelf then
            return
        end
    end

    if self.PlayingCv then
        self.PlayingCv:Stop()
        self.PlayingCv = nil
    end

    self:ShowNormalContent(false)

    if playingElement then
        local isChanged = XMVCA.XFavorability:ChangeStandType(playingElement.SignBoardConfig.ChangeToStandType)
        if isChanged then
            self:ResetPlayList()
        end
        self.RoleModel:StopAnima(playingElement.SignBoardConfig.ActionId, force)
        self.RoleModel:LoadCurrentCharacterDefaultUiEffect()
    end
end

--点击
function XUiPanelSignBoard:OnBtnRoleClick()
    if self.ClickTrigger then
        self.MultClickHelper:Click()
    end
end

--根据好感度决定动作的播放
function XUiPanelSignBoard:TrasformPlayConfigByFavorability(config)
    if config == nil then return end
    --确定当前动作是否满足好感度条件
    local isUnlock , conditionDescript = XMVCA.XFavorability:CheckCharacterActionUnlockBySignBoardActionId(config.Id)
    if isUnlock then
        return config
    end
    --如果没满足则从同样播放条件的动作里随机抽取
    local SignBoardActionDatas = XMVCA.XFavorability:GetSignBoardConfigByRoldIdAndCondition(tonumber(config.RoleId), config.ConditionId)
    local randomDatas = {}
    for _, signBoardActionData in ipairs(SignBoardActionDatas) do
        if signBoardActionData.ConditionParam == config.ConditionParam and XMVCA.XFavorability:CheckCharacterActionUnlockBySignBoardActionId(signBoardActionData.Id) then
            table.insert(randomDatas,signBoardActionData)
        end
    end
    if #randomDatas > 0 then
        local index = math.random(1, #randomDatas)
        return randomDatas[index]
    end
    --如果没动作可以播放 则什么都不发生
    return nil
end

-- 强制播放
-- 当动作页签调用时，会传入当前选择的CvType
-- isRecord决定是否记录当前播放的动作
function XUiPanelSignBoard:ForcePlay(playId, cvType, fromBegin, isRecord)
    local config = XMVCA.XFavorability:GetSignBoardConfigById(playId)
    --好感度系统检查动作播放
    config = self:TrasformPlayConfigByFavorability(config)
    if config == nil then return end
    -- 从头开始播放动画，避免重复播放同一动画时继承上一个动画的进度
    self.FromBegin = fromBegin
    self.SignBoardPlayer:ForcePlay(config, cvType, isRecord)
end

-- 强制播放
-- 当动作页签调用时，会传入当前选择的CvType
-- isRecord决定是否记录当前播放的动作
function XUiPanelSignBoard:ForcePlayCross(playId, cvType, fromBegin, isRecord)
    local config = XMVCA.XFavorability:GetSignBoardConfigById(playId)
    --好感度系统检查动作播放
    config = self:TrasformPlayConfigByFavorability(config)
    if config == nil then return end
    -- 从头开始播放动画，避免重复播放同一动画时继承上一个动画的进度
    self.FromBegin = fromBegin
    self.SignBoardPlayer:ForcePlayCross(config, cvType, isRecord)
end

function XUiPanelSignBoard:IsPlaying()
    return self.SignBoardPlayer:IsPlaying()
end

--多点回调
function XUiPanelSignBoard:OnMultClick(clickTimes)
    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnRole
    dict["role_level"] = XPlayer.GetLevel()
    local param = clickTimes > 1 and 2 or 1 --描述区分单次、多次
    dict["ui_second_button"] = param
    CS.XRecord.Record(dict, "200004", "UiOpen")

    XMVCA.XFavorability:RequestTouchBoard(self.DisplayCharacterId)
    
    local config
    if self.SignBoardPlayer:IsPlaying() and not self.CanBreakTrigger then
        return
    end
    self.CanBreakTrigger = false
    -- 从头开始播放动画，避免重复播放同一动画时继承上一个动画的进度
    config = XMVCA.XFavorability:GetRandomPlayElementsByClick(clickTimes, self.DisplayCharacterId)
    -- 特殊动作屏蔽处理（本我回廊功能）
    if config ~= nil and self.SpecialFilterAnimId and self.SpecialFilterAnimId[config.Id] then
        return
    end
    if config ~= nil then
        if self.Parent.FavorabilityMain then
            self:ForcePlayCross(config.Id, self.Parent.FavorabilityMain.CvType, true, true)
        else
            self:ForcePlayCross(config.Id, nil, true, true)
        end
    end
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
        -- self.PanelOpration.gameObject:SetActiveEx(false)
    end
end

--对话开关
function XUiPanelSignBoard:SetDialogTrigger(bTriggeer)
    self.DialogTrigger = bTriggeer
    if not bTriggeer then
        self:SetPanelLayoutActive(false)
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
    if not XTool.UObjIsNil(self.Acceleration) then
        self.Acceleration.enabled = value
    end
end

function XUiPanelSignBoard:SetPanelLayoutActive(isActive)
    self.PanelChat.gameObject:SetActiveEx(isActive)
    if self.OpenType == XUiPanelSignBoard.SignBoardOpenType.MAIN then
        self.PanelChat.gameObject:SetActiveEx(isActive)
    else
        self.PanelLayout.gameObject:SetActiveEx(isActive)
    end
    if not isActive then
        self.TxtSplitCvContent:HideContent()
    end
    self.RoleModel:SetXPostFaicalControllerActive(not isActive)
end

-- 特殊动作屏蔽处理（本我回廊功能）
function XUiPanelSignBoard:SetSpecialFilterAnimId(animId)
    self.SpecialFilterAnimId = animId
end

-- 开关角色看板动作功能
function XUiPanelSignBoard:SetEnable(enable)
    self.Enable = enable
    if enable and self.SignBoardPlayer and self.SignBoardPlayer.LastPlayTime > 0 then
        -- 处理长待机计时
        self.SignBoardPlayer.LastPlayTime = XTime.GetServerNowTimestamp()
    end
end

--- 动画开始播放
---@param args System.Object[]
--------------------------
function XUiPanelSignBoard:OnAnimationEnter(evt, args)
    --参数数组 0：UnityEngine.Animator
    --参数数组 1：UnityEngine.AnimatorStateInfo
    if not args or args.Length < 2 then
        return
    end
    local stateInfo = args[1]
    if not self.RoleModel or not self.DisplayCharacterId or self.DisplayCharacterId <= 0 
            or not stateInfo then
        return
    end
    --获取身体层正在播放的动画名
    local actionId = self.RoleModel:GetPlayingStateName(0)
    if not stateInfo:IsName(actionId) then
        return
    end
    self.RoleModel:LoadCharacterUiEffect(self.DisplayCharacterId, actionId)
end

return XUiPanelSignBoard