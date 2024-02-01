local XTeam = require("XEntity/XTeam/XTeam")
local XPartnerPrefab = require("XEntity/XPartner/XPartnerPrefab")
XTeamManagerCreator = function()
    ---@class XTeamManager XTeamManager
    local XTeamManager = {}

    local TeamDataKey = "STAGE_TEAM_DATA_"

    local MaxPos = CS.XGame.Config:GetInt("TeamMaxPos")   -- 默认一个队伍的位置数
    local CaptainPos -- 队长位
    local FirstFightPos -- 首发位
    local EmptyTeam = {
        TeamData = {},
        CaptainPos = 1,
        FirstFightPos = 1,
        -- 0表示仅保存在本地
        TeamId = 0,
    }

    local PlayerTeamGroupData = {}
    local PlayerTeamPrefabData = {}

    local METHOD_NAME = {
        SetTeam = "TeamSetTeamRequest",
        SetPrefabTeam = "TeamPrefabSetTeamRequest"
    }

    -- XTeam
    -- 缓存队伍数据
    local TeamDic = {}
    -- XTeam
    -- 缓存预设队伍数据
    local TeamPrefabDic = {}

    --SetTeamPos
    function XTeamManager.Init()
        CaptainPos = 0
        FirstFightPos = 0
        for _, cfg in pairs(XTeamConfig.GetTeamCfg()) do
            if cfg.IsCaptain and CaptainPos == 0 then
                CaptainPos = cfg.Id
            end

            if cfg.IsFirstFight and FirstFightPos == 0 then
                FirstFightPos = cfg.Id
            end
        end

        for i = 1, MaxPos do
            EmptyTeam.TeamData[i] = 0
        end
        --EmptyTeam = XReadOnlyTable.Create(EmptyTeam)
        XTeamManager.EmptyTeam = EmptyTeam
    end

    function XTeamManager.GetTeamId(typeId, stageId)
        local teams = XTeamConfig.GetTeamsByTypeId(typeId)
        if teams == nil then
            return nil
        end

        local sectionId = 0
        local chapterId = 0
        if stageId ~= nil then
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            sectionId = stageInfo.SectionId
            chapterId = stageInfo.ChpaterId
            if sectionId == nil or chapterId == nil then
                return nil
            end
        end

        -- 匹配规则：chapterId, sectionId, stageId 逐级查找，某一项为 nil 时，表示匹配上一级
        for _, val in pairs(teams) do
            if #val.ChapterId <= 0 then
                return val.TeamId         -- 匹配 TypeId
            end

            for _, cId in pairs(val.ChapterId) do
                if chapterId > 0 and cId == chapterId then
                    if #val.SectionId <= 0 then
                        return val.TeamId         -- 匹配 chapterId
                    end

                    for _, sId in pairs(val.SectionId) do
                        if sectionId > 0 and sId == sectionId then
                            if #val.StageId <= 0 then
                                return val.TeamId     -- 匹配 sectionId
                            end

                            for _, stId in pairs(val.StageId) do
                                if stId == stageId then
                                    return val.TeamId     -- 匹配 stageId
                                end
                            end
                        end
                    end
                end
            end
        end

        return nil
    end

    -- 玩家队伍中队长的位置Id
    -- 已废弃
    function XTeamManager.GetTeamCaptainKey(teamId)
        return teamId << 8
    end

    -- 已废弃
    function XTeamManager.GetValidPos(teamData)
        local posId = 1
        for k, v in pairs(teamData) do
            if v > 0 then
                posId = k
                break
            end
        end
        return posId
    end

    local function GetTeamKey(stageId)
        local info = XDataCenter.FubenManager.GetStageInfo(stageId)
        return string.format("%s%s_%d_%s", TeamDataKey, tostring(XPlayer.Id), info.Type, tostring(stageId))
    end

    -- 使用stageId作为Key本地保存编队信息
    function XTeamManager.SaveTeamLocal(curTeam, stageId)
        if not stageId then
            XLog.Warning("stageId is nil !!")
            return
        end
        XSaveTool.SaveData(GetTeamKey(stageId), curTeam)
    end

    -- 使用stageId作为Key读取本地编队信息
    function XTeamManager.LoadTeamLocal(stageId)
        if not stageId then
            XLog.Warning("stageId is nil")
            return EmptyTeam
        end

        local team = XSaveTool.GetData(GetTeamKey(stageId)) or EmptyTeam
        for _, v in ipairs(team.TeamData) do
            if v ~= 0 and not XRobotManager.CheckIsRobotId(v) and not XMVCA.XCharacter:IsOwnCharacter(v) then
                return EmptyTeam
            end
        end

        return team
    end

    -- 使用TeamSetTeamRequest协议保存使用TeamId的XTeamData
    function XTeamManager.SetPlayerTeam(curTeam, isPrefab, cb)
        local curTeamId = curTeam.TeamId
        if curTeamId == 0 then
            XTeamManager.SetPlayerTeamLocal(curTeam, isPrefab, cb)
            return
        end

        local params = {}
        params.TeamData = {}
        params.TeamId = curTeamId
        XMessagePack.MarkAsTable(params.TeamData)
        for k, v in pairs(curTeam.TeamData) do
            params.TeamData[k] = v
        end
        params.CaptainPos = curTeam.CaptainPos
        params.FirstFightPos = curTeam.FirstFightPos
        params.TeamName = curTeam.TeamName

        local methodName, req
        if isPrefab then
            local partnerPrefab = XTeamManager.GetPartnerPrefab(curTeamId)
            params.PartnerData = partnerPrefab:GetPartnerData()
            XMessagePack.MarkAsTable(params.PartnerData)
            methodName = METHOD_NAME.SetPrefabTeam
            req = { TeamPrefabData = params }
        else
            methodName = METHOD_NAME.SetTeam
            req = { TeamData = params }
        end

        --local req = { TeamData = params, IsPrefab = isPrefab }
        XNetwork.Call(methodName, req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XTeamManager.SetPlayerTeamLocal(curTeam, isPrefab, cb)
        end)
    end

    -- 更新TeamId的数据缓存，服务器的XTeamData只在登录的时候下发
    function XTeamManager.SetPlayerTeamLocal(curTeam, isPrefab, cb, saveXTeam)
        if saveXTeam == nil then saveXTeam = true end

        if saveXTeam then
            XTeamManager.SaveXTeam(curTeam.TeamId)
        end

        local curTeamId = curTeam.TeamId
        local characterCheckTable = {}

        local changeCharacter = {}      -- 更改成员的Id数组
        local playCvCharacterInfo = {}  -- 要播放语音的角色信息
        playCvCharacterInfo.Id = 0
        playCvCharacterInfo.IsCaptain = false

        -- 更改成员数，数量等于1，播放该角色的入队语音，数量大于等于2，只播放队长语音，没有队长就不播放语音
        local changeCount = 0

        local playerTeamData = isPrefab and PlayerTeamPrefabData or PlayerTeamGroupData
        -- 更新客户端队伍缓存
        if playerTeamData[curTeamId] == nil then
            playerTeamData[curTeamId] = {}
        else
            for _, characterId in pairs(playerTeamData[curTeamId].TeamData) do
                characterCheckTable[characterId] = true
            end

            for pos, characterId in pairs(curTeam.TeamData) do
                if (not characterCheckTable[characterId]) and (characterId ~= 0) then

                    changeCount = changeCount + 1
                    if pos == curTeam.CaptainPos then
                        playCvCharacterInfo.Id = characterId
                        playCvCharacterInfo.IsCaptain = true
                        break
                    end

                    table.insert(changeCharacter, characterId)
                end
            end

            -- 更改角色不是队长，但只更改了一个角色，播放该角色的入队语音
            if playCvCharacterInfo.Id == 0 and changeCount == 1 then
                playCvCharacterInfo.Id = changeCharacter[1]
            end

            XEventManager.DispatchEvent(XEventId.EVENT_TEAM_MEMBER_CHANGE, curTeamId, playCvCharacterInfo.Id, playCvCharacterInfo.IsCaptain)
        end
        playerTeamData[curTeamId].TeamId = curTeamId
        playerTeamData[curTeamId].CaptainPos = curTeam.CaptainPos
        playerTeamData[curTeamId].FirstFightPos = curTeam.FirstFightPos
        playerTeamData[curTeamId].TeamData = curTeam.TeamData
        playerTeamData[curTeamId].TeamName = curTeam.TeamName
        if isPrefab then
            playerTeamData[curTeamId].PartnerPrefab = XDataCenter.TeamManager.GetPartnerPrefab(curTeamId)
        end
        if cb then cb() end

        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, curTeamId, playerTeamData[curTeamId])
    end

    -- todo  特别优化
    --function XTeamManager.SetExpeditionTeamData(curTeam, cb)
    --    local curTeamId = curTeam.TeamId
    --    local params = {}
    --    params.TeamData = {}
    --    params.TeamId = curTeamId
    --    XMessagePack.MarkAsTable(params.TeamData)
    --    for k, v in pairs(curTeam.TeamData) do
    --        params.TeamData[k] = v
    --    end
    --    params.CaptainPos = curTeam.CaptainPos
    --    params.FirstFightPos = curTeam.FirstFightPos
    --    local req = { TeamData = params}
    --    XNetwork.Call(METHOD_NAME.SetTeam, req, function(res)
    --        if res.Code ~= XCode.Success then
    --            XUiManager.TipCode(res.Code)
    --            return
    --        end
    --        local characterCheckTable = {}
    --        local playerTeamData = PlayerTeamGroupData
    --        -- 更新客户端队伍缓存
    --        if playerTeamData[curTeamId] == nil then
    --            playerTeamData[curTeamId] = {}
    --        else
    --            for _, baseId in pairs(playerTeamData[curTeamId].TeamData) do
    --                characterCheckTable[baseId] = true
    --            end
    --
    --            for pos, baseId in pairs(curTeam.TeamData) do
    --                if not characterCheckTable[baseId] then
    --                    local charId = XExpeditionConfig.GetCharacterIdByBaseId(baseId)
    --                    XEventManager.DispatchEvent(XEventId.EVENT_TEAM_MEMBER_CHANGE, curTeamId, charId, pos == curTeam.CaptainPos)
    --                end
    --            end
    --        end
    --        playerTeamData[curTeamId].TeamId = curTeamId
    --        playerTeamData[curTeamId].CaptainPos = curTeam.CaptainPos
    --        playerTeamData[curTeamId].FirstFightPos = curTeam.FirstFightPos
    --        playerTeamData[curTeamId].TeamData = curTeam.TeamData
    --        playerTeamData[curTeamId].TeamName = curTeam.TeamName
    --
    --        if cb then cb() end
    --
    --        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_PREFAB_CHANGE, curTeamId, playerTeamData[curTeamId])
    --    end)
    --end

    function XTeamManager.GetPlayerTeamData(teamId)
        return PlayerTeamGroupData[teamId] or false
    end

    function XTeamManager.GetTeamData(teamId)
        local teamData = XTeamManager.GetXTeamEntityIds(teamId)
        if teamData then return teamData end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamCaptainPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        if PlayerTeamGroupData[teamId] ~= nil then
            teamData = PlayerTeamGroupData[teamId].TeamData
        end

        if teamData == nil or next(teamData) == nil then
            teamData = {}
            for i = 1, MaxPos do
                teamData[i] = 0
            end
        end
        return teamData
    end

    function XTeamManager.GetTeamCaptainPos(teamId)
        local captainPos = XTeamManager.GetXTeamCaptainPos(teamId)
        if captainPos then return captainPos end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamCaptainPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        captainPos = XTeamManager.GetCaptainPos()
        if PlayerTeamGroupData[teamId] ~= nil then
            captainPos = PlayerTeamGroupData[teamId].CaptainPos
        end
        return captainPos
    end

    ---==========================================
    --- 根据'teamId'得到当前的首发位置，中间是1，左边是2，右边是3
    --- 若第一次进入玩法，没有设置相应的'teamId‘数据，则初始位置为1
    ---@param teamId number
    ---@return number
    ---==========================================
    function XTeamManager.GetTeamFirstFightPos(teamId)
        local posId = XTeamManager.GetXTeamFirstFightPos(teamId)
        if posId then return posId end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        -- 初始位置为1
        posId = 1

        -- 是否设置过该teamId数据
        if PlayerTeamGroupData[teamId] ~= nil then
            posId = PlayerTeamGroupData[teamId].FirstFightPos
        end
        return posId
    end

    function XTeamManager.GetTeamCaptainId(teamId)
        local xTeam = XTeamManager.GetXTeam(teamId)
        if xTeam then
            return xTeam:GetCaptainPosEntityId()
        end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamCaptainId, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        if PlayerTeamGroupData[teamId] == nil then
            return nil
        end

        local captainPos = PlayerTeamGroupData[teamId].CaptainPos
        return PlayerTeamGroupData[teamId].TeamData[captainPos]
    end

    ---==========================================
    --- 根据'teamId'得到当前的首发位的角色Id
    ---@param teamId number
    ---@return number
    ---==========================================
    function XTeamManager.GetTeamFirstFightId(teamId)
        local xTeam = XTeamManager.GetXTeam(teamId)
        if xTeam then
            return xTeam:GetFirstFightPosEntityId()
        end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightId, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        if PlayerTeamGroupData[teamId] == nil then
            return nil
        end

        local firstFightPos = PlayerTeamGroupData[teamId].FirstFightPos
        return PlayerTeamGroupData[teamId].TeamData[firstFightPos]
    end

    -- 得到对应玩法的TeamId与Team数据
    -- stageId : 获取stageInfo后找到TeamType相匹配的TeamId
    function XTeamManager.GetPlayerTeam(typeId, stageId)
        local curTeamId = XTeamManager.GetTeamId(typeId, stageId)
        if curTeamId == nil then
            XLog.ErrorTableDataNotFound("XTeamManager.GetPlayerTeam", "curTeamId",
            TABLE_PATH, "typeId ：   stageId ：", tostring(typeId) .. tostring(stageId))
            return nil
        end

        local CurTeam = {
            ["TeamId"] = curTeamId,
            ["TeamData"] = XTeamManager.GetTeamData(curTeamId),
            ["CaptainPos"] = XTeamManager.GetTeamCaptainPos(curTeamId),
            ["FirstFightPos"] = XTeamManager.GetTeamFirstFightPos(curTeamId),
        }
        return CurTeam
    end

    function XTeamManager.CheckInTeam(characterId)
        local typeId = CS.XGame.Config:GetInt("TypeIdMainLine")
        local curTeamId = XTeamManager.GetTeamId(typeId)
        if curTeamId == nil then
            XLog.ErrorTableDataNotFound("XTeamManager.CheckInTeam", "curTeamId", TABLE_PATH, "typeId ：   stageId ：", tostring(typeId))
            return nil
        end

        local teamData = XTeamManager.GetTeamData(curTeamId)
        for _, v in pairs(teamData) do
            if characterId == v then
                return true
            end
        end
        return false
    end

    function XTeamManager.GetInTeamCheckTable()
        local inTeamCheckTable = {}

        local typeId = CS.XGame.Config:GetInt("TypeIdMainLine")
        local curTeamId = XTeamManager.GetTeamId(typeId)
        local teamData = XTeamManager.GetTeamData(curTeamId)
        for _, v in pairs(teamData) do
            if v > 0 then
                inTeamCheckTable[v] = true
            end
        end

        return inTeamCheckTable
    end

    -- 在NotifyLogin中获取队伍数据
    function XTeamManager.InitTeamGroupData(teamGroupData)
        if teamGroupData == nil then
            return
        end

        for key, value in pairs(teamGroupData) do
            local teamTemp = {}
            for teamDataKey, teamDataValue in pairs(value.TeamData) do
                teamTemp[teamDataKey] = teamDataValue
            end

            PlayerTeamGroupData[key] = {}
            PlayerTeamGroupData[key].TeamId = value.TeamId
            PlayerTeamGroupData[key].CaptainPos = value.CaptainPos
            PlayerTeamGroupData[key].FirstFightPos = value.FirstFightPos
            PlayerTeamGroupData[key].TeamData = teamTemp
        end
    end


    -- 在NotifyLogin中获取预编译队伍
    function XTeamManager.InitTeamPrefabData(teamPrefabData)
        if teamPrefabData == nil then
            return
        end

        for key, value in pairs(teamPrefabData) do
            local teamTemp = {}
            for teamDataKey, teamDataValue in pairs(value.TeamData) do
                teamTemp[teamDataKey] = teamDataValue
            end
            local partnerPrefab = XPartnerPrefab.New(key, value.PartnerData)
            
            PlayerTeamPrefabData[key] = {}
            PlayerTeamPrefabData[key].TeamId = value.TeamId
            PlayerTeamPrefabData[key].CaptainPos = value.CaptainPos
            PlayerTeamPrefabData[key].FirstFightPos = value.FirstFightPos
            PlayerTeamPrefabData[key].TeamData = teamTemp
            PlayerTeamPrefabData[key].TeamName = value.TeamName
            PlayerTeamPrefabData[key].PartnerPrefab = partnerPrefab
        end
    end
    
    --==============================
     ---@desc 获取辅助机预设
     ---@teamId teamId
     ---@return table @class XPartnerPrefab
    --==============================
    function XTeamManager.GetPartnerPrefab(teamId)
        local teamData = PlayerTeamPrefabData[teamId]
        if not teamData then
            local maxPos = XTeamManager.GetMaxPos()
            teamData = {}
            teamData.TeamId = teamId
            teamData.CaptainPos = XTeamManager.GetCaptainPos()
            teamData.FirstFightPos = XTeamManager.GetFirstFightPos()
            teamData.TeamName = CS.XTextManager.GetText("TeamPrefabDefaultName", teamId)
            teamData.TeamData = {}
            for idx = 1, maxPos do
                teamData.TeamData[idx] = 0 
            end
            PlayerTeamPrefabData[teamId] = teamData
        end
        
        local partnerPrefab = teamData.PartnerPrefab
        if not partnerPrefab then
            partnerPrefab = XPartnerPrefab.New(teamId)
            PlayerTeamPrefabData[teamId].PartnerPrefab = partnerPrefab
        end
        
        return partnerPrefab
    end

    function XTeamManager.GetCaptainPos()
        return CaptainPos
    end

    function XTeamManager.GetFirstFightPos()
        return FirstFightPos
    end

    function XTeamManager.GetMaxPos()
        return MaxPos
    end

    function XTeamManager.GetTeamMemberColor(id)
        local colorStr = XTeamConfig.GetTeamCfgById(id).Color
        local color = XUiHelper.Hexcolor2Color(colorStr)
        return color
    end

    function XTeamManager.GetTeamPrefabData()
        return PlayerTeamPrefabData
    end

    function XTeamManager.ResetTeamData(teamId)
        local teamInfos = XTeamManager.GetPlayerTeamData(teamId)
        if not teamInfos then return end
        teamInfos.CaptainPos = 1
        for index in pairs(teamInfos.TeamData) do
            teamInfos.TeamData[index] = 0
        end
    end

    --######################## 新队伍逻辑代码 ########################
    -- return : XTeam
    function XTeamManager.GetMainLineTeam()
        return XTeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdMainLine"))
    end

    function XTeamManager.GetXTeamByTypeId(typeId)
        local teamData = XTeamManager.GetPlayerTeam(typeId)
        local result = TeamDic[teamData.TeamId]
        if result == nil then
            result = XTeam.New(teamData.TeamId)
            result:UpdateSaveCallback(function(inTeam)
                XTeamManager.RequestSaveTeam(inTeam)
            end)
            TeamDic[teamData.TeamId] = result
        end
        result:UpdateFromTeamData(teamData)
        return result
    end

    function XTeamManager.GetXTeamByStageId(stageId)
        local teamData = XTeamManager.LoadTeamLocal(stageId)
        local teamId = GetTeamKey(stageId)
        local result = TeamDic[teamId]
        if result == nil then
            result = XTeam.New(teamId)
            result:UpdateFromTeamData(teamData)
            TeamDic[teamId] = result
        end
        return result
    end

    --根据teamID从内存获取XTeam
    function XTeamManager.GetXTeam(teamId)
        return TeamDic[teamId]
    end

    --把XTeam根据其TeamID存到内存
    ---@param xTeam
    function XTeamManager.SetXTeam(xTeam)
        TeamDic[xTeam:GetId()] = xTeam
    end

    --把XTeam从内存引用中移除
    ---@param xTeam
    function XTeamManager.RemoveXTeam(xTeam)
        TeamDic[xTeam:GetId()] = nil
    end

    function XTeamManager.GetXTeamEntityIds(teamId)
        -- 截断旧队伍逻辑处理
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetEntityIds()
        end
        return nil
    end

    function XTeamManager.GetXTeamCaptainPos(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetCaptainPos()
        end
        return nil
    end

    function XTeamManager.GetXTeamFirstFightPos(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetFirstFightPos()
        end
        return nil
    end

    function XTeamManager.SaveXTeam(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            team:ManualSave()
        end
    end

    -- 创建临时使用的队伍实体
    function XTeamManager.CreateTempTeam(entityIds)
        local result = XTeam.New(XTime.GetServerNowTimestamp())
        result:UpdateAutoSave(false)
        result:UpdateEntityIds(entityIds)
        return result
    end

    function XTeamManager.CreateTeam(teamId)
        local result = XTeam.New(teamId)
        result:UpdateLocalSave(false)
        return result
    end

    function XTeamManager.GetXTeamWithPrefab(teamId)
        local result
        for _, teamData in pairs(PlayerTeamPrefabData) do
            if teamData.TeamId == teamId then
                result = XTeam.New(XTime.GetServerNowTimestamp())
                result:UpdateAutoSave(false)
                result:UpdateFromTeamData(teamData)
                return result
            end
        end
        return result
    end

    -- team : XTeam
    function XTeamManager.RequestSaveTeam(team)
        local entityIds = {}
        XMessagePack.MarkAsTable(entityIds)
        for i, v in ipairs(team:GetEntityIds()) do
            entityIds[i] = v
        end
        local requestBody = {
            TeamData = {
                TeamData = entityIds,
                TeamId = team:GetId(),
                CaptainPos = team:GetCaptainPos(),
                FirstFightPos = team:GetFirstFightPos(),
                TeamName = team:GetName()
            }
        }
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.SetTeam, requestBody)
    end

    XTeamManager.Init()
    return XTeamManager
end

XRpc.NotifyTeamClear = function(data)
    XDataCenter.TeamManager.ResetTeamData(data.TeamId)
end