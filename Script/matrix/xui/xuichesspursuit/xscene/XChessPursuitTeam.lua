local XChessPursuitModel = require("XUi/XUiChessPursuit/XScene/XChessPursuitModel")
local XChessPursuitTeam = XClass(XChessPursuitModel, "XChessPursuitTeam")
local XChessPursuitSceneManager = require("XUi/XUiChessPursuit/XScene/XChessPursuitSceneManager")

function XChessPursuitTeam:Ctor(cubeIndex, teamGridIndex, mapId)
    self.TeamGridIndex = teamGridIndex
    self.CubeIndex = cubeIndex
    self.MapId = mapId
end

function XChessPursuitTeam:LoadCaptainCharacter(captainCharacterId)
    if captainCharacterId == self.CaptainCharacterId then
        return
    end

    self:Dispose()
    self.CaptainCharacterId = captainCharacterId

    if self.CaptainCharacterId then
        local chessPursuitScene = XChessPursuitSceneManager.GetCurrentScene()
        local sceneGameObject = chessPursuitScene:GetSceneGameObject()
        local config = XDormConfig.GetCharacterStyleConfigById(self.CaptainCharacterId)
        local parent = sceneGameObject.transform:Find("Playmaker/Character")
        self.Resource = CS.XResourceManager.Load(config.Model)
    
        if not self.Resource.Asset then
            XLog.Error("XChessPursuitTeam LoadBoss error, instantiate error, name: " .. config.Model)
            return
        end

        self.GameObject = CS.UnityEngine.Object.Instantiate(self.Resource.Asset, parent)
        self.CSXChessPursuitModel = self.GameObject:AddComponent(typeof(CS.XChessPursuitTeam))
        self.Transform = self.GameObject.transform
        self.Transform.localScale = CS.UnityEngine.Vector3(1.3, 1.3, 1.3)
        
        local chessPursuitCubes = XChessPursuitCtrl.GetChessPursuitCubes()
        local cubeGo = chessPursuitCubes[self.CubeIndex].GameObject
        self.CSXChessPursuitModel:Init()
        self.CSXChessPursuitModel:SetPosition(cubeGo)
        self.CSXChessPursuitModel:SetXChessPursuitCtrl(XChessPursuitCtrl.GetCSXChessPursuitCtrlCom())
    end
end

function XChessPursuitTeam:Dispose()
    if self.GameObject then
        self.CSXChessPursuitModel:Dispose()
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
    end

    if self.Resource then
        CS.XResourceManager.Unload(self.Resource)
        self.Resource = nil
    end

    self.Func = nil
    self.GameObject = nil
    self.Transform = nil
    self.CSXChessPursuitModel = nil
    self.CaptainCharacterId = nil
end

function XChessPursuitTeam:GetCubeIndex()
    return self.CubeIndex
end

function XChessPursuitTeam:SetActive(active)
    if self.GameObject then
        self.GameObject:SetActiveEx(active)
    end
end

return XChessPursuitTeam