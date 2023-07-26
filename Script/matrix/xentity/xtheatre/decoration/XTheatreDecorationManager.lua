-- 装修改造管理
local XTheatreDecorationManager = XClass(nil, "XTheatreDecorationManager")

function XTheatreDecorationManager:Ctor()
    self._Decorations = {}  --已生效的装修项（等级0默认生效）
    self._DecorationLvDic = {}  --已生效的装修项对应的当前等级字典
end

function XTheatreDecorationManager:UpdateData(decorations)
    local decorationId
    local lv
    for _, theatreDecorationId in ipairs(decorations) do
        self:UpdateDecoration(theatreDecorationId)
    end
end

function XTheatreDecorationManager:UpdateDecoration(theatreDecorationId)
    self._Decorations[theatreDecorationId] = true
    local decorationId = XTheatreConfigs.GetDecorationId(theatreDecorationId)
    local lv = XTheatreConfigs.GetDecorationLv(theatreDecorationId)
    self._DecorationLvDic[decorationId] = lv
end

--是否已解锁（等级大于0即解锁）
function XTheatreDecorationManager:IsActiveDecoration(decorationId)
    local theatreDecorationIdList = XTheatreConfigs.GetTheatreDecorationIdToIds(decorationId)
    for _, id in ipairs(theatreDecorationIdList) do
        if self._Decorations[id] and XTheatreConfigs.GetDecorationLv(id) > 0 then
            return true
        end
    end
    return false
end

function XTheatreDecorationManager:IsMaxLv(decorationId)
    local curLv = self:GetDecorationLv(decorationId)
    local maxLv = XTheatreConfigs.GetTheatreDecorationMaxLv(decorationId)
    return curLv >= maxLv
end

--返回TheatreDecoration表的Id（显示用）
function XTheatreDecorationManager:GetTheatreDecorationId(decorationId)
    local lv = self:GetDecorationLv(decorationId)
    return XTheatreConfigs.GetTheatreDecorationIdAndLvToId(decorationId, lv)
end

--返回升到下一级所需conditionId
function XTheatreDecorationManager:GetTheatreDecorationNextLvConditionId(decorationId)
    local lv = self:GetDecorationLv(decorationId)
    local theatreDecorationId = XTheatreConfigs.GetTheatreDecorationIdAndLvToId(decorationId, lv)
    return theatreDecorationId and XTheatreConfigs.GetDecorationConditionId(theatreDecorationId) or 0
end

--返回当前已生效的最高等级的装修项对应的TheatreDecoration表的Id
function XTheatreDecorationManager:GetActiveTheatreDecorationId(decorationId)
    local lv = self:GetDecorationLv(decorationId)
    return XTheatreConfigs.GetTheatreDecorationIdAndLvToId(decorationId, lv)
end

function XTheatreDecorationManager:GetDecorationLv(decorationId)
    return self._DecorationLvDic[decorationId] or 0
end

--获得已激活的所有装修项当前等级的配置
function XTheatreDecorationManager:GetAllActiveLevelDecorationConfig()
    local configList = {}
    local decorationIds = XTheatreConfigs.GetTheatreDecorationIds()
    for decorationId in pairs(decorationIds) do
        local lv = self:GetDecorationLv(decorationId)
        local theatreDecorationId = XTheatreConfigs.GetTheatreDecorationIdAndLvToId(decorationId, lv)
        if theatreDecorationId then
            table.insert(configList, XTheatreConfigs.GetTheatreDecoration(theatreDecorationId))
        end
    end
    return configList
end

--装修项升级
--theatreDecorationId：传当前等级的TheatreDecoration表的Id
function XTheatreDecorationManager:RequestTheatreDecorationUpgrade(theatreDecorationId)
    XNetwork.Call("TheatreDecorationUpgradeRequest", { DecorationId = theatreDecorationId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        --设置下一级的TheatreDecoration表的Id
        local lv = XTheatreConfigs.GetDecorationLv(theatreDecorationId)
        local decorationId = XTheatreConfigs.GetDecorationId(theatreDecorationId)
        theatreDecorationId = XTheatreConfigs.GetTheatreDecorationIdAndLvToId(decorationId, lv + 1) or theatreDecorationId
        self:UpdateDecoration(theatreDecorationId)

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_THEATRE_DECORATION_UPGRADE)
        XUiManager.TipText("FurnitureRefitSuccess")
    end)
end

function XTheatreDecorationManager:HandleActiveDecorationTypeParam(decorationType, handleParamFunc)
    local configs = self:GetAllActiveLevelDecorationConfig()
    for _, config in ipairs(configs) do
        for i, cfgType in ipairs(config.Type) do
            if cfgType == decorationType then
                handleParamFunc(config.Param[i])
            end
        end
    end
end

return XTheatreDecorationManager