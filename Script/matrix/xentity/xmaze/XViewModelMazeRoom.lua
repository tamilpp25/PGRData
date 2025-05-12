---@class XViewModelMazeRoom
local XViewModelMazeRoom = XClass(nil, "XViewModelMazeRoom")

function XViewModelMazeRoom:Ctor()
end

function XViewModelMazeRoom:GetPlayerModelName()
    return XMazeConfig.GetPlayerModelName()
end

function XViewModelMazeRoom:GetPlayerName()
    return XPlayer.Name
end

function XViewModelMazeRoom:GetPartnerRobotId()
    return XDataCenter.MazeManager.GetPartnerRobotId()
end

function XViewModelMazeRoom:GetPartnerName()
    local robotId = self:GetPartnerRobotId()
    local characterId = XRobotManager.GetCharacterId(robotId)
    local name = XMVCA.XCharacter:GetCharacterName(characterId)
    return name
end

function XViewModelMazeRoom:IsSelectPartner()
    local robotId = self:GetPartnerRobotId()
    if robotId and robotId > 0 then
        return true
    end
    return false
end

function XViewModelMazeRoom:GetStageId()
    local robotId = self:GetPartnerRobotId()
    if not robotId or robotId == 0 then
        return false
    end
    return XMazeConfig.GetStageId(robotId)
end

function XViewModelMazeRoom:GetTicketNeedAmount()
    local stageId = self:GetStageId()
    -- 未选择角色
    if not stageId then
        return 1
    end
    local isPassed = XDataCenter.MazeManager.IsStagePassed(stageId)
    if isPassed then
        return 0
    end
    return 1
end

function XViewModelMazeRoom:GetTicketItemId()
    return XMazeConfig.GetTicketItemId()
end

function XViewModelMazeRoom:IsTicketEnough()
    local itemId = self:GetTicketItemId()
    local item = XDataCenter.ItemManager.GetItem(itemId)
    if not item then
        return false
    end
    local needAmount = self:GetTicketNeedAmount()
    return item.Count >= needAmount
end

function XViewModelMazeRoom:GetPassStageAmount()
    local amount = XDataCenter.MazeManager.GetPassedStageAmount()
    return amount
end

function XViewModelMazeRoom:GetPassStageAmount2QuickPass()
    local amount = XMazeConfig.GetPassStageAmount2QuickPass()
    return amount
end


function XViewModelMazeRoom:GetAllPartnerRobot()
    local result = XMazeConfig.GetAllPartnerRobot()
    return result
end

return XViewModelMazeRoom