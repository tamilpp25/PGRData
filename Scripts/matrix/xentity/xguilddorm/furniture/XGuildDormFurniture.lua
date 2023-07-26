local XRLGuildDormFurniture = require("XEntity/XGuildDorm/Furniture/XRLGuildDormFurniture")
local XBaseSceneObj = require("XEntity/XGuildDorm/Base/XGuildDormBaseSceneObj")
local XFurnitureModel = require("XEntity/XGuildDorm/Furniture/XGuildDormFurnitureModel") 
local XGDComponentManager = require("XEntity/XGuildDorm/Base/XGDComponentManager")
---@class XGuildDormFurniture : XGuildDormBaseSceneObj
local XGuildDormFurniture = XClass(XBaseSceneObj, "XGuildDormFurniture")

--================
--获取默认家具表的Id(GuildDormDefaultFurniture)
--================
function XGuildDormFurniture:GetId()
    return self.Id
end
--================
--获取家具对应的房间
--================
function XGuildDormFurniture:GetRoom()
    local roomId = self.FurnitureModel and self.FurnitureModel.RoomId
    if not roomId then return nil end
    ---@type XGuildDormScene
    local currentScene = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene()
    return currentScene and currentScene:GetRoomById(roomId)
end
--================
--获取家具表Id(GuildDormFurniture)
--================
function XGuildDormFurniture:GetFurnitureId()
    return self.FurnitureModel and self.FurnitureModel.FurnitureId
end
--================
--获取家具名称
--================
function XGuildDormFurniture:GetName()
    return self.FurnitureModel and self.FurnitureModel.Name
end
--================
--获取家具交互信息列表
--================
function XGuildDormFurniture:GetInteractInfoList()
    return self.FurnitureModel and self.FurnitureModel:GetInteractInfoList()
end
--===================
-- 检测交互点是否能交互
--===================
function XGuildDormFurniture:CheckCanInteract()
    return self.FurnitureModel and self.FurnitureModel.InteractPos > 0
end
--===================
-- 获取家具特效组Id
--===================
function XGuildDormFurniture:GetEffectGroupId()
    return self.FurnitureModel and self.FurnitureModel.EffectGroupId
end
--===========
--构造函数
--@param id：默认家具表Id
--===========
function XGuildDormFurniture:Ctor(id)
    self.Id = id
    self.ServerData = nil
    -- 家具特效
    ---@type UnityEngine.GameObject[]
    self.FurnitureEffectList = {}
    -- 组件 XGDComponet
    self.GDComponentManager = XGDComponentManager.New()
    -- 表现数据
    ---@type XGuildDormFurnitureModel
    self.FurnitureModel = XFurnitureModel.New(self.Id)
    -- 配置表
    local cfg = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.DefaultFurniture, id)
    self.Config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.Furniture, cfg.FurnitureId)
    self.IsAllocatedReward = false
    self.ExtralSpecialUiArgs = {}
    if not string.IsNilOrEmpty(self.Config.RedPointCondition) then
        self:AddExtralSpecialUiArg({
            SpecialUiName = "PanelSummerGift",
            UiNameProxyPath = "XUi/XUiGuildDorm/XUiGuildDormRewardUi",
            SpecialUiNameHeightOffset = self.Config.RewardHeightOffset,
            Type = XGuildDormConfig.SpecialRewardUiType.RedPointReward
        })
    end
    -- 特效
    local effectGroupId = self:GetEffectGroupId()
    if XTool.IsNumberValid(effectGroupId) then
        -- 增加特效管理组件
        local XGDFurnitureEffectComponent = require("XEntity/XGuildDorm/Components/XGDFurnitureEffectComponent")
        self.GDComponentManager:AddComponent(XGDFurnitureEffectComponent.New(self))
    end
end

function XGuildDormFurniture:SetGameObject(go)
    self.FurnitureModel:SetGameObject(go)
    XDataCenter.GuildDormManager.SceneManager.AddSceneObj(self.FurnitureModel.GameObject, self)
end

function XGuildDormFurniture:LoadAsset(modelPath, root)
    self.FurnitureModel:LoadAsset(modelPath, root)
end

function XGuildDormFurniture:Update(dt)
    self.GDComponentManager:Update(dt)
end

function XGuildDormFurniture:UpdateWithServerData(data)
    self.ServerData = data
end

function XGuildDormFurniture:ResetNavmeshObstacle()
    self.FurnitureModel:ResetNavmeshObstacle()
end

function XGuildDormFurniture:Dispose()
    self.FurnitureModel:Dispose()
    self.GDComponentManager:Dispose()
    -- 隐藏特效
    for _, effectObj in pairs(self.FurnitureEffectList) do
        if effectObj and effectObj:Exist() then
            effectObj:SetActiveEx(false)
        end
    end
end

function XGuildDormFurniture:CheckIsShowName()
    return self.Config.IsShowName
end

function XGuildDormFurniture:CheckIsGetReward()
    return self.Config.IsGetReward
end

function XGuildDormFurniture:GetEntityId()
    return self.Id .. "_XGuildDormFurniture"
end

function XGuildDormFurniture:GetRLEntity()
    return self.FurnitureModel
end

function XGuildDormFurniture:GetNameHeightOffset()
    return self.Config.NameHeightOffset or 0
end

function XGuildDormFurniture:GetName()
    return self.Config.Name
end

function XGuildDormFurniture:GetTriangleType()
    return XGuildDormConfig.TriangleType.None
end

function XGuildDormFurniture:GetSpecialUiNames()
    local result = {}
    result = appendArray(result, self.Config.SpecialUiNames)
    for _, v in ipairs(self.ExtralSpecialUiArgs) do
        table.insert(result, v.SpecialUiName)
    end
    return result
    
end

function XGuildDormFurniture:GetUiNameProxyPath(index)
    if index > #self.Config.SpecialUiNames then
        return self.ExtralSpecialUiArgs[index - #self.Config.SpecialUiNames].UiNameProxyPath
    end
    return self.Config.UiNameProxyPaths[index]
end

function XGuildDormFurniture:GetSpecialUiNameHeightOffset(index)
    if index > #self.Config.SpecialUiNames then
        return self.ExtralSpecialUiArgs[index - #self.Config.SpecialUiNames].SpecialUiNameHeightOffset
    end
    return self.Config.SpecialUiNameHeightOffset[index]
end

function XGuildDormFurniture:CheckIsAllocatedReward()
    return self.IsAllocatedReward
end

function XGuildDormFurniture:SetIsAllocatedReward(value)
    self.IsAllocatedReward = value
    if value then
        self:AddExtralSpecialUiArg({
            SpecialUiName = "PanelSummerGift",
            UiNameProxyPath = nil,
            SpecialUiNameHeightOffset = self.Config.RewardHeightOffset,
            Type = XGuildDormConfig.SpecialRewardUiType.RandomReward
        })
    else
        for i = #self.ExtralSpecialUiArgs, 1, -1 do
            if self.ExtralSpecialUiArgs[i].Type == XGuildDormConfig.SpecialRewardUiType.RandomReward then
                table.remove(self.ExtralSpecialUiArgs, i)
            end
        end
    end
end
                                                                   
function XGuildDormFurniture:GetUiShowDistance()
    return self.Config.UiShowDistance or 0
end

--[[
    {
        SpecialUiName : string
        UiNameProxyPath : string
        SpecialUiNameHeightOffset : number
    }
]]
function XGuildDormFurniture:AddExtralSpecialUiArg(value)
    table.insert(self.ExtralSpecialUiArgs, value)
end

-- 播放特效
function XGuildDormFurniture:FurniturePlayEffect(effectId, localPosition, specialNode, specialNodeName)
    local transform = self.FurnitureModel:GetTransform()
    local effectObj = self.FurnitureEffectList[effectId] or nil
    if not effectObj then
        local furnitureEffectCfg = XGuildDormConfig.GetEffectCfgById(effectId)
        -- 创建一个特效节点
        effectObj = CS.UnityEngine.GameObject("Effect" .. effectId)
        effectObj.transform:SetParent(transform, false)
        effectObj.transform:LoadPrefab(furnitureEffectCfg.Path)
        self.FurnitureEffectList[effectId] = effectObj
    else
        effectObj:SetActiveEx(false)
    end
    -- 有特殊节点
    if specialNode then
        local parent = transform:FindTransform(specialNodeName)
        if parent and parent:Exist() then
            effectObj.transform:SetParent(parent, false)
        end
    end
    effectObj.transform.localPosition = localPosition
    effectObj:SetActiveEx(true)
end

-- 隐藏特效
function XGuildDormFurniture:FurnitureHideEffect(effectIds)
    for _, effectId in pairs(effectIds or {}) do
        local effectObj = self.FurnitureEffectList[effectId] or nil
        if effectObj and effectObj:Exist() then
            effectObj:SetActiveEx(false)
        end
    end
end

return XGuildDormFurniture
