---@class XUiMainModel : XModel
local XUiMainModel = XClass(XModel, "XUiMainModel")

-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey = {
    UiPanelTip = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    ActivityBtn = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
}

local BoardTableKey = {
    BoardEffectActivity = { CacheType = XConfigUtil.CacheType.Normal },
}

function XUiMainModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    --定义TableKey
    self._ConfigUtil:InitConfigByTableKey("UiMain", TableKey)
    self._ConfigUtil:InitConfigByTableKey("BoardEffect", BoardTableKey)

    self.BoardEffectData = false
    --新手任务合集ActivityBtn配置Id
    self:_InitNewPlayerTaskCollection()
end

function XUiMainModel:ClearPrivate()
    --这里执行内部数据清理
    XLog.Error("请对内部数据进行清理")
end

function XUiMainModel:ResetAll()
    --这里执行重登数据清理
    self.BoardEffectData = false
end

----------public start----------

---@return table<number, XTableUiPanelTip>
function XUiMainModel:GetUiPanelTip()
    return self._ConfigUtil:GetByTableKey(TableKey.UiPanelTip)
end

function XUiMainModel:GetActivityBtn()
    return self._ConfigUtil:GetByTableKey(TableKey.ActivityBtn)
end

function XUiMainModel:GetActivityBtnConfigById(id)
    if not XTool.IsNumberValid(id) then
        return
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ActivityBtn, id)
end

function XUiMainModel:GetNewPlayerTaskCollection()
    return self._NewPlayerTaskCollection
end

--region BoardEffect

function XUiMainModel:UpdateBoardEffectData(data)
    if not data then
        self.BoardEffectData = false
        return
    end
    self.BoardEffectData = data
end

function XUiMainModel:UpdateLastTriggerTime(time)
    if not self.BoardEffectData then
        return
    end
    self.BoardEffectData.LastTriggerTime = time or 0
end

function XUiMainModel:GetBoardEffectActivityId()
    if not self.BoardEffectData then
        return 0
    end
    return self.BoardEffectData.ActivityId or 0
end

function XUiMainModel:GetBoardEffectLastTriggerTime()
    if not self.BoardEffectData then
        return 0
    end
    return self.BoardEffectData.LastTriggerTime or 0
end

---@return XTableBoardEffectActivity
function XUiMainModel:GetBoardEffectActivityById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BoardTableKey.BoardEffectActivity, id)
end

-- 获取TriggerProbability
function XUiMainModel:GetBoardEffectTriggerProbability()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.TriggerProbability or 0
end

-- 获取TriggerCd
function XUiMainModel:GetBoardEffectTriggerCd()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.TriggerCd or 0
end

-- 获取EffectRootNames
function XUiMainModel:GetBoardEffectEffectRootNames()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.EffectRootNames or {}
end

-- 获取EffectPaths
function XUiMainModel:GetBoardEffectEffectPaths()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.EffectPaths or {}
end

-- 获取EffectTimes
function XUiMainModel:GetBoardEffectEffectTimes()
    local activity = self:GetBoardEffectActivityById(self:GetBoardEffectActivityId())
    return activity and activity.EffectTimes or {}
end

--endregion

----------public end----------

----------private start----------

function XUiMainModel:_InitNewPlayerTaskCollection()
    self._NewPlayerTaskCollection = {}
    local activityBtnData = string.Split(CS.XGame.ClientConfig:GetString("NewPlayerTaskCollectionActivityBtnIds"), "|")
    if XTool.IsTableEmpty(activityBtnData) then
        return
    end

    for _, activityBtnDataStr in ipairs(activityBtnData) do
        local strSplitArr = string.Split(activityBtnDataStr, "#")
        local activityBtnId = tonumber(strSplitArr[1])
        local bestRewardId = tonumber(strSplitArr[2])
        if XTool.IsNumberValid(activityBtnId) then
            table.insert(self._NewPlayerTaskCollection, { ActivityBtnId = activityBtnId, BestRewardId = bestRewardId })
        end
    end
end

----------private end----------

----------config start----------


----------config end----------


return XUiMainModel
