local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XGoldenMinerAgency : XFubenActivityAgency
---@field private _Model XGoldenMinerModel
local XGoldenMinerAgency = XClass(XFubenActivityAgency, "XGoldenMinerAgency")
function XGoldenMinerAgency:OnInit()
    self.IsDebug = false
    self:RegisterActivityAgency()
end

function XGoldenMinerAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyGoldenMinerGameInfo = handler(self, self.NotifyGoldenMinerGameInfo)
    XRpc.NotifyGoldenMinerItemData = handler(self, self.NotifyGoldenMinerItemData)
    XRpc.NotifyGoldenMinerCharacterProgress = handler(self, self.NotifyGoldenMinerCharacterProgress)
end

function XGoldenMinerAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region Debug
function XGoldenMinerAgency:_CheckIsDebug()
    return self.IsDebug and XMain.IsWindowsEditor
end

function XGoldenMinerAgency:DebugWarning(content, ...)
    if not self:_CheckIsDebug() then
        return
    end
    if string.IsNilOrEmpty(content) then
        XLog.Warning("黄金矿工Debug:", ...)
        return
    end
    XLog.Warning("黄金矿工Debug:" .. content, ...)
end

function XGoldenMinerAgency:DebugLog(content, ...)
    if not self:_CheckIsDebug() then
        return
    end
    if string.IsNilOrEmpty(content) then
        XLog.Debug("黄金矿工Debug:", ...)
        return
    end
    XLog.Debug("黄金矿工Debug:" .. content, ...)
end

function XGoldenMinerAgency:DebugAddScore(value)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug: 添加分数 score = ", value)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_SCORE, value)
end

function XGoldenMinerAgency:DebugAddTime(value)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug: 添加事件 time = ", value)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_TIME, value)
end

function XGoldenMinerAgency:DebugAddItem(value)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug:添加道具 Id = ", value)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_ITEM, value)
end

function XGoldenMinerAgency:DebugAddBuff(value)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug:添加buff(部分buff得初始化才会生效) Id = ", value)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_DEBUG_ADD_BUFF, value)
end

function XGoldenMinerAgency:DebugInitBuff(buffList)
    if not self:_CheckIsDebug() then
        return
    end
    XLog.Warning("黄金矿工Debug:添加初始化buffList", buffList)
    if type(buffList) ~= "table" then
        XLog.Error("黄金矿工Debug:添加初始化buffList参数错误，例子:{1,2}")
        return
    end
    self._Model.DebugInitBuffList = buffList
end
--endregion

--region Rpc
---通知当前游戏流程数据
function XGoldenMinerAgency:NotifyGoldenMinerGameInfo(data)
    local dataDb = self._Model:GetMineDb()
    dataDb:UpdateData(data.StageDataDb)
    dataDb:BackupsItemColumns()
end

---更新新解锁的角色卡
function XGoldenMinerAgency:NotifyGoldenMinerCharacterProgress(data)
    local dataDb = self._Model:GetMineDb()
    dataDb:UpdateNewCharacter(data.UnlockCharacter)
    dataDb:UpdateRedEnvelopeProgress(data.RedEnvelopeProgress)
    dataDb:UpdateTotalPlayCount(data.TotalPlayCount)
end

---进图同步道具
function XGoldenMinerAgency:NotifyGoldenMinerItemData(data)
    local dataDb = self._Model:GetMineDb()
    dataDb:UpdateItemColumns(data.ItemColumns)
    dataDb:BackupsItemColumns()
end
--endregion

--region FubenEx
function XGoldenMinerAgency:ExOpenMainUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.GoldenMiner) then
        return
    end
    if not self:CheckIsOpen() then
        XUiManager.TipText("RougeLikeNotInActivityTime")
        return
    end
    XLuaUiManager.Open("UiGoldenMinerMain")
end

function XGoldenMinerAgency:ExCheckInTime()
    -- 保持FubenActivity表TimeId清空功能有效
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    return self:CheckIsOpen()
end

function XGoldenMinerAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.GoldenMiner
end
--endregion

--region Activity
function XGoldenMinerAgency:GetCurActivityHexMapStages(index)
    return self._Model:GetCurActivityHexMapStages(index)
end

function XGoldenMinerAgency:CheckIsOpen()
    return self._Model:CheckIsOpen()
end
--endregion

--region RedPoint
function XGoldenMinerAgency:CheckHaveTaskCanRecv()
    return self._Model:CheckHaveTaskCanRecv()
end

---角色是否解锁
function XGoldenMinerAgency:IsCharacterUnLock(characterId)
    local condition = self._Model:GetCharacterCfgCondition(characterId)
    if not XTool.IsNumberValid(condition) then
        return true
    end
    return self._Model:GetMineDb():IsCharacterUnlock(characterId)
end

---是否使用X角色
function XGoldenMinerAgency:CheckIsUseCharacter(characterId)
    if not self:CheckIsOpen() then
        return false
    end
    if not self._Model:GetMineDb():CheckIsInStage() then
        return false
    end
    local dataDb = self._Model:GetMineDb()
    return dataDb:GetCurPlayCharacterId() == characterId
end
--endregion

--region Cfg - ClientConfig
function XGoldenMinerAgency:GetClientMaxItemGridCount()
    return self._Model:GetClientCfgNumberValue("MaxItemGridCount", 1)
end
--endregion

--region Cfg - Buff
function XGoldenMinerAgency:GetShopGridLockCount()
    return self._Model:GetShopGridLockCount()
end
--endregion

--region Cfg - Item
function XGoldenMinerAgency:GetCfgItemType(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.ItemType
end

function XGoldenMinerAgency:GetCfgItemBuffId(id)
    local cfg = self._Model:GetItemCfg(id)
    return cfg and cfg.BuffId
end
--endregion

--region Cfg - Stage
function XGoldenMinerAgency:GetCfgStageShopGridCount(id)
    local cfg = self._Model:GetStageCfg(id)
    return cfg and cfg.ShopGridCount
end

function XGoldenMinerAgency:GetCfgStageTargetScore(id)
    local cfg = self._Model:GetStageCfg(id)
    return cfg and cfg.TargetScore
end
--endregion

--region Cfg - Upgrade
function XGoldenMinerAgency:GetCfgUpgradeCfgCosts(id, index)
    return self._Model:GetUpgradeCfgCosts(id, index)
end

function XGoldenMinerAgency:GetCfgUpgradeCfgBuffId(id, index)
    return self._Model:GetUpgradeCfgBuffId(id, index)
end

function XGoldenMinerAgency:GetCfgUpgradeLvMaxShipKey(id)
    local cfg = self._Model:GetUpgradeCfg(id)
    return cfg and cfg.LvMaxShipKey
end
--endregion

--region Cfg - HideTask
function XGoldenMinerAgency:GetCfgHideTask(id)
    return self._Model:GetHideTaskCfg(id)
end
--endregion

--region Cfg - Hex
function XGoldenMinerAgency:GetCfgHexMapId(hexId)
    local cfg = self._Model:GetGoldenMinerHexCfg(hexId)
    return cfg and cfg.Map
end
--endregion

return XGoldenMinerAgency