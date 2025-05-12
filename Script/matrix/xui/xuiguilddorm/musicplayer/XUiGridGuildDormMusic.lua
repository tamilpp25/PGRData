---@class XUiGridGuildDormMusic
local XUiGridGuildDormMusic = XClass(nil, "XUiGridGuildDormMusic")

local DOTween = CS.DG.Tweening.DOTween
local MusicPlayerTextMoveSpeed = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMoveSpeed")
local MusicPlayerTextMovePauseInterval = CS.XGame.ClientConfig:GetFloat("MusicPlayerMainViewTextMovePauseInterval")

function XUiGridGuildDormMusic:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.IsPlay = false
    self:SetState(self.IsPlay)
    self.BtnPlay.CallBack = function()
        self:SetState(not self.IsPlay)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_PLAY_BGM, self.CueId, self, XGuildDormConfig.GetBgmCfgById(self.BgmId))
    end
end

function XUiGridGuildDormMusic:Refresh(bgmId, index)
    self.BgmId = bgmId
    local bgmCfg = XGuildDormConfig.GetBgmCfgById(self.BgmId)
    self.CueId = bgmCfg.CueId
    self.TxtListMusicNameNormal.text = bgmCfg.Name
    self.TxtListMusicNamePlaying.text = bgmCfg.Name
    self.TxtListMusicDescNormal.text = bgmCfg.Desc
    self.TxtListMusicDescPlaying.text = bgmCfg.Desc
    self.TxtSerialNormal.text = string.format("%02d", index)
    self.TxtSerialPlaying.text = string.format("%02d", index)
    local playedBgm = XDataCenter.GuildDormManager.GetPlayedBgmId()
    local playedBgmCfg = XGuildDormConfig.GetBgmCfgById(playedBgm)
    self:SetState(playedBgmCfg.CueId == self.CueId)

    -- 体验中
    local isExperience = XDataCenter.GuildDormManager.CheckExperienceTimeIdByBgmId(self.BgmId)
    self.ImgAuditionNormal.gameObject:SetActiveEx(isExperience)
    self.ImgAuditionPlaying.gameObject:SetActiveEx(isExperience)

    self:UpdateMusicTxtAnim()
end

function XUiGridGuildDormMusic:SetState(isPlay)
    self.IsPlay = isPlay
    self.PanelNormal.gameObject:SetActiveEx(not isPlay)
    self.PanelPlaying.gameObject:SetActiveEx(isPlay)
end

function XUiGridGuildDormMusic:UpdateMusicTxtAnim()
    if self.TweenSequenceMusicTxt then
        self.TweenSequenceMusicTxt:Kill()
    end
    local txtDesc = self.IsPlay and self.TxtListMusicDescPlaying or self.TxtListMusicDescNormal
    local txtDescWidth = XUiHelper.CalcTextWidth(txtDesc)
    local maskWidth = txtDesc.transform.parent.rect.width
    local txtDescTransform = txtDesc.transform
    if txtDescWidth < maskWidth then
        txtDescTransform.localPosition = Vector3.zero
        return
    end
    local txtLocalPosition = txtDescTransform.localPosition
    txtDescTransform.localPosition = Vector3(maskWidth, txtLocalPosition.y, txtLocalPosition.z)
    local duration = (txtDescWidth + maskWidth) / MusicPlayerTextMoveSpeed
    local sequence = DOTween.Sequence()
    self.TweenSequenceMusicTxt = sequence
    sequence:Append(txtDescTransform:DOLocalMoveX(-txtDescWidth, duration):SetEase(CS.DG.Tweening.Ease.Linear))
    sequence:AppendInterval(MusicPlayerTextMovePauseInterval)
    sequence:SetLoops(-1)
end

return XUiGridGuildDormMusic
