--============
--公会宿舍场景实体基类
--============
local XGuildDormBaseSceneObj = XClass(nil, "XGuildDormBaseSceneObj")
--============
--将GameObject移动到root根节点
--============
local function BindToRoot(model, root)
    model.transform:SetParent(root)
    model.transform.localPosition = CS.UnityEngine.Vector3.zero
    model.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
    model.transform.localScale = CS.UnityEngine.Vector3.one
end

function XGuildDormBaseSceneObj:Ctor()
    
end
--============
--加载资源
--============
function XGuildDormBaseSceneObj:LoadAsset(modelPath, root)
    --异步加载资源
    self.Resource = CS.XResourceManager.LoadAsync(self.SceneAssetUrl)
    CS.XTool.WaitCoroutine(self.Resource, function()
            if not self.Resource.Asset then
                XLog.Error("XGuildDormScene LoadScene error, instantiate error, name: " .. self.SceneAssetUrl)
                return
            end
            self.GameObject = CS.UnityEngine.Object.Instantiate(self.Resource.Asset)
            self:SetGameObject(self.GameObject)
            if root then
                BindToRoot(self.GameObject, root)
            end
        end)
end
--============
--为实体设置场景GameObject
--============
function XGuildDormBaseSceneObj:SetGameObject(go)
    self.GameObject = go
    self.Transform = go.transform
    XDataCenter.GuildDormManager.SceneManager.AddSceneObj(self.GameObject, self)
    self:OnLoadComplete()
end
--============
--当GameObject设置好后回调
--虚方法
--============
function XGuildDormBaseSceneObj:OnLoadComplete()
    
end
return XGuildDormBaseSceneObj