local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XChessPursuitModel = require("XUi/XUiChessPursuit/XScene/XChessPursuitModel")
local XChessPursuitBoss = XClass(XChessPursuitModel, "XChessPursuitBoss")

function XChessPursuitBoss:Ctor()
end

function XChessPursuitBoss:LoadBoss(id, parent, cb)
    if self.GameObject then
        return
    end

    local config = XChessPursuitConfig.GetChessPursuitBossTemplate(id)

    XLog.Error("[XResourceManager优化] 已经无法运行, 从XResourceManager改为loadPrefab")
    if not self.Resource.Asset then
        XLog.Error("XChessPursuitBoss LoadBoss error, instantiate error, name: " .. config.Perfab)
        return
    end

    self.GameObject = CS.UnityEngine.Object.Instantiate(self.Resource.Asset, parent)
    self.Transform = self.GameObject.transform
    self.CSXChessPursuitModel = self.GameObject:AddComponent(typeof(CS.XChessPursuitBoss))
    self.CSXChessPursuitModel:SetXChessPursuitCtrl(XChessPursuitCtrl.GetCSXChessPursuitCtrlCom())

    self.Collider = self.GameObject:GetComponent(typeof(CS.UnityEngine.Collider))
end

function XChessPursuitBoss:Dispose()
    if self.GameObject then
        self.CSXChessPursuitModel:Dispose()
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
        self.GameObject = nil
    end

    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end
    
    self.Func = nil
end

function XChessPursuitBoss:SetColliderActive(isActive)
    if self.Collider then
        self.Collider.enabled = isActive
    end
end

return XChessPursuitBoss