local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

--- @class XBossInshotAgency : XFubenActivityAgency
--- @field private _Model XBossInshotModel
local XBossInshotAgency = XClass(XFubenActivityAgency, "XBossInshotAgency")
function XBossInshotAgency:OnInit()
    -- 初始化一些变量
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.BossInshot)
end

function XBossInshotAgency:InitRpc()
    XRpc.NotifyBossInshotData = handler(self, self.NotifyBossInshotData)
    XRpc.NotifyBossInshotPlayback = handler(self, self.NotifyBossInshotPlayback)
end

function XBossInshotAgency:InitEvent()
    self:AddAgencyEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.OnFubenSettleReward,self)
end

function XBossInshotAgency:RemoveEvent()
    self:RemoveAgencyEvent(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.OnFubenSettleReward,self)
end

--- 获取战斗队伍最大角色数量
function XBossInshotAgency:GetBattleTeamMaxCharCount()
    local activityId = self._Model:GetActivityId()
    local charCnt = self._Model:GetActivityPositionNum(activityId)
    return charCnt
end

--- 获取战斗房间的成员Id列表
function XBossInshotAgency:GetActivityBattleRoleRoomEntities()
    local entities = {}
    local activityId = self._Model:GetActivityId()
    local ids = self._Model:GetActivityCharacterIds(activityId)
    for _, id in ipairs(ids) do
        local characterCfg = self._Model:GetConfigBossInshotCharacter(id)
        if characterCfg.CharacterId ~= 0 then
            local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterCfg.CharacterId)
            if isOwn then
                local entity = XMVCA.XCharacter:GetCharacter(characterCfg.CharacterId)
                table.insert(entities, entity)
            end
        end
        if characterCfg.RobotId ~= 0 then
            local entity = XRobotManager.GetRobotById(characterCfg.RobotId)
            table.insert(entities, entity)
        end
    end
    return entities
end

--- 获取角色选择天赋Id列表
function XBossInshotAgency:GetCharacterSelectTalentIds(characterId)
    return self._Model:GetCharacterSelectTalentIds(characterId)
end

--- 角色天赋是否选择
function XBossInshotAgency:IsCharacterTalentSelect(characterId, talentId)
    return self._Model:IsCharacterTalentSelect(characterId, talentId)
end

--- 角色天赋是否解锁
function XBossInshotAgency:IsCharacterTalentUnlock(characterId, talentId)
    return self._Model:IsCharacterTalentUnlock(characterId, talentId)
end

--- 设置角色详情界面显示的天赋选择
function XBossInshotAgency:SetCharacterDetailTalentPos(talentPos)
    self._Model:SetCharacterDetailTalentPos(talentPos)
end

--- 获取角色详情界面显示的天赋选择
function XBossInshotAgency:GetCharacterDetailTalentPos(talentPos)
    return self._Model:GetCharacterDetailTalentPos(talentPos)
end

--- 获取关卡最大分数
function XBossInshotAgency:GetStageMaxScore(stageId)
    return self._Model:GetStageMaxScore(stageId)
end

---------------------------------------- #region Rpc ----------------------------------------
--- 通知跃升挑战数据
function XBossInshotAgency:NotifyBossInshotData(data)
    self._Model:NotifyBossInshotData(data)
end

--- 通知回放开关是否开启
function XBossInshotAgency:NotifyBossInshotPlayback(data)
    self._Model:NotifyBossInshotPlayback(data)
end

--- 进战斗前，选择技能请求
function XBossInshotAgency:BossInshotSelectSkillRequest(stageId, eventId)
    local req = { StageId = stageId, EventId = eventId }
    XNetwork.Call("BossInshotSelectSkillRequest", req, function(res)
        
    end)
end

--- 选择天赋请求
function XBossInshotAgency:BossInshotSelectTalentRequest(characterId, pos, talentId, cb)
    local req = { CharacterId = characterId, SelectTalentIds = {} }
    local selectTalentIds = self:GetCharacterSelectTalentIds(characterId)
    for i = 1, XEnumConst.BOSSINSHOT.WEAR_TALENT_MAX_CNT do
        req.SelectTalentIds[i] = selectTalentIds[i] or 0
    end
    req.SelectTalentIds[pos] = talentId
    XNetwork.CallWithAutoHandleErrorCode("BossInshotSelectTalentRequest", req, function(res)
        self._Model:UpdateCharacterSelectTalentIds(characterId, req.SelectTalentIds)
        if cb then cb() end
    end)
end

--- 排行榜请求
function XBossInshotAgency:BossInshotQueryRankRequest(characterCfgId, bossId, isTotalRank, cb)
    bossId = bossId or 0
    
    -- 优先从缓存数据取
    local INTERVAL_TIME = 30 -- 间隔时间
    local nowTime = XTime.GetServerNowTimestamp()
    local rankData = self._Model:GetRankData(characterCfgId, bossId, isTotalRank)
    if rankData and (nowTime - rankData.Time) < INTERVAL_TIME then
        if cb then cb(rankData.Data) end
        return
    end
    
    local req = { CharacterCfgId = characterCfgId, BossId = bossId, IsTotalRank = isTotalRank }
    XNetwork.Call("BossInshotQueryRankRequest", req, function(res)
        self._Model:SaveRankData(characterCfgId, bossId, isTotalRank, nowTime, res)
        if cb then cb(res) end
    end)
end
---------------------------------------- #endregion Rpc ----------------------------------------

---------------------------------------- #region 副本入口扩展 ----------------------------------------
function XBossInshotAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XMVCA.XFuben:GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

--- 打开玩法界面
function XBossInshotAgency:ExOpenMainUi()
    local isOpen, tips = self._Model:IsActivityOpen()
    if not isOpen then
        XUiManager.TipError(tips)
        return false
    end

    if not XMVCA.XSubPackage:CheckSubpackageByIdAndIntercept(XEnumConst.SUBPACKAGE.TEMP_VIDEO_SUBPACKAGE_ID.GAMEPLAY) then
        return false
    end

    XLuaUiManager.Open("UiBossInshotMain")
    self._Model:RemoveFirstEnterRed()
    return true
end
---------------------------------------- #endregion 副本入口扩展 ----------------------------------------

---------------------------------------- #region 战斗 ----------------------------------------
--- 开始战斗前获取数据
---@param stage XTableStage
function XBossInshotAgency:PreFight(stage, teamId, isAssist, challengeCount)
    self.FightStageId = stage.StageId
    local preFight = {}
    preFight.CardIds = {0, 0, 0}
    preFight.RobotIds = {0, 0, 0}
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1

    if stage.RobotId and #stage.RobotId > 0 then
        for i, v in pairs(stage.RobotId) do
            preFight.RobotIds[i] = v
        end
        -- 设置默认值
        preFight.CaptainPos = 1
        preFight.FirstFightPos = 1
    else
        local team = self._Model:GetTeam()
        local teamData = team:GetEntityIds()
        for teamIndex, characterId in pairs(teamData) do
            if XRobotManager.CheckIsRobotId(characterId) then
                preFight.RobotIds[teamIndex] = characterId
            else
                preFight.CardIds[teamIndex] = characterId
            end
        end
        preFight.CaptainPos = team:GetCaptainPos()
        preFight.FirstFightPos = team:GetFirstFightPos()
    end
    return preFight
end

-- 是否自动退出战斗
function XBossInshotAgency.CheckAutoExitFight(stageId)
    return false
end

-- 手动调用退出战斗
function XBossInshotAgency:ExitFight()
    return XMVCA.XFuben:ExitFight()
end

-- 不退出战斗场景，以战斗场景为背景弹结算界面
function XBossInshotAgency:OnFubenSettleReward(settleData)
    if settleData and self.FightStageId == settleData.StageId then
        if settleData.IsWin then
            -- 更新关卡最高分
            self._Model:UpdateMaxScore(settleData)
            XLuaAudioManager.StopAll();
            CS.XRLManager.Camera:LuaResetTrack()
            XLuaUiManager.Open("UiBossInshotSettlement", settleData, true)
            self:SetMouseVisible()
        else
            self:ExitFight()
        end
    end
end

-- 退出战斗场景，战斗胜利，弹结算界面，占位不弹通用胜利
function XBossInshotAgency:ShowReward(settleData)

end

-- 显示鼠标，键盘按Y进入自由模式：鼠标隐藏，视角将自动跟随鼠标移动
function XBossInshotAgency:SetMouseVisible()
    -- 这里只有PC端开启了键鼠以后才能获取到设备
    if CS.XFight.Instance and CS.XFight.Instance.InputSystem then
        local inputKeyboard = CS.XFight.Instance.InputSystem:GetDevice(typeof(CS.XInputKeyboard))
        inputKeyboard.HideMouseEvenByDrag = false
    end
    CS.UnityEngine.Cursor.lockState = CS.UnityEngine.CursorLockMode.None
    CS.UnityEngine.Cursor.visible = true
end

---------------------------------------- #endregion 战斗 ----------------------------------------


---------------------------------------- #region 配置表 ----------------------------------------
--- 获取天赋配置表
function XBossInshotAgency:GetConfigBossInshotTalent(id)
    return self._Model:GetConfigBossInshotTalent(id)
end

--- 获取角色默认穿戴天赋配置表
function XBossInshotAgency:GetCharacterDefaultWearTalentCfg(characterId)
    return self._Model:GetCharacterDefaultWearTalentCfg(characterId)
end

--- 获取角色手动穿戴天赋配置表列表
function XBossInshotAgency:GetCharacterHandWearTalentCfgs(characterId)
    return self._Model:GetCharacterHandWearTalentCfgs(characterId)
end
---------------------------------------- #endregion 配置表 ----------------------------------------


---------------------------------------- #region 跳转和红点 ----------------------------------------
--- 跳转玩法接口
function XBossInshotAgency:SkipToBossInshot()
    return self:ExOpenMainUi()
end

--- 是否显示活动红点
function XBossInshotAgency:IsShowActivityRedPoint()
    return self._Model:IsShowActivityRedPoint()
end
---------------------------------------- #endregion 跳转和红点 ----------------------------------------

return XBossInshotAgency
