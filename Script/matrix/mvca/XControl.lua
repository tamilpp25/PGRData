---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:41
---
local IsWindowsEditor = XMain.IsWindowsEditor

---@class XControl : XMVCAEvent
---@field protected _Model XModel
---@field private _Agency XAgency
---@field private _Loader XLoaderUtil
XControl = XClass(XMVCAEvent, "XControl")
local LockRefKey = "__LockRefKey__"
function XControl:Ctor(id, mainControl)
    self._Id = id
    self._Model = XMVCA:_GetOrRegisterModel(self._Id)
    self._Agency = false
    self._Loader = false
    self._RefUi = {} --记录引用的ui列表
    self._MainControl = mainControl
    ---@type table<string, XControl>
    self._SubControls = {} --子control, 支持多个control
    self._DelayReleaseTime = 0 --延迟释放时间, 默认不延迟
    self._LastUseTime = 0 --最后使用时间
    self._IsRelease = false
end

function XControl:CallInit()
    self:OnInit()
    self:AddAgencyEvent()
end

function XControl:GetId()
    return self._Id
end

function XControl:GetIsRelease()
    return self._IsRelease
end

---设置延迟释放时间, 单位秒(s)
---@param time number
function XControl:SetDelayReleaseTime(time)
    self._DelayReleaseTime = time
end

function XControl:_GetDelayReleaseTime()
    return self._DelayReleaseTime
end

---更新最后使用时间
function XControl:_UpdateLastUseTime()
    self._LastUseTime = CS.UnityEngine.Time.realtimeSinceStartup
end

---获取最后使用时间
function XControl:_GetLastUseTime()
    return self._LastUseTime
end

---初始化函数,提供给子类重写
function XControl:OnInit()

end

---获取模块的Agency
---@return XAgency
function XControl:GetAgency()
    if not self._Agency then
        self._Agency = XMVCA:GetAgency(self._Id)
    end
    return self._Agency
end

---获取绑定模块的加载器
---@return XLoaderUtil
function XControl:GetLoader()
    if not self._Loader then
        if self._MainControl then --有主control的就跟主control取就好了
            self._Loader = self._MainControl:GetLoader()
        else
            self._Loader = CS.XLoaderUtil.GetModuleLoader(self._Id)
        end
    end
    return self._Loader
end

---增加一个子control
---@param cls any
---@return XControl
function XControl:AddSubControl(cls)
    if not self._SubControls[cls] then
        local control = cls.New(self._Id, self) --使用本control的id,这样才能保证获取的model一样
        self._SubControls[cls] = control
        control:CallInit()
        return control
    else
        XLog.Error("请勿重复添加子control!")
    end
end

---删除一个子Control
---@param control XControl
function XControl:RemoveSubControl(control)
    if self._SubControls[control.__class] then
        self._SubControls[control.__class] = nil
        control:Release()
    else
        XLog.Error("移除不存在的子control: " .. control.__cname)
    end
    return nil
end

---获取一个子Control
---@return XControl
function XControl:GetSubControl(cls)
    return self._SubControls[cls]
end

---control在生命周期启动的时候需要对Agency及对外的Agency进行添加监听
function XControl:AddAgencyEvent()

end

---controld在生命周期结束的时候需要对Agency及对外的Agency进行移除监听
function XControl:RemoveAgencyEvent()

end

---添加界面引用
function XControl:AddViewRef(ui)
    if not table.indexof(self._RefUi, ui) then
        table.insert(self._RefUi, ui)
    else
        XLog.Error(string.format("绑定已存在的ui序号: control %s, UId: %s", self._Id, ui))
    end
end

---移除界面引用
function XControl:SubViewRef(ui)
    local index = table.indexof(self._RefUi, ui)
    if index then
        table.remove(self._RefUi, index)
    else
        XLog.Error(string.format("解绑不存在的ui序号: control %s, UId: %s", self._Id, ui))
    end
end

function XControl:HasViewRef()
    return #self._RefUi > 0
end

---手动锁定引用, 因为有些系统依赖场景
function XControl:LockRef()
    self:AddViewRef(LockRefKey)
end

---手动解除锁定
function XControl:UnLockRef()
    self:SubViewRef(LockRefKey)
end

function XControl:Release()
    self._IsRelease = true
    self:RemoveAgencyEvent()
    self._RefUi = nil

    if self._MainControl == nil then
        self._Model:ClearPrivate()
        self._Model:ClearPrivateConfig()
        if self._Loader then --只有主loader才需要从C#层释放
            CS.XLoaderUtil.ClearModuleLoader(self._Id)
        end
    end
    self._Loader = nil
    self._Model = nil

    self._Agency = nil
    self:Clear() --这里清理界面注册的事件
    for _, subControl in pairs(self._SubControls) do
        subControl:Release()
    end
    self._SubControls = nil
    self._MainControl = nil
    self:OnRelease()
    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.Control, self)
    end
end

---热重载的释放得特殊处理
function XControl:_HotReloadRelease()
    self._IsRelease = true
    self:RemoveAgencyEvent()
    self._RefUi = nil
    self._Agency = nil
    self:Clear() --这里清理界面注册的事件
    for _, subControl in pairs(self._SubControls) do
        subControl:_HotReloadRelease()
    end
    self._SubControls = nil
    self._MainControl = nil
    self:OnRelease()
    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.Control, self)
    end
end

function XControl:_HotReloadControl(oldCls, newCls)
    local oldSubControl = self:GetSubControl(oldCls)
    if oldSubControl then
        self._SubControls[oldCls] = nil
        oldSubControl:_HotReloadRelease()

        self:AddSubControl(newCls)

        --这里判断是否有暂时缓存的
        for k, v in pairs(self) do
            if v == oldSubControl then
                self[k] = self:GetSubControl(newCls)
            end
        end
    end
end

---给子类重写, 当模块没有引用时触发
function XControl:OnRefClear()

end


---给子类重写的, 当Control释放的时候执行
function XControl:OnRelease()
    XLog.Error("请在子类重写Control.OnRelease方法")
end