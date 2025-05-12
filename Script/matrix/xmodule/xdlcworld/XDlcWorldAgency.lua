local XDlcWorld = require("XModule/XDlcWorld/XEntity/XDlcWorld")
local XDlcSettingDetail = require("XModule/XDlcWorld/XEntity/XDlcSettingDetail")
local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")

---@class XDlcWorldAgency : XAgency
---@field private _Model XDlcWorldModel
local XDlcWorldAgency = XClass(XAgency, "XDlcWorldAgency")

function XDlcWorldAgency:OnInit()
    -- 初始化一些变量
end

function XDlcWorldAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
    XRpc.DlcBossSettleResponse = Handler(self, self.OnNotifyFightFinishSettle)
    XRpc.NotifyJoinWorldInfo = Handler(self, self.OnNotifyJoinWorldInfo)
end

function XDlcWorldAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

-- region World相关

---@return XDlcWorld
function XDlcWorldAgency:GetWorldById(id)
    local config = self._Model:GetWorldConfigById(id)

    return self:_GetWorldByConfig(config)
end

---@return XDlcWorld[]
function XDlcWorldAgency:GetWorldListByIdList(idList)
    local worldList = {}

    for i = 1, #idList do
        worldList[i] = self:GetWorldById(idList[i])
    end

    return worldList
end

function XDlcWorldAgency:GetWorldNameById(id)
    return self._Model:GetNameById(id)
end

function XDlcWorldAgency:GetWorldTypeById(id)
    return self._Model:GetTypeById(id)
end

function XDlcWorldAgency:GetTeachingCharacterIdById(id)
    return self._Model:GetTeachingCharacterIdById(id)
end

function XDlcWorldAgency:GetChapterIdById(id)
    return self._Model:GetChapterIdById(id)
end

function XDlcWorldAgency:GetBgmIdById(id)
    return self._Model:GetBgmIdById(id)
end

function XDlcWorldAgency:GetEventIdById(id)
    return self._Model:GetEventIdById(id)
end

function XDlcWorldAgency:GetLoadingTypeById(id)
    return self._Model:GetLoadingTypeById(id)
end

function XDlcWorldAgency:GetFinishRewardShowById(id)
    return self._Model:GetFinishRewardShowById(id)
end

function XDlcWorldAgency:GetFinishDropIdById(id)
    return self._Model:GetFinishDropIdById(id)
end

function XDlcWorldAgency:GetFirstRewardIdById(id)
    return self._Model:GetFirstRewardIdById(id)
end

function XDlcWorldAgency:GetTeamPlayerLeastById(id)
    return self._Model:GetTeamPlayerLeastById(id)
end

function XDlcWorldAgency:GetTeamPlayerLimitById(id)
    return self._Model:GetTeamPlayerLimitById(id)
end

function XDlcWorldAgency:GetOnlinePlayerLeastById(id)
    return self._Model:GetOnlinePlayerLeastById(id)
end

function XDlcWorldAgency:GetOnlinePlayerLimitById(id)
    return self._Model:GetOnlinePlayerLimitById(id)
end

function XDlcWorldAgency:GetSettleLoseTipIdById(id)
    return self._Model:GetSettleLoseTipIdById(id)
end

function XDlcWorldAgency:GetMatchPlayerCountThresholdById(id)
    return self._Model:GetMatchPlayerCountThresholdById(id)
end

function XDlcWorldAgency:GetNeedFightPowerById(id)
    return self._Model:GetNeedFightPowerById(id)
end

function XDlcWorldAgency:GetIsRankById(id)
    return self._Model:GetIsRankById(id)
end

function XDlcWorldAgency:GetMatchStrategyById(id)
    return self._Model:GetMatchStrategyById(id)
end

function XDlcWorldAgency:CheckWorldIsRankById(id)
    return self:GetIsRankById(id) == 1
end

function XDlcWorldAgency:GetDifficultyIdById(id)
    return self._Model:GetDifficultyIdById(id)
end

function XDlcWorldAgency:GetSettingDetailIdById(id)
    return self._Model:GetSettingDetailIdById(id)
end

function XDlcWorldAgency:GetRebootIdById(id)
    return self._Model:GetRobootIdById(id)
end

-- endregion

-- region SettingDetail相关

---@return XDlcSettingDetail[]
function XDlcWorldAgency:GetSettingDetailListByWorldId(worldId)
    local detailId = self:GetSettingDetailIdById(worldId)
    local config = self._Model:GetSettingDetailConfigById(detailId)
    local tipNameList = config.TipName
    local tipDescList = config.TipDes
    local detailList = {}

    if XTool.IsTableEmpty(tipNameList) or XTool.IsTableEmpty(tipDescList) then
        return {}
    end

    local count = math.min(#tipNameList, #tipDescList)

    for i = 1, count do
        detailList[i] = XDlcSettingDetail.New(detailId, tipNameList[i], tipDescList[i], "")
    end

    return detailList
end

-- endregion

-- region Npc属性相关

function XDlcWorldAgency:GetAttributeConfigById(attribId)
    return self._Model:GetAttributeConfigById(attribId)
end

-- endregion

-- region 战斗相关

function XDlcWorldAgency:HasResult()
    return self._Model:GetResult() ~= nil
end

function XDlcWorldAgency:InitFightDelegate(worldId)
    local worldType = XMVCA.XDlcWorld:GetWorldTypeById(worldId)

    if worldType == XEnumConst.DlcWorld.WorldType.Hunt then
        XDataCenter.XDlcHuntAttrManager.InitFightDelegate()
    else
        XMVCA.XDlcWorld:_SetFightDelegate(worldId)
    end
end

function XDlcWorldAgency:OnNotifyFightFinishSettle(res)
    -- local worldId = res.SettleData.ResultData.WorldData.WorldId
    -- -- if worldId and self:GetWorldTypeById(worldId) == XEnumConst.DlcWorld.WorldType.Hunt then
    -- --     XDataCenter.DlcHuntManager.OnNotifyFightSettle(res.SettleData)
    -- --     return
    -- -- end
    XMVCA.XDlcRoom:RecordFightQuit(1)
    self._Model:SetResult(res)
end

function XDlcWorldAgency:OnNotifyJoinWorldInfo(data)
    if data.WorldInfo then
        local worldId = data.WorldInfo.WorldId

        if XMVCA.XDlcWorld:GetWorldTypeById(worldId) == XEnumConst.DlcWorld.WorldType.Hunt then
            XDataCenter.DlcRoomManager.SetReJoinWorldInfo(data.WorldInfo)
        else
            XMVCA.XDlcRoom:SetReJoinWorldInfo(data.WorldInfo)
        end
    end
end

function XDlcWorldAgency:OnReconnectFight()
    if XMVCA.XDlcRoom:IsCanReconnect() then
        local worldInfo = XMVCA.XDlcRoom:GetRejoinWorldInfo()
        local worldId = worldInfo:GetWorldId()
        local agency = self:GetAgencyByWorldId(worldId)

        if not agency then
            XLog.Error("无法找到WorldId对应的Agency, WorldId = " .. worldId)

            return false
        end

        agency:DlcReconnect()

        return true
    end

    return false
end

function XDlcWorldAgency:OnEnterFight(worldId)
    self:_PreEnterFight()
    self:_SetFightDelegate(worldId)
    self._Model:SetResult(nil)
end

function XDlcWorldAgency:OnFightSettle()
    if XMVCA.XDlcRoom:IsSettled() then
        return
    end

    local worldId = self:_GetSettleWorldId()
    local worldType = self:GetWorldTypeById(worldId)
    local agency = self:GetAgencyByWorldType(worldType)
    local fightEvent = nil

    if agency then
        fightEvent = agency:DlcGetFightEvent()

        if not fightEvent then
            XLog.Error(agency.__cname .. ":GetFightEvent返回FightEvent为空!")
            fightEvent = XDlcWorldFight.New()
        end
    else
        XLog.Error("找不到WorldType = " .. worldType
                       .. "对应的Agency! 请在XDlcWorldAgency:GetAgencyByWorldType中注册!")
        fightEvent = XDlcWorldFight.New()
    end

    XMVCA.XDlcRoom:Settlement()
    self:_FinishFight()
    self:_ClearFightDelegate()
    if self:_IsForceExit() then
        fightEvent:OnFightForceExit(worldType)
        XMVCA.XDlcRoom:Close()
    else
        local result = self._Model:GetResult()
        local resultData = result.SettleData.ResultData

        fightEvent:OnFightFinishSettle(worldType, result.SettleData, resultData.IsPlayerWin, false)
    end
end

-- endregion

-- region 活动相关

function XDlcWorldAgency:GetAgencyByWorldId(worldId, isNotTip)
    local worldType = self:GetWorldTypeById(worldId)

    return self:GetAgencyByWorldType(worldType, isNotTip)
end

---@return XDlcActivityAgency
function XDlcWorldAgency:GetAgencyByWorldType(worldType, isNotTip)
    -- if worldType == XEnumConst.DlcWorld.WorldType.Hunt then
    --     return XDataCenter.DlcHuntManager
    -- end

    local moduleId = self._Model:GetAgencyByWorldType(worldType)

    if not moduleId then
        if not isNotTip then
            XLog.Error("不存在WorldType = " .. worldType .. "的Agency! 请在OnInit方法中注册!")
        end
    else
        return XMVCA:GetAgency(moduleId)
    end
end

function XDlcWorldAgency:RegisterActivity(worldType, moduleId)
    self:__DebugCheck(moduleId)
    self._Model:AddAgency(worldType, moduleId)
end

-- endregion

function XDlcWorldAgency:_PreEnterFight()
    CsXBehaviorManager.Instance:Clear()
    XTableManager.ReleaseAll(true)
    CS.BinaryManager.OnPreloadFight(true)
    ---垃圾收集
    collectgarbage("collect")
    CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal, function()
        CS.XUiSceneManager.Clear()
    end)
    CsXUiManager.Instance:SetRevertAndReleaseLock(false)
end

function XDlcWorldAgency:_FinishFight()
    XLuaUiManager.SafeClose("UiDialog")
    XLuaUiManager.SafeClose("UiSet")
end

function XDlcWorldAgency:_SetFightDelegate(worldId)
    if worldId then
        local agency = self:GetAgencyByWorldId(worldId, true)

        if agency then
            CS.StatusSyncFight.XFightDelegate.GetDlcBaseAttrib = Handler(agency, agency.DlcGetBaseAttrib)
            CS.StatusSyncFight.XFightDelegate.GetDlcNpcAttrib = Handler(agency, agency.DlcGetNpcAttrib)
            CS.StatusSyncFight.XFightDelegate.GetWorldNpcBornMagicLevelMap = Handler(agency,
                agency.DlcGetWorldNpcBornMagicLevelMap)
        else
            self:_SetDefaultFightDelegate()
        end
    end
end

function XDlcWorldAgency:_SetDefaultFightDelegate()
    local agency = require("XModule/XBase/XDlcActivityAgency")
    
    CS.StatusSyncFight.XFightDelegate.GetDlcBaseAttrib = Handler(agency, agency.DlcGetBaseAttrib)
    CS.StatusSyncFight.XFightDelegate.GetDlcNpcAttrib = Handler(agency, agency.DlcGetNpcAttrib)
    CS.StatusSyncFight.XFightDelegate.GetWorldNpcBornMagicLevelMap = Handler(agency,
        agency.DlcGetWorldNpcBornMagicLevelMap)
end

function XDlcWorldAgency:_ClearFightDelegate()
    CS.StatusSyncFight.XFightDelegate.GetDlcBaseAttrib = nil
    CS.StatusSyncFight.XFightDelegate.GetDlcNpcAttrib = nil
    CS.StatusSyncFight.XFightDelegate.GetWorldNpcBornMagicLevelMap = nil
end

---@return XDlcWorld
function XDlcWorldAgency:_GetWorldByConfig(config)
    return XDlcWorld.New(config)
end

function XDlcWorldAgency:_IsForceExit()
    if not self:HasResult() then
        return true
    end

    local settleState = self:_GetSettleState()

    return settleState == XEnumConst.DlcWorld.SettleState.ErrorState
end

function XDlcWorldAgency:_GetSettleState()
    local resultData = self._Model:GetResult().SettleData.ResultData
    if not resultData then
        XLog.Error("XDlcFightSettleData.ResultData为空!")
        return XEnumConst.DlcWorld.SettleState.ErrorState
    end

    return resultData.SettleState
end

function XDlcWorldAgency:_GetSettleWorldId()
    if self:_IsForceExit() then
        return XMVCA.XDlcRoom:GetFightBeginData():GetWorldData():GetId()
    end

    local resultData = self._Model:GetResult().SettleData.ResultData

    if not resultData then
        XLog.Error("XDlcFightSettleData.ResultData为空!")
        return 0
    end

    local worldData = resultData.WorldData

    if not worldData then
        XLog.Error("XDlcFightSettleData.ResultData.WorldData为空!")
        return 0
    end

    return worldData.WorldId
end

function XDlcWorldAgency:__DebugCheck(moduleId)
    if XMain.IsDebug then
        local XDlcActivityAgency = require("XModule/XBase/XDlcActivityAgency")
        local agency = XMVCA:GetAgency(moduleId)

        if agency then
            if not CheckClassSuper(agency, XDlcActivityAgency) then
                XLog.Error(agency.__cname .. "需要继承XDlcActivityAgency并重写其方法!")
            end
        else
            XLog.Error("ModuleId = " .. moduleId .. "找不到对应Agency!")
        end
    end
end

return XDlcWorldAgency
