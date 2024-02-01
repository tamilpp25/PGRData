---
--- MVCA管理容器
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:32
---
---
--先引用进来基础的class
require("MVCA/XUidObject")
require("MVCA/ModuleId")
require("MVCA/XMVCAUtil")
require("MVCA/XConfigUtil")
require("MVCA/XMVCAEvent")
require("MVCA/XEntity")
require("MVCA/XModel")
require("MVCA/XControl")
require("MVCA/XEntityControl")
require("MVCA/XAgency")
require("MVCA/MVCAEventId")

local IsWindowsEditor = XMain.IsWindowsEditor

---@class XMVCACls : XMVCAEvent
---@field _AgencyDict table<string, XAgency>
---@field _ControlDict table<string, XControl>
---@field _ModelDict table<string, XModel>
---@field _ControlReleaseDict table<string, XControl>
---@field XCharacter XCharacterAgency
---@field XCommonCharacterFilter XCommonCharacterFilterAgency
---@field XEquip XEquipAgency
---@field XTheatre3 XTheatre3Agency
---@field XBlackRockChess XBlackRockChessAgency
---@field XFuben XFubenAgency
---@field XPassport XPassportAgency
---@field XUiMain XUiMainAgency
---@field XConnectingLine XConnectingLineAgency
---@field XSubPackage XSubPackageAgency
---@field XPreload XPreloadAgency
---@field XTaikoMaster XTaikoMasterAgency
---@field XSameColor XSameColorAgency
---@field XRogueSim XRogueSimAgency
---@field XBirthdayPlot XBirthdayPlotAgency
---@field XFavorability XFavorabilityAgency
---@field XDlcRoom XDlcRoomAgency
---@field XDlcWorld XDlcWorldAgency
---@field XDlcCasual XDlcCasualAgency
---@field XFubenEx XFubenExAgency
---@field XCerberusGame XCerberusGameAgency
---@field XFangKuai XFangKuaiAgency
---@field XGoldenMiner XGoldenMinerAgency
---@field XReform XReformAgency
---@field XKotodamaActivity XKotodamaActivityAgency
---@field XMail XMailAgency
---@field XAccumulateExpend XAccumulateExpendAgency
---@field XFubenBossSingle XFubenBossSingleAgency
---@field XTemple XTempleAgency
---@field XFSM XFSMAgency
local XMVCACls = XClass(XMVCAEvent, "XMVCACls")

function XMVCACls:Ctor()
    self._AgencyDict = {}
    self._ControlDict = {}
    self._ControlReleaseDict = {} --延迟释放的词典
    self._ModelDict = {}
    self._OneKeyReLogin = false
    self._ReleaseTimer = false
    self._CheckReleaseControlHandler = handler(self, self._CheckReleaseControl)
    if IsWindowsEditor then
        self._PreloadConfig = {}
        
        setmetatable(self, {
            __index = function(t, k)
                if ModuleId[k] and not self._AgencyDict[k] then
                    XLog.Error("未注册Agency：" .. tostring(k) .. ", 请先在XMVCACls:InitModule 进行注册！")
                end
                local value = self.__class[k] or XMVCACls[k] or GetClassVirtualTable(self.__class)[k]
                if not value then
                    XLog.Error("未获取到Key为" .. tostring(k) .. "的值，如果是Agency请先在XMVCACls:InitModule 进行注册！")
                end
                return value
            end
        })
    end
    
end

---注册模块
---@param id number 模块id, ModuleId
function XMVCACls:RegisterAgency(id)
    if self._AgencyDict[id] then
        XLog.Error("请勿重复初始化Agency: " .. id)
    else
        local cls = XMVCAUtil.GetAgencyCls(id)
        local agency = cls.New(id)
        self._AgencyDict[id] = agency
        self[id] = agency
        agency:OnInit()
    end
end

---初始化所有模块的办事处的rpc, 因为之前是在import文件的时候就注册了
function XMVCACls:InitAllAgencyRpc()
    for _, v in pairs(self._AgencyDict) do
        v:InitRpc() --后端通讯rpc
    end
end

function XMVCACls:Init()
    self:_ReleaseAllDelayControl() --这里全部移除掉
    self:_Reset()
    self:_InitAllAgencyEvent()
end

function XMVCACls:_InitAllAgencyEvent()
    for _, v in pairs(self._AgencyDict) do
        v:InitEvent() --跨模块事件
        v:AfterInitManager()
    end
end

function XMVCACls:_Reset()
    --for _, v in pairs(self._ControlDict) do
    --    v:ResetAll()
    --end
    for _, v in pairs(self._ModelDict) do
        v:ResetAll()
    end
end

---获取Agency
---@return XAgency
function XMVCACls:GetAgency(id)
    if not self._AgencyDict[id] then
        XLog.Error("未注册Agency：" .. tostring(id) .. ", 请先在XMVCACls:InitModule 进行注册！")
        return
    end
    return self._AgencyDict[id]
end

----------control相关----------

---注册Control
function XMVCACls:_RegisterControl(id)
    if self._ControlDict[id] then
        XLog.Error("请勿重复初始化Control: " .. id)
    else
        if self._ControlReleaseDict[id] then --在延迟列表里存在
            local control = self._ControlReleaseDict[id]
            self:_RemoveDelayReleaseControl(id)
            self._ControlDict[id] = control
        else
            local cls = XMVCAUtil.GetControlCls(id)
            ---@type XControl
            local control = cls.New(id)
            self._ControlDict[id] = control
            control:CallInit()
        end
    end
end

---获取或注册control
---@return XControl
function XMVCACls:_GetOrRegisterControl(id)
    if not self._ControlDict[id] then
        self:_RegisterControl(id)
    end
    return self._ControlDict[id]
end

---检测control是否要释放掉
---@param id number 模块id ModuleId
function XMVCACls:CheckReleaseControl(id)
    local control = self._ControlDict[id]
    if control and not control:HasViewRef() then
        if control:_GetDelayReleaseTime() ~= 0 then
            self:_AddDelayReleaseControl(control)
        else
            control:Release()
        end
        self._ControlDict[id] = nil
    end
end

---@param control XControl
function XMVCACls:_AddDelayReleaseControl(control)
    local id = control:GetId()
    if self._ControlReleaseDict[id] then
        XLog.Error("延迟释放列表里已存在Control: " .. id)
        return
    else
        self._ControlReleaseDict[id] = control
        control:_UpdateLastUseTime() --更新最后使用时间
    end
    if not self._ReleaseTimer then
        self._ReleaseTimer = XScheduleManager.ScheduleForever(self._CheckReleaseControlHandler, 0, 0)
    end
end

function XMVCACls:_RemoveDelayReleaseControl(id)
    if not self._ControlReleaseDict[id] then
        XLog.Error("移除延迟释放列表不存在的Control: " .. id)
        return
    end
    self._ControlReleaseDict[id] = nil
    if not next(self._ControlReleaseDict) then
        self:_RemoveDelayTimer()
    end
end

function XMVCACls:_CheckReleaseControl()
    local removeIds = {}
    local now = CS.UnityEngine.Time.realtimeSinceStartup
    for id, control in pairs(self._ControlReleaseDict) do
        if not control:HasViewRef() and now - control:_GetLastUseTime() >= control:_GetDelayReleaseTime() then --超出释放时间了
            table.insert(removeIds, id)
        end
    end

    for _, id in ipairs(removeIds) do
        local control = self._ControlReleaseDict[id]
        control:Release()
        self._ControlReleaseDict[id] = nil
    end

    if not next(self._ControlReleaseDict) then
        self:_RemoveDelayTimer()
    end
end

--直接移除所有的延迟释放control
function XMVCACls:_ReleaseAllDelayControl()
    for _, control in ipairs(self._ControlReleaseDict) do
        control:Release()
    end
    self._ControlReleaseDict = {}
    self:_RemoveDelayTimer()
end

function XMVCACls:_RemoveDelayTimer()
    if self._ReleaseTimer then
        XScheduleManager.UnSchedule(self._ReleaseTimer)
        self._ReleaseTimer = false
    end
end


---检测control是否有被引用
---@param id number 模块id ModuleId
---@return boolean
function XMVCACls:_CheckControlRef(id)
    local control = self._ControlDict[id]
    if control then
        return true
    end
    return false
end

----------model相关----------

function XMVCACls:_RegisterModel(id)
    if self._ModelDict[id] then
        XLog.Error("请勿重复初始化Model: " .. id)
    else
        local cls = XMVCAUtil.GetModelCls(id)
        self._ModelDict[id] = cls.New(id)
    end
end

function XMVCACls:_GetOrRegisterModel(id)
    if not self._ModelDict[id] then
        self:_RegisterModel(id)
    end
    return self._ModelDict[id]
end

function XMVCACls:_ReleaseAll()
    for moduleId, agency in pairs(self._AgencyDict) do
        agency:Release()
        self[moduleId] = nil
    end
    for _, control in pairs(self._ControlDict) do
        control:Release()
    end
    self:_ReleaseAllDelayControl()
    for _, model in pairs(self._ModelDict) do
        model:Release()
    end
    self._AgencyDict = {}
    self._ControlDict = {}
    self._ModelDict = {}
end

---HotReload相关
--一键重登
function XMVCACls:SetOneKeyReLogin()
    self._OneKeyReLogin = true
end
--一键重登全部干掉
function XMVCACls:_HotReloadAll()
    if self._OneKeyReLogin then
        self:_ReleaseAll()
        self:InitModule()
        self:InitAllAgencyRpc()
        self._OneKeyReLogin = false
    end
end

function XMVCACls:_HotReloadAgency(id)
    if self._AgencyDict[id] then --已经存在的
        local oldAgency = self._AgencyDict[id]
        oldAgency:Release()
        local cls = XMVCAUtil.GetAgencyCls(id)
        local newAgency = cls.New(id)
        self._AgencyDict[id] = newAgency
        self[id] = newAgency
        newAgency:OnInit()
        newAgency:InitRpc()
        newAgency:InitEvent()
    end
end

---Control相关的需要把相关界面关闭再打开
function XMVCACls:_HotReloadControl(id)
    if self._ControlDict[id] then
        local oldControl = self._ControlDict[id]
        self._ControlDict[id] = nil -- 要清空掉
        oldControl:_HotReloadRelease()
    elseif self._ControlReleaseDict[id] then
        local oldControl = self._ControlReleaseDict[id]
        self._ControlReleaseDict[id] = nil
        oldControl:_HotReloadRelease()
        if not next(self._ControlReleaseDict) then
            self:_RemoveDelayTimer()
        end
    end
end

function XMVCACls:_HotReloadSubControl(id, oldCls, newCls)
    if self._ControlDict[id] then
        local mainControl = self._ControlDict[id]
        mainControl:_HotReloadControl(oldCls, newCls)
    elseif self._ControlReleaseDict[id] then
        local mainControl = self._ControlReleaseDict[id]
        mainControl:_HotReloadControl(oldCls, newCls)
    end
end

function XMVCACls:_HotReloadModel(id)
    if self._ModelDict[id] then
        local oldModel = self._ModelDict[id]

        local cls = XMVCAUtil.GetModelCls(id)

        ---@type XModel
        local newModel = cls.New(id)
        self:_CloneModel(oldModel, newModel)
        oldModel:Release()

        self._ModelDict[id] = newModel

        local agency = self._AgencyDict[id]
        if agency and agency._Model then
            agency._Model = newModel
        end
        local control = self._ControlDict[id]
        if control and control._Model then
            control._Model = newModel
        end
    end
end

function XMVCACls:_CloneModel(oldModel, newModel)
    local ReloadFunc = XHotReload.ReloadFunc
    for key, value in pairs(oldModel) do
        if key ~= "_ConfigUtil" then
            newModel[key] = XTool.CloneEx(value)
            if type(value) == "function" then
                ReloadFunc(value)
            end
        end
    end
end


---常用的一些模块放在这里初始化
function XMVCACls:InitModule()
    self:RegisterAgency(ModuleId.XMail)
    self:RegisterAgency(ModuleId.XCharacter)
    self:RegisterAgency(ModuleId.XCommonCharacterFilter)
    self:RegisterAgency(ModuleId.XEquip)

    self:RegisterAgency(ModuleId.XFSM)
    self:RegisterAgency(ModuleId.XFuben)
    self:RegisterAgency(ModuleId.XFubenEx)
    self:RegisterAgency(ModuleId.XTheatre3)
    self:RegisterAgency(ModuleId.XBlackRockChess)
    self:RegisterAgency(ModuleId.XTurntable)
    self:RegisterAgency(ModuleId.XBlackRockStage)
    self:RegisterAgency(ModuleId.XPassport)
    self:RegisterAgency(ModuleId.XTaikoMaster)
    self:RegisterAgency(ModuleId.XUiMain)
    self:RegisterAgency(ModuleId.XNewActivityCalendar)
    self:RegisterAgency(ModuleId.XTwoSideTower)
    self:RegisterAgency(ModuleId.XFavorability)
    self:RegisterAgency(ModuleId.XSameColor)
    self:RegisterAgency(ModuleId.XGoldenMiner)
    
    self:RegisterAgency(ModuleId.XDlcRoom)
    self:RegisterAgency(ModuleId.XDlcWorld)
    self:RegisterAgency(ModuleId.XDlcCasual)
    self:RegisterAgency(ModuleId.XConnectingLine)
    self:RegisterAgency(ModuleId.XSubPackage)
    self:RegisterAgency(ModuleId.XPreload)
    self:RegisterAgency(ModuleId.XRogueSim)
    self:RegisterAgency(ModuleId.XBirthdayPlot)
    self:RegisterAgency(ModuleId.XCerberusGame)
    self:RegisterAgency(ModuleId.XArchive)
    self:RegisterAgency(ModuleId.XAnniversary)
    self:RegisterAgency(ModuleId.XReform)
    self:RegisterAgency(ModuleId.XKotodamaActivity)
    self:RegisterAgency(ModuleId.XFangKuai)
    self:RegisterAgency(ModuleId.XAccumulateExpend)
    --self:RegisterAgency(ModuleId.X3C)
    self:RegisterAgency(ModuleId.XMainLine2)
    self:RegisterAgency(ModuleId.XFubenBossSingle)
    self:RegisterAgency(ModuleId.XTemple)
end

function XMVCACls:AddPreloadConfig(path)
    if IsWindowsEditor then
        table.insert(self._PreloadConfig, path)
    end
end

function XMVCACls:ProfilerLiveControl()
    if IsWindowsEditor then
        local Uid2NameMap = XLuaUiManager.GetUid2NameMap()
        local log = ""
        for moduleId, control in pairs(self._ControlDict) do
            log = log .. moduleId .. " RefUi: "
            local refViewUidList = control._RefUi
            for _, uid in ipairs(refViewUidList) do
                log = log .. (Uid2NameMap[uid] or "")
            end
            log = log .. "\n"
        end
        XLog.Debug(log)
    end
end

---@type XMVCACls
XMVCA = XMVCACls.New()



---新框架开发规则---
---1. 事件注册事件需要传入self, 不使用匿名函数
---2. 不要在类里定义基于文件的local变量, 不好做回收
---3. 内部使用的变量和函数前面加下划线
---4. model不对外, 避免又出现到处访问的情况

---现存问题
---XLuaUi:OnGetEvents()注册的事件, 是针对基于XGameEventManager (C#)层派发的事件, lua层需要自己在XEventManager注册, 目前这块用的比较混乱了















