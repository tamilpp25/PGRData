---@class XViewModelDlcHuntSettleLose
local XViewModelDlcHuntSettleLose = XClass(nil, "XViewModelDlcHuntSettleLose")

function XViewModelDlcHuntSettleLose:Ctor(worldId)
    self._WorldId = worldId
    self._Data = {
        ChapterName = "",
        DifficultyName = "",
        MemberAmount = 0,
        
    }
end

function XViewModelDlcHuntSettleLose:_GetWorldId()
    return self._WorldId
end

function XViewModelDlcHuntSettleLose:Update()
    local worldId = self:_GetWorldId()
    local chapterId = XDlcHuntWorldConfig.GetChapterId(worldId)
    self._Data.ChapterName = XDlcHuntWorldConfig.GetChapterName(chapterId)
    self._Data.DifficultyName = XDlcHuntWorldConfig.GetWorldDifficultyName(worldId)
    local loseTipId
    local isFail4FightingPowerNotEnough = false
    local isFail4Disband
    if not isFail4Disband and not isFail4FightingPowerNotEnough then
        loseTipId = XDlcHuntWorldConfig.GetWorldLostTipId(worldId)
    end
    if isFail4Disband then
        loseTipId = XDlcHuntConfigs.GetLoseTipIdDisband()
    end
    if isFail4FightingPowerNotEnough then
        loseTipId = XDlcHuntConfigs.GetLoseTipIdWeak()
    end
    local tipDescList = XFubenConfigs.GetTipDescList(loseTipId) 
    local skipIdList = XFubenConfigs.GetSkipIdList(loseTipId)
end

function XViewModelDlcHuntSettleLose:GetData()
    return self._Data
end

return XViewModelDlcHuntSettleLose