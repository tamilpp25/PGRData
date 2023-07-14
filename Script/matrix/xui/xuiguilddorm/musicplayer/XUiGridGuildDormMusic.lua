---@class XUiGridGuildDormMusic
local XUiGridGuildDormMusic = XClass(nil, "XUiGridGuildDormMusic")

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

function XUiGridGuildDormMusic:Refresh(bgmId,index)
    self.BgmId = bgmId
    local bgmCfg = XGuildDormConfig.GetBgmCfgById(self.BgmId)
    self.CueId = bgmCfg.CueId
    self.TxtListMusicNameNormal.text = bgmCfg.Name
    self.TxtListMusicNamePlaying.text = bgmCfg.Name
    self.TxtListMusicDescNormal.text = bgmCfg.Desc
    self.TxtListMusicDescPlaying.text = bgmCfg.Desc
    self.TxtSerialNormal.text = string.format("%02d",index)
    self.TxtSerialPlaying.text = string.format("%02d",index)
    local playedBgm = XDataCenter.GuildDormManager.GetPlayedBgmId()
    local playedBgmCfg = XGuildDormConfig.GetBgmCfgById(playedBgm)
    self:SetState(playedBgmCfg.CueId == self.CueId)
    
    -- 体验中
    local isExperience = XDataCenter.GuildDormManager.CheckExperienceTimeIdByBgmId(self.BgmId)
    self.ImgAuditionNormal.gameObject:SetActiveEx(isExperience)
    self.ImgAuditionPlaying.gameObject:SetActiveEx(isExperience)
end

function XUiGridGuildDormMusic:SetState(isPlay)
    self.IsPlay = isPlay
    self.PanelNormal.gameObject:SetActiveEx(not isPlay)
    self.PanelPlaying.gameObject:SetActiveEx(isPlay)
end

return XUiGridGuildDormMusic
