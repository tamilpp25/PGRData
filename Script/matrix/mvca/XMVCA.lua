---
--- MVCA管理容器
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:32
---
---
--先引用进来基础的class
require("MVCA/ModuleId")
require("MVCA/XMVCAUtil")
require("MVCA/XConfigUtil")
require("MVCA/XMVCAEvent")
require("MVCA/XModel")
require("MVCA/XControl")
require("MVCA/XAgency")
require("MVCA/MVCAEventId")

local IsWindowsEditor = XMain.IsWindowsEditor

---@class XMVCACls : XMVCAEvent
---@field _AgencyDict table<string, XAgency>
---@field _ControlDict table<string, XControl>
---@field _ModelDict table<string, XModel>
---@field XCharacter XCharacterAgency
---@field XCommonCharacterFilt XCommonCharacterFiltAgency
---@field XEquip XEquipAgency
---@field XTheatre3 XTheatre3Agency
---@field XFuben XFubenAgency
---@field XPassport XPassportAgency
---@field XUiMain XUiMainAgency
---@field XConnectingLine XConnectingLineAgency
---@field XSubPackage XSubPackageAgency
---@field XPreload XPreloadAgency
---@field XTaikoMaster XTaikoMasterAgency
---@field XSameColor XSameColorAgency
local XMVCACls = XClass(XMVCAEvent, "XMVCACls")

function XMVCACls:Ctor()
    self._AgencyDict = {}
    self._ControlDict = {}
    self._ModelDict = {}
    self._OneKeyReLogin = false
    if IsWindowsEditor then
        self._ControlProfiler = {}
        setmetatable(self._ControlProfiler, { __mode = "kv"})
        self._ConfigProfiler = {}
        setmetatable(self._ConfigProfiler, { __mode = "kv"})
        self._PreloadConfig = {}
        
        setmetatable(self, {
            __index = function(t, k)
                if ModuleId[k] and not self._AgencyDict[k] then
                    XLog.Error("未注册Agency：" .. tostring(k) .. ", 请先在XMVCACls:InitModule 进行注册！")
                end
                local value = self.__class[k] or XMVCACls[k] or GetClassVituralTable(self.__class)[k]
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
        local cls = XMVCAUtil.GetControlCls(id)
        ---@type XControl
        local control = cls.New(id)
        self._ControlDict[id] = control
        control:CallInit()
        if IsWindowsEditor then
            self._ControlProfiler[control] = control:GetId()
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
        control:Release()
        self._ControlDict[id] = nil
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
    end
end

function XMVCACls:_HotReloadSubControl(id, oldCls, newCls)
    if self._ControlDict[id] then
        local mainControl = self._ControlDict[id]
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
            newModel[key] = XTool.Clone(value)
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
    self:RegisterAgency(ModuleId.XCommonCharacterFilt)
    self:RegisterAgency(ModuleId.XEquip)

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
    
    self:RegisterAgency(ModuleId.XConnectingLine)
    self:RegisterAgency(ModuleId.XSubPackage)
    self:RegisterAgency(ModuleId.XPreload)
end

--XMVCA:Profiler()
---检测control释放
function XMVCACls:Profiler()
    if IsWindowsEditor then
        collectgarbage("collect") --得调用Lua Profiler界面的GC才能释放干净
        XLog.Debug("XMVCACls:ControlProfiler", self._ControlProfiler)
        XLog.Debug("XMVCACls:ConfigProfiler", self._ConfigProfiler)
        XLog.Debug("XMVCACls:PreloadConfig", self._PreloadConfig)
    end
end

function XMVCACls:AddConfigProfiler(configTable, tag)
    if IsWindowsEditor then
        self._ConfigProfiler[configTable] = tag
    end
end

function XMVCACls:AddPreloadConfig(path)
    if IsWindowsEditor then
        table.insert(self._PreloadConfig, path)
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















