
---@class XChessScene 战棋场景
---@field _GameObject UnityEngine.GameObject
---@field _Transform UnityEngine.Transform
---@field _LoadCb function
---@field _ReleaseTimer boolean 准备释放
---@field _Path string 场景路径
---@field _Loader XLoaderUtil 加载器
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
    self._GameObject = nil
    self._Transform  = nil
    if self._Loader then
        self._Loader:UnloadAll()
    end
    self._Loader = nil
    self:StopReleaseTimer()
end

function XChessScene:Load()
    if string.IsNilOrEmpty(self._Path) then
        XLog.Error("场景路径为空!!!")
        return
    end
    local loader = self:GetLoader()
    local asset = loader:Load(self._Path)
    if not asset then
        XLog.Error("场景加载失败, Url = " .. self._Path)
        return
    end
    self._GameObject = XUiHelper.Instantiate(asset)
    self._Transform = self._GameObject.transform
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

function XChessScene:GetLoader()
    if self._Loader then
        return self._Loader
    end
    self._Loader = CS.XLoaderUtil.GetModuleLoader(ModuleId.XBlackRockChess)
    
    return self._Loader
end

return XChessScene