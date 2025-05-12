local XTeam = require("XEntity/XTeam/XTeam")
local XComboList = require("XEntity/XBiancaTheatre/Combo/XTheatreComboList")
---@class XTheatreTeam : XTeam
local XTheatreTeam = XClass(XTeam, "XTheatreTeam")

function XTheatreTeam:Ctor()
    XTheatreTeam.Super.Ctor(self)
    self:InitComboList()
end

--############### 羁绊相关 begin ############
--初始化队伍羁绊列表
function XTheatreTeam:InitComboList()
    self.ComboList = XComboList.New(self)
end

--刷新Combo状态
function XTheatreTeam:CheckCombos()
    self.ComboList:CheckCombos(self.TeamChara)
end

function XTheatreTeam:GetAllCombos()
    return self.ComboList
end
--############### 羁绊相关 end ############

-- 获取当前队伍的角色类型
function XTheatreTeam:GetCharacterType()
    if self.CustomCharacterType then
        return self.CustomCharacterType
    end
    local entityId = nil
    for _, value in pairs(self.EntitiyIds) do
        if value > 0 then
            entityId = value
            break
        end
    end
    if entityId == nil then
        return XEnumConst.CHARACTER.CharacterType.Normal
    end
    local role = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetRole(entityId)
    if role == nil then return XEnumConst.CHARACTER.CharacterType.Normal end
    return role:GetCharacterViewModel():GetCharacterType()
end

--获得队伍队长技描述
function XTheatreTeam:GetCaptainSkillDesc()
    local entityId = self:GetCaptainPosEntityId()
    if not XTool.IsNumberValid(entityId) then
        return ""
    end

    local currRoles = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentRoles(true)
    local role = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetRole(entityId)
    if not role then
        return ""
    end

    local rawId = role:GetRawDataId()
    return role:GetIsLocalRole() and XMVCA.XCharacter:GetCaptainSkillDesc(rawId) or XRobotManager.GetRobotCaptainSkillDesc(rawId)
end

--设置多队伍的队伍下标
function XTheatreTeam:SetTeamIndex(teamIndex)
    self.TeamIndex = teamIndex
end

function XTheatreTeam:GetTeamIndex()
    return self.TeamIndex
end

return XTheatreTeam