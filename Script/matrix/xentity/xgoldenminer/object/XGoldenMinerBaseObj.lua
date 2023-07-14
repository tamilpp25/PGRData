local XGoldenMinerBaseObj = XClass(nil, "XGoldenMinerBaseObj")

local MILLION_PERCENT = 1000000

--黄金矿工玩法对象
function XGoldenMinerBaseObj:Ctor(go, id, index, trigerCallback, resourceManagerLoadFunc)
    self.GameObject = go
    self.Transform = go.transform
    self:SetId(id)  --GoldenMinerStone表Id
    self.Index = index --对象在地图中的下标
    self.TrigerCallback = trigerCallback    --触发本对象回调
    self.ResourceManagerLoadFunc = resourceManagerLoadFunc  --加载预制的方法

    self.RectTransform = self.Transform:GetComponent("RectTransform")
    -- 监听触发
    self.GoInputHandler = self.Transform:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    self.GoInputHandler:AddTriggerEnter2DCallback(function(collider) self:OnTriggerEnter(collider) end)

    self.GameObject.name = id
end

function XGoldenMinerBaseObj:Init(mapId, rectSize, originParent)
    local index = self.Index
    local width = rectSize.x
    local height = rectSize.y
    local xPosPercent = XGoldenMinerConfigs.GetMapXPosPercent(mapId, index) / MILLION_PERCENT
    local yPosPercent = XGoldenMinerConfigs.GetMapYPosPercent(mapId, index) / MILLION_PERCENT
    local scale = XGoldenMinerConfigs.GetMapScale(mapId, index) / MILLION_PERCENT
    local rotationZ = XGoldenMinerConfigs.GetMapRotationZ(mapId, index) / MILLION_PERCENT
    self.Transform.localPosition = Vector3(xPosPercent * width, yPosPercent * height, 0)
    self.RectTransform.localEulerAngles = Vector3(0, 0, rotationZ)
    self.Transform.localScale = Vector3(scale, scale, scale)

    self.OriginParent = originParent
end

function XGoldenMinerBaseObj:OnTriggerEnter(collider)
    if XTool.UObjIsNil(collider.transform:GetComponent("Rigidbody2D")) then
        return
    end

    --触发对象不是钩爪
    local goldenMinerStoneId = tonumber(collider.gameObject.name)
    if XTool.IsNumberValid(goldenMinerStoneId) then
        local colliderHandler = collider.transform:GetComponent(typeof(CS.XGoInputHandler))
        local boomCollider = collider.transform:GetComponent("CircleCollider2D")    --炸弹的爆炸范围
        if not colliderHandler or not boomCollider or not colliderHandler.enabled or not boomCollider.enabled then
            return
        end

        local stoneType = XGoldenMinerConfigs.GetStoneType(goldenMinerStoneId)
        if stoneType == XGoldenMinerConfigs.StoneType.Boom and not XTool.UObjIsNil(self.GameObject) then
            self:DestroySelf(true)
        end
        return
    end

    self:SetGoInputHandlerActive(false)

    if self.TrigerCallback then
        self.TrigerCallback(self)
    end
end

function XGoldenMinerBaseObj:DestroySelf(isBoom)
    XUiHelper.Destroy(self.GameObject)
end

function XGoldenMinerBaseObj:IsTriggerCollider(collider)
    if XTool.UObjIsNil(collider.transform:GetComponent("Rigidbody2D")) then
        return false
    end

    local goldenMinerStoneId = tonumber(collider.gameObject.name)
    if XTool.IsNumberValid(goldenMinerStoneId) then
        local colliderHandler = collider.transform:GetComponent(typeof(CS.XGoInputHandler))
        local boomCollider = collider.transform:GetComponent("CircleCollider2D")    --炸弹的爆炸范围
        if not colliderHandler or not boomCollider or not colliderHandler.enabled or not boomCollider.enabled then
            return false
        end
    end

    return true
end

--把自身设置到钩爪节点中
function XGoldenMinerBaseObj:SetObjToTriggerParent(triggerObjs)
    if XTool.UObjIsNil(triggerObjs) or XTool.UObjIsNil(self.GameObject) then
        return
    end

    self.Transform:SetParent(triggerObjs.transform, false)
    self:EdgeTop()

    local effect = XGoldenMinerConfigs.GetStoneCatchEffect(self:GetId())
    if string.IsNilOrEmpty(effect) then
        return
    end
    self:LoadResource(self.Transform, effect)
end

--变成等重量的黄金
function XGoldenMinerBaseObj:ChangeToGold()
    local id = self:GetId()
    local weight = XGoldenMinerConfigs.GetStoneWeight(id)
    local goldId = XGoldenMinerConfigs.GetGoldIdByWeight(weight, id)
    if not goldId then
        return
    end

    local parent = self.Transform.parent
    local prefab = XGoldenMinerConfigs.GetStonePrefab(goldId)
    XUiHelper.Destroy(self.GameObject)
    local obj = self:LoadResource(parent, prefab)
    if obj then
        self.GameObject = obj
        self.Transform = obj.transform
    end

    self:EdgeTop()

    self:SetId(goldId)
end

--锚点设置到上中心
function XGoldenMinerBaseObj:EdgeTop()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    local rectTranform = self.Transform:GetComponent("RectTransform")
    rectTranform.anchorMin = Vector2(0.5, 1)
    rectTranform.anchorMax = Vector2(0.5, 1)
    rectTranform.pivot = Vector2(0.5, 1)
    self.Transform.localPosition = Vector3.zero
end

function XGoldenMinerBaseObj:LoadResource(parent, prefabPath, isCenter)
    if self.ResourceManagerLoadFunc then
        local resource = self.ResourceManagerLoadFunc(prefabPath)
        local obj = XUiHelper.Instantiate(resource.Asset, parent)
        if isCenter then
            local rectTranform = obj.transform:GetComponent("RectTransform")
            rectTranform:SetInsetAndSizeFromParentEdge(CS.UnityEngine.RectTransform.Edge.Top, 0, rectTranform.rect.height)
            rectTranform.anchorMin = Vector2(0.5, 0.5)
            rectTranform.anchorMax = Vector2(0.5, 0.5)
        end
        obj.transform.localPosition = Vector3.zero
        return obj
    end
end

function XGoldenMinerBaseObj:SetId(id)
    self.Id = id
end

function XGoldenMinerBaseObj:SetGoInputHandlerActive(isActive)
    if XTool.UObjIsNil(self.GoInputHandler) then
        return
    end
    self.GoInputHandler.enabled = isActive
end

function XGoldenMinerBaseObj:IsActiveGoInputHandler()
    if XTool.UObjIsNil(self.GoInputHandler) then
        return false
    end
    return self.GoInputHandler.enabled
end

function XGoldenMinerBaseObj:GetId()
    return self.Id
end

function XGoldenMinerBaseObj:GetIndex()
    return self.Index
end

function XGoldenMinerBaseObj:GetType()
    local id = self:GetId()
    return XGoldenMinerConfigs.GetStoneType(id)
end

function XGoldenMinerBaseObj:GetScore()
    local id = self:GetId()
    return XGoldenMinerConfigs.GetStoneScore(id)
end

function XGoldenMinerBaseObj:GetWeight()
    local id = self:GetId()
    return XGoldenMinerConfigs.GetStoneWeight(id)
end

return XGoldenMinerBaseObj