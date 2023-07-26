---@class XViewModelDlcHuntSettle
local XViewModelDlcHuntSettle = XClass(nil, "XViewModelDlcHuntSettle")

function XViewModelDlcHuntSettle:Ctor(settleData)
    self._Data = {
        ChapterName = "",
        DifficultyName = "",
        PassTime = "00:00",
        Players = {},
        CountDown = 10,
        MyDamage = 0,
        MyDamageToParts = 0,
        MyTimesReborn = 0,
        MyTimesSaveTeammate = 0,
        Rewards = {
            {
                ItemAmount = 0,
                Id = 0,
                Type = 0,
                Icon = 0,
            }
        }
    }
    self._WorldId = settleData.WorldId
    self._SettleData = settleData
end

function XViewModelDlcHuntSettle:_GetWorldId()
    return self._WorldId
end

function XViewModelDlcHuntSettle:Update()
    local worldId = self:_GetWorldId()
    local chapterId = XDlcHuntWorldConfig.GetChapterId(worldId)
    self._Data.ChapterName = XDlcHuntWorldConfig.GetChapterName(chapterId)
    self._Data.DifficultyName = XDlcHuntWorldConfig.GetWorldDifficultyName(worldId)
    local settleData = self._SettleData
    self.PassTime = XUiHelper.GetTime(settleData.PassTime)
    for i = 1, #settleData.Players do
        local playerId = 0
        local medals = { 1, 10, 21 }
        local medalData = {}
        for j = 1, #medals do
            local id = medals[i]
            local icon = XDlcHuntWorldConfig.GetBadgeIcon(id)
            local desc = XDlcHuntWorldConfig.GetBadgeDesc(id)
            medalData[j] = { Icon = icon, Desc = desc }
        end
        self.Players[1] = {
            Damage = 100,
            BreakParts = 1000,
            PlayerId = playerId,
            IsMySelf = playerId == XPlayer.Id,
            Medal = medalData,
        }
    end
end

function XViewModelDlcHuntSettle:GetData()
    return self._Data
end

return XViewModelDlcHuntSettle