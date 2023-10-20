local XDlcWorld = require("XModule/XDlcWorld/XEntity/XDlcWorld")
local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")
local XDlcActivityAgency = require("XModule/XBase/XDlcActivityAgency")

---@class XDlcWorldAgency : XAgency
---@field private _Model XDlcWorldModel
local XDlcWorldAgency = XClass(XAgency, "XDlcWorldAgency")

function XDlcWorldAgency:OnInit()
    --初始化一些变量
end

function XDlcWorldAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.DlcBossSettleResponse = Handler(self, self.OnNotifyFightFinishSettle)
end

function XDlcWorldAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
    self:__DebugCheck()
end

--region World相关
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

function XDlcWorldAgency:CheckWorldIsRankById(id)
    return self:GetIsRankById(id) == 1
end

function XDlcWorldAgency:GetDifficultyIdById(id)
    return self._Model:GetDifficultyIdById(id)
end

function XDlcWorldAgency:GetRebootIdById(id)
    return self._Model:GetRobootIdById(id)
end
--endregion

--region 战斗相关
function XDlcWorldAgency:GetAgencyByWorldId(worldId)
    local worldType = self:GetWorldTypeById(worldId)

    return self:GetAgencyByWorldType(worldType)
end

---@return XDlcActivityAgency
function XDlcWorldAgency:GetAgencyByWorldType(worldType)
    --后续Dlc活动增多可以改成主干FubenManager的注册方式
    if worldType == XEnumConst.DlcWorld.WorldType.Cube then
        return XMVCA.XDlcCasual
    elseif worldType == XEnumConst.DlcWorld.WorldType.Hunt then
        -- abandoned 后续DlcHunt开二期时补上 切勿模仿
        return XMVCA.XDlcCasual
    end
end

function XDlcWorldAgency:HasResult()
    return self._Model:GetResult() ~= nil
end

function XDlcWorldAgency:OnNotifyFightFinishSettle(res)
    local worldId = res.SettleData.ResultData.WorldData.WorldId
    if worldId and self:GetWorldTypeById(worldId) == XEnumConst.DlcWorld.WorldType.Hunt then
        XDataCenter.DlcHuntManager.OnNotifyFightSettle(res.SettleData)
        return
    end
    self._Model:SetResult(res)
end

function XDlcWorldAgency:OnEnterFight()
    self:_PreEnterFight()
    self._Model:SetResult(nil)
end

function XDlcWorldAgency:OnFightSettle()
    if XMVCA.XDlcRoom:IsSettled() then
        return
    end

    local worldId = XMVCA.XDlcRoom:GetFightBeginData():GetWorldData():GetId()
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
        XLog.Error("找不到WorldType = " .. worldType .. "对应的Agency! 请在XDlcWorldAgency:GetAgencyByWorldType中注册!")
        fightEvent = XDlcWorldFight.New()
    end

    XMVCA.XDlcRoom:Settlement()
    if self:_IsForceExit() then
        fightEvent:OnFightForceExit(worldType)
        XMVCA.XDlcRoom:Close(false)
    else
        local result = self._Model:GetResult()

        fightEvent:OnFightFinishSettle(worldType, result.SettleData, result.SettleData.ResultData.IsWin)
    end
end
--endregion

function XDlcWorldAgency:_PreEnterFight()
    ---垃圾收集
    collectgarbage("collect")
    -- ui场景提前释放，不等ui销毁
    CS.XUiSceneManager.Clear()
    CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal)
    CsXUiManager.Instance:SetRevertAndReleaseLock(false)
end

---@return XDlcWorld
function XDlcWorldAgency:_GetWorldByConfig(config)
    return XDlcWorld.New(config)
end

function XDlcWorldAgency:_IsForceExit()
    return not self:HasResult() or self:_GetSettleState() ~= XEnumConst.DlcWorld.SettleState.None
end

function XDlcWorldAgency:_GetSettleState()
    local resultData = self._Model:GetResult().SettleData.ResultData
    if not resultData then
        XLog.Error("XDlcFightSettleData.ResultData为空!")
        return XEnumConst.DlcWorld.SettleState.Exit
    end

    return resultData.SettleState
end

function XDlcWorldAgency:__DebugCheck()
    if XMain.IsDebug then
        for key, worldType in pairs(XEnumConst.DlcWorld.WorldType) do
            local agency = self:GetAgencyByWorldType(worldType)
            if agency then
                if not CheckClassSuper(agency, XDlcActivityAgency) then
                    XLog.Error(agency.__cname .. "需要继承XDlcActivityAgency并重写其方法!")
                end
            else
                XLog.Error("WorldType = " .. key .. " 找不到对应的Agency!请在XDlcWorldAgency:GetAgencyByWorldType中注册!")
            end
        end
    end
end

return XDlcWorldAgency
