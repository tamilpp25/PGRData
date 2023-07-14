
local XSCBattleManager = XClass(nil, "XSCBattleManager")
local XSCBuff = require("XEntity/XSameColorGame/Battle/XSCBuff")
local XSCBattleRoleSkill = require("XEntity/XSameColorGame/Battle/XSCBattleRoleSkill")
local ChangeItemPos = function(item)--转换服务器坐标的参考基准
    local tagItemList = {}
    local tagItem = {ItemId = item.ItemId, PositionX = item.PositionX + 1, PositionY = item.PositionY + 1}
    return tagItem
end

local ChangeItemPosList = function(itemList)--转换服务器坐标的参考基准
    local tagItemList = {}
    for _,item in pairs(itemList) do
        local pos = {ItemId = item.ItemId, PositionX = item.PositionX + 1, PositionY = item.PositionY + 1}
        table.insert(tagItemList, pos)
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
        local param = {BallList = ChangeItemPosList(action.ItemList),
            ActionType = action.ActionType}
        self.IsActionPlayingDic[action.ActionType] = true
        XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_MAPINIT, param)
    end,

    [XSameColorGameConfigs.ActionType.ActionItemRemove] = function(self, action)--消除
        self:DoCountCombo(action.CurrentCombo)
        local param = {RemoveBallList = ChangeItemPosList(action.ItemList),
            ActionType = action.ActionType}
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

function XSCBattleManager:ClearPrepSkill()
    self.InPrepSkill = nil
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

function XSCBattleManager:GetBattleStep(boss)
    return boss:GetMaxRound() - self:GetBattleRound() + self.ExtraStep
end

function XSCBattleManager:SetExtraStep(step)
    self.ExtraStep = self.ExtraStep + step
end

function XSCBattleManager:GetCountCombo()
    return self.ComboCount
end

function XSCBattleManager:DoCountCombo(combo)
    self.ComboCount = self.ComboCount + combo
end

function XSCBattleManager:GetDamageCount()
    return self.ScoreData.TotalScore
end

function XSCBattleManager:GetScoreData()
    return self.ScoreData
end

function XSCBattleManager:SetScoreData(data)
    self.ScoreData = data
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
    self:ShowEnergyChange(XSameColorGameConfigs.EnergyChangeFrom.Combo, 1)--连击回能
    self:ShowEnergyChange(XSameColorGameConfigs.EnergyChangeFrom.Buff,1)--Buff回能
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
            XLuaUiManager.SetMask(true)
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
                self.ActionList = nil
                self.ActionSchedule = 1
                self.ComboCount = 0
                self.IsActionAllFinish = true
                self:CheckCloseMask()
                XEventManager.DispatchEvent(XEventId.EVENT_SC_ACTION_ACTIONLIST_OVER)
            end
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
    return self.IsAnimeFinish and self.IsActionAllFinish
end

function XSCBattleManager:CheckCloseMask()
    if self:CheckAnimeAndActionIsAllFinish() then
        XLuaUiManager.SetMask(false)
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

return XSCBattleManager