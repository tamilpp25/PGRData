XSceneResourceManager = XSceneResourceManager or {}

local ScenePoolRoot = nil
local ResourceMap = nil
---@type XLoaderUtil
local Loader

local LoadCount = 2

-- 初始化
function XSceneResourceManager.InitPool()
    XLog.Error("废弃方法，请联系牟文删除！")
    --if XTool.UObjIsNil(ScenePoolRoot) then
    --    ScenePoolRoot = CS.UnityEngine.GameObject("ScenePoolRoot")
    --    ScenePoolRoot:SetActive(false)
    --    CS.UnityEngine.Object.DontDestroyOnLoad(ScenePoolRoot)
    --end
    --
    --XSceneResourceManager.ClearPool()
    --ResourceMap = {}
end

-- 出池
function XSceneResourceManager.GetGoFromPool(path)
    XLog.Error("废弃方法，请联系牟文删除！")
    --if not ResourceMap then
    --    ResourceMap = {}
    --end
    --
    --local temp = ResourceMap[path]
    --if not temp then
    --    temp = {}
    --    temp.Gos = {}
    --    ResourceMap[path] = temp
    --end
    --
    --if not temp.Resource then
    --    temp.Resource = CS.XResourceManager.Load(path)
    --end
    --
    --local go
    --
    --while (#temp.Gos > 0) do
    --    go = table.remove(temp.Gos, #temp.Gos)
    --    if not XTool.UObjIsNil(go) then
    --        go:SetActive(true)
    --        break
    --    end
    --end
    --
    --if XTool.UObjIsNil(go) then
    --    go = CS.UnityEngine.Object.Instantiate(temp.Resource.Asset)
    --end
    --
    --return go
end

-- 回池
function XSceneResourceManager.ReturnGoToPool(path, go)
    XLog.Error("废弃方法，请联系牟文删除！")
    --if XTool.UObjIsNil(go) then
    --    return
    --end
    --
    --if not ResourceMap then
    --    ResourceMap = {}
    --end
    --
    --local temp = ResourceMap[path]
    --if not temp then
    --    temp = {}
    --    temp.Gos = {}
    --    ResourceMap[path] = temp
    --end
    --
    --if not temp.Resource then
    --    CS.UnityEngine.GameObject.Destroy(go)
    --    return
    --end
    --
    --go.transform:SetParent(ScenePoolRoot.transform, false)
    --table.insert(temp.Gos, go)
end

-- 清池
function XSceneResourceManager.ClearPool()
    XLog.Error("废弃方法，请联系牟文删除！")
    --if ResourceMap then
    --    for _, v in pairs(ResourceMap) do
    --        -- 销毁GameObject
    --        if v.Gos then
    --            for _, go in ipairs(v.Gos) do
    --                if not XTool.UObjIsNil(go) then
    --                    CS.UnityEngine.GameObject.Destroy(go)
    --                end
    --            end
    --        end
    --        v.Gos = nil
    --
    --        -- 释放资源
    --        if v.Resource then
    --            v.Resource:Release()
    --        end
    --    end
    --end
    --
    --ResourceMap = nil
end

---@return XLoaderUtil
function XSceneResourceManager.GetLoader()
    if XTool.UObjIsNil(Loader) then
        Loader = CS.XLoaderUtil.GetModuleLoader("HomeDormResManager")
    end
    return Loader
end

function XSceneResourceManager.Unload(url)
    if string.IsNilOrEmpty(url) then
        return
    end
    
    local loader = XSceneResourceManager.GetLoader()
    loader:Unload(url)
    if loader:GetResCount() == 0 then
        CS.XLoaderUtil.ClearModuleLoader("HomeDormResManager")
        Loader = nil
    end
end

function XSceneResourceManager.UnloadAll()
    local loader = XSceneResourceManager.GetLoader()
    loader:UnloadAll()
end

function XSceneResourceManager.LoadSync(url)
    if string.IsNilOrEmpty(url) then
        return
    end
    
    local loader = XSceneResourceManager.GetLoader()
    return loader:Load(url)
end

function XSceneResourceManager.LoadAsync(url, func)
    local loader = XSceneResourceManager.GetLoader()
    loader:LoadAsync(url, func)
end