
---@class XChessScene 战棋场景
---@field _Resource
---@field _GameObject UnityEngine.GameObject
---@field _Transform UnityEngine.Transform
---@field _LoadCb function
---@field _ReleaseTimer boolean 准备释放
---@field _Path string 场景路径
local XChessScene = XClass(nil, "XChessScene")

-- 延时销毁
local DelayReleaseTime = 0 * XScheduleManager.SECOND

local CsVector3 = CS.UnityEngine.Vector3

function XChessScene:Ctor(loadCb)
    self._LoadCb = loadCb
    self._OnTryToReleaseCb = handler(self, self.TryToRelease)
end

--- 展示
--------------------------
function XChessScene:Display(path)
    if self._Path == path and self:Exist() then
        -- 重新显示，打断销毁
        self:StopReleaseTimer()
        self._GameObject:SetActiveEx(true)
        return
    end
    if not string.IsNilOrEmpty(self._Path) then
        self:Release()
    end
    self._Path = path
    self:Load()
end

--- 搁置
--------------------------
function XChessScene:Dispose()
    if not self:Exist() then
        return
    end
    self._GameObject:SetActiveEx(false)
    self:StopReleaseTimer()
    self._ReleaseTimer = XScheduleManager.ScheduleOnce(self._OnTryToReleaseCb, DelayReleaseTime)
end

function XChessScene:Release()
    self:TryDestroy()
    if self._Resource then
        self._Resource:Release()
    end
    self._Resource = nil
    self._GameObject = nil
    self._Transform  = nil
    self:StopReleaseTimer()
end

function XChessScene:Load()
    local resource = CS.XResourceManager.Load(self._Path)
    if not resource or not resource.Asset then
        XLog.Error("加载资源出错, 资源路径 = " .. self._Path)
        return
    end

    self._GameObject = XUiHelper.Instantiate(resource.Asset)
    self._Transform = self._GameObject.transform
    self._Resource = resource
    self:TryReset()

    if self._LoadCb then self._LoadCb() end
end

function XChessScene:Exist()
    return not XTool.UObjIsNil(self._GameObject)
end

function XChessScene:TryReset()
    if not self:Exist() then
        return
    end
    self._Transform.localPosition = CsVector3.zero
    self._Transform.localEulerAngles = CsVector3.zero
    self._Transform.localScale = CsVector3.one
end

function XChessScene:TryToRelease()
    if not self:Exist() then
        return
    end
    self:Release()
end

function XChessScene:TryDestroy()
    if not self:Exist() then
        return
    end
    XUiHelper.Destroy(self._GameObject)
end

function XChessScene:TryGetComponent(systemType)
    if not self:Exist() then
        return
    end
    return self._GameObject:GetComponent(typeof(systemType))
end

function XChessScene:TryFind(path)
    if not self:Exist() then
        return
    end
    return self._Transform:Find(path)
end

function XChessScene:StopReleaseTimer()
    if not self._ReleaseTimer then
        return
    end
    XScheduleManager.UnSchedule(self._ReleaseTimer)
    self._ReleaseTimer = nil
end

return XChessScene