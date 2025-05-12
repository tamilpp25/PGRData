local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--region ClassDesc
---@class XUiGuildDormMusicPlayer
---@field CurrAudioInfo CriMana.AudioInfo
---@field CurrCueId number
---@field RoomId number
---@field BgmIds number[]
---@field TxtMusicDesc UnityEngine.UI.Text
---@field TxtMusicName UnityEngine.UI.Text
---@field RImgCdFace UnityEngine.UI.RawImage
---@field RImgCdFaceBg UnityEngine.UI.RawImage
---
local XUiGuildDormMusicPlayer = XLuaUiManager.Register(XLuaUi, "UiGuildDormMusicPlayer")
local XUiPanelMusicSpectrum = require("XUi/XUiMusicPlayer/XUiPanelMusicSpectrum")
local ScheduleIntervalTime = CS.XGame.ClientConfig:GetInt("MusicPlayerSpectrumIntervalTime")
local CSXAudioManager = CS.XAudioManager
local DOTween = CS.DG.Tweening.DOTween
local MusicPlayerTextMoveSpeed = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMoveSpeed")
local MusicPlayerTextMovePauseInterval = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMovePauseInterval")

function XUiGuildDormMusicPlayer:OnStart()
    self:InitDynamicTable()
    self:InitButtonEvent()
    self:InitPlayedBgmInfo()
    self:SetupDynamicTable()
    local dict = {}
    dict["button"] = XGlobalVar.BtnGuildDormMain.BtnMusicInteract
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200006", "GuildDorm")
    self.PanelSpectrum = XUiPanelMusicSpectrum.New(self.PanelLeftBar)
    self.AnimEnable = self:FindTransform("AnimEnable")
    self.RoundEffectEnable = self:FindTransform("RoundEffectEnable"):GetComponent("PlayableDirector")
    self.RoundEffectLoop = self:FindTransform("RoundEffectLoop"):GetComponent("PlayableDirector")
    self.EffectLoop = self:FindTransform("EffectLoop"):GetComponent("PlayableDirector")
    self.EffectEnable = self:FindTransform("EffectEnable"):GetComponent("PlayableDirector")
    self:UpdateSpectrum()
    self:UpdateMusicAnim()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_SHOW, false)
    self.BtnEditEventId = XRedPointManager.AddRedPointEvent(self.BtnEdit, self.OnClickBtnEditRedPoint, self, { XRedPointConditions.Types.CONDITION_GUILD_DORM_BGM })
end

function XUiGuildDormMusicPlayer:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_PLAY_BGM, self.OnPlayCallBack, self)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_UPDATE_BGM_LIST, self.RefreshBgmList, self)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_UPDATE_MUSIC, self.PlayNextBgm, self)
    XUiHelper.RegisterHelpButton(self.BtnHelp, "GuildDormMusicPlayer")
    self.AnimEnable:PlayTimelineAnimation(nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.None)
    self.RoundEffectEnable.gameObject:SetActiveEx(false)
    self.RoundEffectEnable.gameObject:SetActiveEx(true)
    self.RoundEffectLoop:Stop()
    self.RoundEffectEnable.transform:PlayTimelineAnimation(function(isFinish) self:OnPlayEnableFinish(isFinish)  end)
    self.EffectEnable.transform:PlayTimelineAnimation(function(isFinish) self:OnPlayEffectEnableFinish(isFinish)  end)
end

function XUiGuildDormMusicPlayer:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_PLAY_BGM, self.OnPlayCallBack, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_UPDATE_BGM_LIST, self.RefreshBgmList, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_UPDATE_MUSIC, self.PlayNextBgm, self)
end

function XUiGuildDormMusicPlayer:OnDestroy()
    if self.ScheduleId then
        XScheduleManager.UnSchedule(self.ScheduleId)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ROLE_INTERACT_SHOW, true)
    XRedPointManager.RemoveRedPointEvent(self.BtnEditEventId)
end

function XUiGuildDormMusicPlayer:OnPlayEnableFinish(isFinish)
    if not isFinish then return end
    self.RoundEffectLoop:Evaluate()
    self.RoundEffectLoop:Play()
end

function XUiGuildDormMusicPlayer:OnPlayEffectEnableFinish(isFinish)
    if not isFinish then return end
    self.EffectLoop:Evaluate()
    self.EffectLoop:Play()
end

function XUiGuildDormMusicPlayer:RefreshBgmList()
    self:SetupDynamicTable()
    self:InitPlayedBgmInfo()
end
function XUiGuildDormMusicPlayer:PlayNextBgm()
    self:PlayAnimation("QieHuan")
    self:SetupDynamicTable()
    self:InitPlayedBgmInfo()
end

function XUiGuildDormMusicPlayer:OnPlayCallBack(cueId, grid, bgmCfg)
    ---@type XUiGridGuildDormMusic[]
    local grids = self.DynamicTable:GetGrids()
    for _, g in pairs(grids) do
        g:SetState(g == grid)
    end
    XDataCenter.GuildDormManager.PlayBgm(bgmCfg.Id)
    self:PlayAnimation("QieHuan")
    XEventManager.DispatchEvent(XEventId.EVENT_DORM_UPDATE_MUSIC)
    self:InitPlayedBgmInfo()
    self:UpdateSpectrum()
    self:UpdateMusicAnim()
end

function XUiGuildDormMusicPlayer:InitPlayedBgmInfo()
    local bgmId = XDataCenter.GuildDormManager.GetPlayedBgmId()
    local bgmCfg = XGuildDormConfig.GetBgmCfgById(bgmId)
    self.CueId = bgmCfg.CueId
    self.TxtMusicName.text = bgmCfg.Name
    self.TxtMusicDesc.text = bgmCfg.Desc
    self.RImgCdFace:SetRawImage(bgmCfg.Image)
    if not string.IsNilOrEmpty(bgmCfg.BgImage) then
        self.RImgCdFaceBg:SetRawImage(bgmCfg.BgImage)
    end
end

function XUiGuildDormMusicPlayer:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(require("XUi/XUiGuildDorm/MusicPlayer/XUiGridGuildDormMusic"))
end

function XUiGuildDormMusicPlayer:SetupDynamicTable()
    self.BgmIds = XDataCenter.GuildDormManager.GetBgmIds()
    self.DynamicTable:SetDataSource(self.BgmIds)
    self.DynamicTable:ReloadDataASync()
end

function XUiGuildDormMusicPlayer:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.BgmIds[index], index)
    end
end

function XUiGuildDormMusicPlayer:InitButtonEvent()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnEdit.CallBack = function()
        local dict = {}
        dict["button"] = XGlobalVar.BtnGuildDormMain.BtnMusicEdit
        dict["role_level"] = XPlayer.GetLevel()
        CS.XRecord.Record(dict, "200006", "GuildDorm")
        
        XDataCenter.GuildDormManager.SaveGuildDormBgmBtnFirst()
        XRedPointManager.Check(self.BtnEditEventId)
        if XDataCenter.GuildManager.IsGuildLeader() or XDataCenter.GuildManager.IsGuildCoLeader() then
            XLuaUiManager.Open("UiGuildMusicEdit")
        else
            XUiManager.TipText("GuildDormMusicPlayerEditTip")
        end
    end
    self.BtnEdit.gameObject:SetActiveEx(XDataCenter.GuildManager.IsGuildLeader() or XDataCenter.GuildManager.IsGuildCoLeader())
end

function XUiGuildDormMusicPlayer:UpdateSpectrum()
    if self.ScheduleId then
        XScheduleManager.UnSchedule(self.ScheduleId)
        self.ScheduleId = nil
    end
    self.ScheduleId = XScheduleManager.ScheduleForever(function()
        local spectrumData = CSXAudioManager.GetSpectrumLvData()
        self.PanelSpectrum:UpdateSpectrum(spectrumData)
    end, ScheduleIntervalTime, 0)
end

function XUiGuildDormMusicPlayer:UpdateMusicAnim()
    if self.TweenSequenceTxtMusicPlayer then
        self.TweenSequenceTxtMusicPlayer:Kill()
    end
    local txtDescWidth = XUiHelper.CalcTextWidth(self.TxtMusicDesc)
    local txtNameWidth = XUiHelper.CalcTextWidth(self.TxtMusicName)
    local txtWidth = txtDescWidth + txtNameWidth
    local maskWidth = self.TxtMusicDesc.transform.parent.sizeDelta.x
    local txtDescTransform = self.TxtMusicDesc.transform
    if txtWidth < maskWidth then
        txtDescTransform.localPosition = Vector3.zero
        return
    end
    local txtLocalPosition = txtDescTransform.localPosition
    txtDescTransform.localPosition = Vector3(maskWidth, txtLocalPosition.y, txtLocalPosition.z)
    local distance = txtWidth + maskWidth
    local sequence = DOTween.Sequence()
    self.TweenSequenceTxtMusicPlayer = sequence
    sequence:Append(txtDescTransform:DOLocalMoveX(-txtWidth, distance / MusicPlayerTextMoveSpeed))
    sequence:AppendInterval(MusicPlayerTextMovePauseInterval)
    sequence:SetLoops(-1)
end

function XUiGuildDormMusicPlayer:OnClickBtnEditRedPoint(count)
    -- 首次进入显示红点
    local isFirst = XDataCenter.GuildDormManager.GetGuildDormBgmBtnFirst()
    self.BtnEdit:ShowReddot(count >= 0 or not isFirst)
end

return XUiGuildDormMusicPlayer
