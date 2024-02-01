---@class XTaikoMasterTeam
local XTaikoMasterTeam = XClass(nil, "XTaikoMasterTeam")

function XTaikoMasterTeam:Ctor(activityId)
    self._ActivityId = activityId
    self._Id = XEnumConst.TAIKO_MASTER.TEAM_ID
    self._TeamName = ""
    -- RobotId
    self._EntityIds = {0, 0, 0, 0}
    self._CaptainPos = 1
    self._FirstFightPos = 1
end

--region Checker
function XTaikoMasterTeam:CheckIsInTeam(robotId)
    for i, entityId in ipairs(self._EntityIds) do
        if entityId == robotId then
            return true
        end
    end
    return false
end
--endregion

--region Getter
function XTaikoMasterTeam:GetId()
    return self._Id
end

function XTaikoMasterTeam:GetName()
    return self._TeamName
end

function XTaikoMasterTeam:GetEntityIds()
    return self._EntityIds
end

function XTaikoMasterTeam:GetEntityId(index)
    return self._EntityIds[index]
end

function XTaikoMasterTeam:GetCaptainPos()
    return self._CaptainPos
end

function XTaikoMasterTeam:GetFirstFightPos()
    return self._FirstFightPos
end

function XTaikoMasterTeam:GetEntityCount()
    local result = 0
    for _, entityId in pairs(self._EntityIds) do
        if XTool.IsNumberValid(entityId) then
            result = result + 1
        end
    end
    return result
end
--endregion

--region Setter
function XTaikoMasterTeam:SwitchTeamPos(index, targetIndex)
    local temp = self._EntityIds[targetIndex] or 0
    self._EntityIds[targetIndex] = self._EntityIds[index] or 0
    self._EntityIds[index] = temp
    self:SaveTeam()
end

function XTaikoMasterTeam:SetEntityPos(index, entityId, isWithSave)
    self._EntityIds[index] = entityId
    if isWithSave then
        self:SaveTeam()
    end
end

---根据关卡限制人数处理队伍内多余角色
function XTaikoMasterTeam:SetTeamByNum(num)
    local result = 0
    local firstEmpty = 0
    local beChangePos = {}
    for i, entityId in pairs(self._EntityIds) do
        if XTool.IsNumberValid(entityId) then
            table.insert(beChangePos, entityId)
            result = result + 1
        else
            if firstEmpty == 0 then
                firstEmpty = i
            end
        end
    end
    -- 队伍过多中间有空则顺延
    if not XTool.IsTableEmpty(beChangePos) and (result >= num or firstEmpty <= num) then
        for i, _ in pairs(self._EntityIds) do
            self._EntityIds[i] = 0
        end
        for i, entityId in pairs(beChangePos) do
            if i <= num then
                self._EntityIds[i] = entityId
            end
        end
        self:SaveTeam()
    end
end
--endregion

function XTaikoMasterTeam:SaveTeam()
    --XDataCenter.TeamManager.RequestSaveTeam(self)
    local team = {
        _ActivityId = self._ActivityId,
        _EntityIds = self._EntityIds,
        _CaptainPos = self._CaptainPos,
        _FirstFightPos = self._FirstFightPos,
    }
    XSaveTool.SaveData(self:_GetCacheKey(), team)
end

function XTaikoMasterTeam:GetCacheTeam()
    return XSaveTool.GetData(self:_GetCacheKey())
end

function XTaikoMasterTeam:_GetCacheKey()
    return string.format("TaikoMasterTeamData_%s_PlayId_%s", self._ActivityId, XPlayer.Id)
end

function XTaikoMasterTeam:Copy(team)
    if XTool.IsTableEmpty(team) then
        return
    end
    self._EntityIds = team._EntityIds
    self._CaptainPos = team._CaptainPos
    self._FirstFightPos = team._FirstFightPos
end

return XTaikoMasterTeam