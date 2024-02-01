local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
---@class XMainLine2Agency : XFubenActivityAgency
---@field _Model XMainLine2Model
local XMainLine2Agency = XClass(XFubenActivityAgency, "XMainLineAgency")

function XMainLine2Agency:OnInit()
    --初始化一些变量
    self:RegisterFuben(XEnumConst.FuBen.StageType.Mainline2)
end

function XMainLine2Agency:AfterInitManager()
    XDataCenter.FubenManagerEx.RegisterManager(self)
end

function XMainLine2Agency:InitRpc()
    -- 注册服务器事件
end

function XMainLine2Agency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--- 获取章节类型
function XMainLine2Agency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.MainLine2
end

--- 通过章节Id，获取主章节实例
function XMainLine2Agency:ExGetChapterViewModelBySubChapterId(chapterId)
    local mainCfgs = self._Model:GetConfigMain()
    for _, mainCfg in pairs(mainCfgs) do
        for _, cId in ipairs(mainCfg.ChapterIds) do
            if cId == chapterId then
                return self:GetMain(mainCfg.Id)
            end
        end
    end

    return nil
end

-- region rpc start -------------------------------------------------------------------------------------------------
function XMainLine2Agency:OnLoginNotify(fubenMainLine2Data)
    self._Model:OnLoginNotify(fubenMainLine2Data)
end

--- 请求领取成就
---@param id number 主章节Id
function XMainLine2Agency:RequestReceiveAchievement(mainId, cb)
    local req = { ChapterId = mainId }
    XNetwork.CallWithAutoHandleErrorCode("MainLine2ReceiveAchievementRequest", req, function(res)
        self._Model:OnReceiveAchievement(mainId)
        if res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
        if cb then cb() end
    end)
end

--- 请求领取通关奖励
function XMainLine2Agency:RequestReceiveTreasure(chapterId, cb)
    local req = { ChapterId = chapterId }
    XNetwork.CallWithAutoHandleErrorCode("MainLine2ReceiveTreasureRequest", req, function(res)
        self._Model:OnReceiveTreasure(chapterId, res.RewardIdxs)
        if res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
        if cb then cb() end
    end)
end
--endregion ---------------------------------------------------------------------------------------------------------


--- 主章节是否存在
---@param id number 主章节Id
function XMainLine2Agency:IsMainExit(id)
    return self._Model:IsMainExit(id)
end

--- 获取主章节实例
---@param mainId number 主章节Id
function XMainLine2Agency:GetMain(mainId)
    return self._Model:GetMain(mainId)
end

--- 获取所有主章节实例
function XMainLine2Agency:GetAllMains()
    return self._Model:GetAllMains()
end

--- 获取主章节配置表列表
---@param storyType number 章节类型
---@param groupId number 组Id
function XMainLine2Agency:GetMainCfgsByStoryTypeGroupId(storyType, groupId)
    return self._Model:GetMainCfgsByStoryTypeGroupId(storyType, groupId)
end

--- 获取主章节进度
---@param mainId number 主章节Id
function XMainLine2Agency:GetMainProgress(mainId)
    local allPassCnt = 0
    local allMaxCnt = 0
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        local passCnt, maxCnt = self._Model:GetChapterProgress(chapterId)
        allPassCnt = allPassCnt + passCnt
        allMaxCnt = allMaxCnt + maxCnt
    end
    return allPassCnt, allMaxCnt
end

--- 主章节是否显示新章节标签：存在 已解锁 + 未通关 的关卡
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainHasNewTag(mainId)
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        if self:IsChapterUnlock(chapterId) and not self:IsChapterPassed(chapterId) then
            return true
        end
    end
    return false
end

--- 主章节是否显示限时标签：配置TimeId，可选配置ConditionId
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainShowTimeLimitTag(mainId)
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        local timeId = self._Model:GetChapterActivityTimeId(chapterId)
        if XFunctionManager.CheckInTimeByTimeId(timeId) then
            return true
        end
    end
    return false
end

--- 主章节是否解锁
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainUnlock(mainId)
    return self._Model:IsMainUnlock(mainId)
end

--- 主章节是否全通关
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainPassed(mainId)
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        if not self:IsChapterPassed(chapterId) then
            return false
        end
    end
    return true
end

--- 获取主章节成就进度
---@param mainId number 主章节Id
function XMainLine2Agency:GetMainAchievementProgress(mainId)
    local curCnt = 0
    local mainCfg = self._Model:GetConfigMain(mainId)
    for _, chapterId in ipairs(mainCfg.ChapterIds) do
        local groupIds = self._Model:GetChapterStageGroupIds(chapterId)
        for _, groupId in ipairs(groupIds) do
            local stageIds = self._Model:GetGroupStageIds(groupId)
            for _, stageId in ipairs(stageIds) do
                local cnt, map = self:GetStageAchievementMap(stageId)
                curCnt = curCnt + cnt
            end
        end
    end
    
    local maxCnt = self._Model:GetAchievementCount(mainCfg.AchievementId)
    return curCnt, maxCnt
end

--- 获取主章节成就图标
---@param mainId number 主章节Id
function XMainLine2Agency:GetMainAchievementIcon(mainId)
    local mainCfg = self._Model:GetConfigMain(mainId)
    if mainCfg.AchievementId ~= 0 then
        return self._Model:GetAchievementChapterIcon(mainCfg.AchievementId)
    end

    return nil
end

--- 主章节是否显示蓝点
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainRed(mainId)
    -- 成就奖励未领取
    local isGet = self._Model:IsAchievementGet(mainId)
    if not isGet then
        local curCnt, maxCnt = self:GetMainAchievementProgress(mainId)
        if curCnt >= maxCnt then
            return true
        end
    end

    -- 进度奖励未领取
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        if self:IsChapterRed(chapterId) then
            return true
        end
    end

    -- 时间蓝点
    if self:IsMainRedTimeIdShow(mainId) then
        return true
    end

    return false
end

-- 是否显示主章节时间红点
function XMainLine2Agency:IsMainRedTimeIdShow(mainId)
    local isPass = self:IsMainPassed(mainId)
    if isPass then
        return false
    end

    local timeId = self._Model:GetMainRedTimeId(mainId)
    if timeId == 0 then
        return false
    end

    -- 已移除红点
    local key = string.format("XMainLine2Main.tab_RedTimeId_%s_%s", XPlayer.Id, timeId) 
    local isRemove = XSaveTool.GetData(key) == true
    if isRemove then
        return false
    end

    -- 时间内
    local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
    return isInTime
end

-- 移除主章节时间红点
function XMainLine2Agency:RemoveMainRedTimeIdShow(mainId)
    if self:IsMainRedTimeIdShow(mainId) then
        local timeId = self._Model:GetMainRedTimeId(mainId)
        local key = string.format("XMainLine2Main.tab_RedTimeId_%s_%s", XPlayer.Id, timeId)
        XSaveTool.SaveData(key, true)
    end
end

--- 章节是否存在
---@param chapterId number 章节Id
function XMainLine2Agency:IsChapterExit(chapterId)
    return self._Model:IsChapterExit(chapterId)
end

--- 章节是否通关
---@param chapterId number 章节Id
function XMainLine2Agency:IsChapterPassed(chapterId)
    return self._Model:IsChapterPassed(chapterId)
end

--- 章节是否解锁
---@param chapterId number 章节Id
function XMainLine2Agency:IsChapterUnlock(chapterId)
    return self._Model:IsChapterUnlock(chapterId)
end

--- 章节是否显示蓝点
---@param chapterId number 章节Id
function XMainLine2Agency:IsChapterRed(chapterId)
    return self._Model:IsChapterRed(chapterId)
end

--- 获取章节打的下一关入口
---@param chapterId number 章节Id
function XMainLine2Agency:GetChapterNextEntrance(chapterId)
    return self._Model:GetChapterNextEntrance(chapterId)
end

--- 获取章节Id
---@param mainId number 主章节Id
---@param difficultyId number 难度Id
function XMainLine2Agency:GetChapterId(mainId, difficultyId)
    return self._Model:GetChapterId(mainId, difficultyId)
end

--- 获取章节的主章节Id
---@param chapterId number 章节Id
function XMainLine2Agency:GetChapterMainId(chapterId, ignoreError)
    return self._Model:GetChapterMainId(chapterId, ignoreError)
end

--- 关卡是否存在
---@param stageId number 关卡Id
function XMainLine2Agency:IsStageExit(stageId)
    return self._Model:IsStageExit(stageId)
end

--- 获取关卡配置表
---@param stageId number 关卡Id
function XMainLine2Agency:GetConfigStage(stageId)
    return self._Model:GetConfigStage(stageId)
end

--- 获取关卡对应章节成就图标
---@param stageId number 关卡Id
function XMainLine2Agency:GetStageChapterAchievementIcon(stageId)
    if not self:IsStageExit(stageId) then
        return
    end

    local chapterId = self._Model:GetStageChapterId(stageId)
    local mainId = self:GetChapterMainId(chapterId)
    local achievementId = self._Model:GetMainAchievementId(mainId)
    return self._Model:GetAchievementIcon(achievementId)
end

--- 获取关卡成就名称
---@param stageId number 关卡Id
---@param index number 成就下标，从1开始
function XMainLine2Agency:GetStageAchievementName(stageId, index)
    return self._Model:GetStageAchievementName(stageId, index)
end

--- 获取关卡成就完成情况
---@param stageId number 关卡Id
function XMainLine2Agency:GetStageAchievementMap(stageId)
    return self._Model:GetStageAchievementMap(stageId)
end

--- 获取关卡成就信息
---@param stageId number 关卡Id
---@param isFighting boolean 是否在战斗中
function XMainLine2Agency:GetStagesAchievementInfos(stageId, isFighting)
    return self._Model:GetStagesAchievementInfos(stageId, isFighting)
end

--- 获取关卡是否通关
---@param stageId number 关卡Id
function XMainLine2Agency:IsStagePass(stageId)
    return self._Model:IsStagePass(stageId)
end

--- 关卡是否配置怪物上场
---@param stageId number 关卡Id
function XMainLine2Agency:IsStageMonster(stageId)
    local stageCfg = self:GetConfigStage(stageId)
    if stageCfg.MonsterHead or stageCfg.MonsterHalfBody then
        return true
    end

    return false
end

--- 关卡是否配置成就
---@param stageId number 关卡Id
function XMainLine2Agency:IsStageAchievement(stageId)
    local stageIds = self._Model:GetStageStageIds(stageId)
    for _, stageId in ipairs(stageIds) do
        local stageCfg = self._Model:GetConfigStage(stageId)
        if #stageCfg.AchievementDescs > 0 then
            return true
        end
    end

    return false
end

--- 获取关卡所在的关卡列表
---@param stageId number 关卡Id
---@return number[] 关卡Id列表
function XMainLine2Agency:GetStageStageIds(stageId)
    return self._Model:GetStageStageIds(stageId)
end

--- 关卡是否显示战中提示面板
---@param stageId number 关卡Id
function XMainLine2Agency:IsShowFightInstruction(stageId)
    if not self:IsStageMonster(stageId) then
        return true
    end
    if self:IsStageAchievement(stageId) then
        return true
    end

    return false
end

--- 获取成就完成情况
---@param achievement number 已完成成就 位字段
function XMainLine2Agency:GetAchievementMap(achievement)
    return self._Model:GetAchievementMap(achievement)
end

--- 获取客户端配置表参数
---@param key string 参数key
---@param index number 参数下标
function XMainLine2Agency:GetClientConfigParams(key, index)
    return self._Model:GetClientConfigParams(key, index)
end


--region Fuben ----------------------------------------------------------------------------------------------------------------------
--- 开始战斗前获取数据
---@param stage XTableStage
function XMainLine2Agency:PreFight(stage, teamId, isAssist, challengeCount)
    local preFight = {}
    preFight.CardIds = {}
    preFight.RobotIds = {}
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1
    if not stage.RobotId or #stage.RobotId <= 0 then
        local teamData = XDataCenter.TeamManager.GetTeamData(teamId)
        for i, v in pairs(teamData) do
            local isRobot = XEntityHelper.GetIsRobot(v)
            preFight.RobotIds[i] = isRobot and v or 0
            preFight.CardIds[i] = isRobot and 0 or v
        end
        preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
        preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
    else
        for i, v in pairs(stage.RobotId) do
            preFight.RobotIds[i] = v
        end
        -- 设置默认值
        preFight.CaptainPos = 1
        preFight.FirstFightPos = 1
    end
    return preFight
end

-- 战斗胜利，弹结算界面
function XMainLine2Agency:ShowReward(winData)
    -- 记录章节最后打的关卡
    self._Model:SetLastPassStage(winData.StageId)

    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    local teleportInfo = fubenAgency:GetStageTeleportInfo()
    if teleportInfo then
        -- 跳转下一关战斗
        -- 打开黑幕避免进入战斗前打开关卡界面
        XLuaUiManager.Open("UiBiancaTheatreBlack")
        local team = XDataCenter.TeamManager.GetXTeamByStageId(teleportInfo.SkipStageId)
        fubenAgency:EnterFightByStageId(teleportInfo.SkipStageId, team:GetId(), nil, nil, nil, function()
            XLuaUiManager.Remove("UiBiancaTheatreBlack")
        end)
    else
        -- 结算界面
        XLuaUiManager.Open("UiMainLine2Settlement", winData)
    end
end
--endregion ----------------------------------------------------------------------------------------------------------------------------------

--region open ui start ----------------------------------------------------------------------------------------------------------------------

--- 打开章节UI界面
---@param mainId number 主章节Id
---@param chapterId number 章节Id
---@param stageId number 关卡Id
---@param isOpenStageDetail boolean 是否打开关卡详情
function XMainLine2Agency:OpenChapterUi(mainId, chapterId, stageId, isOpenStageDetail)
    if not chapterId then
        local mainCfg = self._Model:GetConfigMain(mainId)
        chapterId = mainCfg.ChapterIds[1]
    end

    local isUnlock, tips = self:IsChapterUnlock(chapterId)
    if isUnlock then
        XLuaUiManager.Open("UiMainLine2Chapter", mainId, chapterId, stageId, isOpenStageDetail)
        self:RemoveMainRedTimeIdShow(mainId)
    else
        XUiManager.TipError(tips)
    end
end

--- 跳转接口
---@param chapterId number 章节Id
---@param stageId number 关卡Id
---@param isOpenStageDetail boolean 是否打开关卡详情
function XMainLine2Agency:SkipToMainLine2(chapterId, stageId, isOpenStageDetail)
    local mainId = self:GetChapterMainId(chapterId, true)
    self:OpenChapterUi(mainId, chapterId, stageId, isOpenStageDetail)
end

--endregion ----------------------------------------------------------------------------------------------------------------------------------


return XMainLine2Agency