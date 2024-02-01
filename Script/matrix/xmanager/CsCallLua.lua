local Fuben = {}
local Character = {}
local DlcFuben = {}
local Player = {}

function Fuben.CheckSettleFight()
    return XDataCenter.FubenManager.CheckSettleFight()
end

function Fuben.GetStageRebootId(stageId)
    return XDataCenter.FubenManager.GetStageRebootId(stageId)
end

function Fuben.GetStageBgmId(stageId)
    return XDataCenter.FubenManager.GetStageBgmId(stageId)
end

function Fuben.GetStageAmbientSound(stageId)
    return XDataCenter.FubenManager.GetStageAmbientSound(stageId)
end

function Fuben.GetStageOnlineMsgId(stageId)
    return XDataCenter.FubenManager.GetStageOnlineMsgId(stageId)
end

function Fuben.GetStageForceAllyEffect(stageId)
    return XDataCenter.FubenManager.GetStageForceAllyEffect(stageId)
end

function Fuben.GetStageResetHpCounts(stageId)
    return XDataCenter.FubenManager.GetStageResetHpCounts(stageId)
end

function Fuben.GetAssistTemplateInfo()
    return XDataCenter.FubenManager.GetAssistTemplateInfo()
end

function Character.GetFightCharHeadIcon(character, characterId)
    return XMVCA.XCharacter:GetFightCharHeadIcon(character, characterId)
end

function Character.GetCharSmallHeadIconByCharacter(character)
    return XMVCA.XCharacter:GetCharSmallHeadIconByCharacter(character)
end

function Character.GetCharacter(id)
    return XMVCA.XCharacter:GetCharacter(id)
end

function Character.GetCharacterNpcDic(id)
    return XMVCA.XCharacter:GetCharacterNpcDic(id)
end

function Character.GetCharacterIdByNpcId(id)
    return XMVCA.XCharacter:GetCharacterIdByNpcId(id)
end

function DlcFuben.GetWorldType(worldId)
    return XMVCA.XDlcWorld:GetWorldTypeById(worldId)
end

function Player.GetLevel()
    return XPlayer.GetLevel()
end

CsCallLua = {}
CsCallLua.Fuben = Fuben
CsCallLua.Character = Character
CsCallLua.DlcFuben = DlcFuben
CsCallLua.Player = Player