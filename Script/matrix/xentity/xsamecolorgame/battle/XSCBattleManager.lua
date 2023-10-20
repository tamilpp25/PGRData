---@class XSCBattleManager
local XSCBattleManager = XClass(nil, "XSCBattleManager")
local XSCBuff = require("XEntity/XSameColorGame/Battle/XSCBuff")
local XSCBattleRoleSkill = require("XEntity/XSameColorGame/Battle/XSCBattleRoleSkill")
local ShowScorePara = 0.1 -- 消除分数的放大/缩小倍数，只用于消求过程ActionType.ActionItemRemove，分数结算ActionType.ActionSettleScore由服务器计算好
local ACTION_TYPE = XEnumConst.SAME_COLOR_GAME.ACTION_TYPE

---@type function
---@return XSCBattleBallInfo
local ChangeItemPos = function(item)--转换服务器坐标的参考基准
    local tagItem = {ItemId = item.ItemId,
                 PositionX = item.PositionX + 1,
                 PositionY = item.PositionY + 1,
                 ItemType = item.ItemType,
    }
    return tagItem
end

---@type function
---@return XSCBattleBallInfo[]
local ChangeItemPosList = function(itemList)--转换服务器坐标的参考基准
    ---@type XSCBattleBallInfo[]
    local tagItemList = {}
    ---@type XSCBattleBallInfo[]
    local tagItemDic = {}
    -- v1.31-爆炸剔除重复球
    for _, item in pairs(itemList) do
        ---@type XSCBattleBallInfo
        local pos = ChangeItemPos(item)
        local key = XSameColorGameConfigs.CreatePosKey(pos.PositionX, pos.PositionY)
        if not tagItemDic[key] or
                (tagItemDic[key].ItemType ~= XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.BOOM_CENTER and 
                        pos.ItemType == XEnumConst.SAME_COLOR_GAME.BALL_REMOVE_TYPE.BOOM_CENTER)
        then
            tagItemDic[key] = pos
        end
    end

    for _, item in pairs(tagItemDic) do
        table.insert(tagItemList, item)
    end
    return tagItemList
end

---@type function
---@return XSCBattleDropBallInfo[]
local ChangeDropItemPosList = function(dropItemList)--转换服务器坐标的参考基准
    local tagDropItemList = {}
    for _,item in pairs(dropItemList) do
        local pos = {}
        pos.ItemId = item.ItemId
        pos.StartPositionX = item.StartPositionX + 1
        pos.StartPositionY = item.StartPositionY + 1
        pos.EndPositionX = item.EndPositionX + 1
        pos.EndPositionY = item.EndPositionY + 1
        table.insert(tagDropItemList, pos)
    end
    return tagDropItemList
end

---@type function[]
XSCBattleManager.DoAction = {
    ---@param self XSCBattleManager
    [ACTION_TYPE.MAP_INIT] = function(self, action)--地图初始化
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.BallList = ChangeItemPosList(action.ItemList)
        
        self:SetLeftTime(action.LeftTime)
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_MAP_INIT, param)
    end,
    
    ---@param self XSCBattleManager
    [ACTION_TYPE.ITEM_REMOVE] = function(self, action)--消除
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.RemoveBallList = ChangeItemPosList(action.ItemList)
        param.CurrentScore = math.floor(action.CurrentScore * ShowScorePara)
        param.CurrentSkillId = self:GetCurUsingSkillId()
        
        self:DoCountCombo(action.CurrentCombo)
        self.IsActionPlayingDic[action.ActionType] = true
        XScheduleManager.ScheduleOnce(function()
            XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALL_REMOVE, param)
        end, 150)
    end,
    
    ---@param self XSCBattleManager
    [ACTION_TYPE.ITEM_DROP] = function(self, action)--下落
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.DropBallList = ChangeDropItemPosList(action.DropItemList)
        
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALL_DROP, param)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.ITEM_CREATE_NEW] = function(self, action)--增球
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.AddBallList = ChangeItemPosList(action.ItemList)
        
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALL_ADD, param)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.MAP_SHUFFLE] = function(self, action)--洗球
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.BallList = ChangeItemPosList(action.ItemList)
        
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_SHUFFLE, param)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.GAME_INTERRUPT] = function(self, action)--中断
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_INTERRUPT, param)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.SETTLE_SCORE] = function(self, action)--此行动只占位，数据存储和表演逻辑在其他地方
        self.IsActionPlayingDic[action.ActionType] = true
        self:ShowSettleScore()
        self:DoActionFinish(action.ActionType)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.ITEM_SWAP] = function(self, action)--换球
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.SourceBall = ChangeItemPos(action.Source)
        param.DestinationBall = ChangeItemPos(action.Destination)
        
        self:ChangeRound(action.CurRound)
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALL_SWAP, param)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.STEP_ADD] = function(self, action)--增加步数
        if self:IsTimeType() then
            self:SetLeftTime(action.Step)
            XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_LEFT_TIME_CHANGE)
        else
            ---@type XSCBattleActionInfo
            local param = {}
            param.ActionType = action.ActionType
            param.Step = action.Step
            
            self:SetExtraStep(action.Step)
            self.IsActionPlayingDic[action.ActionType] = true
            XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ADD_STEP, param)
        end
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.STEP_SUB] = function(self, action)--减少步数
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.Step = action.Step
        
        self:SetExtraStep(-action.Step)
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_SUB_STEP, param)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.ITEM_CHANGE_COLOR] = function(self, action)--球换色
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.BallList = ChangeItemPosList(action.ItemList)
        
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALL_CHANGE_COLOR, param)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.BUFF_ADD] = function(self, action)--增加玩家buff
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        
        if action.BossId == 0 then
            local buff = self:GetBuff(action.BuffId, action.BuffUid)
            self:AddShowBuff(buff)
            self:AddCountDownDic(string.format("Buff_%d", action.BuffUid), buff)
        end
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ADD_BUFF, param)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.BUFF_REMOVE] = function(self, action)--移除buff
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        
        self:RemoveShowBuff(action.BuffUid)
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_SUB_BUFF, param)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.BOSS_RELEASE_SKILL] = function(self, action)--boss技能
        self.IsActionPlayingDic[action.ActionType] = true
        self:DoActionFinish(action.ActionType)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.BOSS_SKIP_SKILL] = function(self, action)--boss跳过技能
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.BossSkillId = action.BossSkillId
        
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BOSS_SKIP_SKILL, param)
        self:DoActionFinish(action.ActionType)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.ENERGY_CHANGE] = function(self, action)--能量改变
        --local param = {EnergyChange = action.EnergyChange,
        --    EnergyChangeFrom = action.EnergyChangeType,
        --    ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        --XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ENERGYCHANGE, param)
        self:DoActionFinish(action.ActionType)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.SKILL_CD_CHANGE] = function(self, action)--技能cd改变
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.SkillGroupId = action.SkillId
        param.LeftCd = action.LeftCd
        
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_CD_CHANGE, param)
        self:DoActionFinish(action.ActionType)

        -- 固定时间的技能通过NotifySameColorGameUpdate来结束技能 例如：v4.0的白毛剑气技能5秒后结束技能
        self:ClearComboCount()
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.LEFT_TIME_CHANGE] = function(self, action)--关卡剩余时间改变
        self:SetLeftTime(action.LeftTime)
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_LEFT_TIME_CHANGE)
        -- 通过XRpc.NotifySameColorGameUpdate直接刷新的action，不走DoActionFinish的流程
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.BUFF_LEFT_TIME_CHANGE] = function(self, action)--buff剩余时间改变
        -- 通过XRpc.NotifySameColorGameUpdate直接刷新的action，不走DoActionFinish的流程
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BUFF_LEFT_TIME_CHANGE)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.MAP_RESET] = function(self, action)--棋盘重置
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.BallList = ChangeItemPosList(action.ItemList)
        
        self.IsActionPlayingDic[action.ActionType] = true
        local isStartSkill = self:GetPrepSkill() ~= nil
        if isStartSkill then
            -- 开始技能的棋盘重置，阻塞播过渡表现
            XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_MAP_RESET, param)
            self.Resetting = true
            XScheduleManager.ScheduleOnce(function()
                self.Resetting = false
            end, XEnumConst.SAME_COLOR_GAME.TIME_USE_SKILL_MASK * 1000)
        else
            -- 结束技能时的棋盘重置，存在跳过动画阻塞的技能，延迟重置，等球全部回收完毕
            XScheduleManager.ScheduleOnce(function()
                XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_MAP_RESET, param)
            end, XEnumConst.SAME_COLOR_GAME.TIME_BALL_REMOVE * 1000)

            self.Resetting = true
            XScheduleManager.ScheduleOnce(function()
                self.Resetting = false
            end, (XEnumConst.SAME_COLOR_GAME.TIME_BALL_REMOVE + XEnumConst.SAME_COLOR_GAME.TIME_USE_SKILL_MASK) * 1000)
        end
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.TIME_ADD] = function(self, action)--增加时间
        self:SetLeftTime(action.LeftTime)
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_LEFT_TIME_CHANGE)
    end,

    ---@param self XSCBattleManager
    [ACTION_TYPE.ITEM_SWAP_EX] = function(self, action)--棋盘交换列
        ---@type XSCBattleActionInfo
        local param = {}
        param.ActionType = action.ActionType
        param.SourceBallList = ChangeItemPosList(action.Sources)
        param.DestinationBallList = ChangeItemPosList(action.Destinations)
        --排序
        table.sort(param.SourceBallList, function(a, b)
            return a.PositionY > b.PositionY
        end)
        table.sort(param.DestinationBallList, function(a, b)
            return a.PositionY > b.PositionY
        end)

        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALL_SWAP_EX, param)
    end,
}

function XSCBattleManager:Ctor()
    self:Init()
    self:InitRole()
    self.ActionList = nil
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_FINISH, self.ActionFinish, self)
end

function XSCBattleManager:Init()
    self.ActionSchedule = 1
    ---@type table<number, boolean> key = XEnumConst.SAME_COLOR_GAME.ACTION_TYPE
    self.IsActionPlayingDic = {}
    self.IsAnimeFinish = true
    self.IsActionAllFinish = true
    self.ComboCount = 0
    self.MaxComboCount = 0--最大combo数量
    self.BattleRound = 0
    ---通过技能加减的来的步数
    self.ExtraStep = 0
    ---@type XSCBuff[]
    self.CountdownDic = {}
    ---@type XSCBuff[]
    self.BuffDic = {}
    self.BuffKeyCount = 0
    ---@type XSCBuff[]
    self.ShowBuffList = {}
    self.ScoreData = {}
    self.BossSkill = 0
    self.BossSkillIndex = -1
    ---@type XSCBuff[]
    self.BossBuffList = {}
    self.CurEnergy = 0
    self.EnergyChangeDataDic = {}
    self.EnergyChangeShowList = {}
    self.IsHintAutoEnergy = true
    self.IsShowingEnergyChange = false
    self.LeftTime = 0--剩余时间
    self.Resetting = false
    
    self:InitRoleSkill()
end

function XSCBattleManager:GetIsResetting()
    return self.Resetting
end

--region Action
function XSCBattleManager:DoActionFinish(actionType)
    XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_FINISH, actionType)
end

-- 执行刷新Action，不需要一个接一个
function XSCBattleManager:DoUpdateActionList(actions)
    -- 阻塞的action列表是否正在执行中
    -- 部分通过时间update触发的刷新action，会与正在执行的action列表冲突，塞到action列表最后执行
    local isDealingAction = self.ActionList ~= nil and self.ActionSchedule < #self.ActionList

    for _, action in ipairs(actions) do
        if isDealingAction and action.ActionType == ACTION_TYPE.MAP_RESET then
            table.insert(self.ActionList, action)
        else
            self.DoAction[action.ActionType](self, action)
        end
    end
end

function XSCBattleManager:SetActionList(actions)
    self.ActionList = actions
    self.ActionSchedule = 1
    self.IsActionPlayingDic = {}
    self:_SetPreData()
end

function XSCBattleManager:_SetPreData()--(不按行动顺序)
    local comboRecord = {}
    local ballRemoveCount = 0
    for _,action in pairs(self.ActionList or {}) do
        if action.ActionType == ACTION_TYPE.SETTLE_SCORE then
            comboRecord = action.ComboRecord
            self:SetScoreData(action)
        end
        if action.ActionType == ACTION_TYPE.BOSS_RELEASE_SKILL then
            self.BossSkill = action.BossSkillId
            self.BossSkillIndex = self.BossSkillIndex + 1
        end
        if action.ActionType == ACTION_TYPE.BOSS_SKIP_SKILL then
            self.BossSkillIndex = self.BossSkillIndex + 1
        end
        if action.ActionType == ACTION_TYPE.BUFF_ADD then
            if action.BossId and action.BossId > 0 then
                table.insert(self.BossBuffList,self:GetBuff(action.BuffId, action.BuffUid))
            end
        end
        if action.ActionType == ACTION_TYPE.ITEM_REMOVE then
            ballRemoveCount = ballRemoveCount + 1
        end
        if action.ActionType == ACTION_TYPE.ENERGY_CHANGE then
            self:AddEnergyChangeData(action)
        end
    end

    -- 技能期间触发的消球，消球次数累加起来
    local preSkill = self:GetPrepSkill()
    if preSkill then
        ballRemoveCount = preSkill:AddBallRemoveCount(ballRemoveCount)
    end

    if ballRemoveCount > 0 then
        XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLE_SHOW_COMBO, ballRemoveCount)
    end
end

function XSCBattleManager:GetActionList()
    return self.ActionList
end

function XSCBattleManager:ClearActionList()
    self.ActionList = nil
end

function XSCBattleManager:ActionFinish(actionType)
    self.IsActionPlayingDic[actionType] = nil
    self:CheckActionList()
end

function XSCBattleManager:CheckActionList()
    if self.ActionList and not self:CheckActionPlaying() then
        local action = self.ActionList[self.ActionSchedule]
        local nextAction = self.ActionList[self.ActionSchedule + 1]
        local IsSpecial = false

        if self.ActionSchedule == 1 then
            XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLE_SHOW_MASK, true)
            self.IsActionAllFinish = false
        end

        if action and nextAction then
            if action.ActionType == ACTION_TYPE.ITEM_DROP and
                    nextAction.ActionType == ACTION_TYPE.ITEM_CREATE_NEW then
                self.ActionSchedule = self.ActionSchedule + 2
                IsSpecial = true
                self.DoAction[action.ActionType](self, action)
                self.DoAction[nextAction.ActionType](self, nextAction)
            end
        end

        if not IsSpecial then
            if action then
                self.ActionSchedule = self.ActionSchedule + 1
                self.DoAction[action.ActionType](self, action)
            else
                self:ClearActionList()
                self.ActionSchedule = 1
                self:ClearComboCount()
                self.IsActionAllFinish = true
                self:CheckCloseMask()
                self:ClearCurSuingSkill()
                XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_LIST_OVER)
            end
        end
    end
end

function XSCBattleManager:CheckActionPlaying()
    for _, playing in pairs(self.IsActionPlayingDic or {}) do
        if playing then
            return true
        end
    end
    return false
end

function XSCBattleManager:CheckAnimeAndActionIsAllFinish()
    -- 跳过动画阻塞
    local preSkill = self:GetPrepSkill()
    if preSkill then
        local skillId = preSkill:GetSkillId()
        if XEnumConst.SAME_COLOR_GAME.SKILL_ANIM_NOT_MASK[XSameColorGameConfigs.GetSkillType(skillId)] then
            return self.IsActionAllFinish
        end
    end

    -- 默认：动画、ActionList都会打开mask阻塞玩家的操作
    return self.IsAnimeFinish and self.IsActionAllFinish
end

function XSCBattleManager:CheckCloseMask()
    if self:CheckAnimeAndActionIsAllFinish() then
        XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLE_SHOW_MASK, false)
    end
end
--endregion

--region Score
function XSCBattleManager:GetScoreData()
    return self.ScoreData
end

function XSCBattleManager:SetScoreData(data)
    self.ScoreData = data
    self:SetMaxComboCount(data.TotalCombo)
end

function XSCBattleManager:ShowSettleScore()
    -- 不阻塞的技能，不需要延迟播回能
    local isNotMask = false
    local preSkill = self:GetPrepSkill()
    if preSkill then
        local skillId = preSkill:GetSkillId()
        isNotMask = XEnumConst.SAME_COLOR_GAME.SKILL_ANIM_NOT_MASK[XSameColorGameConfigs.GetSkillType(skillId)]
    end

    local waitTime = 0--isNotMask and 0 or 1
    self:ShowEnergyChange(XEnumConst.SAME_COLOR_GAME.ENERGY_CHANGE_FROM.COMBO, waitTime)--连击回能
    self:ShowEnergyChange(XEnumConst.SAME_COLOR_GAME.ENERGY_CHANGE_FROM.BUFF, waitTime)--Buff回能
    XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_SETTLE_SCORE)
end
--endregion

--region Energy
function XSCBattleManager:DoAutoEnergyHint()
    if self.IsHintAutoEnergy then
        self.IsHintAutoEnergy = false
        XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLE_AUTO_ENERGY, self.BattleRound + 1)
    end
end

function XSCBattleManager:GetCurEnergy()
    return self.CurEnergy
end

function XSCBattleManager:SetCurEnergy(energy)
    self.CurEnergy = energy
end

function XSCBattleManager:AddEnergy(num)
    self.CurEnergy = self.CurEnergy + num
end

function XSCBattleManager:AddEnergyChangeData(energyChangeData)
    local data = {
        EnergyChange = energyChangeData.EnergyChange,
        EnergyChangeFrom = energyChangeData.EnergyChangeType,
    }
    self.EnergyChangeDataDic[energyChangeData.EnergyChangeType] = data
end

function XSCBattleManager:ShowEnergyChange(type, waitTime)
    if self.EnergyChangeDataDic[type] then
        table.insert(self.EnergyChangeShowList, {Type = type, WaitTime = waitTime or 0})
        self:CheckEnergyChange()
    end
end

function XSCBattleManager:CheckEnergyChange()
    local showInfo = self.EnergyChangeShowList[1]
    local changeData = showInfo and self.EnergyChangeDataDic[showInfo.Type]
    if not self.IsShowingEnergyChange and changeData then
        self.IsShowingEnergyChange = true
        self.EnergyChangeDataDic[showInfo.Type] = nil
        table.remove(self.EnergyChangeShowList, 1)
        self:AddEnergy(changeData.EnergyChange)
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ENERGY_CHANGE, changeData)
        XScheduleManager.ScheduleOnce(function()
            self.IsShowingEnergyChange = false
            self:CheckEnergyChange()
        end, showInfo.WaitTime * 1000)
    end
end
--endregion

--region Combo
function XSCBattleManager:DoCountCombo(combo)
    self.ComboCount = self.ComboCount + combo
end

function XSCBattleManager:GetCountCombo()
    return self.ComboCount
end

function XSCBattleManager:GetDamageCount()
    return self.ScoreData.TotalScore or 0
end

function XSCBattleManager:GetMaxComboCount()
    return self.MaxComboCount
end

function XSCBattleManager:SetMaxComboCount(comboCount)
    self.MaxComboCount = comboCount > self.MaxComboCount and comboCount or self.MaxComboCount
end

function XSCBattleManager:GetBattleComboLevel(combo)
    local comboLevel = 1
    local levelLimitList = XMVCA.XSameColor:GetClientCfgValue("BattleComboLevel")
    for level,limit in pairs(levelLimitList or {}) do
        if combo >= tonumber(limit) then
            comboLevel = level
        end
    end
    return comboLevel
end

-- v4.0 处于技能释放中，继续累加combo数量
function XSCBattleManager:ClearComboCount()
    if not self:GetPrepSkill() and not self.ActionList then
        self.ComboCount = 0
    end
end

function XSCBattleManager:SetIsAnimeFinish(IsFinish)
    self.IsAnimeFinish = IsFinish
end
--endregion

--region Buff
---@return XSCBuff
function XSCBattleManager:GetBuff(buffId, buffUid)
    local buff = self.BuffDic[buffUid]
    if buff == nil then
        buff = XSCBuff.New(buffId, buffUid)
        self.BuffDic[buffUid] = buff
    end
    return buff
end

function XSCBattleManager:GetShowBuffList()--当前生效的buff
    return self.ShowBuffList
end

function XSCBattleManager:AddShowBuff(buff)
    table.insert(self.ShowBuffList, 1, buff)
end

function XSCBattleManager:RemoveShowBuff(buffUid)
    for index = #self.ShowBuffList, 1, -1 do
        local buff = self.ShowBuffList[index]
        if buff and buff:GetBuffUId() == buffUid then
            table.remove(self.ShowBuffList, index)
        end
    end
end

function XSCBattleManager:ShowBossBuff()
    if self.BossBuffList and next(self.BossBuffList) then
        for _,buff in pairs(self.BossBuffList) do
            self:AddShowBuff(buff)
            self:AddCountDownDic(string.format("Buff_%d", buff:GetBuffId()), buff)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ADD_BUFF)
        self.BossBuffList = {}
    end
end

---@param entity XSCBuff
function XSCBattleManager:AddCountDownDic(key, entity)
    entity:SetCountDown()
    self.CountdownDic[key] = entity
end
--endregion

--region Role
function XSCBattleManager:InitRole()
    ---@type XSCRole
    self._CurRole = false
end

function XSCBattleManager:GetCurRole()
    return self._CurRole
end

---@param role XSCRole
function XSCBattleManager:SetCurRole(role)
    self._CurRole = role
end
--endregion

--region RoleSkill
function XSCBattleManager:InitRoleSkill()
    ---@type XSCBattleRoleSkill
    self.InPrepSkill = nil
    self.RoleMainSkillId = 0
    ---@type XSCBattleRoleSkill[]
    self.BattleRoleSkillDic = {}
    self._CurUsingSkillId = false
    self._IsAfterSkill = false
end

---@return XSCBattleRoleSkill
function XSCBattleManager:GetPrepSkill()
    return self.InPrepSkill
end

---@param skill XSCBattleRoleSkill
function XSCBattleManager:SetPrepSkill(skill)
    self.InPrepSkill = skill
end

function XSCBattleManager:ClearPrepSkill()
    if self.InPrepSkill then
        self.InPrepSkill:Clear()
        self.InPrepSkill = nil
    end
end

---@param skill XSCBattleRoleSkill
function XSCBattleManager:CheckIsPrepSkill(skill)
    if self.InPrepSkill == nil then
        return false
    else
        return self.InPrepSkill == skill
    end
end

function XSCBattleManager:CheckPrepSkillIsMain(skillId)
    return self.RoleMainSkillId == skillId
end

function XSCBattleManager:SetRoleMainSkill(skillId)
    self.RoleMainSkillId = skillId
end

---@return XSCBattleRoleSkill
function XSCBattleManager:GetBattleRoleSkill(skillGroupId)
    local result = self.BattleRoleSkillDic[skillGroupId]
    if result == nil then
        result = XSCBattleRoleSkill.New(skillGroupId)
        self.BattleRoleSkillDic[skillGroupId] = result
    end
    return result
end

function XSCBattleManager:ClearCurSuingSkill()
    if self:GetPrepSkill() then
        return
    end
    self:SetCurUsingSkillId(false)
    self:SetIsAfterSkill(false)
end

function XSCBattleManager:SetCurUsingSkillId(skillId)
    self._CurUsingSkillId = skillId
end

---@return number
function XSCBattleManager:GetCurUsingSkillId()
    return self._CurUsingSkillId
end

function XSCBattleManager:GetIsAfterSkill()
    return self._IsAfterSkill
end

function XSCBattleManager:SetIsAfterSkill(value)
    self._IsAfterSkill = value
end
--endregion

--region BossSkill
function XSCBattleManager:GetBossSkill()
    return self.BossSkill
end

function XSCBattleManager:ClearBossSkill()
    self.BossSkill = 0
end

function XSCBattleManager:GetBossSkillIndex()
    return self.BossSkillIndex
end

function XSCBattleManager:ShowBossSkill()
    XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BOSS_SKILL)
end
--endregion

--region BattleRound
function XSCBattleManager:GetBattleRound()
    return self.BattleRound
end

function XSCBattleManager:ChangeRound(round)
    if round ~= self.BattleRound then
        self.BattleRound = round
        self.IsHintAutoEnergy = true
        local removeList = {}
        for key,entity in pairs(self.CountdownDic or {}) do
            if next(entity) then
                entity:DoCountDown()
                if entity:GetCountDown() <= 0 then
                    table.insert(removeList,key)
                end
            else
                table.insert(removeList,key)
            end
        end
        for _,key in pairs(removeList or {}) do
            self.CountdownDic[key] = nil
        end

        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ROUND_CHANGE)
    end
end

function XSCBattleManager:ResetRound()
    self.BattleRound = 0
end

-- 获取挑战剩余回合数
function XSCBattleManager:GetBattleStep(boss)
    return boss:GetMaxRound() - self:GetBattleRound() + self.ExtraStep
end

function XSCBattleManager:SetExtraStep(step)
    self.ExtraStep = self.ExtraStep + step
end
--endregion

--region BattleTime
-- 获取当前挑战是否限时关卡
function XSCBattleManager:IsTimeType()
    local bossManager = XDataCenter.SameColorActivityManager.GetBossManager()
    local boss = bossManager:GetCurrentChallengeBoss()
    return boss:IsTimeType()
end

-- 获取挑战剩余时间
function XSCBattleManager:GetLeftTime()
    return self.LeftTime
end

function XSCBattleManager:SetLeftTime(leftTime)
    self.LeftTime = leftTime
end

function XSCBattleManager:UseSkillPauseTime(skillGroupId)
    if self:GetCurRole():GetMainSkillGroupId() ~= skillGroupId then
        XDataCenter.SameColorActivityManager.RequestPauseResume(true, self:IsTimeType())
    end
end

function XSCBattleManager:UseSkillResumeTime(skillGroupId, cb)
    if self:GetCurRole():GetMainSkillGroupId() ~= skillGroupId then
        XDataCenter.SameColorActivityManager.RequestPauseResume(false, self:IsTimeType(), cb)
    else
        if cb then cb() end
    end
end
--endregion

return XSCBattleManager