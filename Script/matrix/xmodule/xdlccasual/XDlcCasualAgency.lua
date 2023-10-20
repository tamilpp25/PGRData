local XDlcActivityAgency = require("XModule/XBase/XDlcActivityAgency")
local XDlcCasualRoom = require("XModule/XDlcCasual/XEntity/XDlcCasualRoom")
local XDlcCasualWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcCasualWorldFight")

---@class XDlcCasualAgency : XDlcActivityAgency
---@field private _Model XDlcCasualModel
local XDlcCasualAgency = XClass(XDlcActivityAgency, "XDlcCasualAgency")

function XDlcCasualAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XDlcCasualAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyDlcCasualCubeData = Handler(self, self.OnNotifyDlcCasualCubeData)
end

function XDlcCasualAgency:InitEvent()
    --实现跨Agency事件注册
end

function XDlcCasualAgency:OnNotifyDlcCasualCubeData(data)
    local activityId = data.Id

    self._Model:SetActivityId(activityId)
    XMVCA.XDlcRoom:InitFight()
    self:DispatchEvent(XEventId.EVENT_DLC_CASUAL_ACTIVITY_UPDATE_NOTIFY)
end

function XDlcCasualAgency:GetNpcIdById(characterId)
    return self._Model:GetCharacterNpcIdById(characterId)
end

--region 副本入口相关
function XDlcCasualAgency:ExOpenMainUi()
    if not self:_CheckActivityOpen() then
        return
    end

    XLuaUiManager.Open("UiDlcCasualGamesMain")
end

function XDlcCasualAgency:ExCheckInTime()
    return self:_CheckActivityOpen()
end

function XDlcCasualAgency:ExGetConfig()
    if not XTool.IsTableEmpty(self.ExConfig) then
        return self.ExConfig
    end
    self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)

    return self.ExConfig
end

function XDlcCasualAgency:ExGetProgressTip()
    return ""
end

function XDlcCasualAgency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.DlcCasual
end

--endregion

--region Dlc活动相关
function XDlcCasualAgency:DlcGetRoomProxy()
    return XDlcCasualRoom.New()
end

function XDlcCasualAgency:DlcGetFightEvent()
    return XDlcCasualWorldFight.New()
end

--endregion

function XDlcCasualAgency:GetOpenLevelLimit()
    local config = self:ExGetConfig()
    local funcId = config.FunctionNameId
    local conditionId = XFunctionConfig.GetFuncOpenCfg(funcId).Condition[1]
    local levelLimit = XConditionManager.GetConditionParams(conditionId)

    return levelLimit
end

--region 私有方法
function XDlcCasualAgency:_CheckActivityOpen()
    local activityId = self._Model:GetActivityId()

    if not activityId then
        return false
    end

    local timeId = self._Model:GetActivityTimeIdById(activityId)

    return XFunctionManager.CheckInTimeByTimeId(timeId, false)
end

--endregion

return XDlcCasualAgency
