local XAdventureChapter = require("XEntity/XBiancaTheatre/Adventure/XAdventureChapter")
local XAdventureDifficulty = require("XEntity/XBiancaTheatre/Adventure/XAdventureDifficulty")
local XAdventureMultiDeploy = require("XEntity/XBiancaTheatre/Adventure/Deploy/XAdventureMultiDeploy")
local XTheatreItem = require("XEntity/XBiancaTheatre/Item/XTheatreItem")
local XTheatreTeam = require("XEntity/XBiancaTheatre/XTheatreTeam")
local XAdventureRole = require("XEntity/XBiancaTheatre/Adventure/XAdventureRole")
local XAdventureEnd = require("XEntity/XBiancaTheatre/Adventure/XAdventureEnd")
---@class XBiancaTheatreAdventureManager
local XAdventureManager = XClass(nil, "XAdventureManager")

--当前冒险管理
function XAdventureManager:Ctor()
    -- 当前难度数据 XAdventureDifficulty
    self.CurrentDifficulty = nil
    -- 当前章节数据 XAdventureChapter
    self.CurrentChapter = nil
    -- 当前可用的角色 XAdventureRole
    self.CurrentRoles = {}
    -- 多队伍编队管理
    self.AdventureMultiDeploy = XAdventureMultiDeploy.New()
    -- 单队伍数据 XTheatreTeam
    self.SingleTeam = nil
    -- 当前的获取的技能 XAdventureSkill
    self.CurrentSkills = nil
    -- 当前操作队列
    self.OperationQueue = XQueue.New()
    -- 是否能够使用自己的角色
    self.CanUseLocalRole = true
    -- 当前获取的好感度
    self.CurrentFavorCoin = 0
    -- 当前获得的装修点
    self.CurrentDecorationCoin = 0
    -- 当前分队ID
    self.CurTeamId = 0
    -- 本局拥有道具（key：BiancaTheatreItem表Id）
    self.Items = {}
    -- 本局拥有道具列表
    self.ItemList = {}
    -- 当前选择的招募券Id
    self.SelectTickId = 0
    -- 灵视值
    self.VisionValue = 0
    self.OldVisionValue = self.VisionValue

    -- 注册更新灵视值
    XDataCenter.ItemManager.AddCountUpdateListener(XBiancaTheatreConfigs.VisionItem, handler(self, self.UpdateVisionValue), self)
end

function XAdventureManager:InitWithServerData(data)
    local chapaterData = data.CurChapterDb
    -- 更新当前章节数据
    self.CurrentChapter = XAdventureChapter.New(chapaterData.ChapterId)
    self.CurrentChapter:InitWithServerData({
        Steps = chapaterData.Steps, --当前步骤数据
        PassFightCount = chapaterData.PassFightCount, -- 完成战斗节点数
        PassChapter = chapaterData.PassChapter, -- 当前章节是否已通关
        PassNodeCount = chapaterData.PassNodeCount -- 当前已通过的节点数
    })
    -- 更新当前难度
    self.CurrentDifficulty = XAdventureDifficulty.New(data.DifficultyId)
    -- 更到当前选择的分队
    self:UpdateCurTeamId(data.CurTeamId)
    -- 更新当前可用的角色
    for _, characterData in ipairs(data.Characters) do
        self:AddRoleById(characterData.CharacterId, nil, nil, XTool.IsNumberValid(characterData.IsDecay))
        self:UpdateRoleLevel(characterData.CharacterId, characterData.Level)
    end
    -- 更新单队伍数据
    self:UpdateTeamByServerData(self:GetSingleTeam(), data.SingleTeamData)
    -- 更新本局拥有道具
    self.Items = {}
    self.ItemList = {}
    for _, itemData in pairs(data.Items) do
        self:UpdateItemData(itemData)
    end
    -- 更新灵视数据
    self:UpdateVisionValue()
end

function XAdventureManager:UpdateCurTeamId(teamId)
    self.CurTeamId = teamId
end

-- 更新本局选择的招募券Id
function XAdventureManager:UpdateSelectTickId(tickId)
    self.SelectTickId = tickId
end

function XAdventureManager:GetSelectTickId()
    return self.SelectTickId
end

--------------------------------------------------------------------------------

-- 秘藏品相关
--------------------------------------------------------------------------------

-- 更新本局拥有道具
function XAdventureManager:UpdateItemData(itemData)
    local item = self.Items[itemData.ItemId]
    if not item then
        item = XTheatreItem.New(itemData.Uid)
        self.Items[itemData.ItemId] = item
    end
    item:UpdateData(itemData.ItemId)
    item:AddCount()
    table.insert(self.ItemList, 1, item)
end

-- 移除本局拥有道具
function XAdventureManager:RemoveItemData(itemId)
    local item = self.Items[itemId]
    if item then
        item:RemoveCount()
        if item:GetItemCount() <= 0 then
            self.Items[itemId] = nil
        end
        for i, theatreItem in ipairs(self.ItemList) do
            if theatreItem:GetItemId() == itemId then
                table.remove(self.ItemList, i)
                return
            end
        end
    end
end

-- 获得本局拥有道具列表
function XAdventureManager:GetItemList()
    return self.ItemList
end

function XAdventureManager:IsHaveTheatreItem(theatreItemId)
    return self.Items[theatreItemId]
end

function XAdventureManager:GetTheatreItemCount(theatreItemId)
    local item = self:IsHaveTheatreItem(theatreItemId)
    return item and item:GetItemCount() or 0
end

--------------------------------------------------------------------------------

-- 灵视相关
--------------------------------------------------------------------------------

function XAdventureManager:GetVisionValue()
    return self.VisionValue
end

---灵视变更前的值(结算用上)
---@return number|nil
function XAdventureManager:GetOldVisionValue()
    return self.OldVisionValue
end

function XAdventureManager:UpdateVisionValue()
    self.OldVisionValue = self.VisionValue
    self.VisionValue = XDataCenter.ItemManager.GetCount(XBiancaTheatreConfigs.VisionItem)
    XEventManager.DispatchEvent(XEventId.EVENT_BIANCA_THEATRE_VISION_CHANGE)
end

--------------------------------------------------------------------------------

function XAdventureManager:UpdateTeamByServerData(team, data)
    team:Clear()
    if data == nil then return end
    team:UpdateCaptainPos(data.CaptainPos)
    team:UpdateFirstFightPos(data.FirstFightPos)
    -- 本地角色处理
    for pos, id in ipairs(data.CardIds) do
        if id > 0 then
            team:UpdateEntityTeamPos(id, pos, true)
        end
    end
    -- 机器人角色处理
    for pos, id in ipairs(data.RobotIds) do
        if id > 0 then
            team:UpdateEntityTeamPos(id, pos, true)
        end
    end
end

function XAdventureManager:UpdateUseOwnCharacter(value)
    self.CanUseLocalRole = value == 1
end

function XAdventureManager:UpdateCurrentFavorCoin(value)
    self.CurrentFavorCoin = value
end

function XAdventureManager:UpdateCurrentDecorationCoin(value)
    self.CurrentDecorationCoin = value
end

function XAdventureManager:GetCurrentFavorCoin()
    return self.CurrentFavorCoin
end

function XAdventureManager:GetCurrentDecorationCoin()
    return self.CurrentDecorationCoin
end

function XAdventureManager:Release()
    self:ClearTeam()
end

function XAdventureManager:ClearTeam()
    if self.SingleTeam then 
        self.SingleTeam:Clear()
        self.SingleTeam = nil
    end
    self.AdventureMultiDeploy:ClearTeam()
end

function XAdventureManager:AddNextOperationData(data, isFront)
    if isFront then
        self.OperationQueue:EnqueueFront(data)
    else
        self.OperationQueue:Enqueue(data)
    end
end

function XAdventureManager:ShowNextOperation(callback)
    if self.OperationQueue:IsEmpty() then
        if callback then callback() end
        return
    end
    local data = self.OperationQueue:Dequeue()
    local chapter = self:GetCurrentChapter()
    if data.OperationQueueType == XBiancaTheatreConfigs.OperationQueueType.NodeReward then
        -- 升级
        if data.RewardType == XBiancaTheatreConfigs.AdventureRewardType.LevelUp then
            XLuaUiManager.Open("UiTheatreTeamUp", data.LastLevel, data.LastAveragePower
            , function() self:ShowNextOperation(callback) end)
        -- 装修点
        elseif data.RewardType == XBiancaTheatreConfigs.AdventureRewardType.Decoration then
            XUiManager.OpenUiObtain({{
                RewardType = XRewardManager.XRewardType.Item,
                TemplateId = XBiancaTheatreConfigs.TheatreDecorationCoin,
                Count = data.DecorationPoint
            }}, nil, function() self:ShowNextOperation(callback) end)
        -- 好感度
        elseif data.RewardType == XBiancaTheatreConfigs.AdventureRewardType.PowerFavor then
            XUiManager.OpenUiObtain({{
                RewardType = XRewardManager.XRewardType.Item,
                TemplateId = XBiancaTheatreConfigs.TheatreFavorCoin,
                Count = data.FavorPoint
            }}, nil, function() self:ShowNextOperation(callback) end)
        end
    elseif data.OperationQueueType == XBiancaTheatreConfigs.OperationQueueType.ChapterSettle then
        XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.Remove("UiBiancaTheatrePlayMain")
            -- 进入下一个章节
            self:EnterChapter(data.LastChapteEndStoryId)    
        end, 1)
        -- if callback then callback() end
    elseif data.OperationQueueType == XBiancaTheatreConfigs.OperationQueueType.AdventureSettle then
        XLuaUiManager.Remove("UiBiancaTheatreOutpost")
        XLuaUiManager.Remove("UiBiancaTheatrePlayMain")
        local adventureEnd = XAdventureEnd.New(data.SettleData.Ending)
        adventureEnd:InitWithServerData(data.SettleData)
        XLuaUiManager.Open("UiTheatreInfiniteSettleWin", adventureEnd, data.LastChapteEndStoryId)
        -- if callback then callback() end
    elseif data.OperationQueueType == XBiancaTheatreConfigs.OperationQueueType.BattleSettle then
        if table.nums(data.RewardGoodsList) > 0 then
            XLuaUiManager.Open("UiBiancaTheatreTipReward", function() self:ShowNextOperation(callback) end,
            data.RewardGoodsList, nil)
        else
            self:ShowNextOperation(callback)
        end
    end
end

function XAdventureManager:GetCurrentChapter(autoCreatre)
    if autoCreatre == nil then autoCreatre = true end
    if self.CurrentChapter == nil and autoCreatre then
        self:UpdateNextChapter()
    end
    return self.CurrentChapter
end

function XAdventureManager:CreatreChapterById(id)
    self.CurrentChapter = XAdventureChapter.New(id)
    return self.CurrentChapter
end

function XAdventureManager:UpdateNextChapter()
    if self.CurrentChapter == nil then
        self.CurrentChapter = XAdventureChapter.New(self:GetDefaultChapterId())
    else
        local nextChapterId = self.CurrentChapter:GetId() + 1
        if XBiancaTheatreConfigs.GetBiancaTheatreChapter(nextChapterId) then
            self.CurrentChapter = XAdventureChapter.New(nextChapterId)
        end
    end
end

function XAdventureManager:GetDefaultChapterId()
    return 1
end

-- 角色相关
--------------------------------------------------------------------------------

-- 检查是否能够使用本地角色
function XAdventureManager:CheckCanUseLocalRole()
    return self.CanUseLocalRole
end

--获得已招募的角色数量
function XAdventureManager:GetRolesCount()
    return #self:GetCurrentRoles()
end

--获得已招募的角色总星数
function XAdventureManager:GetRolesStarCount()
    local starCount = 0
    for i, role in ipairs(self.CurrentRoles) do
        starCount = starCount + role:GetLevel()
    end
    return starCount
end

-- includeLocal : 是否包含本地角色
---@return XBiancaTheatreAdventureRole[]
function XAdventureManager:GetCurrentRoles(includeLocal)
    if includeLocal == nil then includeLocal = false end
    local result = {}
    for _, role in ipairs(self.CurrentRoles) do
        --添加试玩角色的AdventureRole
        table.insert(result, role:GetRobotRole())
        if includeLocal then
            role:GenerateLocalRole()
            if role:GetIsLocalRole() then
                table.insert(result, role)
            end
        end
    end
    return result
end

function XAdventureManager:AddRoleById(roleId, configId, isUplevel, isDecay)
    if configId == nil then configId = roleId end
    for _, role in ipairs(self.CurrentRoles or {}) do
        if role:GetId() == roleId then
            -- 升星
            if isUplevel then
                role:UpdateLevel(role:GetLevel() + 1)
            end
            if isDecay then
                role:UpdateDecay(isDecay)
            end
            -- 重复添加
            return role
        end
    end
    table.insert(self.CurrentRoles, XAdventureRole.New(roleId, nil, isDecay))
    return self.CurrentRoles[#self.CurrentRoles]
end

function XAdventureManager:UpdateRoleLevel(roleId, level)
    for _, role in ipairs(self.CurrentRoles or {}) do
        if role:GetId() == roleId then 
            role:UpdateLevel(level)
            return
        end
    end
end

---@return XBiancaTheatreAdventureRole
function XAdventureManager:GetRole(id)
    for _, role in ipairs(self:GetCurrentRoles(true)) do
        if role:GetId() == id then
            return role
        end
    end
end

function XAdventureManager:GetRoleByCharacterId(characterId)
    for _, role in ipairs(self:GetCurrentRoles(true)) do
        if role:GetBaseId() == characterId then
            return role
        end
    end
end

-- 获取角色平均战力
function XAdventureManager:GeRoleAveragePower()
    local result = 0
    local roles = self:GetCurrentRoles(false)
    for _, role in ipairs(roles) do
        result = result + role:GetAbility()
    end
    if result == 0 then
        return 0
    end
    result = math.floor(result / #roles)
    return result
end

-- 检查角色是否腐化
function XAdventureManager:CheckRoleIsDecayByCharacterId(characterId)
    for _, role in ipairs(self.CurrentRoles) do
        if role:GetBaseId() == characterId and role:GetIsDecay() then
            return true
        end
    end
end

--------------------------------------------------------------------------------

-- 获取开启的所有难度数据
function XAdventureManager:GetDifficulties(checkOpen)
    if checkOpen == nil then checkOpen = false end
    if self.__Difficulties == nil then
        self.__Difficulties = {}
        local difficultyConfigDic = XBiancaTheatreConfigs.GetTheatreDifficulty()
        for id, _ in pairs(difficultyConfigDic) do
            table.insert(self.__Difficulties, XAdventureDifficulty.New(id))
        end    
        table.sort(self.__Difficulties, function(a, b)
            return a:GetId() < b:GetId()
        end)
    end
    if checkOpen then
        local result = {}
        for _, difficulty in ipairs(self.__Difficulties) do
            if difficulty:GetIsOpen() then
                table.insert(result, difficulty)
            end
        end
        return result
    end
    return self.__Difficulties
end

function XAdventureManager:UpdateCurrentDifficulty(difficulty)
    self.CurrentDifficulty = difficulty
end

function XAdventureManager:GetCurrentDifficulty()
    return self.CurrentDifficulty
end

-- 当前难度缓存键值
function XAdventureManager:GetDifficultyLocalCacheKey()
    return string.format("BiancaTheatreData_%s_CurDifficultyId", XPlayer.Id)
end

-- 读取当前难度缓存值
function XAdventureManager:SaveDifficultyLocalCache(CurrentDifficulty)
    if not CurrentDifficulty then return end
    XSaveTool.SaveData(XAdventureManager:GetDifficultyLocalCacheKey(), CurrentDifficulty:GetId())
end

-- 读取当前难度缓存值
function XAdventureManager:GetDifficultyLocalCacheIndex()
    local difficultyId = XSaveTool.GetData(XAdventureManager:GetDifficultyLocalCacheKey())
    if not XTool.IsNumberValid(difficultyId) then return end
    for index, difficulty in ipairs(XAdventureManager:GetDifficulties(true)) do
        if difficulty:GetId() == difficultyId then
            return index
        end
    end
end

function XAdventureManager:GetPlayableCount()
    return 0
end

function XAdventureManager:GetSingleTeam()
    if self.SingleTeam == nil then
        self.SingleTeam = XTheatreTeam.New("BiancaTheatre_Adventure_Single_Team")
    end
    return self.SingleTeam
end

function XAdventureManager:GetMultipleTeamByIndex(index)
    return self.AdventureMultiDeploy:GetMultipleTeamByIndex(index)
end

function XAdventureManager:GetTeamById(id)
    if self.SingleTeam and self.SingleTeam:GetId() == id then 
        return self.SingleTeam
    end

    return self.AdventureMultiDeploy:GetTeamById(id)
end

function XAdventureManager:GetAdventureMultiDeploy()
    return self.AdventureMultiDeploy
end

-- 获取冒险等级
function XAdventureManager:GetCurrentLevel()
    return self.CurrentLevel
end

function XAdventureManager:UpdateCurrentLevel(value)
    self.CurrentLevel = value
    self:UpdateCurrentRoleRobots(value)
end

function XAdventureManager:UpdateCurrentRoleRobots(level)
    --for _, role in ipairs(self.CurrentRoles) do
    --    if not role:GetIsLocalRole() then
    --        role:GenerateNewRobot(level)
    --    end
    --end
end

function XAdventureManager:GetCurrentSkills()
    return self.CurrentSkills or {}
end

function XAdventureManager:GetCoreSkills()
    local result = {}
    local additionalSkillCount = 0
    for _, skill in ipairs(self:GetCurrentSkills()) do
        if skill:GetSkillType() == XBiancaTheatreConfigs.SkillType.Core then
            table.insert(result, skill)
        else
            additionalSkillCount = additionalSkillCount + 1
        end
    end
    table.sort(result, function(aSkill, bSkill)
        return aSkill:GetPos() < bSkill:GetPos()
    end)
    return result, additionalSkillCount
end

--获得对应位置的技能
function XAdventureManager:GetCoreSkillByPos(pos)
    local coreSkills = self:GetCoreSkills()
    for i, v in ipairs(coreSkills) do
        if v:GetPos() == pos then
            return v
        end
    end
end

function XAdventureManager:GetCoreSkillLv(skillType)
    local coreSkills = self:GetCoreSkills()
    for _, v in ipairs(coreSkills) do
        local skillTypeList = XBiancaTheatreConfigs.GetTheatreSkillPosDefineSkillType(v:GetPos())
        for _, skillTypeTemp in ipairs(skillTypeList) do
            if skillType == skillTypeTemp then
                return v:GetCurrentLevel()
            end
        end
    end
end

function XAdventureManager:GetAdditionSkillDic()
    local result = {}
    local powerCountDic = {}
    local powerId = nil
    for _, skill in ipairs(self:GetCurrentSkills()) do
        if skill:GetSkillType() == XBiancaTheatreConfigs.SkillType.Additional then
            powerId = skill:GetPowerId()
            if not powerCountDic[powerId] then
                table.insert(result, skill)
            end
            powerCountDic[powerId] = powerCountDic[powerId] and powerCountDic[powerId] + 1 or 1
        end
    end
    return result, powerCountDic
end

-- 获取当前所有技能附加的战力
function XAdventureManager:GetCurrentSkillsPower()
    return 0
end

function XAdventureManager:EnterFight(inStageId, index, callback)
    if index == nil then index = 1 end
    local team = self:GetSingleTeam()
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(inStageId)
    if stageConfig == nil then return end
    --local teamId = team:GetId()
    local teamId = 0
    local isAssist = false
    local challengeCount = 1
    XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount, nil, callback)
end

function XAdventureManager:GetCardIdsAndRobotIdsFromTeam(team)
    local cardIds = {0, 0, 0}
    local robotIds = {0, 0, 0}
    local role
    for pos, entityId in ipairs(team:GetEntityIds()) do
        if entityId > 0 then
            role = self:GetRole(entityId)
            if role then 
                if role:GetIsLocalRole() then -- 本地角色
                    cardIds[pos] = role:GetRawDataId()
                else
                    robotIds[pos] = role:GetRawDataId()
                end
            else
                XLog.Error("肉鸽找不到角色，Id为" .. entityId)
            end
        end
    end
    return cardIds, robotIds
end

function XAdventureManager:GetRoleIdByRobotId(robotId)
    return XBiancaTheatreConfigs.GetCharacterIdByRobotId(robotId)
end

function XAdventureManager:GetCurTeamId()
    return self.CurTeamId
end

-- 检查队伍是否受到人数显示效果影响
function XAdventureManager:CheckIsLockTeamRoleCount()
    if not XTool.IsNumberValid(XDataCenter.BiancaTheatreManager.GetTeamCountEffect()) then
        return false
    end
    local curCount = 0
    local cardIds, robotIds = self:GetCardIdsAndRobotIdsFromTeam(self.SingleTeam)
    for _, cardId in ipairs(cardIds) do
        if XTool.IsNumberValid(cardId) then
            curCount = curCount + 1
        end
    end

    for _, robotId in ipairs(robotIds) do
        if XTool.IsNumberValid(robotId) then
            curCount = curCount + 1
        end
    end
    return curCount > XDataCenter.BiancaTheatreManager.GetTeamCountEffect()
end

--######################## 协议 begin ########################

-- 请求选择难度
function XAdventureManager:RequestStartAdventure(callback)
    local requestBody = {
        Difficulty = self.CurrentDifficulty:GetId(), -- 难度Id
    }
    self.CurrentChapter = nil -- 避免其他GetChapter时创建了默认的章节数据
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreSelectDifficultyRequest", requestBody, function(res)
        -- hack : 服务器通知节点有可能比该请求返回还要快，因此如果不为空就用节点通知的
        if self.CurrentChapter == nil then
            self.CurrentChapter = XAdventureChapter.New(res.ChapterId)
        end
        XDataCenter.BiancaTheatreManager.UpdateDifficultyId(requestBody.Difficulty)
        XDataCenter.BiancaTheatreManager.UpdateCurChapterId(res.ChapterId)
        -- 进入默认章节
        if callback then callback() end
    end)
end

-- 请求结束冒险
function XAdventureManager:RequestSettleAdventure(callback)
    local requestBody = {}
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreSettleAdventureRequest", requestBody, function(res)
        XDataCenter.BiancaTheatreManager.SettleInitData()
        XDataCenter.BiancaTheatreManager.SetAdventureEnd(res.SettleData)
        if callback then callback() end

        XDataCenter.BiancaTheatreManager.CheckOpenSettleWin()
    end)
end

-- 请求设置单队伍
function XAdventureManager:RequestSetSingleTeam(callback)
    if self:CheckIsLockTeamRoleCount() then
        XUiManager.TipErrorWithKey("BiancaTheatreLockRollCount", XDataCenter.BiancaTheatreManager.GetTeamCountEffect())
        return
    end
    local cardIds, robotIds = self:GetCardIdsAndRobotIdsFromTeam(self.SingleTeam)
    local requestBody = {
        TeamData = {
            TeamIndex = 0,
            CaptainPos = self.SingleTeam:GetCaptainPos(),
            FirstFightPos = self.SingleTeam:GetFirstFightPos(),
            CardIds = cardIds,
            RobotIds = robotIds,
        }
    }
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreSetSingleTeamRequest", requestBody, function(res)
        if callback then callback() end
    end)
end

--选择开道具箱奖励，3选1
function XAdventureManager:RequestSelectItemReward(innerItemId, callback)
    local requestBody = {
        InnerItemId = innerItemId,    --肉鸽item表ID
    }
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local curStep = adventureManager:GetCurrentChapter():GetCurStep()
    if curStep then
        curStep:SetOverdue(1)
    end
    
    XNetwork.Call("BiancaTheatreSelectItemRewardRequest", requestBody, function(res)
        if res.Code ~= XCode.Success then
            if curStep then
                curStep:SetOverdue(0)
            end
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then callback() end
    end)
end

--战斗结束————打开战斗奖励选择界面————领取战斗奖励
--fightRewards：XARewardNode的列表，领取成功后更新数据
function XAdventureManager:RequestRecvFightReward(uid, callback, fightRewards)
    local requestBody = {
        Uid = uid,    --选择唯一ID
    }
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreRecvFightRewardRequest", requestBody, function(res)
        for _, node in pairs(fightRewards or {}) do
            if node:GetUid() == uid then
                node:UpdateReceived(1)
                break
            end
        end
        
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            XLuaUiManager.Open("UiBiancaTheatreTipReward", nil, res.RewardGoodsList)
        end
        if callback then callback() end
    end)
end

--事件/战斗节点————战斗结束————战斗奖励选择界面————领取战斗奖励————结束领取
function XAdventureManager:RequestEndRecvFightReward(callback)
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local chapter = adventureManager:GetCurrentChapter()
    local curStep = chapter:GetCurStep()
    local isCheckOpen = curStep:GetRootStepIsSelectableEvent()
    if curStep then
        curStep:SetOverdue(1)
    end

    XNetwork.Call("BiancaTheatreEndRecvFightRewardRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            if curStep then
                curStep:SetOverdue(0)
            end
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then callback() end

        if isCheckOpen then
            XDataCenter.BiancaTheatreManager.CheckOpenView(true)
        end
    end)
end
--######################## 协议 end ########################

return XAdventureManager