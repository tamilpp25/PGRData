
local XSCBattleManager = XClass(nil, "XSCBattleManager")
local XSCBuff = require("XEntity/XSameColorGame/Battle/XSCBuff")
local XSCBattleRoleSkill = require("XEntity/XSameColorGame/Battle/XSCBattleRoleSkill")
local ShowScorePara = 0.1 -- 消除分数的放大/缩小倍数，只用于消求过程ActionType.ActionItemRemove，分数结算ActionType.ActionSettleScore由服务器计算好

local ChangeItemPos = function(item)--转换服务器坐标的参考基准
    local tagItemList = {}
    local tagItem = {ItemId = item.ItemId, PositionX = item.PositionX + 1, PositionY = item.PositionY + 1}
    return tagItem
end

local ChangeItemPosList = function(itemList)--转换服务器坐标的参考基准
    local tagItemList = {}
    local tagItemDic = {}
    -- v1.31-爆炸剔除重复球
    for _,item in pairs(itemList) do
        local pos = {ItemId = item.ItemId, 
                     PositionX = item.PositionX + 1, 
                     PositionY = item.PositionY + 1,
                     ItemType = item.ItemType,  --爆炸类型，详见XSameColorGameConfigs.SkillBoomBallType
        }
        local key = XSameColorGameConfigs.CreatePosKey(pos.PositionX, pos.PositionY)
        if not tagItemDic[key] or
           tagItemDic[key].ItemType ~= XSameColorGameConfigs.BallRemoveType.BoomCenter and pos.ItemType == XSameColorGameConfigs.BallRemoveType.BoomCenter then
            tagItemDic[key] = pos
        end
    end

    for _, item in pairs(tagItemDic) do
        table.insert(tagItemList, item)
    end
    return tagItemList
end

local ChangeDorpItemPosList = function(dropItemList)--转换服务器坐标的参考基准
    local tagDropItemList = {}
    for _,item in pairs(dropItemList) do
        local pos = {ItemId = item.ItemId, StartPositionX = item.StartPositionX + 1, StartPositionY = item.StartPositionY + 1,
            EndPositionX = item.EndPositionX + 1, EndPositionY = item.EndPositionY + 1}
        table.insert(tagDropItemList, pos)
    end
    return tagDropItemList
end

XSCBattleManager.DoAction = {
    [XSameColorGameConfigs.ActionType.ActionMapInit] = function(self, action)--地图初始化
        self:SetLeftTime(action.LeftTime)
        local param = {BallList = ChangeItemPosList(action.ItemList),
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_MAPINIT, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionItemRemove] = function(self, action)--消除
        self:DoCountCombo(action.CurrentCombo)
        local param = {RemoveBallList = ChangeItemPosList(action.ItemList),
            ActionType = action.ActionType, CurrentScore = math.floor(action.CurrentScore * ShowScorePara)}
        self.IsActionPlayingDic[action.ActionType] = true

        XScheduleManager.ScheduleOnce(function()
                --XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLESHOW_SINGLECOMBOPLAY)
                XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALLREMOVE, param)
            end, 150)
    end,

    [XSameColorGameConfigs.ActionType.ActionItemDrop] = function(self, action)--下落
        local param = {DropBallList = ChangeDorpItemPosList(action.DropItemList),
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALLDROP, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionItemCreateNew] = function(self, action)--增球
        local param = {AddBallList = ChangeItemPosList(action.ItemList),
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALLADD, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionShuffle] = function(self, action)--洗球
        local param = {BallList = ChangeItemPosList(action.ItemList),
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_SHUFFLE, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionGameInterrupt] = function(self, action)--中断
        local param = {ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_INTERRUPT, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionSettleScore] = function(self, action)--此行动只占位，数据存储和表演逻辑在其他地方
        self.IsActionPlayingDic[action.ActionType] = true
        self:ShowSettleScore()
        self:DoActionFinish(action.ActionType)
    end,

    [XSameColorGameConfigs.ActionType.ActionSwap] = function(self, action)--换球
        self:ChangeRound(action.CurRound)
        local param = {SourceBall = ChangeItemPos(action.Source),
            DestinationBall = ChangeItemPos(action.Destination),
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALLSWAP, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionAddStep] = function(self, action)--增加步数
        self:SetExtraStep(action.Step)
        local param = {Step = action.Step,
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ADDSTEP, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionSubStep] = function(self, action)--减少步数
        self:SetExtraStep(-action.Step)
        local param = {Step = action.Step,
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_SUBSTEP, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionChangeColor] = function(self, action)--球换色
        local param = {BallList = ChangeItemPosList(action.ItemList),
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BALLCHANGECOLOR, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionAddBuff] = function(self, action)--增加玩家buff
        if action.BossId == 0 then
            local buff = self:GetBuff(action.BuffId, action.BuffUid)
            self:AddShowBuff(buff)
            self:AddCountDownDic(string.format("Buff_%d", action.BuffUid), buff)
        end
        local param = {
            ActionType = action.ActionType
        }
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ADDBUFF, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionRemoveBuff] = function(self, action)--移除buff
        self:RemoveShowBuff(action.BuffUid)
        local param = {
            ActionType = action.ActionType
        }
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_SUBBUFF, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionBossReleaseSkill] = function(self, action)--boss技能
        self.IsActionPlayingDic[action.ActionType] = true
        self:DoActionFinish(action.ActionType)
    end,

    [XSameColorGameConfigs.ActionType.ActionBossSkipSkill] = function(self, action)--boss跳过技能
        local param = {BossSkillId = action.BossSkillId,
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BOSSSKIPSKILL, param)
        self:DoActionFinish(action.ActionType)
    end,

    [XSameColorGameConfigs.ActionType.ActionEnergyChange] = function(self, action)--能量改变
        --local param = {EnergyChange = action.EnergyChange,
        --    EnergyChangeFrom = action.EnergyChangeType,
        --    ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        --XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ENERGYCHANGE, param)
        self:DoActionFinish(action.ActionType)
    end,

    [XSameColorGameConfigs.ActionType.ActionCdChange] = function(self, action)--技能cd改变
        local param = {SkillGroupId = action.SkillId,
            LeftCd = action.LeftCd,
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_CDCHANGE, param)
        self:DoActionFinish(action.ActionType)

        -- 固定时间的技能通过NotifySameColorGameUpdate来结束技能 例如：v4.0的白毛剑气技能5秒后结束技能
        self:ClearComboCount()
    end,

    [XSameColorGameConfigs.ActionType.ActionLeftTimeChange] = function(self, action)--关卡剩余时间改变
        self:SetLeftTime(action.LeftTime)
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_LEFTTIME_CHANGE)
        -- 通过XRpc.NotifySameColorGameUpdate直接刷新的action，不走DoActionFinish的流程
    end,

    [XSameColorGameConfigs.ActionType.ActionBuffLeftTimeChange] = function(self, action)--buff剩余时间改变
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BUFF_LEFTTIME_CHANGE)
        -- 通过XRpc.NotifySameColorGameUpdate直接刷新的action，不走DoActionFinish的流程
    end,

    [XSameColorGameConfigs.ActionType.ActionMapReset] = function(self, action)--棋盘重置
        self.IsActionPlayingDic[action.ActionType] = true
        local param = {BallList = ChangeItemPosList(action.ItemList),
            ActionType = action.ActionType}

        local isStartSkill = self:GetPrepSkill() ~= nil
        if isStartSkill then
            -- 开始技能的棋盘重置，阻塞播过渡表现
            XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_MAPRESET, param)
            self.Resetting = true
            XScheduleManager.ScheduleOnce(function()
                self.Resetting = false
            end, XSameColorGameConfigs.UseSkillMaskTime * 1000)
        else
            -- 结束技能时的棋盘重置，存在跳过动画阻塞的技能，延迟重置，等球全部回收完毕
            XScheduleManager.ScheduleOnce(function()
                XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_MAPRESET, param)
            end, XSameColorGameConfigs.BallRemoveTime * 1000)

            self.Resetting = true
            XScheduleManager.ScheduleOnce(function()
                self.Resetting = false
            end, (XSameColorGameConfigs.BallRemoveTime + XSameColorGameConfigs.UseSkillMaskTime) * 1000)
        end
    end,
}

function XSCBattleManager:Ctor()
    self:Init()
    self.ActionList = nil
    XEventManager.AddEventListener(XEventId.EVENT_SC_ACTION_ACTIONFINISH, self.ActionFinish, self)
end

function XSCBattleManager:Init()
    self.ActionSchedule = 1
    self.ComboCount = 0
    self.BattleRound = 0
    self.ExtraStep = 0--通过技能加减的来的步数
    self.IsActionPlayingDic = {}
    self.CountdownDic = {}
    self.InPrepSkill = nil
    self.BuffDic = {}
    self.BuffKeyCount = 0
    self.ShowBuffList = {}
    self.BattleRoleSkillDic = {}
    self.ScoreData = {}
    self.BossSkill = 0
    self.BossSkillIndex = -1
    self.BossBuffList = {}
    self.IsAnimeFinish = true
    self.IsActionAllFinish = true
    self.IsHintAutoEnergy = true
    self.EnergyChangeDataDic = {}
    self.EnergyChangeShowList = {}
    self.IsShowingEnergyChange = false
    self.CurEnergy = 0
    self.RoleMainSkillId = 0
    self.LeftTime = 0--剩余时间
    self.MaxComboCount = 0--最大combo数量
    self.Resetting = false
end

function XSCBattleManager:DoActionFinish(actionType)
    XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ACTIONFINISH, actionType)
end

function XSCBattleManager:SetActionList(actions)
    self.ActionList = actions
    self.ActionSchedule = 1
    self.IsActionPlayingDic = {}
    self:SetPreData()
end

function XSCBattleManager:AddCountDownDic(key, entity)
    entity:SetCountDown()
    self.CountdownDic[key] = entity
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

function XSCBattleManager:CheckActionPlaying()
    for _,plaing in pairs(self.IsActionPlayingDic or {}) do
        if plaing then
            return true
        end
    end
    return false
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

function XSCBattleManager:GetPrepSkill()
    return self.InPrepSkill
end

function XSCBattleManager:SetPrepSkill(skill)
    self.InPrepSkill = skill
end

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

function XSCBattleManager:ClearPrepSkill()
    if self.InPrepSkill then
        self.InPrepSkill:Clear()
        self.InPrepSkill = nil
    end
end

function XSCBattleManager:GetBossSkill()
    return self.BossSkill
end

function XSCBattleManager:ClearBossSkill()
    self.BossSkill = 0
end

function XSCBattleManager:GetBossSkillIndex()
    return self.BossSkillIndex
end

function XSCBattleManager:GetBattleRound()
    return self.BattleRound
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

function XSCBattleManager:GetCountCombo()
    return self.ComboCount
end

function XSCBattleManager:DoCountCombo(combo)
    self.ComboCount = self.ComboCount + combo
end

function XSCBattleManager:GetDamageCount()
    return self.ScoreData.TotalScore or 0
end

function XSCBattleManager:SetMaxComboCount(comboCount)
    self.MaxComboCount = comboCount > self.MaxComboCount and comboCount or self.MaxComboCount
end

function XSCBattleManager:GetMaxComboCount()
    return self.MaxComboCount
end

function XSCBattleManager:GetScoreData()
    return self.ScoreData
end

function XSCBattleManager:SetScoreData(data)
    self.ScoreData = data
    self:SetMaxComboCount(data.TotalCombo)
end

function XSCBattleManager:SetIsAnimeFinish(IsFinish)
    self.IsAnimeFinish = IsFinish
end

function XSCBattleManager:ShowBossBuff()
    if self.BossBuffList and next(self.BossBuffList) then
        for _,buff in pairs(self.BossBuffList) do
            self:AddShowBuff(buff)
            self:AddCountDownDic(string.format("Buff_%d", buff:GetBuffId()), buff)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ADDBUFF)
        self.BossBuffList = {}
    end
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
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ENERGYCHANGE, changeData)
        XScheduleManager.ScheduleOnce(function()
                self.IsShowingEnergyChange = false
                self:CheckEnergyChange()
            end, showInfo.WaitTime * 1000)
    end
end

function XSCBattleManager:ShowBossSkill()
    XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_BOSSSKILL)
end

function XSCBattleManager:ShowSettleScore()
    -- 不阻塞的技能，不需要延迟播回能
    local isNotMask = false
    local preSkill = self:GetPrepSkill()
    if preSkill then
        local skillId = preSkill:GetSkillId()
        isNotMask = XSameColorGameConfigs.AnimNotMaskSkill[skillId]
    end

    local waitTime = isNotMask and 0 or 1
    self:ShowEnergyChange(XSameColorGameConfigs.EnergyChangeFrom.Combo, waitTime)--连击回能
    self:ShowEnergyChange(XSameColorGameConfigs.EnergyChangeFrom.Buff, waitTime)--Buff回能
    XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_SETTLESCORE)
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

function XSCBattleManager:CheckActionList()
    if self.ActionList and not self:CheckActionPlaying() then
        local action = self.ActionList[self.ActionSchedule]
        local nextAction = self.ActionList[self.ActionSchedule + 1]
        local IsSpecial = false

        if self.ActionSchedule == 1 then
            XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLESHOW_MASK, true)
            self.IsActionAllFinish = false
        end

        if action and nextAction then
            if action.ActionType == XSameColorGameConfigs.ActionType.ActionItemDrop and
                nextAction.ActionType == XSameColorGameConfigs.ActionType.ActionItemCreateNew then
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
                XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ACTIONLIST_OVER)
            end
        end
    end
end

-- v4.0 处于技能释放中，继续累加combo数量
function XSCBattleManager:ClearComboCount()
    if not self:GetPrepSkill() and not self.ActionList then
        self.ComboCount = 0
    end
end

-- 执行刷新Action，不需要一个接一个
function XSCBattleManager:DoUpdateActionList(actions)
    -- 阻塞的action列表是否正在执行中
    -- 部分通过时间update触发的刷新action，会与正在执行的action列表冲突，塞到action列表最后执行
    local isDealingAction = self.ActionList ~= nil and self.ActionSchedule < #self.ActionList

    for _, action in ipairs(actions) do
        if isDealingAction and action.ActionType == XSameColorGameConfigs.ActionType.ActionMapReset then
            table.insert(self.ActionList, action)
        else
            self.DoAction[action.ActionType](self, action)
        end
    end
end

function XSCBattleManager:DoAutoEnergyHint()
    if self.IsHintAutoEnergy then
        self.IsHintAutoEnergy = false
        XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLESHOW_HINTAUTOENERGY, self.BattleRound + 1)
    end
end

function XSCBattleManager:CheckAnimeAndActionIsAllFinish()
    -- 跳过动画阻塞
    local preSkill = self:GetPrepSkill()
    if preSkill then
        local skillId = preSkill:GetSkillId()
        if XSameColorGameConfigs.AnimNotMaskSkill[skillId] then
            return self.IsActionAllFinish
        end
    end

    -- 默认：动画、ActionList都会打开mask阻塞玩家的操作
    return self.IsAnimeFinish and self.IsActionAllFinish
end

function XSCBattleManager:CheckCloseMask()
    if self:CheckAnimeAndActionIsAllFinish() then
        XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLESHOW_MASK, false)
    end
end

function XSCBattleManager:SetPreData()--(不按行动顺序)
    local comboRecord = {}
    local ballRemoveCount = 0
    for _,action in pairs(self.ActionList or {}) do
        if action.ActionType == XSameColorGameConfigs.ActionType.ActionSettleScore then
            comboRecord = action.ComboRecord
            self:SetScoreData(action)
        end
        if action.ActionType == XSameColorGameConfigs.ActionType.ActionBossReleaseSkill then
            self.BossSkill = action.BossSkillId
            self.BossSkillIndex = self.BossSkillIndex + 1
        end
        if action.ActionType == XSameColorGameConfigs.ActionType.ActionBossSkipSkill then
            self.BossSkillIndex = self.BossSkillIndex + 1
        end
        if action.ActionType == XSameColorGameConfigs.ActionType.ActionAddBuff then
            if action.BossId and action.BossId > 0 then
                table.insert(self.BossBuffList,self:GetBuff(action.BuffId, action.BuffUid))
            end
        end
        if action.ActionType == XSameColorGameConfigs.ActionType.ActionItemRemove then
            ballRemoveCount = ballRemoveCount + 1
        end
        if action.ActionType == XSameColorGameConfigs.ActionType.ActionEnergyChange then
            self:AddEnergyChangeData(action)
        end
    end

    -- 技能期间触发的消球，消球次数累加起来
    local preSkill = self:GetPrepSkill()
    if preSkill then
        ballRemoveCount = preSkill:AddBallRemoveCount(ballRemoveCount)
    end

    if ballRemoveCount > 0 then
        XEventManager.DispatchEvent(XEventId.EVENT_SC_BATTLESHOW_COMBOPLAY, ballRemoveCount)
    end
end

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

function XSCBattleManager:GetBattleRoleSkill(skillGroupId)
    local result = self.BattleRoleSkillDic[skillGroupId]
    if result == nil then
        result = XSCBattleRoleSkill.New(skillGroupId)
        self.BattleRoleSkillDic[skillGroupId] = result
    end
    return result
end

function XSCBattleManager:GetBattleComboLevel(combo)
    local comboLevel = 1
    local levelLimitList = XSameColorGameConfigs.GetActivityConfigValue("BattleComboLevel")
    for level,limit in pairs(levelLimitList or {}) do
        if combo >= tonumber(limit) then
            comboLevel = level
        end
    end
    return comboLevel
end

function XSCBattleManager:GetIsResetting()
    return self.Resetting
end

return XSCBattleManager