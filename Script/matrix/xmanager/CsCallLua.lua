local Fuben = {}
local Character = {}

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

CsCallLua = {}
CsCallLua.Fuben = Fuben
CsCallLua.Character = Character