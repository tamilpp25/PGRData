
local XHomeCharObj = require("XHome/XDorm/XHomeCharObj")

---@class XHomePetObj : XHomeCharObj 宠物
---@field Agent BehaviorTree.XAgent
---@field Id number
---@field BindFurniture XHomeFurnitureObj
---@field IsSelf boolean 是否为自己的房间
local XHomePetObj = XClass(XHomeCharObj, "XHomePetObj")

function XHomePetObj:SetData(data, bindFurniture, isSelf)
    self.Data = data
    self.Id = self.Data.Id
    self.BindFurniture = bindFurniture
    self.IsSelf = isSelf
    self.BindFurnitureId = self.BindFurniture.Data.Id
end

function XHomePetObj:ExitRoom()
    self:DisInteractFurniture()
    self:DisPreInteractFurniture()
    self.InteractInfoList = nil
    self.Status = nil
    XHomeCharManager.RecycleHomePet(self.BindFurnitureId, self.Data.Id, self)
end

function XHomePetObj:Recycle()
    self.InteractInfoList = nil
    self.Status = nil
    XHomeCharManager.RecycleHomePet(self.BindFurnitureId, self.Data.Id, self)
end

--- 设置宠物出生
---@param map
---@param room XHomeRoomObj
--------------------------
function XHomePetObj:Born(map, room)
    self.Map = map
    self.Room = room
    self:SetBornPosition()
    self:ChangeStatus(XHomeBehaviorStatus.BORN)
    self:ChangeStateMachine(XHomeCharFSMType.IDLE)

    self.GameObject:SetActiveEx(not room:CheckIsInReform())
end

function XHomePetObj:OnLoadComplete()
    self.Agent = self.GameObject:GetComponent(typeof(CS.BehaviorTree.XAgent))
    if not self.Agent then
        self.Agent = self.GameObject:AddComponent(typeof(CS.BehaviorTree.XAgent))
        self.Agent.ProxyType = "HomePet"
        self.Agent:InitProxy()
    end
    self.Agent.Proxy.LuaAgentProxy:SetHomePetObj(self)
    
    self.RenderingUIProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(self.GameObject)
    self.Animator = self.GameObject:GetComponent(typeof(CS.UnityEngine.Animator))
    self.Animator.applyRootMotion = true
    --寻路
    self.NavMeshAgent = CS.XNavMeshUtility.AddMoveAgent(self.GameObject)
    self.NavMeshAgent.Radius = 0.6
    self.NavMeshAgent.IsObstacle = true
    self.NavMeshAgent:AddNotifyCollide(function(obj) 
        self:OnCollideAgent(obj)
    end)
    --层级
    self.GameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer(HomeSceneLayerMask.Device))
    --阴影
    CS.XMaterialContainerHelper.ProcessCharacterShadowVolume(self.GameObject)
end

function XHomePetObj:ChangeStatus(state)
    if self.Status == state and self.Status ~= XHomeBehaviorStatus.IDLE then
        return
    end

    if self.Status == XHomeBehaviorStatus.BORN and state ~= XHomeBehaviorStatus.IDLE then
        return
    end 
    
    --隐藏特效
    self:HideEffect()
    --隐藏气泡
    self:HideBubble()
    
    self.Status = state
    local temp = XDormConfig.GetDormPetBehaviour(self.Data.Id, state)
    if not temp then
        XLog.Error("获取宠物行为树失败，宠物id=".. tostring(self.Data.Id) .. ", 状态=" .. tostring(state))
        return
    end
    local behaviorId = temp.BehaviorId
    self.CanClick = temp.CanClick == 1
    --切换状态机
    self:ChangeStateMachine(temp.StateMachine)
    
    XLuaBehaviorManager.PlayId(behaviorId, self.Agent)
end

--到达家具交互
function XHomePetObj:ReachFurniture()
    if self.Furniture == nil then
        self:ChangeStatus(XHomeBehaviorStatus.IDLE)
        return false
    end
    for _, v in ipairs(self.Furniture.InteractInfoList) do
        local state = self:GetInteractInfoBehavior(v)
        if XDormConfig.GetDormPetBehaviour(self.Id, state) then
            self:ChangeStatus(state)
            return true
        end
    end
    return false
end

function XHomePetObj:SetBornPosition()
    local bornPoint = self.BindFurniture.GameObject:FindGameObject("BornPoint") or self.GameObject
    self.Transform.rotation = CS.UnityEngine.Quaternion.LookRotation(bornPoint.transform.forward)
    self.Transform.position = bornPoint.transform.position
    local pos = XHomeDormManager.WorldPosToGroundGridPos(bornPoint.transform.position, self.Room.Transform)
    self.Pos = {
        x = pos.x,
        y = pos.y,
    }
end

function XHomePetObj:GetRandomSeed()
    if XTool.IsNumberValid(self.BindFurnitureId) then
        return os.time() + self.BindFurnitureId
    end
    return os.time() + self.Id
end

--检测附近的人物交互
function XHomePetObj:CheckCharacterInteracter()
    local result = XHomeCharManager.CheckPetCharacterInteracter(self.BindFurniture.Data.Id, self.Id)
    return result
end

function XHomePetObj:CheckFurnitureInteract()
    local result, dest, interact = XHomeCharManager.CheckPetFurnitureInteract(self.BindFurniture.Data.Id, self.Data.Id)
    if not result then
        return false
    end
    
    self.Agent:SetVarDicByKey("Destination", dest)
    self.Furniture = interact.Furniture
    self.InteractInfo = interact

    for _, v in ipairs(self.Furniture.InteractInfoList) do
        if v.GridPos.x == self.InteractInfo.GridPos.x and v.GridPos.y == self.InteractInfo.GridPos.y then
            local haveBehavior = false
            local relation = XDormConfig.GetDormF2CBehaviorRelative(self.Furniture.Cfg.Id, self.Data.Id, v.PosIndex)
            if relation then
                haveBehavior = true
            else
                local state = XDormConfig.GetDormPetBehaviour(self.Data.Id, v.AttractBehaviorType)
                haveBehavior = state ~= nil
            end

            if haveBehavior then
                local state = self:GetInteractInfoAttractBehavior(v)
                v.UsedType = v.UsedType | XFurnitureInteractUsedType.Character
                v.CharacterId = self.Data.Id
                self:ChangeStatus(state)
            end
            break
        end
    end
    
    return result
end

function XHomePetObj:GetAvailableInteract(characterId)
    local infoList = self:GetInteractInfoList()
    for _, info in ipairs(infoList) do
        local relation  = XDormConfig.GetDormF2CBehaviorRelative(self.BindFurniture.Cfg.Id, characterId, info.PosIndex)
        if relation then return info end

        if info.UsedType == XFurnitureInteractUsedType.None or info.UsedType == XFurnitureInteractUsedType.Block then
            if info.StayType and info.StayType ~= XFurnitureInteractUsedType.Block
                    and XDormConfig.GetCharacterBehavior(characterId, info.BehaviorType) then
                return info
            end
        end
    end
    return nil
end

function XHomePetObj:GenerateInteractInfo()
    self.InteractInfoList = {}
    local template = XDormConfig.GetDormPetTemplate(self.Data.Id)
    local sumIndex = template.InteractPos or 0
    for i = 1, sumIndex do
        local stayPoint = self.GameObject:FindGameObject("StayPos" .. tostring(i)) or self.GameObject
        local interactPoint = self.GameObject:FindGameObject("Interactpos" .. tostring(i)) or self.GameObject
        local ignorePoint = self.GameObject:FindGameObject("IgnoreBlock" .. tostring(i)) or self.GameObject

        if interactPoint == nil then
            if XMain.IsEditorDebug then
                XLog.Error(string.format("宠物配置了%s号交互点，宠物预制%s不存在", i, self.GameObject.name))
            end
            break
        end

        local info = {
            Index = i,
            GridPos = CS.UnityEngine.Vector2Int.zero,
            UsedType = XFurnitureInteractUsedType.None,
            StayType = XFurnitureInteractUsedType.None,
            StayPos = stayPoint,
            InteractPos = interactPoint,
            PosIndex = i,
            BehaviorType = template.BehaviorType[i] or template.BehaviorType[1],
            AttractBehaviorType = template.AttractBehaviorType[i] or template.AttractBehaviorType[1]
        }
        
        table.insert(self.InteractInfoList, info)
    end
end

function XHomePetObj:GetInteractInfoList()
    if XTool.IsTableEmpty(self.InteractInfoList) then
        self:GenerateInteractInfo()
    end
    return self.InteractInfoList
end

function XHomePetObj:RayCastSelected(isSelect)
    if self.IsShowGlow == isSelect then
        return
    end

    if self.IsShowRedGlow then
        self:RayCastNotOwn(false)
    end

    if isSelect then
        CS.XMaterialContainerHelper.AddRoomRim(self.GameObject)
    else
        CS.XMaterialContainerHelper.RemoveRoomRim(self.GameObject)
    end

    self.IsShowGlow = isSelect
end

-- 获取最近家具交互点信息
function XHomePetObj:GetNearAvailableInteract(position, characterId)
    local interactInfo = nil
    local lastDistance = 0

    local list = self:GetInteractInfoList()
    for _, info in ipairs(list) do
        local haveBehavior = false
       
        if info.UsedType == XFurnitureInteractUsedType.None or info.UsedType == XFurnitureInteractUsedType.Block and
                XDormConfig.GetCharacterBehavior(characterId, info.AttractBehaviorType) then
            haveBehavior = true
        end
        
        if haveBehavior then
            local distance = Vector3.Distance(position, info.StayPos.transform.position)
            if lastDistance <= 0 or distance < lastDistance then
                interactInfo = info
                lastDistance = distance
            end
        end
    end

    return interactInfo
end

function XHomePetObj:GetConfigId()
    return self.BindFurniture.Cfg.Id
end

function XHomePetObj:GetBindFurnitureId()
    return self.BindFurnitureId
end

-- 通过构造体ID获取交互中的家具交互点信息
function XHomePetObj:GetInteractById(characterId)
    local list = self:GetInteractInfoList()
    if not list then
        return nil
    end

    for _, v in ipairs(list) do
        if (v.UsedType & XFurnitureInteractUsedType.Character) > 0 and characterId == v.CharacterId then
            return v
        end
    end

    return nil
end

function XHomePetObj:GetInteract(gridX, gridY)
    local list = self:GetInteractInfoList()
    for _, info in ipairs(list) do
        if info.GridPos.x == gridX and info.GridPos.y == gridY then
            return info
        end
    end

    return nil
end

--- 角色状态改变时
---@param state string
---@param charObj XHomeCharObj
--------------------------
function XHomePetObj:OnCharacterStateChange(state, charObj)
    if XDormConfig.IsPetPlayWithChar(self.Id, state) then
        self:ChangeStatus(XHomeBehaviorStatus.PLAY_WITH_CHAR)
        local newId = XHomeCharManager.CreateNewIdWithCharAndFurniture(charObj:GetCharacterId(), self.BindFurnitureId)
        XHomeCharManager.SetFurnitureInteractTime(newId)
    elseif state == XHomeBehaviorStatus.GRAB_UP and self.Status == XHomeBehaviorStatus.PLAY_WITH_CHAR then --抓起处于交互的角色时
        self:ChangeStatus(XHomeBehaviorStatus.IDLE)
    end
end

function XHomePetObj:GetObjType()
    return XHomeSceneObjType.Pet
end

function XHomePetObj:OnCollideAgent(obj)
    if not obj then
        return
    end

    ---@type XSceneObject
    local sceneObj = XSceneEntityManager.GetEntity(obj.gameObject)
    if not sceneObj or not sceneObj.GetObjType or sceneObj:GetObjType() ~= XHomeSceneObjType.Character then
        return
    end
    --local info = self:GetAvailableInteract(sceneObj.Id)
    --if not info then
    --    return
    --end
    sceneObj:DoCollidePet(self)
end


--取消家具预关联
function XHomePetObj:DisPreInteractFurniture()
    if self.PreInteractFurniture == nil then
        return false
    end

    if self.BindFurniture == nil then
        return false
    end

    for _, v in ipairs(self.PreInteractFurniture.InteractInfoList) do
        if v.CharacterId == self.Id and (v.UsedType & XFurnitureInteractUsedType.Character) > 0 then
            XHomeCharManager.SetFurnitureInteractTime(self.BindFurnitureId)
            v.UsedType = v.UsedType - XFurnitureInteractUsedType.Character
            v.CharacterId = nil
            break
        end
    end
    
    return true
end

--取消家具关联
function XHomePetObj:DisInteractFurniture()
    if self.Furniture == nil then
        return false
    end

    if self.BindFurniture == nil then
        return false
    end

    for _, v in ipairs(self.Furniture.InteractInfoList) do
        if v.CharacterId == self.Id and (v.UsedType & XFurnitureInteractUsedType.Character) > 0 then
            XHomeCharManager.SetFurnitureInteractTime(self.BindFurnitureId)
            v.UsedType = v.UsedType - XFurnitureInteractUsedType.Character
            v.CharacterId = nil
            break
        end
    end

    self.Furniture = nil
    self.InteractInfo = nil
    return true
end

-- 播放特效
function XHomePetObj:DoEffectNode(effectId)
    return self:PlayFurnitureEffect(effectId)
end

--交互家具面向方向调整
function XHomePetObj:SetForwardToFurniture(forward)
    local furniture = self.Furniture
    local info = self.InteractInfo
    if not furniture or not info then
        return false
    end

    local interact = furniture:GetInteract(info.GridPos.x, info.GridPos.y)
    if not interact then
        return false
    end
    local point = interact.PetInteractPoint or interact.InteractPos
    if XTool.UObjIsNil(point) then
        XLog.Warning("交互点异常", info.GridPos.x, info.GridPos.y)
        return
    end
    local eulerAngle = point.transform.eulerAngles

    if forward < 0 then
        eulerAngle = eulerAngle + CS.UnityEngine.Vector3(0, 180, 0)
    end
    self.Agent:SetVarDicByKey("TurnTo", eulerAngle)
    return true
end

--显示气泡
function XHomePetObj:ShowBubble(id, callBack)
    XEventManager.DispatchEvent(XEventId.EVENT_HOME_OBJ_SHOW_DIALOG_BOX, self.BindFurnitureId, id, self.Transform, function()
        if callBack then
            callBack()
        end
    end, true)
end

--显示气泡
function XHomePetObj:ShowRandomBubble(callBack)
    XLog.Error("宠物暂未实现随机播放")
end

--隐藏气泡
function XHomePetObj:HideBubble()
    XEventManager.DispatchEvent(XEventId.EVENT_HOME_OBJ_HIDE_DIALOG_BOX, self.BindFurnitureId)
end

--播放特效
function XHomePetObj:PlayEffect(effectId, bindWorldPos)
    XEventManager.DispatchEvent(XEventId.EVENT_HOME_OBJ_SHOW_3DUI_OBJ, self.BindFurnitureId, effectId, self.Transform, 
            bindWorldPos, self.RenderingUIProxy, self.HeadPos, true)
end

--隐藏特效
function XHomePetObj:HideEffect()
    XEventManager.DispatchEvent(XEventId.EVENT_HOME_OBJ_HIDE_3DUI_OBJ, self.BindFurnitureId)
end

return XHomePetObj