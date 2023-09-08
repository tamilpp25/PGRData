---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:41
---

---@class XControl : XMVCAEvent
---@field private _Model XModel
XControl = XClass(XMVCAEvent, "XControl")
local LockRefKey = "__LockRefKey__"
function XControl:Ctor(id, mainControl)
    XControl.Super.Ctor(self)
    self._Id = id
    self._Model = XMVCA:_GetOrRegisterModel(self._Id)
    self._Agency = nil
    self._RefUi = {} --记录引用的ui列表
    self._MainControl = mainControl
    ---@type table<string, XControl>
    self._SubControls = {} --子control, 支持多个control
    self._Class2NameMap = {}
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

---增加一个子control
---@param cls any
---@return XControl
function XControl:AddSubControl(cls)
    local cls2Name
    if self._Class2NameMap[cls] then
        cls2Name = self._Class2NameMap[cls]
    else
        cls2Name = tostring(cls)
        self._Class2NameMap[cls] = cls2Name
    end
    if not self._SubControls[cls2Name] then
        local control = cls.New(self._Id, self) --使用本control的id,这样才能保证获取的model一样
        self._SubControls[cls2Name] = control
        control:CallInit()
        return control
    else
        XLog.Error("请勿重复添加子control!")
    end
end

---删除一个子Control
---@param control XControl
function XControl:RemoveSubControl(control)
    local cls2Name = self._Class2NameMap[control.__class]
    if cls2Name and self._SubControls[cls2Name] then
        self._SubControls[cls2Name] = nil
        control:Release()
    else
        XLog.Error("移除不存在的子control: " .. control.__cname)
    end
    return nil
end

---获取一个子Control
---@return XControl
function XControl:GetSubControl(cls)
    local cls2Name = self._Class2NameMap[cls]
    return self._SubControls[cls2Name]
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
    end
end

---移除界面引用
function XControl:SubViewRef(ui)
    local index = table.indexof(self._RefUi, ui)
    if index then
        table.remove(self._RefUi, index)
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
    self._Class2NameMap = nil
    if self._Model then
        self._Model:ClearPrivate()
        self._Model:ClearPrivateConfig()
        self._Model = nil
    end
    self._Agency = nil
    self:Clear() --这里清理界面注册的事件
    for _, subControl in pairs(self._SubControls) do
        subControl:Release()
    end
    self._SubControls = nil
    self._MainControl = nil
    self:OnRelease()
end

---热重载的释放得特殊处理
function XControl:_HotReloadRelease()
    self._IsRelease = true
    self:RemoveAgencyEvent()
    self._RefUi = nil
    self._Class2NameMap = nil
    self._Agency = nil
    self:Clear() --这里清理界面注册的事件
    for _, subControl in pairs(self._SubControls) do
        subControl:_HotReloadRelease()
    end
    self._SubControls = nil
    self._MainControl = nil
    self:OnRelease()
end

function XControl:_HotReloadControl(oldCls, newCls)
    local oldSubControl = self:GetSubControl(oldCls)
    if oldSubControl then
        local cls2Name = self._Class2NameMap[oldCls]
        self._SubControls[cls2Name] = nil
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


---给子类重写的, 当Control释放的时候执行
function XControl:OnRelease()
    XLog.Error("请在子类重写Control.OnRelease方法")
end