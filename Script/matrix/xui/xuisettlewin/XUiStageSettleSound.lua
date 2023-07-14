---@class XUiStageSettleSound
local XUiStageSettleSound = XClass(nil, "XUiStageSettleSound")

function XUiStageSettleSound:Ctor(rootUi, stageId, isWin)
    self.RootUi = rootUi
    self.StageId = stageId
    self.IsWin = isWin
    self:GetConfig()
end

function XUiStageSettleSound:GetConfig()
    -- 获取默认的Sound
    local defaultSoundIds = self.IsWin and XFubenConfigs.GetStageSettleWinSoundId() or XFubenConfigs.GetStageSettleLoseSoundId()
    -- 获取特殊的Bgm
    local specialSoundIds
    local config = XFubenConfigs.GetSettleSpecialSoundCfgByStageId(self.StageId)
    if not XTool.IsTableEmpty(config) then
        specialSoundIds = self.IsWin and config.WinSoundId or config.LoseSoundId
    end

    self.SoundIds = {}
    if XTool.IsTableEmpty(specialSoundIds) then
        for i, v in pairs(defaultSoundIds or {}) do
            self.SoundIds[i] = tonumber(v)
        end
    else
        self.SoundIds = specialSoundIds
    end
end

function XUiStageSettleSound:PlaySettleSound()
    if XTool.IsTableEmpty(self.SoundIds) then
        return
    end
    for _, soundId in pairs(self.SoundIds) do
        XSoundManager.PlaySoundByType(soundId, XSoundManager.SoundType.Sound)
    end
end

function XUiStageSettleSound:StopSettleSound()
    if XTool.IsTableEmpty(self.SoundIds) then
        return
    end
    for _, soundId in pairs(self.SoundIds) do
        XSoundManager.Stop(soundId)
    end
    self.SoundIds = {}
end

return XUiStageSettleSound