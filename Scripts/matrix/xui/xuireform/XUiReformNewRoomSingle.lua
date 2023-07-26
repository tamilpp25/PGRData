-- 已废弃
local XUiReformNewRoomSingle = {}

function XUiReformNewRoomSingle.InitEditBattleUi(uiNewRoomSingle)
    uiNewRoomSingle.BtnTeamPrefab.gameObject:SetActiveEx(false)
    uiNewRoomSingle.PanelCharacterLimit.gameObject:SetActiveEx(false)
end

function XUiReformNewRoomSingle.GetBattleTeamData()
    return XDataCenter.ReformActivityManager.GetFightTeam()
end

-- 当点击角色模型时
function XUiReformNewRoomSingle.HandleCharClick(uiNewRoomSingle, pos, stageId)
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(stageId)
    local memberGroup = baseStage:GetCurrentEvolvableStageGroup(XReformConfigs.EvolvableGroupType.Member)
    local teamData = baseStage:GetCurrentEvolvableStageTeamData()
    local sources = memberGroup:GetAllCanJoinTeamSources()
    local sourceInTeamDic = {}
    local sourceInTeam = nil
    local sourceIdWeightDic = {}
    for index, sourceId in ipairs(teamData.SourceIdsInTeam) do
        sourceInTeam = memberGroup:GetSourceById(sourceId)
        if sourceInTeam then
            sourceIdWeightDic[sourceId] = 100
            sourceInTeamDic[index] = sourceInTeam
        end
    end
    -- 在队伍里的默认在前排
    table.sort(sources, function(sourceA, sourceB)
        local aWeight = sourceIdWeightDic[sourceA:GetId()] or 1
        local bWeight = sourceIdWeightDic[sourceB:GetId()] or 1
        local aStarLevel = sourceA:GetStarLevel()
        local bStarLevel = sourceB:GetStarLevel()
        -- 不相等，说明在一个在队伍，一个在非队伍，队伍更大
        if aWeight ~= bWeight then
            return aWeight > bWeight
        else
            if aStarLevel == bStarLevel then
                return sourceA:GetId() < sourceB:GetId()
            else
                return aStarLevel > bStarLevel
            end
        end
    end)
    local characterTeamData = XTool.Clone(uiNewRoomSingle.CurTeam.TeamData)
    XLuaUiManager.Open("UiReformTeamUp", sources, sourceInTeamDic, pos, function(source, isJoin)
        if isJoin then
            teamData.SourceIdsInTeam[pos] = source:GetId()
            characterTeamData[pos] = XRobotManager.GetCharacterId(source:GetRobotId())
        else
            for i, value in ipairs(teamData.SourceIdsInTeam) do
                if value == source:GetId() then
                    teamData.SourceIdsInTeam[i] = 0
                    characterTeamData[i] = 0
                    break
                end
            end
        end
        baseStage:SaveCurrentEvolvableTeamData(teamData)
        uiNewRoomSingle:UpdateTeam(characterTeamData)
    end, function()
        uiNewRoomSingle:UpdateTeam(characterTeamData)
    end)
end

function XUiReformNewRoomSingle.GetRealCharData(uiNewRoomSingle, stageId)
    return XUiReformNewRoomSingle.GetRobotIds(stageId)
end

function XUiReformNewRoomSingle.GetRobotIds(stageId)
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(stageId)
    local memberGroup = baseStage:GetCurrentEvolvableStageGroup(XReformConfigs.EvolvableGroupType.Member)
    local teamData = baseStage:GetCurrentEvolvableStageTeamData()
    local result = {}
    local source = nil
    for _, sourceId in ipairs(teamData.SourceIdsInTeam) do
        source = memberGroup:GetSourceById(sourceId)
        if source then
            table.insert(result, source:GetRobotId())
        else
            table.insert(result, 0)
        end
    end
    return result
end

function XUiReformNewRoomSingle.CheckCanCharClick()
    return true
end

function XUiReformNewRoomSingle.GetIsHideSwitchFirstFightPosBtns()
    return false
end

function XUiReformNewRoomSingle.GetIsSaveTeamData()
    return false
end

function XUiReformNewRoomSingle.SwitchTeamPos(stageId, fromPos, toPos)
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(stageId)
    local teamData = baseStage:GetCurrentEvolvableStageTeamData()
    local fromId = teamData.SourceIdsInTeam[fromPos]
    teamData.SourceIdsInTeam[fromPos] = teamData.SourceIdsInTeam[toPos]
    teamData.SourceIdsInTeam[toPos] = fromId
    baseStage:SaveCurrentEvolvableTeamData(teamData)
end

function XUiReformNewRoomSingle.SetFirstFightPos(stageId, index)
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(stageId)
    local teamData = baseStage:GetCurrentEvolvableStageTeamData()
    teamData.FirstFightPos = index
    baseStage:SaveCurrentEvolvableTeamData(teamData)
end

function XUiReformNewRoomSingle.SetCaptainPos(stageId, index)
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(stageId)
    local teamData = baseStage:GetCurrentEvolvableStageTeamData()
    teamData.CaptainPos = index
    baseStage:SaveCurrentEvolvableTeamData(teamData)
end

function XUiReformNewRoomSingle.GetFirstFightPos(stageId)
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(stageId)
    return baseStage:GetCurrentEvolvableStageTeamData().FirstFightPos
end

function XUiReformNewRoomSingle.GetCaptainPos(stageId)
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(stageId)
    return baseStage:GetCurrentEvolvableStageTeamData().CaptainPos
end

function XUiReformNewRoomSingle.GetTeamCaptainId(stageId)
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(stageId)
    local teamData = baseStage:GetCurrentEvolvableStageTeamData()
    return teamData.SourceIdsInTeam[teamData.CaptainPos]
end

function XUiReformNewRoomSingle.GetTeamFirstFightId(stageId)
    local baseStage = XDataCenter.ReformActivityManager.GetBaseStage(stageId)
    local teamData = baseStage:GetCurrentEvolvableStageTeamData()
    return teamData.SourceIdsInTeam[teamData.FirstFightPos]
end

function XUiReformNewRoomSingle.GetIsCheckCaptainIdAndFirstFightId(stageId)
    return true
end

function XUiReformNewRoomSingle.GetAutoCloseInfo()
    local endTime = XDataCenter.ReformActivityManager.GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XDataCenter.ReformActivityManager.HandleActivityEndTime()
        end
    end
end

return XUiReformNewRoomSingle