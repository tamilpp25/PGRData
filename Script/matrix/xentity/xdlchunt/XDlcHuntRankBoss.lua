---@class XDlcHuntRankBoss
local XDlcHuntRankBoss = XClass(nil, "XDlcHuntRankBoss")

function XDlcHuntRankBoss:Ctor()
    self._WorldId = false
    self._Data = false
end

function XDlcHuntRankBoss:GetPlayers()
    return {
        
    }
end

function XDlcHuntRankBoss:_GetWorldId()
    return self._WorldId
end

function XDlcHuntRankBoss:GetDifficultyName()
    return XDlcHuntWorldConfig.GetWorldDifficultyName(self:_GetWorldId())
end

function XDlcHuntRankBoss:GetPassTime()
    return XUiHelper.GetTime(self._Data.Name)
end

return XDlcHuntRankBoss