local XTheatreTeam = require("XEntity/XBiancaTheatre/XTheatreTeam")
local XAdventureRole = require("XEntity/XBiancaTheatre/Adventure/XAdventureRole")

local type = type
local pairs = pairs
local ipairs = ipairs
local IsNumberValid = XTool.IsNumberValid
local tableInsert = table.insert
local clone = XTool.Clone

local Default = {
    _StageId = 0, --关卡Id
    _MultipleTeams = {}, --多队伍数据 XTheatreTeam
}

local GetCurrNode = function()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    return adventureManager:GetCurrentChapter():GetCurrentNode()
end

--多队伍编队管理
local XAdventureMultiDeploy = XClass(nil, "XAdventureMultiDeploy")

function XAdventureMultiDeploy:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

--是否已上阵相同型号角色
function XAdventureMultiDeploy:GetSameCharacterPos(characterId)
    if not IsNumberValid(characterId) then return false end

    local isSame, pos
    for _, team in pairs(self._MultipleTeams) do
        isSame, pos = team:CheckHasSameCharacterId(characterId)
        if isSame then
            return pos
        end
    end
end

--获取一支队伍已上阵成员总战力
function XAdventureMultiDeploy:GetTeamAbility(teamId)
    local team = self._MultipleTeams[teamId]
    if not team then
        return 0
    end

    return team:GetAbility()
end

--自动编队
--先确定梯队上阵属性：按照物理->火->授格者->雷->冰->暗的顺序
--给该梯队上阵角色，如梯队为物理，按物理输出型->物理装甲型->物理辅助型->物理异格型的顺序上阵角色
function XAdventureMultiDeploy:AutoTeam(teamList)
    -- 正在使用的角色id字典
    local usingCharacterIdDic = {}
    -- 各队伍的属性
    local teamElementList = {}

    local manager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local roleElementList = manager:GetCurrentRoles()
    local roleCareerList = manager:GetCurrentRoles(true)

    for i, team in ipairs(teamList) do
        --已经压制成功的不清理
        if self:GetMultipleTeamIsWin(i) then
            local entityIds = team:GetEntityIds()
            for _, entityId in ipairs(entityIds) do
                local role = manager:GetRole(entityId)
                if role then
                    usingCharacterIdDic[XEntityHelper.GetCharacterIdByEntityId(role:GetCharacterId())] = true
                end
            end
        else
            team:Clear()
        end
    end

    --按角色属性排序
    table.sort(roleElementList, function(roleA, roleB)
        local characterIdA = roleA:GetCharacterId()
        local characterIdB = roleB:GetCharacterId()
        if characterIdA ~= characterIdB then
            local elementSortOrderA = roleA:GetMinSortOrderElementId(nil)
            local elementSortOrderB = roleB:GetMinSortOrderElementId(nil)
            if not elementSortOrderA then
                return false
            end
            if not elementSortOrderB then
                return true
            end
            if elementSortOrderA ~= elementSortOrderB then
                return elementSortOrderA < elementSortOrderB
            end
        end
        return roleA:GetId() < roleB:GetId()
    end)

    --按职业类型排序
    table.sort(roleCareerList, function(roleA, roleB)
        local characterIdA = roleA:GetCharacterId()
        local characterIdB = roleB:GetCharacterId()
        if characterIdA ~= characterIdB then
            local theatreSortOrderA = XBiancaTheatreConfigs.GetTheatreAutoTeamCareerSortOrder(nil, roleA:GetCareerType())
            local theatreSortOrderB = XBiancaTheatreConfigs.GetTheatreAutoTeamCareerSortOrder(nil, roleB:GetCareerType())
            if theatreSortOrderA ~= theatreSortOrderB then
                return theatreSortOrderA < theatreSortOrderB
            end
        end

        local abilityA = roleA:GetAbility()
        local abilityB = roleB:GetAbility()
        if abilityA ~= abilityB then
            return abilityA > abilityB
        end

        return roleA:GetId() > roleB:GetId()
    end)

    local isomerSortOrder = XBiancaTheatreConfigs.GetTheatreAutoTeamElementSortOrder(nil, nil, true)
    local characterId
    for i, team in ipairs(teamList) do
        if self:GetMultipleTeamIsWin(i) then
            goto continue
        end

        --确定梯队上阵属性和队伍类型
        local elementId, isomer
        for _, role in ipairs(roleElementList) do
            if not usingCharacterIdDic[role:GetCharacterId()] then
                isomer = role:GetCharacterType() == XEnumConst.CHARACTER.CharacterType.Isomer
                elementId = role:GetMinSortOrderElementId()
                break
            end
        end

        if not elementId and not isomer then
            goto continue
        end

        --按职业类型优先级上阵和队伍属性相同的角色，授格者不看队伍属性
        local teamPos = 1
        for _, role in ipairs(roleCareerList) do
            if not usingCharacterIdDic[role:GetCharacterId()] then
                if (isomer and role:GetCharacterType() == XEnumConst.CHARACTER.CharacterType.Isomer) or
                    (not isomer and role:GetCharacterType() == XEnumConst.CHARACTER.CharacterType.Normal and role:IsSameElement(nil, elementId)) then
                        team:UpdateEntityTeamPos(role:GetId(), teamPos, true)
                        usingCharacterIdDic[role:GetCharacterId()] = true
                        teamPos = teamPos + 1
                end
            end

            if team:GetIsFullMember() then
                break
            end
        end

        :: continue ::
    end

    --队伍未满角色，且有角色可上阵，铺满
    for i, team in ipairs(teamList) do
        if self:GetMultipleTeamIsWin(i) or team:GetIsFullMember() then
            goto continue
        end

        for _, role in ipairs(roleCareerList) do
            if not usingCharacterIdDic[role:GetCharacterId()] then
                for teamPos, entityId in ipairs(team:GetEntityIds()) do
                    if not XTool.IsNumberValid(entityId) then
                        team:UpdateEntityTeamPos(role:GetId(), teamPos, true)
                        usingCharacterIdDic[role:GetCharacterId()] = true
                        break
                    end
                end
            end

            if team:GetIsFullMember() then
                break
            end
        end
        :: continue ::
    end
end

function XAdventureMultiDeploy:GetTeamList()
    return self._MultipleTeams
end

function XAdventureMultiDeploy:ClearTeam()
    for _, team in pairs(self._MultipleTeams) do
        team:Clear()
    end
    self._MultipleTeams = {}
end

--按照队伍要求人数裁剪多余的队伍
function XAdventureMultiDeploy:ClipMembers(requireTeamMember)
    local teamIndex
    for _, team in pairs(self._MultipleTeams) do
        teamIndex = team:GetTeamIndex() or 0
        if teamIndex > requireTeamMember then
            team:Clear()
        end
    end
end

function XAdventureMultiDeploy:GetTeamById(id)
    for _, team in pairs(self._MultipleTeams) do
        if team:GetId() == id then
            return team
        end
    end
end

function XAdventureMultiDeploy:GetMultipleTeamByIndex(index)
    local theatreTeam = self._MultipleTeams[index]
    if theatreTeam == nil then
        theatreTeam = XTheatreTeam.New("Theatre_Adventure_Multiple_Team" .. index)
        theatreTeam:SetTeamIndex(index)
        theatreTeam:Clear()
        theatreTeam:UpdateAutoSave(false)
        self._MultipleTeams[index] = theatreTeam
    end
    return theatreTeam
end

-- 检查多队伍列表是否为空
function XAdventureMultiDeploy:CheckMultipleTeamEmpty()
    for _, team in pairs(self._MultipleTeams) do
        if not team:GetIsEmpty() then
            return false
        end
    end
    return true
end

-- 获取多队伍指定index的队伍是否已经胜利
function XAdventureMultiDeploy:GetMultipleTeamIsWin(index)
    local node = GetCurrNode()
    if not node then
        return false
    end

    return node.IsStageFinish and node:IsStageFinish(index) or false
end

function XAdventureMultiDeploy:ResetMultiBattleFinishStage(index)
    local node = GetCurrNode()
    if not node then
        return
    end

    if node.ResetFinishStage then
        node:ResetFinishStage(index)
    end
end

--当前节点的所有关卡是否通关
function XAdventureMultiDeploy:IsAllFinished()
    local node = GetCurrNode()
    if not node then
        return true
    end

    local stageIds = node.GetStageIds and node:GetStageIds() or {}
    for i in ipairs(stageIds) do
        if not node:IsStageFinish(i) then
            return false
        end
    end
    return true
end

-- 获得下一关的下标
function XAdventureMultiDeploy:GetNextBattleIndex()
    local notNextIndex = 0
    local node = GetCurrNode()
    if not node then
        return notNextIndex
    end

    local stageIds = node.GetStageIds and node:GetStageIds()
    for i in ipairs(stageIds or {}) do
        if not self:GetMultipleTeamIsWin(i) then
            return i
        end
    end

    return notNextIndex
end

-- 角色是否在其他队伍中
-- checkEntityId: XAdventureRoleId
-- isCheckSameRole: 是否检查相同的角色
-- 返回是否在其他队伍中, 所在队伍的下标, 在队伍中的几号位
function XAdventureMultiDeploy:IsInOtherTeam(teamId, checkEntityId, isCheckSameRole)
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local role = adventureManager:GetRole(checkEntityId)
    if not role then
        return false, 0, 0
    end

    local teamList = self:GetTeamList()
    local isInTeam, pos
    local otherTeamRole
    for _, otherTeam in pairs(teamList) do
        if otherTeam:GetId() ~= teamId then
            isInTeam, pos = otherTeam:GetEntityIdIsInTeam(checkEntityId)
            
            if isCheckSameRole and not isInTeam then
                for pos, entityId in ipairs(otherTeam:GetEntityIds()) do
                    otherTeamRole = adventureManager:GetRole(entityId)
                    if otherTeamRole and otherTeamRole:GetCharacterId() == role:GetCharacterId() then
                        return true, otherTeam:GetTeamIndex(), pos
                    end
                end
            end

            if otherTeam:GetId() ~= teamId and isInTeam then
                return true, otherTeam:GetTeamIndex(), pos
            end
        end
    end
    return false, 0, 0
end

-- 请求设置多队伍
function XAdventureMultiDeploy:RequestSetMultiTeam(callback, theatreStageId)
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local stageCount = XBiancaTheatreConfigs.GetTheatreStageCount(theatreStageId)
    if not XTool.IsNumberValid(stageCount) then
        XLog.Error(string.format("肉鸽多队伍的关卡数量错误，stageCount：%s，theatreStageId：%s", stageCount, theatreStageId))
        return
    end

    local requestBody = {}
    requestBody.TeamDatas = {}
    local team
    for teamIndex = 1, stageCount do
        team = self:GetMultipleTeamByIndex(teamIndex)

        --检查队伍列表中所有需要的队伍是否均有队长/首发
        if not XTool.IsNumberValid(team:GetCaptainPosEntityId()) then
            XUiManager.TipText("StrongholdEnterFightTeamListNoCaptain")
            return
        end
        if not XTool.IsNumberValid(team:GetFirstFightPosEntityId()) then
            XUiManager.TipText("StrongholdEnterFightTeamListNoFirstPos")
            return
        end

        local cardIds, robotIds = adventureManager:GetCardIdsAndRobotIdsFromTeam(team)
        table.insert(requestBody.TeamDatas, {
            TeamIndex = teamIndex,
            CaptainPos = team:GetCaptainPos(),
            FirstFightPos = team:GetFirstFightPos(),
            CardIds = cardIds,
            RobotIds = robotIds,
        })
    end

    XNetwork.CallWithAutoHandleErrorCode("TheatreSetMultiTeamRequest", requestBody, function(res)
        if callback then callback() end
    end)
end

--多队伍重置
function XAdventureMultiDeploy:RequestTheatreMultiTeamReset(teamIndex, cb)
    XNetwork.CallWithAutoHandleErrorCode("TheatreMultiTeamResetRequest", {TeamIndex = teamIndex}, function(res)
        self:ResetMultiBattleFinishStage(teamIndex)
        if cb then
            cb()
        end
    end)
end

return XAdventureMultiDeploy