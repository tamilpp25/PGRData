local XMVCA = XMVCA
local StageType = XEnumConst.FuBen.StageType
local ProcessFunc = XEnumConst.FuBen.ProcessFunc

---@class XStageInfo
local XStageInfo = XClass(nil, "XStageInfo")

function XStageInfo:Ctor(stageId)
    self._StageId = stageId
    self._StarMaps = {}

    -- 以下这批是外部设置的私有信息, 暂时作保留
    self.TotalStars = 3
    self.BossSectionId = nil
    self.ChapterName = nil
    self.stageDataName = nil
    self.BountyId = nil
    self.mode = nil

    -- 以下这一批内容, 是已经处理过的, 已经被换成函数
    self._Key2Function = {
        Unlock = self.IsUnlock,
        HaveAssist = self.IsHaveAssist,
        Passed = self.IsPassed,
        Type = self.GetType,
        Stars = self.GetStars,
        StarsMap = self.GetStarMap,
        NextStageId = self.GetNextStageId,
        IsOpen = self.GetIsOpen,
        Difficult = self.GetDifficult,
        ChapterId = self.GetChapterId,
        OrderId = self.GetOrderId,
    }

    self._CheckDeathLoop = nil
end

function XStageInfo:CheckOptimized(key)
    if self._Key2Function[key] then
        --XLog.Error("[XStageInfo] 该变量已改为动态获取, 请勿写入, 如有问题, 请联系立斌, 谢谢" .. tostring(key))
        return true
    end
end

function XStageInfo:GetValueByKey(key)
    if self[key] then
        return self[key]
    end
    local func = self._Key2Function[key]
    if func then
        return func(self)
    end
    if key == "__metatable" then
        return getmetatable(self)
    end
    --XLog.Error("[XStageInfo] 访问优化中漏掉的key:" .. tostring(key))
end

---@return XTableStage
function XStageInfo:GetStageConfig()
    return XMVCA.XFuben:GetStageCfg(self._StageId)
end

function XStageInfo:GetStageCfgs()
    return XMVCA.XFuben:GetStageCfgs()
end

function XStageInfo:GetDataFromServer()
    return XMVCA.XFuben:GetStageData(self._StageId)
end

function XStageInfo:IsUnlock()
    return XMVCA.XFuben:CheckStageIsUnlock(self._StageId)
end

function XStageInfo:IsHaveAssist()
    local stageCfg = self:GetStageConfig()
    if stageCfg then
        return stageCfg.HaveAssist
    end
    return false
end

function XStageInfo:IsPassed()
    local dataFromServer = self:GetDataFromServer()
    if dataFromServer then
        return dataFromServer.Passed
    end
    if not self._CheckDeathLoop then
        self._CheckDeathLoop = true
        local type = self:GetType()
        local ok, result = XMVCA.XFuben:CallCustomFunc(type, ProcessFunc.CheckPassedByStageId, self._StageId)
        self._CheckDeathLoop = nil
        if result then
            return result
        end
    else
        XLog.Error("[XStageInfo] IsPassed触发了死循环")
    end
    return false
end

function XStageInfo:GetType()
    local stageCfg = self:GetStageConfig()
    if stageCfg then
        return stageCfg.Type
    end
    return 0
end

function XStageInfo:GetStars()
    local dataFromServer = self:GetDataFromServer()
    if dataFromServer then
        local starsMark = dataFromServer.StarsMark
        local star = 0
        for i = 1, 3 do
            local value = starsMark & 1 << (i - 1)
            if value > 0 then
                star = star + 1
            end
        end
        return star
    end
    return 0
end

function XStageInfo:GetStarMap()
    local type = self:GetType()
    local ok, result = XMVCA.XFuben:CallCustomFunc(type, ProcessFunc.GetStarMap, self._StageId)
    if ok then
        return result
    end

    local dataFromServer = self:GetDataFromServer()
    if dataFromServer then
        local starsMark = dataFromServer.StarsMark
        for i = 1, 3 do
            local value = starsMark & 1 << (i - 1)
            self._StarMaps[i] = value > 0
        end
        return self._StarMaps
    end
    for i = #self._StarMaps, 1, -1 do
        self._StarMaps[i] = nil
    end
    return self._StarMaps
end

function XStageInfo:GetNextStageId()
    local stageConfig = self:GetStageConfig()
    if stageConfig.StageType == XFubenConfigs.STAGETYPE_STORYEGG
            or stageConfig.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG then
        return false
    end

    local nextStageId = stageConfig.NextStageId[1]
    if XMain.IsEditorDebug then
        if nextStageId and nextStageId > 0 then
            local nextStageConfig = XMVCA.XFuben:GetStageCfg(nextStageId)
            local isFind = false
            for i = 1, #nextStageConfig.PreStageId do
                if nextStageConfig.PreStageId[i] == self._StageId then
                    isFind = true
                    break
                end
            end
            if not isFind then
                XLog.Error(string.format("[XStageInfo] nextStageId生成出现错误, StageId: %d, NextStageId: %d", self._StageId, nextStageId))
            end
        end
    end

    return nextStageId
end

function XStageInfo:GetIsOpen()
    local stageCfg = self:GetStageConfig()
    if not stageCfg then
        return false
    end

    local stageType = self:GetType()
    local ok, result = XMVCA.XFuben:CallCustomFunc(stageType, ProcessFunc.CheckIsOpen, self._StageId)
    if ok then
        if result ~= nil then
            return result
        end
    end

    for _, preStageId in pairs(stageCfg.PreStageId or {}) do
        if preStageId > 0 then
            local dataFromServer = XMVCA.XFuben:GetStageData(preStageId)
            if not dataFromServer or not dataFromServer.Passed then
                return false
            end
        end
    end
    return true
end

function XStageInfo:GetDifficult()
    local type = self:GetType()
    local ok, result = XMVCA.XFuben:CallCustomFunc(type, ProcessFunc.GetDifficult, self._StageId)
    return result
end

function XStageInfo:GetChapterId()
    local type = self:GetType()
    local ok, result = XMVCA.XFuben:CallCustomFunc(type, ProcessFunc.GetChapterId, self._StageId)
    return result
end

function XStageInfo:GetOrderId()
    local type = self:GetType()
    local ok, result = XMVCA.XFuben:CallCustomFunc(type, ProcessFunc.GetOrderId, self._StageId)
    return result
end

return XStageInfo