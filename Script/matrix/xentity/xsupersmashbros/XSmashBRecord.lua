---@class XSmashBRecord
local XSmashBRecord = XClass(nil, "XSmashBRecord")

function XSmashBRecord:Ctor(mode, result, index)
    ---@type XSmashBMode
    self._Mode = mode
    self._Result = result
    self._Index = index
end

function XSmashBRecord:GetTeamMaxPosition()
    return 1
end

function XSmashBRecord:CheckIsStart()
    return false
end

function XSmashBRecord:GetEnemyTeam()
    return self._Result.MonsterGroupIdList
end

function XSmashBRecord:GetBattleEnemyIndex()
    return 1
end

function XSmashBRecord:GetMonsterBattleNum()
    return 1
end

function XSmashBRecord:GetIsLinearStage()
    return self._Mode:GetIsLinearStage()
end

-- always true
function XSmashBRecord:GetLastWin()
    return true
end

function XSmashBRecord:GetIsLinearStage()
    return self._Mode:GetIsLinearStage()
end

function XSmashBRecord:GetNextEnemy()
    return self._Mode:GetNextEnemy()
end

function XSmashBRecord:GetBattleEnemyIndex()
    return 1
end

function XSmashBRecord:GetMonsterBattleNum()
    return 1
end

function XSmashBRecord:IsCanChangeStage()
    return false
end

function XSmashBRecord:GetId()
    return self._Mode:GetId()
end

function XSmashBRecord:GetRoleMaxPosition()
    return 1
end

function XSmashBRecord:GetBattleTeam()
    local lastOne = #self._Result.CharacterResultList
    return { self._Result.CharacterResultList[lastOne].CharacterId }
end

function XSmashBRecord:GetBattleCharaIndex()
    return 1
end

function XSmashBRecord:GetRoleBattleNum()
    return 1
end

function XSmashBRecord:GetRoleRandomStartIndex()
    return self._Mode:GetRoleRandomStartIndex()
end

function XSmashBRecord:GetLineProgress()
    return XUiHelper.GetText("SSBMainPointGetText", self._Index, #self._Mode.AllStageId)
end

function XSmashBRecord:IsCanReady()
    return false
end

function XSmashBRecord:FindCharacterAlive()
    for i = 1, #self._Result.CharacterResultList do
        local character = self._Result.CharacterResultList[i]
        if character.HpPercent > 0 then
            return character
        end
    end
    return self._Result.CharacterResultList[#self._Result.CharacterResultList]
end

function XSmashBRecord:GetCharacterHpLeft()
    local character = self:FindCharacterAlive()
    return character and character.HpPercent or 0
end

function XSmashBRecord:GetCharacterIcon()
    local character = self:FindCharacterAlive()
    local characterId = character and character.CharacterId
    characterId = XRobotManager.GetCharacterId(characterId)
    if not characterId then
        return false
    end
    return XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId)
end

function XSmashBRecord:GetAbility()
    local character = self:FindCharacterAlive()
    local characterId = character and character.CharacterId
    if not characterId then
        return 0
    end
    local role = XDataCenter.SuperSmashBrosManager.GetRoleById(characterId)
    return role:GetAbility()
end

return XSmashBRecord