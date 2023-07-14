local Vector3 = CS.UnityEngine.Vector3
local DOTween = CS.DG.Tweening.DOTween
local XUiGuildDormSpecialUiGrid = require("XUi/XUiGuildDorm/XUiGuildDormSpecialUiGrid")
local XUiGuildDormMusicGrid = XClass(XUiGuildDormSpecialUiGrid, "XUiGuildDormMusicGrid")
local MusicPlayerTextMoveSpeed = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMoveSpeed")
local MusicPlayerTextMovePauseInterval = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMovePauseInterval")

function XUiGuildDormMusicGrid:Ctor()
    self.TweenSequenceTxtMusicPlayer = nil
    XEventManager.AddEventListener(XEventId.EVENT_DORM_UPDATE_MUSIC, self.UpdateMusic, self)
    -- todo_gd 到时初始化读取正式名称
    self:UpdateMusic()
    -- 停止背景音乐 （暂停音乐后使用PlayMusicWithAnalyzer同一首音乐不会播放）
    CS.XAudioManager.StopMusic()
    local bgmId = XDataCenter.GuildDormManager.GetPlayedBgmId()
    XDataCenter.GuildDormManager.PlayBgm(bgmId)
end

function XUiGuildDormMusicGrid:UpdateMusic()
    if XTool.UObjIsNil(self.TxtMusicName) then
        XEventManager.RemoveEventListener(XEventId.EVENT_DORM_UPDATE_MUSIC, self.UpdateMusic, self)
        return
    end
    local bgmId = XDataCenter.GuildDormManager.GetPlayedBgmId()
    local bgmCfg = XGuildDormConfig.GetBgmCfgById(bgmId)
    self.TxtMusicName.text = bgmCfg.Name
    self:UpdateMusicAnim()
end

function XUiGuildDormMusicGrid:UpdateMusicAnim()
    if self.TweenSequenceTxtMusicPlayer then
        self.TweenSequenceTxtMusicPlayer:Kill()
    end
    if self.MaskMusicPlayer == nil then return end -- 防打包
    local txtDescWidth = XUiHelper.CalcTextWidth(self.TxtMusicDesc)
    local txtNameWidth = XUiHelper.CalcTextWidth(self.TxtMusicName)
    local txtWidth = txtDescWidth + txtNameWidth
    local maskWidth = self.MaskMusicPlayer.sizeDelta.x
    local txtDescTransform = self.TxtMusicDesc.transform
    local txtLocalPosition = txtDescTransform.localPosition
    txtDescTransform.localPosition = Vector3(maskWidth, txtLocalPosition.y, txtLocalPosition.z)
    local distance = txtWidth + maskWidth
    local sequence = DOTween.Sequence()
    self.TweenSequenceTxtMusicPlayer = sequence
    sequence:Append(txtDescTransform:DOLocalMoveX(-txtWidth, distance / MusicPlayerTextMoveSpeed))
    sequence:AppendInterval(MusicPlayerTextMovePauseInterval)
    sequence:SetLoops(-1) 
end

function XUiGuildDormMusicGrid:Destroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_UPDATE_MUSIC, self.UpdateMusic, self)
    XDataCenter.GuildDormManager.StopBgm()
    XUiGuildDormMusicGrid.Super.Destroy(self)
end

return XUiGuildDormMusicGrid