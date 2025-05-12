---@class XGachaCanLiverModel : XModel
local XGachaCanLiverModel = XClass(XModel, "XGachaCanLiverModel")

local TablePrivate = {
    
}

local TableNormal = {
    GachaCanLiver = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    GachaCanLiverShow = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
    GachaCanLiverShop = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id" },
}

function XGachaCanLiverModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Gacha", TablePrivate, XConfigUtil.CacheType.Private)
    self._ConfigUtil:InitConfigByTableKey("Gacha", TableNormal, XConfigUtil.CacheType.Normal)
end

function XGachaCanLiverModel:ClearPrivate()
    
end

function XGachaCanLiverModel:ResetAll()
    self:ClearActivityData()
end

--region ActivityData

function XGachaCanLiverModel:RefreshActivityData(data)
    self.ChoseCanLiverId = data.ChoseCanLiverId
    self.GachaCanLiverDataList = data.GachaCanLiverDataList
    self.ActivityCanLiverIds = data.ActivityCanLiverIds
    self.CurAllOutCanLiverGachaIds = data.CurAllOutCanLiverGachaIds
end

--- 清理掉根据服务端下发协议数据产生的直接或二次数据，防止换号时有数据残留
function XGachaCanLiverModel:ClearActivityData()
    self.ChoseCanLiverId = nil
    self.GachaCanLiverDataList = nil
    self.ActivityCanLiverIds = nil
    self.CurAllOutCanLiverGachaIds = nil
end

function XGachaCanLiverModel:GetCurActivityId()
    return self.ChoseCanLiverId or 0
end

function XGachaCanLiverModel:GetCurActivityIsClose()
    local curActivityId = self:GetCurActivityId()
    if XTool.IsNumberValid(curActivityId) then
        local data = self:GetActivityDataById(curActivityId)

        if data then
            return data.IsClose or false
        else
            return not self:CheckActivityIsExist(curActivityId)
        end
    end
end

function XGachaCanLiverModel:GetCurActivityFreeItemIdGainTimes()
    local curActivityId = self:GetCurActivityId()
    if XTool.IsNumberValid(curActivityId) then
        local data = self:GetActivityDataById(curActivityId)

        if data then
            return data.FreeItemGainTimes
        end
    end
    return 0
end

function XGachaCanLiverModel:GetActivityDataById(id)
    if not XTool.IsTableEmpty(self.GachaCanLiverDataList) then
        for i, v in pairs(self.GachaCanLiverDataList) do
            if v.Id == id then
                return v
            end
        end
    end
end

function XGachaCanLiverModel:CheckActivityIsExist(id)
    if not XTool.IsTableEmpty(self.ActivityCanLiverIds) then
        return table.contains(self.ActivityCanLiverIds, id)
    end
    return false
end

--- 获取当前活动的所有商店Id
---@param ignoreClosed @是否筛选掉已经关闭的商店
function XGachaCanLiverModel:GetCurActivityShopIds(ignoreClosed)
    if ignoreClosed then
        local shopIds = {
            self:GetCurActivityResidentShopId()
        }
        
        local timelimitShopId = self:GetCurActivityTimelimitShopId()
        
        local shopCfg = XTool.IsNumberValid(timelimitShopId) and self:GetGachaCanLiverShopCfgById(timelimitShopId) or nil

        if shopCfg and XFunctionManager.CheckInTimeByTimeId(shopCfg.TimeId) then
            if not XTool.IsTableEmpty(shopCfg.ConditionIds) then
                local isConditionSatisfy = true
                for i, v in pairs(shopCfg.ConditionIds) do
                    if not XConditionManager.CheckCondition(v) then
                        isConditionSatisfy = false
                        break
                    end
                end

                if isConditionSatisfy then
                    table.insert(shopIds, timelimitShopId)
                end
            else
                table.insert(shopIds, timelimitShopId)
            end
        end
        
        return shopIds
    else
        return {
            self:GetCurActivityResidentShopId(),
            self:GetCurActivityTimelimitShopId()
        }    
    end

end

--- 获取当前的最新开启的限时卡池Id
function XGachaCanLiverModel:GetCurActivityLatestTimelimitGachaId()
    local ids = self:GetCurActivityTimeLimitGachaIds()

    if not XTool.IsTableEmpty(ids) then
        for i = #ids, 1, -1 do
            local id = ids[i]

            if XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsUnlock(id) then
                return id
            end
        end
    else
        XLog.Error('限时卡池组Id为空，当前活动Id：'..tostring(self._Model:GetCurActivityId()))
    end
end

function XGachaCanLiverModel:CheckGachaIsSellOutRare(gachaId)
    if not XTool.IsTableEmpty(self.CurAllOutCanLiverGachaIds) then
        return table.contains(self.CurAllOutCanLiverGachaIds, gachaId)
    end
    return false
end
--endregion

--region ActivityData-Config

--- GachaCanLiver
function XGachaCanLiverModel:GetCurActivityFreeItemId()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            if not XTool.IsNumberValid(cfg.FreeItemId) then
                XLog.Error('活动Id:'..tostring(curActivityId)..'的免费道具Id配置无效:'..tostring(cfg.FreeItemId))
            end
            return cfg.FreeItemId
        end
    end
end

function XGachaCanLiverModel:GetCurActivityFreeItemGainUpLimit()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            return cfg.FreeItemGainUpLimit
        end
    end
end

function XGachaCanLiverModel:GetCurActivityCoinItemId()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            return cfg.CoinItemId
        end
    end
end

function XGachaCanLiverModel:GetCurActivityResidentShopId()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            return cfg.ResidentShopId
        end
    end
end

function XGachaCanLiverModel:GetCurActivityTimelimitShopId()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            return cfg.TimelimitShopId
        end
    end
end

function XGachaCanLiverModel:GetCurActivityTaskIds()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            return cfg.TaskIds
        end
    end
end

function XGachaCanLiverModel:GetCurActivityTaskTimeLimitGroupIds()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            return cfg.TaskTimeLimitGroupIds
        end
    end
end

function XGachaCanLiverModel:GetCurActivityTaskGroupId()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            return cfg.TaskGroupId
        end
    end
end



function XGachaCanLiverModel:GetCurActivityResidentGachaId()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            return cfg.ResidentGachaId
        end
    end
end

function XGachaCanLiverModel:GetCurActivityTimeLimitGachaIds()
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            return cfg.TimeLimitGachaIds
        end
    end
end

function XGachaCanLiverModel:GetCurActivityTimeLimitGachaIdIndex(gachaId)
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            for i, v in pairs(cfg.TimeLimitGachaIds) do
                if v == gachaId then
                    return i
                end
            end
        end
        
        XLog.Error('对应限时卡池Id在配置中不存在，gachaId:'..tostring(gachaId)..' 当前活动Id:'..tostring(self:GetCurActivityId()))
    end
end

function XGachaCanLiverModel:GetCurActivityTimeLimitGachaConditionByIndex(index)
    local curActivityId = self:GetCurActivityId()

    if XTool.IsNumberValid(curActivityId) then
        local cfg = self:GetGachaCanLiverCfgById(curActivityId)

        if cfg then
            local conditionId = cfg.TimeLimitGachaConditionIds[index]
            
            return conditionId
        end
    end
end

--endregion

--region Others

--- 获取唯一指向该活动的键
function XGachaCanLiverModel:GetActivityUniqueKey()
    return 'GachaCanLiver_'..tostring(self:GetCurActivityId())..'_'..tostring(XPlayer.Id)..'_'
end

--endregion

--region Config
function XGachaCanLiverModel:GetGachaCanLiverShowCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GachaCanLiverShow, id)
end

function XGachaCanLiverModel:GetGachaCanLiverCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GachaCanLiver, id)
end

function XGachaCanLiverModel:GetGachaCanLiverShopCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.GachaCanLiverShop, id)
end
--endregion


return XGachaCanLiverModel