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
        params.SelectedGeneralSkill = curTeam.SelectedGeneralSkill
        params.EnterCgIndex = curTeam.EnterCgIndex
        params.SettleCgIndex = curTeam.SettleCgIndex
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
        playerTeamData[curTeamId].SelectedGeneralSkill = curTeam.SelectedGeneralSkill
        playerTeamData[curTeamId].EnterCgIndex = curTeam.EnterCgIndex
        playerTeamData[curTeamId].SettleCgIndex = curTeam.SettleCgIndex
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

    function XTeamManager.GetTeamEnterCgIndex(teamId)
        local index = XTeamManager.GetXTeamEnterCgIndex(teamId)
        if index then return index end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        -- 默认位置为0
        index = 0

        -- 是否设置过该teamId数据
        if PlayerTeamGroupData[teamId] ~= nil then
            index = PlayerTeamGroupData[teamId].EnterCgIndex
        end
        return index
    end

    function XTeamManager.GetTeamSettleCgIndex(teamId)
        local index = XTeamManager.GetXTeamSettleCgIndex(teamId)
        if index then return index end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        -- 默认位置为0
        index = 0

        -- 是否设置过该teamId数据
        if PlayerTeamGroupData[teamId] ~= nil then
            index = PlayerTeamGroupData[teamId].SettleCgIndex
        end
        return index
    end
    
    function XTeamManager.GetTeamSelectedGeneralSkill(teamId)
        local selectedGeneralSkill = XTeamManager.GetXTeamSelectGeneralSkill(teamId)
        if XTool.IsNumberValid(selectedGeneralSkill) then
            return selectedGeneralSkill
        end

        if not XTeamConfig.GetTeamTypeCfg(teamId) and teamId ~= 0 then
            XLog.Error("XTeamManager.GetTeamFirstFightPos, 缺少TeamTypeCfg，teamId = ", tostring(teamId))
            return
        end

        selectedGeneralSkill = 0
        -- 是否设置过该teamId数据
        if PlayerTeamGroupData[teamId] ~= nil then
            selectedGeneralSkill = PlayerTeamGroupData[teamId].SelectedGeneralSkill
        end
        return selectedGeneralSkill
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
            ["SelectedGeneralSkill"] = XTeamManager.GetTeamSelectedGeneralSkill(curTeamId),
            ["EnterCgIndex"] = XTeamManager.GetTeamEnterCgIndex(curTeamId),
            ["SettleCgIndex"] = XTeamManager.GetTeamSettleCgIndex(curTeamId),
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
            PlayerTeamGroupData[key].SelectedGeneralSkill = value.SelectedGeneralSkill
            PlayerTeamGroupData[key].EnterCgIndex = value.EnterCgIndex
            PlayerTeamGroupData[key].SettleCgIndex = value.SettleCgIndex
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
            PlayerTeamPrefabData[key].SelectedGeneralSkill = value.SelectedGeneralSkill
            PlayerTeamPrefabData[key].EnterCgIndex = value.EnterCgIndex
            PlayerTeamPrefabData[key].SettleCgIndex = value.SettleCgIndex
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
    ---@return XTeam
    function XTeamManager.GetMainLineTeam()
        return XTeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdMainLine"))
    end

    ---@return XTeam
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
        --- GetTeamKey接口获取的TeamId和XTeam内部自动保存时用的Id不一致（详见XTeam内GetSaveKey接口）
        --- 如果没有配套使用SaveTeamLocal接口，teamData将始终为空
        local teamData = XTeamManager.LoadTeamLocal(stageId)
        local teamId = GetTeamKey(stageId)
        local result = TeamDic[teamId]
        if result == nil then
            -- 如果Xteam此前执行了内部变更保存，构造函数执行期间将正常加载本地缓存的队伍数据（详见XTeam内LoadTeamData接口)
            result = XTeam.New(teamId)
            -- 此处teamData数据覆盖，teamData始终为空时，无论XTeam内部缓存结果，最终始终读取空队伍
            result:UpdateFromTeamData(teamData)
            TeamDic[teamId] = result
        end
        return result
    end

    --- 该接口获取的XTeam启用内部变更自动保存，无需外部手动调用保存接口
    function XTeamManager.GetXTeamByStageIdEx(stageId)
        local teamId = GetTeamKey(stageId)
        ---@type XTeam
        local result = TeamDic[teamId]
        if result == nil then
            result = XTeam.New(teamId)
            result:UpdateAutoSave(true)
            TeamDic[teamId] = result
        end
        return result
    end

    --根据teamID从内存获取XTeam
    ---@return XTeam
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

    function XTeamManager.GetXTeamEnterCgIndex(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetEnterCgIndex()
        end
        return nil
    end

    function XTeamManager.GetXTeamSettleCgIndex(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetSettleCgIndex()
        end
        return nil
    end

    function XTeamManager.GetXTeamSelectGeneralSkill(teamId)
        ---@type XTeam
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            return team:GetCurGeneralSkill()
        end
        return 0
    end

    function XTeamManager.SaveXTeam(teamId)
        local team = XTeamManager.GetXTeam(teamId)
        if team then
            team:ManualSave()
        end
    end
    
    local _TempTeam

    -- 创建临时使用的队伍实体
    function XTeamManager.CreateTempTeam(entityIds)
        local result = XTeam.New(XTime.GetServerNowTimestamp())
        result:UpdateAutoSave(false)
        result:UpdateEntityIds(entityIds)
        _TempTeam = result
        return result
    end

    function XTeamManager.ClearTempTeam()
        _TempTeam = nil
    end
    
    function XTeamManager.GetTempTeam(teamId)
        if _TempTeam and _TempTeam.Id == teamId then
            return _TempTeam
        end
    end
    
    function XTeamManager.GetTempTeamForce()
        return _TempTeam
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

    ---@param team XTeam
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
                TeamName = team:GetName(),
                SelectedGeneralSkill = team:GetCurGeneralSkill(),
                EnterCgIndex = team:GetEnterCgIndex(),
                SettleCgIndex = team:GetSettleCgIndex(),
            }
        }
        XNetwork.CallWithAutoHandleErrorCode(METHOD_NAME.SetTeam, requestBody)
    end

    --- 根据传入的限定可选角色，对上阵队伍进行筛选剔除掉无效实体(提供通用接口用于支持那些非XTeam类型管理的队伍）
    ---@param entityIds @队伍上阵实体的id列表（自机id或机器人id。按通用标准，无角色位填充0）
    ---@param limitEntityIds @限定的可选实体id列表
    ---@param captainPos @队伍的队长位，不填则不判断队长变更的情况
    ---@return any @是否实体有变化, 是否队长位变更，过滤后的实体表
    function XTeamManager.GetValidEntitiesByLimitEntityIds(entityIds, limitEntityIds, captainPos)
        if not XTool.IsTableEmpty(entityIds) and not XTool.IsTableEmpty(limitEntityIds) then
            if not XTool.IsNumberValid(captainPos) or captainPos > 3 then
                captainPos = 0
            end
            
            local needChangeCaptainPos = false
            local entityChanged = false
            -- 剔除不在可选角色列表中的id
            for i = 1, #entityIds do
                if XTool.IsNumberValid(entityIds[i]) and not table.contains(limitEntityIds, entityIds[i]) then
                    entityIds[i] = 0
                    entityChanged = true
                    if captainPos == i then
                        needChangeCaptainPos = true
                    end
                end
            end
            
            return entityChanged, needChangeCaptainPos, entityIds
        end
        
        return false, false, nil
    end

    --- 根据传入的实体Id列表, 按照既定规则返回一个默认效应技能id(提供通用接口用于支持那些不会转换到XTeam处理的情况）
    --- 需注意本接口仅一次性查找、不能用于查其他玩家角色的数据，不会收集和处理可选技能，无法用于“效应选择”功能
    ---@param entityIds @队伍上阵实体的id列表（自机id或机器人id。按通用标准，无角色位填充0）
    ---@param lastGeneralSkillId @该队伍变更前所选择的效应技能Id, 缺省时为0
    ---@return number @新选择的效应技能Id
    function XTeamManager.GetTeamDefaultGeneralSkillId(entityIds, lastGeneralSkillId)
        if XTool.IsTableEmpty(entityIds) then
            return 0
        end

        if lastGeneralSkillId == nil then
            lastGeneralSkillId = 0
        end
        
        -- 判断新队伍产生的可选技能是否包含旧选择的技能
        local containsLastGeneralSkillId = false
        -- 优先选人数多的，其次选id小的
        -- 根据以下编码，值最大的即为选择的generalSkillId
        local generalSkillMap = {} -- <key: id, value: 100000 + characterCount*1000 + (999 - id) >

        for i, entityId in pairs(entityIds) do
            -- 获取角色已激活的效应技能列表（自机和机器人）
            local skillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(entityId)
            if not XTool.IsTableEmpty(skillIds) then
                for i, skillId in pairs(skillIds) do
                    if generalSkillMap[skillId] == nil then
                        generalSkillMap[skillId] = 100000 + 999 - skillId
                    end

                    generalSkillMap[skillId] = generalSkillMap[skillId] + 1000

                    if skillId == lastGeneralSkillId then
                        containsLastGeneralSkillId = true
                    end
                end
            end
        end

        -- 如果新队伍可选的效应技能包括旧选择的，那么仍使用旧的
        if containsLastGeneralSkillId then
            return lastGeneralSkillId
        end

        -- 按照规则选择新效应技能
        if not XTool.IsTableEmpty(generalSkillMap) then
            local maxKey = 1
            local maxValue = 0

            for i, v in pairs(generalSkillMap) do
                if v > maxValue then
                    maxKey = i
                    maxValue = v
                end
            end

            return maxKey
        end

        return 0
    end

    XTeamManager.Init()
    return XTeamManager
end

XRpc.NotifyTeamClear = function(data)
    XDataCenter.TeamManager.ResetTeamData(data.TeamId)
end