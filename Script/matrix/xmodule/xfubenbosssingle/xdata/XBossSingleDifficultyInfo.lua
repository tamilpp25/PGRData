---@class XBossSingleDifficultyInfo
local XBossSingleDifficultyInfo = XClass(nil, "XBossSingleDifficultyInfo")

function XBossSingleDifficultyInfo:Ctor()
    self._BossName = ""
    self._BossIcon = ""
    self._BossDifficultyName = ""
    self._TagIcon = ""
    self._GroupId = 0
    self._GroupName = ""
    self._GroupIcon = ""
    self._IsHideBoss = false
end

function XBossSingleDifficultyInfo:SetBossName(value)
    self._BossName = value
end

function XBossSingleDifficultyInfo:GetBossName()
    return self._BossName
end

function XBossSingleDifficultyInfo:SetBossIcon(value)
    self._BossIcon = value
end

function XBossSingleDifficultyInfo:GetBossIcon()
    return self._BossIcon
end

function XBossSingleDifficultyInfo:SetBossDifficultyName(value)
    self._BossDifficultyName = value
end

function XBossSingleDifficultyInfo:GetBossDifficultyName()
    return self._BossDifficultyName
end

function XBossSingleDifficultyInfo:SetTagIcon(value)
    self._TagIcon = value
end

function XBossSingleDifficultyInfo:GetTagIcon()
    return self._TagIcon
end

function XBossSingleDifficultyInfo:SetGroupId(value)
    self._GroupId = value
end

function XBossSingleDifficultyInfo:GetGroupId()
    return self._GroupId
end

function XBossSingleDifficultyInfo:SetGroupName(value)
    self._GroupName = value
end

function XBossSingleDifficultyInfo:GetGroupName()
    return self._GroupName
end

function XBossSingleDifficultyInfo:SetGroupIcon(value)
    self._GroupIcon = value
end

function XBossSingleDifficultyInfo:GetGroupIcon()
    return self._GroupIcon
end

function XBossSingleDifficultyInfo:SetIsHideBoss(value)
    self._IsHideBoss = value
end

function XBossSingleDifficultyInfo:GetIsHideBoss()
    return self._IsHideBoss
end

return XBossSingleDifficultyInfo