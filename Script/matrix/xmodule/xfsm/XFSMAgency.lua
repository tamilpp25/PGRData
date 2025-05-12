---@class XFSMAgency : XAgency
---@field private _Model XFSMModel
local XFSMAgency = XClass(XAgency, "XFSMAgency")
function XFSMAgency:OnInit()
    --初始化一些变量
    self.AutoUpdateTimer = nil  -- 自动Update的计时器，自动状态机通过计时器刷新

    ---@type table<XUpdatableFSM, any>
    self.ActiveFSMDic = {} -- 当前存活中的FSM
    ---@type table<XUpdatableFSM, any>
    self.AutoUpdateFSMDic = {} -- 当前自动状态的FSM
    self.IsAutoPlayCount = 0 -- 计数当前处于play状态的Auto模式FSM
end

function XFSMAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XFSMAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------
function XFSMAgency:CreateUpdatableFSM(controllerPath, proxy, ...)
    if not controllerPath or not proxy then
        XLog.Error("controllerName or proxy is nil")
        return
    end

    local fsm = require("XFSM/XUpdatableFSM")
    -- local controller = require("XFSM/XController/" .. controllerName)
    local controller = require(controllerPath)
    ---@type XBaseController
    local xController = controller.New()
    ---@type XUpdatableFSM
    local xFSM = fsm.New(xController:GetConfig(), proxy, xController, ...)
    self.ActiveFSMDic[xFSM] = proxy
    return xFSM
end

--region AutoMode start
---@param self XFSMAgency
local MinusCountByLeavePlayState = function(self, xFSM)
    local state = self.AutoUpdateFSMDic[xFSM] 
    if state == XEnumConst.FSM.AutoState.Play then
        self.IsAutoPlayCount = self.IsAutoPlayCount - 1
    end
end

---@param self XFSMAgency
local AddCountByEnterPlayState = function(self)
    self.IsAutoPlayCount = self.IsAutoPlayCount + 1
end

---@param xFSM XUpdatableFSM
function XFSMAgency:SetFSMAutoUpdateFlag(xFSM, flag)
    -- 必须是存活中的fsm
    if not self.ActiveFSMDic[xFSM] then
        return
    end

    xFSM.IsAutoUpdate = flag
    if flag then
        self.AutoUpdateFSMDic[xFSM] = XEnumConst.FSM.AutoState.Init
    else
        self.AutoUpdateFSMDic[xFSM] = nil
    end

    self:CheckNeedAutoUpdate()
end

---@param xFSM XUpdatableFSM
function XFSMAgency:SetAutoFSMPlay(xFSM)
    if not self.AutoUpdateFSMDic[xFSM] then
        return
    end

    AddCountByEnterPlayState(self)
    self.AutoUpdateFSMDic[xFSM] = XEnumConst.FSM.AutoState.Play
    self:CheckNeedAutoUpdate()
end

---@param xFSM XUpdatableFSM
function XFSMAgency:SetAutoFSMPause(xFSM)
    if not self.AutoUpdateFSMDic[xFSM] then
        return
    end

    MinusCountByLeavePlayState(self, xFSM)
    self.AutoUpdateFSMDic[xFSM] = XEnumConst.FSM.AutoState.Pause
    self:CheckNeedAutoUpdate()
end

--- func desc
---@param xFSM XUpdatableFSM
function XFSMAgency:SetAutoFSMStop(xFSM)
    local state = self.AutoUpdateFSMDic[xFSM]
    if not state then
        return
    end

    MinusCountByLeavePlayState(self, xFSM)
    self.AutoUpdateFSMDic[xFSM] = XEnumConst.FSM.AutoState.Init
    local initState = xFSM.Cfg.Initial
    if xFSM[initState] then
        xFSM[initState]()
    end
end

function XFSMAgency:CheckNeedAutoUpdate()
    if XTool.IsNumberValid(self.IsAutoPlayCount) then
        -- 需要开启update
        if not self.AutoUpdateTimer then
            self.AutoUpdateTimer = XScheduleManager.ScheduleForever(function()
                self:UpdateFSM()
            end, 0, 0)
        end
    else
        -- 需要停止update
        if self.AutoUpdateTimer then
            XScheduleManager.UnSchedule(self.AutoUpdateTimer)
            self.AutoUpdateTimer = nil
        end
    end
end
--endregion AutoMode start
---@param xFSM XUpdatableFSM
function XFSMAgency:ReleaseFSM(xFSM)
    self:SetAutoFSMStop(xFSM)
    self.ActiveFSMDic[xFSM] = nil
    self.AutoUpdateFSMDic[xFSM] = nil
    xFSM:Release()
    self:CheckNeedAutoUpdate()
end
----------public end----------

----------private start----------
function XFSMAgency:UpdateFSM()
    for xFSM, state in pairs(self.AutoUpdateFSMDic) do
        if state == XEnumConst.FSM.AutoState.Play then
            xFSM:UpdateAuto()
        end
    end
end
----------private end----------

return XFSMAgency