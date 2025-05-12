local XUiPanelMatch = require("XUi/XUiOnlineBoss/XUiPanelMatch")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelBossInfo = require("XUi/XUiOnlineBoss/XUiPanelBossInfo")
local XUiOnlineBoss = XLuaUiManager.Register(XLuaUi, "UiOnlineBoss")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local UiState = {
    Enter = 1,
    Match = 2,
    Info = 3,
    NewBoss = 4,
}

function XUiOnlineBoss:OnAwake()
    local root = self.UiModelGo.transform
    self.SceneCase = root:FindTransform("SceneCase")
    self.PanelModel = root:FindTransform("PanelModel")
    self.UiCamFarMain = root:FindTransform("UiCamFarMain") or root:FindTransform("UiCamFarMainActivity")
    self.UiCamFarPanelMatch = root:FindTransform("UiCamFarPanelMatch") or root:FindTransform("UiCamFarPanelMatchActivity")
    self.UiCamFarBossInfo = root:FindTransform("UiCamFarBossInfo") or root:FindTransform("UiCamFarBossInfoActivity")
    self.UiCamNearMain = root:FindTransform("UiCamNearMain") or root:FindTransform("UiCamNearMainActivity")
    self.UiCamNearPanelMatch = root:FindTransform("UiCamNearPanelMatch") or root:FindTransform("UiCamNearPanelMatchActivity")
    self.UiCamNearBossInfo = root:FindTransform("UiCamNearBossInfo") or root:FindTransform("UiCamNearBossInfoActivity")
    self.UiCamNearFirst = root:FindTransform("UiCamNearFirstActivity")
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    -- self.TextTypewriter = self.TxtAutoInvade:GetComponent("TextTypewriter")
end

function XUiOnlineBoss:OnStart(selectIdx, isFirst)
    self.ScenePool = {}
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.MatchPanel = XUiPanelMatch.New(self.PanelMatch, self)
    self.BossInfoPanel = XUiPanelBossInfo.New(self.PanelBossInfo)
    

    self.UiState = isFirst and UiState.NewBoss or UiState.Enter
    self.GameObjectGroup = {
        [UiState.Enter] = {
            self.PanelEnter.gameObject,
            self.UiCamFarMain.gameObject,
            self.UiCamNearMain.gameObject,
        },
        [UiState.Match] = {
            self.PanelMatch.gameObject,
            self.UiCamFarPanelMatch.gameObject,
            self.UiCamNearPanelMatch.gameObject,
        },
        [UiState.Info] = {
            self.PanelBossInfo.gameObject,
            self.UiCamFarBossInfo.gameObject,
            self.UiCamNearBossInfo.gameObject,
        },
    }
    if self.Name == "UiOnlineBossActivity" then
        self.GameObjectGroup[UiState.NewBoss] = {
            self.PanelEnter.gameObject,
            self.UiCamFarMain.gameObject,
            self.UiCamNearFirst.gameObject,
        }
    end

    self.TabList = {
        self.BtnTog0,
        self.BtnTog1,
        self.BtnTog2,
        self.BtnTog3,
        self.BtnTog4,
    }

    self.DifficultMap = {
        XDataCenter.FubenBossOnlineManager.OnlineBossDifficultLevel.SIMPLE,
        XDataCenter.FubenBossOnlineManager.OnlineBossDifficultLevel.NORMAL,
        XDataCenter.FubenBossOnlineManager.OnlineBossDifficultLevel.HARD,
        XDataCenter.FubenBossOnlineManager.OnlineBossDifficultLevel.HELL,
        XDataCenter.FubenBossOnlineManager.OnlineBossDifficultLevel.NightMare,
    }

    self:SetDifficult(self.DifficultMap[1])

    self.TabPanel:Init(self.TabList, handler(self, self.OnSelectTab), 1)
    if XDataCenter.FubenBossOnlineManager.CheckOnlineBossUnlock(self.DifficultMap[1]) then
        self.TabPanel:SelectIndex(selectIdx or 1)
    end
    self.DefaultIndex = selectIdx

    self.CurAnimator = nil
    self:InitModel()
    self:InitPanelInvade()
    self:SwitchState(self.UiState)

    self:RegisterClickEvent(self.BtnStart, self.OnBtnStartClick)
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnInvade, self.OnBtnInvadeClick)

    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.EnterRoom, self)
    XEventManager.AddEventListener(XEventId.EVENT_ONLINEBOSS_UPDATE, self.OnBossUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_ONLINEBOSS_REFRESH, self.OnBossRefresh, self)
end

function XUiOnlineBoss:OnEnable()

    XDataCenter.FubenBossOnlineManager.RefreshBossData()
    self:RefreshBtnList()
    if self.CurAnimator and self.SectionTemplate then
        self.CurAnimator:Play(self.SectionTemplate.Animation)
    end

    if self.UiState == UiState.Match then
        self.MatchPanel:Refresh()
        self.PanelMatchEnable:PlayTimelineAnimation()
    elseif self.UiState == UiState.NewBoss then
        self.PanelTip.gameObject:SetActive(true)
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1105)
        self.TipEnable:PlayTimelineAnimation(function()
            if not self.GameObject or not self.GameObject:Exist() then
                return
            end
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1106)
            self:SwitchState(UiState.Enter)
            self.EnterFirst:PlayTimelineAnimation()
            self.PanelTip.gameObject:SetActive(true)
            XScheduleManager.ScheduleOnce(function()
                if not self.GameObject or not self.GameObject:Exist() then
                    return
                end
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1107)
            end, 1500)
        end)
    elseif self.UiState == UiState.Enter then
        if self.Name == "UiOnlineBossActivity" then
            -- XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1107)
            self.EnterEnable:PlayTimelineAnimation()
        end
    end
    self:StartTimer()
end

function XUiOnlineBoss:OnDisable()
    self:StopTimer()
end

function XUiOnlineBoss:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.EnterRoom, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ONLINEBOSS_UPDATE, self.OnBossUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ONLINEBOSS_REFRESH, self.OnBossRefresh, self)
end

function XUiOnlineBoss:UseLastTemplate()
    return XDataCenter.FubenBossOnlineManager.GetIsActivity() and not XDataCenter.FubenBossOnlineManager.CheckIsInvade()
end

function XUiOnlineBoss:InitPanelInvade()
    if self:UseLastTemplate() then
        self.PanelInvade.gameObject:SetActive(true)
    else
        self.PanelInvade.gameObject:SetActive(false)
    end
end

function XUiOnlineBoss:OnSelectTab(index)
    local diff = self.DifficultMap[index]
    if XDataCenter.FubenBossOnlineManager.CheckOnlineBossUnlock(diff, true) and self.CurDifficult ~= diff then
        self:SetDifficult(diff)
        self:RefreshModel()
        self:RefreshName()
        self:RefreshRisk()
        self:PlayAnimation("QieHuan")
    end
end

function XUiOnlineBoss:RefreshName()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtName.text = stageCfg.Name
end

function XUiOnlineBoss:OnUpdateRefreshTime()
    local curTime = XTime.GetServerNowTimestamp()
    local nextTime = XDataCenter.FubenBossOnlineManager.GetOnlineBossUpdateTime()

    if not self.GameObject or not self.GameObject:Exist() then
        self:StopTimer()
        return
    end

    local remainTime = nextTime - curTime
    if remainTime > 0 then
        self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ONLINE_BOSS)
    else
        self.TxtTime.text = "00:00"
        self:StopTimer()
        self:OnTimeOut()
    end
end

function XUiOnlineBoss:StartTimer()
    if self.Timers then
        self:StopTimer()
    end
    self:OnUpdateRefreshTime()
    self.Timers = XScheduleManager.ScheduleForever(function() self:OnUpdateRefreshTime() end, XScheduleManager.SECOND)
end

function XUiOnlineBoss:StopTimer()
    if self.Timers then
        XScheduleManager.UnSchedule(self.Timers)
        self.Timers = nil
    end
end

function XUiOnlineBoss:RefreshRisk()
    if self.Name == "UiOnlineBossActivity" then
        local bossData = XDataCenter.FubenBossOnlineManager.GetActOnlineBossSectionForDiff(self.CurDifficult)
        local riskTemplate = XFubenBossOnlineConfig.GetRiskTemplate(bossData.KillCount)
        self.TxtRisk.text = riskTemplate.Name
        self.TxtKill.text = CS.XTextManager.GetText("BossOnlineKillCount", bossData.KillCount)
        local color = XUiHelper.Hexcolor2Color(riskTemplate.Color)
        self.TxtRisk.color = color
        self.TxtKill.color = color
        self.PanelRisk.gameObject:SetActive(true)
    else
        self.PanelRisk.gameObject:SetActive(false)
    end
end

function XUiOnlineBoss:OnBtnStartClick()
    if not XDataCenter.FubenBossOnlineManager.CheckOnlineBossUnlock(self.CurDifficult, true) then
        return
    end
    local bossData = XDataCenter.FubenBossOnlineManager.GetActOnlineBossSectionForDiff(self.CurDifficult)
    self:OnEnterMatch(bossData.BossId)
end

function XUiOnlineBoss:Close()
    if self.UiState == UiState.Enter then
        self.Super.Close(self)
    elseif self.UiState == UiState.Match then
        if XDataCenter.RoomManager.Matching then
            local title = CS.XTextManager.GetText("TipTitle")
            local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceCancelMatch")
            XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
                XDataCenter.RoomManager.CancelMatch(function()
                    self:SwitchState(UiState.Enter)
                end)
            end)
        else
            self:SwitchState(UiState.Enter)
        end
    elseif self.UiState == UiState.Info then
        self:SwitchState(UiState.Match)
        self.PanelMatchEnable:PlayTimelineAnimation()
    end
end

function XUiOnlineBoss:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiOnlineBoss:OnBtnInvadeClick()
    if not self:UseLastTemplate() or self.IsPlayInvade then
        return
    end
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1104)
    XDataCenter.FubenBossOnlineManager.RecordInvade()

    self.InvadeEffect.gameObject:SetActive(true)
    local effectUrl = CS.XGame.ClientConfig:GetString("BossOnlineInvadeEffectUrl")
    local effect = self.InvadeEffect.gameObject:LoadUiEffect(effectUrl)
    local obj = { Transform = effect.transform }
    XTool.InitUiObject(obj)
    self.InvadeBeginEffect = obj.BeginEffect
    self.InvadeEndEffect = obj.EndEffect
    self.InvadeBeginEffect:PlayTimelineAnimation()

    XScheduleManager.ScheduleOnce(function()
        if not self.GameObject or not self.GameObject:Exist() then
            return
        end
        self:PlayTxtAutoInvade()
    end, CS.XGame.ClientConfig:GetInt("BossOnlineInvadeDelay"))

    self.IsPlayInvade = true
end

function XUiOnlineBoss:OnBossUpdate()
    self:RefreshModel()
    self:RefreshName()
    self:RefreshRisk()
    self:StartTimer()
    self:RefreshBtnList()
end

function XUiOnlineBoss:OnBossRefresh()
    self:OnTimeOut()
end

function XUiOnlineBoss:OnTimeOut()
    if XDataCenter.RoomManager.Matching then
        XDataCenter.RoomManager.CancelMatch()
        XLuaUiManager.Remove("UiOnLineMatching")
    end

    if XLuaUiManager.IsUiShow("UiDialog") then
        XLuaUiManager.Close("UiDialog")
    end

    XDataCenter.FubenBossOnlineManager.TryPopOverTips()
    if XUiManager.CheckTopUi(CsXUiType.Normal, self.Name) then
        self.Super.Close(self)
    else
        self:Remove()
    end
end

function XUiOnlineBoss:SwitchState(state)
    XLog.Debug("XUiOnlineBoss:SwitchState " .. state)
    self.UiState = state
    for _, v in pairs(self.GameObjectGroup) do
        for _, go in pairs(v) do
            go:SetActive(false)
        end
    end

    for _, go in pairs(self.GameObjectGroup[state]) do
        go:SetActive(true)
    end

end

function XUiOnlineBoss:OnShowBossInfo(section)
    self:SwitchState(UiState.Info)
    self.BossInfoPanel:SetData(section)
    self.PanelBossInfoEnable:PlayTimelineAnimation()
end

function XUiOnlineBoss:OnEnterMatch(sectionId)
    self:SwitchState(UiState.Match)
    local sectionCfg = XDataCenter.FubenBossOnlineManager.GetActOnlineBossSectionById(sectionId)
    if sectionCfg then
        self.MatchPanel:Refresh(sectionCfg)
        self.PanelMatchEnable:PlayTimelineAnimation()
    end
end

function XUiOnlineBoss:OnCancelMatch()
    self.MatchPanel:OnCancelMatch()
end

function XUiOnlineBoss:EnterRoom()
    self.MatchPanel:ResetState()
end

--初始化模型
function XUiOnlineBoss:InitModel()
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelModel, self.Name, nil, true)
    self:RefreshModel()
end

--怪物模型&场景
function XUiOnlineBoss:RefreshModel()
    local bossData = XDataCenter.FubenBossOnlineManager.GetActOnlineBossSectionForDiff(self.CurDifficult)
    if bossData then
        local sectionTemplate = XDataCenter.FubenBossOnlineManager.GetActOnlineBossSectionById(bossData.BossId, self:UseLastTemplate())
        if sectionTemplate then
            self.SectionTemplate = sectionTemplate
            if self.Name == "UiOnlineBossActivity" then
                self:LoadScene(self.SectionTemplate.Scene)
            end
            self:LoadModel(self.SectionTemplate.ModelId)
        end
    end
end

function XUiOnlineBoss:RefreshBtnList()
    for k, v in pairs(self.TabList) do
        local diff = self.DifficultMap[k]
        if XDataCenter.FubenBossOnlineManager.CheckOnlineBossUnlock(diff) then
            if v.ButtonState == CS.UiButtonState.Disable then
                v.ButtonState = CS.UiButtonState.Normal
            end
        else
            v.ButtonState = CS.UiButtonState.Disable
        end
    end
end

function XUiOnlineBoss:PlayTxtAutoInvade()
    local count = CS.XGame.ClientConfig:GetInt("BossOnlineInvadeDescCount")
    local desc = {}
    for i = 1, count do
        desc[i] = CS.XTextManager.GetText("BossOnlineInvade" .. i)
    end

    local delay = 0
    local interval = CS.XGame.ClientConfig:GetInt("BossOnlineInvadeInterval")
    local wait = CS.XGame.ClientConfig:GetInt("BossOnlineInvadeWait")
    for _, v in ipairs(desc) do
        local str = v
        local chartab = string.CharsConvertToCharTab(str)
        local length = #chartab
        XScheduleManager.ScheduleOnce(function()
            if not self.GameObject or not self.GameObject:Exist() then
                return
            end
            XUiHelper.ShowCharByTypeAnimation(self.TxtAutoInvade, str, interval)
        end, delay)
        delay = delay + length * interval + wait
    end

    XScheduleManager.ScheduleOnce(function()
        if not self.GameObject or not self.GameObject:Exist() then
            return
        end
        local defaultIdx = self.DefaultIndex or 1
        self.TxtAutoInvade.gameObject:SetActive(false)
        self.InvadeEndEffect:PlayTimelineAnimation(function()
            XLuaUiManager.PopThenOpen("UiOnlineBossActivity", defaultIdx, true)
        end)
        self.DefaultIndex = nil
    end, delay)
end

function XUiOnlineBoss:SetDifficult(difficult)
    self.CurDifficult = difficult
    local bossData = XDataCenter.FubenBossOnlineManager.GetActOnlineBossSectionForDiff(self.CurDifficult)
    local sectionCfg = XDataCenter.FubenBossOnlineManager.GetActOnlineBossSectionById(bossData.BossId, self:UseLastTemplate())
    self.StageId = sectionCfg.StageId
end

--加载模型
function XUiOnlineBoss:LoadModel(modelId)
    if not self.RoleModelPanel then
        return
    end

    self.ImgEffectHuanren.gameObject:SetActive(false)
    self.ImgEffectHuanren.gameObject:SetActive(true)
    self.RoleModelPanel:SetDefaultAnimation(self.SectionTemplate.Animation)
    self.RoleModelPanel:UpdateBossModel(modelId, XModelManager.MODEL_UINAME.XUiOnlineBoss, nil, function(model)
        local animator = model:GetComponent("Animator")
        if animator then
            self.CurAnimator = animator
        end
    end)
    self.PanelModel.gameObject:SetActive(false)
    self.PanelModel.gameObject:SetActive(true)
end

--加载场景
function XUiOnlineBoss:LoadScene(sceneUrl)
    local scene = self.ScenePool[sceneUrl]
    if not scene then
        scene = XModelManager.LoadSceneModel(sceneUrl, self.SceneCase, self.Name)
        self.ScenePool[sceneUrl] = scene
    end

    if self.CurScene then
        self.CurScene.gameObject:SetActive(false)
    end

    scene.gameObject:SetActive(true)
    self.CurScene = scene
end

--加载特效
function XUiOnlineBoss:LoadEffect()
end

return XUiOnlineBoss
