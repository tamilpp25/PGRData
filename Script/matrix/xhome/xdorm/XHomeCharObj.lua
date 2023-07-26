
local XSceneObject = require("XHome/XSceneObject")

---@class XHomeCharObj : XSceneObject 角色对象
---@field CharData XClientDormCharacter 服务器数据
---@field Room XHomeRoomObj 服务器数据
local XHomeCharObj = XClass(XSceneObject, "XHomeCharObj")

--设置数据
function XHomeCharObj:SetData(data, isSelf)
    self.CharData = data
    self.IsSelf = isSelf
    self.Id = data.CharacterId
    self.CeilSize = XHomeDormManager.GetCeilSize()

end

--进入房间设置出生点
function XHomeCharObj:Born(map, room)
    self.Map = map
    self.Room = room

    self:ReSetPosition()
    self.Agent:SetVarDicByKey("DormitoryId", self.CharData.DormitoryId)

    self.NavMeshAgent.IsObstacle = true
    self:ChangeStatus(XHomeBehaviorStatus.IDLE)

    self:ChangeStateMachine(XHomeCharFSMType.IDLE)

    self.GameObject:SetActive(true)
    self.Visible = true
end

--事件改变
function XHomeCharObj:OnEventChange(event)
    if XHomeBehaviorStatus.IDLE ~= self.Status then
        return
    end

    self:ChangeStatus(event.BehaviorId)
end

--退出房间
function XHomeCharObj:ExitRoom()
    self:DisInteractFurniture()
    self:DisPreInteractFurniture()
    XHomeCharManager.DespawnHomeCharacter(self.Id, self)
end

function XHomeCharObj:Recycle()
    XHomeCharManager.DespawnHomeCharacter(self.CharData.CharacterId, self)
end

--加载完成
function XHomeCharObj:OnLoadComplete()
    --行为代理
    self.Agent = self.GameObject:GetComponent(typeof(CS.BehaviorTree.XAgent))
    if XTool.UObjIsNil(self.Agent) then
        self.Agent = self.GameObject:AddComponent(typeof(CS.BehaviorTree.XAgent))
        self.Agent.ProxyType = "HomeCharacter"
        self.Agent:InitProxy()
    end

    self.Agent.Proxy.LuaAgentProxy:SetHomeCharObj(self)
    self.RenderingUIProxy = CS.XNPCRendingUIProxy.GetNPCRendingUIProxy(self.GameObject)
    self.HeadPos = self.Transform:Find("Bip001/Bip001Pelvis/Bip001Spine/Bip001Spine1/Bip001Neck/Bip001Head")

    self.Animator = self.GameObject:GetComponent(typeof(CS.UnityEngine.Animator))
    self.DormPutOnAnimaTime = CS.XGame.ClientConfig:GetFloat("DormPutOnAnimaTime")
    self.IsPressing = false
    self.FondleType = 0


    --寻路组件
    -- self.NavMeshAgent = CS.XNavMeshUtility.AddNavMeshAgent(self.GameObject)
    -- self.NavMeshAgent.radius = 0.35
    self.NavMeshAgent = CS.XNavMeshUtility.AddMoveAgent(self.GameObject)
    self.NavMeshAgent.Radius = 0.35
    self.NavMeshAgent.IsObstacle = true
    self.GoInputHandler = self.GameObject:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end

    --层级
    self.GameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer(HomeSceneLayerMask.HomeCharacter))
    --阴影
    CS.XMaterialContainerHelper.ProcessCharacterShadowVolume(self.GameObject)

    if not XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler:AddPointerClickListener(function(eventData) self:OnClick(eventData) end)
        self.GoInputHandler:AddDragListener(function(eventData) self:OnDrag(eventData) end)
        self.GoInputHandler:AddPointerDownListener(function(eventData) self:OnPointerDown(eventData) end)
        self.GoInputHandler:AddPressListener(function(pressTime) self:OnPress(pressTime) end)
        self.GoInputHandler:AddPointerUpListener(function(eventData) self:OnPointerUp(eventData) end)
        self.GoInputHandler:AddPointerExitListener(function(eventData) self:OnPointerExit(eventData) end)
    end
end

-----------------------------------------------------------
--获取属性
function XHomeCharObj:GetAtrributeValue(attributeKey)
    return self.CharData[attributeKey]
end

--播放动作
function XHomeCharObj:DoAction(actionId, needFadeCross, crossDuration)

    if (needFadeCross) then
        self.Animator:CrossFade(actionId, crossDuration, -1, 0)
    else
        self.Animator:Play(actionId, -1, 0)
    end
end

--显示气泡
function XHomeCharObj:ShowBubble(id, callBack)
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SHOW_DIALOBOX, self.Id, id, self.Transform, function()
        if callBack then
            callBack()
        end
    end)
end

--显示气泡
function XHomeCharObj:ShowRandomBubble(callBack)
    local config = XDormConfig.GetCharacterDialog(self.CharData, self.Status)

    if not config then
        if callBack then
            callBack()
        end

        return
    end

    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SHOW_DIALOBOX, self.Id, config.Id, self.Transform, function()
        if callBack then
            callBack()
        end
    end)
end

--隐藏气泡
function XHomeCharObj:HideBubble()
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_HIDE_DIALOBOX, self.Id)
end

--随机寻路
function XHomeCharObj:DoPathFind(minDistance, maxDistance)
    local findPath = false
    local x = self.Pos.x
    local y = self.Pos.y
    local distance

    self.Pos = XHomeDormManager.WorldPosToGroundGridPos(self.Transform.position, self.Room.Transform)
    local findCount = 0
    while (not findPath) do
        math.randomseed(os.time())
        distance = math.random(minDistance, maxDistance)
        local vec = CS.UnityEngine.Random.insideUnitCircle
        x = math.floor(0.5 + distance * vec.x + self.Pos.x)
        y = math.floor(0.5 + distance * vec.y + self.Pos.y)

        if x > 1 and x < CS.XHomeMapManager.Inst.MapSize.x - 2 and y > 1 and y < CS.XHomeMapManager.Inst.MapSize.y - 2 then
            local gridInfo = self.Map:GetGridInfo(x, y)
            --local gridMask = CS.XRoomMapInfo.GetMapGridMask(gridInfo, CS.XRoomBlockType.Blocked, CS.XRoomBlockType.Furniture, CS.XRoomBlockType.Interaction)
            if gridInfo <= 0 then
                findPath = true
            end
        end
        findCount = findCount + 1
        if findCount >= 10000 then return self.Agent:SetVarDicByKey("Destination", XHomeDormManager.GetLocalPosByGrid(self.Pos.x, self.Pos.y, CS.XHomePlatType.Ground, 0)) end
    end

    self.Pos.x = x
    self.Pos.y = y

    local pos = XHomeDormManager.GetLocalPosByGrid(x, y, CS.XHomePlatType.Ground, 0)
    pos = self.Room.Transform.localToWorldMatrix:MultiplyPoint(pos)
    self.Agent:SetVarDicByKey("Destination", pos)
end

--改变状态机
function XHomeCharObj:ChangeStateMachine(stateM)
    if self.StateMachine and self.StateMachine.name == stateM then
        return
    end

    if self.StateMachine then
        self.StateMachine:Exit()
    end

    self.StateMachine = XHomeCharFSMFactory.New(stateM, self)
    self.StateMachine:Enter()

    self.StateMachine:Execute()
end

--改变状态
function XHomeCharObj:ChangeStatus(state)
    if self.Status == state and self.Status ~= XHomeBehaviorStatus.IDLE then
        return
    end

    self.FondleTypeList = {}

    --隐藏特效
    self:HideEffect()
    --隐藏气泡
    self:HideBubble()

    --检测事件
    local event = XHomeCharManager.GetCharacterEvent(self.CharData.CharacterId, self.IsSelf)
    if event and XHomeBehaviorStatus.IDLE == state then
        state = event.BehaviorId
    end

    self.Status = state
    local temp = XDormConfig.GetCharacterBehavior(self.Id, state)
    if not temp then
        XLog.Error("获取角色行为树失败，角色id=".. tostring(self.Id) .. ", state=" .. tostring(state))
        return
    end
    local behaviorTreeId = temp.BehaviorId
    self.CanClick = temp.CanClick == 1
    --切换状态机
    self:ChangeStateMachine(temp.StateMachine)

    XLuaBehaviorManager.PlayId(behaviorTreeId, self.Agent)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_HOME_CHARACTER_STATUS_CHANGE, self.Id)
end

--播放特效
function XHomeCharObj:PlayEffect(effectId, bindWorldPos)
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_SHOW_3DIOBJ, self.Id, effectId, self.Transform, bindWorldPos, self.RenderingUIProxy, self.HeadPos)
end

function XHomeCharObj:PlayFurnitureEffect(effectId)
    if self.Furniture ~= nil then
        self.Furniture:DoEffectNode(effectId)
    end
    return true
end

--隐藏特效
function XHomeCharObj:HideEffect()
    XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_HIDE_3DIOBJ, self.Id)
end

--设置是否阻挡
function XHomeCharObj:SetObstackeEnable(obstackeEnable)
    self.NavMeshAgent.IsObstacle = obstackeEnable
end

--播放事件奖励
function XHomeCharObj:ShowEventReward()
    XHomeCharManager.ShowEventReward(self.Id)
end

--获取状态
function XHomeCharObj:GetState()
    return self.Status
end

--检测附近的人物交互
function XHomeCharObj:CheckCharacterInteracter()
    local result = XHomeCharManager.CheckCharacterInteracter(self.Id)
    return result
end

--检测附近的家具交互点
function XHomeCharObj:CheckFurnitureInteract()
    local result, dest, interact = XHomeCharManager.CheckFurnitureInteract(self.Id)
    if result then
        self.Agent:SetVarDicByKey("Destination", dest)
        self.Furniture = interact.Furniture
        self.InteractInfo = interact

        for _, v in ipairs(self.Furniture.InteractInfoList) do
            if v.GridPos.x == self.InteractInfo.GridPos.x and v.GridPos.y == self.InteractInfo.GridPos.y then
                local haveBehavior = false
                local relation = XDormConfig.GetDormF2CBehaviorRelative(self.Furniture.Cfg.Id, self.Id, v.PosIndex)
                if relation then
                    haveBehavior = true
                else
                    local state = XDormConfig.GetCharacterBehavior(self.Id, v.AttractBehaviorType)
                    haveBehavior = state ~= nil
                end
                if haveBehavior then
                    local state = self:GetInteractInfoAttractBehavior(v)
                    v.UsedType = v.UsedType | XFurnitureInteractUsedType.Character
                    v.CharacterId = self.Id
                    self:ChangeStatus(state)
                end
                break
            end
        end
    end

    return result
end

--检测任务完成
function XHomeCharObj:CheckEventCompleted(completeType, callBack)
    local temp = XHomeCharManager.CheckCharacterEventCompleted(self.Id, completeType, self.IsSelf)
    if not temp then
        return false
    end

    XDataCenter.DormManager.RequestDormitoryCharacterOperate(self.Id, self.CharData.DormitoryId, temp.EventId, 1, callBack)
    return true
end

--检测任务存在
function XHomeCharObj:CheckEventExist(eventId)
    return XHomeCharManager.CheckCharacterEventExist(self.Id, eventId, self.IsSelf)
end

--检测是否正在播放指定动画
function XHomeCharObj:CheckIsPlayingAnimation(animationName)
    if not animationName or #animationName <= 0 then
        return false
    end

    local curStateInfo = self.Animator:GetCurrentAnimatorStateInfo(0)
    local nextStateInfo = self.Animator:GetNextAnimatorStateInfo(0)

    for _, v in ipairs(animationName) do
        local newHash = CS.UnityEngine.Animator.StringToHash(v)

        if (curStateInfo.shortNameHash == newHash or nextStateInfo.shortNameHash == newHash) then
            return true
        end
    end

    return false
end

--侧身摄像机
function XHomeCharObj:SidewaysSceneCamera()
    local currentCamera = XHomeSceneManager.GetSceneCamera()
    local direction = currentCamera.transform.position - self.Transform.position
    local Direct = CS.UnityEngine.Vector3(direction.z, 0, -direction.x);
    self.Transform.rotation = CS.UnityEngine.Quaternion.LookRotation(Direct, CS.UnityEngine.Vector3.up);
end

--面向摄像机
function XHomeCharObj:FaceToSceneCamera()
    local currentCamera = XHomeSceneManager.GetSceneCamera()
    local direction = currentCamera.transform.position - self.Transform.position
    local Direct = CS.UnityEngine.Vector3(direction.x, 0, direction.z);
    self.Transform.rotation = CS.UnityEngine.Quaternion.LookRotation(Direct, CS.UnityEngine.Vector3.up);
end

function XHomeCharObj:Dispose()

    if not XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler:RemoveAllListeners()
    end
    self.GoInputHandler = nil

    self:HideBubble()
    self:HideEffect()

    XHomeCharObj.Super.Dispose(self)
end

function XHomeCharObj:OnDrag(eventData)
    if not self.IsSelf then
        return
    end

    if self.Status ~= XHomeBehaviorStatus.GRAB_UP then
        return
    end

    -- 托起
    local currentCamera = XHomeSceneManager.GetSceneCamera()
    local direction = self.Transform.position - currentCamera.transform.position
    local z = CS.UnityEngine.Vector3.Dot(direction, currentCamera.transform.forward);
    local screenPos = CS.UnityEngine.Vector3(eventData.position.x, eventData.position.y, z)
    local pos = currentCamera:ScreenToWorldPoint(screenPos)
    local gridPos = XHomeDormManager.WorldPosToGroundGridPos(pos, self.Room.Transform)
    --判断拖拽越界
    if gridPos.x <= 0 or gridPos.y <= 0 or gridPos.x >= XHomeDormManager.GetMapWidth() - 1 or gridPos.y >= XHomeDormManager.GetMapHeight() - 1 then
        return
    end

    self.Transform.position = CS.UnityEngine.Vector3(pos.x, self.OrignalPosition.y + 0.5, pos.z)

    --判断射线碰到家私
    local layerMask = CS.UnityEngine.LayerMask.GetMask("Device")
    if layerMask then

        local hit = self.Transform:PhysicsRayCast(CS.UnityEngine.Vector3.up * 100, CS.UnityEngine.Vector3.down, layerMask)

        if not XTool.UObjIsNil(hit) then
            local obj = XSceneEntityManager.GetEntity(hit.gameObject)

            if self.PreInteractFurniture ~= nil and (obj == nil or obj.Data.Id ~= self.PreInteractFurniture.Data.Id) then
                self.PreInteractFurniture:RayCastSelected(false)
                self.IsRayCastFurniture = false
            end

            if obj then
                local interactInfo = obj:GetAvailableInteract(self.CharData.CharacterId)
                if interactInfo then
                    self.PreInteractFurniture = obj
                    self.PreInteractFurniture:RayCastSelected(true)
                    self.IsRayCastFurniture = true
                else
                    if self.PreInteractFurniture then
                        self.PreInteractFurniture:RayCastSelected(false)
                    end
                    self.IsRayCastFurniture = false
                    self.PreInteractFurniture = nil
                end
            end
        else
            if self.PreInteractFurniture ~= nil then
                self.PreInteractFurniture:RayCastSelected(false)
                self.PreInteractFurniture = nil
                self.IsRayCastFurniture = false

            end
        end
    end
end

--长按
function XHomeCharObj:OnPress(pressTime)
    if not self.IsSelf then
        return
    end

    if self.CharLongPressTrigger ~= nil and self.CharLongPressTrigger == false then
        return
    end

    if self.Status ~= XHomeBehaviorStatus.GRAB_UP then
        if not self.IsPressing then
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_PUT_ON, self.Id, self.Transform, true)
            self.IsPressing = true
        elseif pressTime >= self.DormPutOnAnimaTime then
            self:SidewaysSceneCamera()
            self.OrignalPosition = self.Transform.position

            self.Transform.position = CS.UnityEngine.Vector3(self.OrignalPosition.x, self.OrignalPosition.y + 0.5, self.OrignalPosition.z)

            self:ChangeStatus(XHomeBehaviorStatus.GRAB_UP)
            self:HideBubble()
            XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_CATCH)
            self.NavMeshAgent.IsObstacle = false
            self.IsPressing = false
        end
    end

end

--点击：会直接被外部调用，不会传eventData
function XHomeCharObj:OnClick(eventData)
    if not self.IsSelf then
        return
    end

    if eventData then
        self.Agent:SetVarDicByKey("BindWorldPos", eventData.pointerCurrentRaycast.worldPosition)
    end

    if self.CanClick then
        local currentCamera = XHomeSceneManager.GetSceneCamera()
        local direction = currentCamera.transform.position - self.Transform.position
        direction.y = 0
        local eulerAngle = CS.UnityEngine.Quaternion.LookRotation(direction).eulerAngles
        self.Agent:SetVarDicByKey("TurnTo", eulerAngle)
        XHomeCharManager.SetSelectCharacter(self)

        self:ChangeStatus(XHomeBehaviorStatus.SELECTED)
        self:HideBubble()
        XEventManager.DispatchEvent(XEventId.EVENT_DORM_EXP_DETAIL_SHOW, self.Id, self.Transform)
    end

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_CHARACTER_CLICK_SUCCESS, self.Id)
end

--手指压下
function XHomeCharObj:OnPointerDown()
    if not self.IsSelf then
        return
    end

    if self.CanClick then
        self:HideBubble()
        local currentCamera = XHomeSceneManager.GetSceneCamera()
        local direction = currentCamera.transform.position - self.Transform.position
        direction.y = 0
        local eulerAngle = CS.UnityEngine.Quaternion.LookRotation(direction).eulerAngles
        self.Agent:SetVarDicByKey("TurnTo", eulerAngle)
        self:ChangeStatus(XHomeBehaviorStatus.WAIT)
    end
end

--手指松开
function XHomeCharObj:OnPointerUp()
    if not self.IsSelf then
        return
    end

    if self.Status == XHomeBehaviorStatus.GRAB_UP or self.IsPressing then
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_PUT_DOWN)
    end

    if self.Status == XHomeBehaviorStatus.GRAB_UP then

        self:FaceToSceneCamera()
        if not self.PreInteractFurniture then
            self.NavMeshAgent.IsObstacle = true
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_CHARACTER_POINTER_UP_SUCCESS, self.Id)
        else
            self.NavMeshAgent.IsObstacle = false

            local interactInfo = self.PreInteractFurniture:GetNearAvailableInteract(self.Transform.position, self.CharData.CharacterId)
            if not interactInfo then
                self.PreInteractFurniture:RayCastSelected(false)
                self.IsRayCastFurniture = false
                self.PreInteractFurniture = nil
                self.NavMeshAgent.IsObstacle = true
                CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_CHARACTER_POINTER_UP_SUCCESS, self.Id)
                return
            end

            self.PreInteractFurniture:RayCastSelected(false)
            self.IsRayCastFurniture = false

            self.Transform.eulerAngles = interactInfo.StayPos.transform.eulerAngles

            self.Furniture = self.PreInteractFurniture
            self.InteractInfo = interactInfo

            local state = self:GetInteractInfoBehavior(interactInfo)
            self.Transform.position = CS.UnityEngine.Vector3(interactInfo.StayPos.transform.position.x, self.OrignalPosition.y, interactInfo.StayPos.transform.position.z)
            self:ChangeStatus(state)
        end
    end
    self.PreInteractFurniture = nil

    if self.IsPressing then
        self.IsPressing = false
    end
end

function XHomeCharObj:GetInteractInfoBehavior(info)
    local relation = XDormConfig.GetDormF2CBehaviorRelative(self.Furniture.Cfg.Id, self.Id, info.PosIndex)
    if relation and relation.BehaviorWeight then
        local totalweight = 0
        for _, weight in pairs(relation.BehaviorWeight) do
            totalweight = totalweight + weight
        end
        math.randomseed(os.time())
        local random = math.random(0, totalweight)
        local countWeight = 0
        for index, weight in pairs(relation.BehaviorWeight) do
            countWeight = countWeight + weight
            if random <= countWeight then
                return relation.Behavior[index]
            end
        end
    end
    return info.BehaviorType
end

function XHomeCharObj:GetInteractInfoAttractBehavior(info)
    local relation = XDormConfig.GetDormF2CBehaviorRelative(self.Furniture.Cfg.Id, self.Id, info.PosIndex)
    if relation and relation.AttractBehaviorWeight then
        local totalweight = 0
        for _, weight in pairs(relation.AttractBehaviorWeight) do
            totalweight = totalweight + weight
        end
        math.randomseed(os.time())
        local random = math.random(0, totalweight)
        local countWeight = 0
        for index, weight in pairs(relation.AttractBehaviorWeight) do
            countWeight = countWeight + weight
            if random <= countWeight then
                return relation.AttractBehavior[index]
            end
        end
    end
    return info.AttractBehaviorType
end

--手指退出
function XHomeCharObj:OnPointerExit()
    if not self.IsSelf then
        return
    end

    if self.IsPressing then
        XEventManager.DispatchEvent(XEventId.EVENT_CHARACTER_EXIT)
        self.IsPressing = false
    end
end

--关联家具
function XHomeCharObj:InteractFurniture()
    -- 没有关联的家具或者没有交互点，直接返回，获取关联的家具是从Drag的射线判定获取
    if self.Furniture == nil or not self.InteractInfo then
        return false
    end

    -- 遍历家具的可交互点信息
    for _, v in ipairs(self.Furniture.InteractInfoList) do
        -- 找到与当前交互点相同格子的位置
        if v.GridPos.x == self.InteractInfo.GridPos.x and v.GridPos.y == self.InteractInfo.GridPos.y then
            v.UsedType = v.UsedType | XFurnitureInteractUsedType.Character
            v.CharacterId = self.Id
            break
        end
    end

    return true
end

function XHomeCharObj:PlayFurnitureAction(actionId, needFadeCross, crossDuration, needReplayAnimation)
    if self.Furniture ~= nil then
        self.Furniture:DoActionNode(actionId, needFadeCross, crossDuration)
    end
    return true
end

-- 播放关联家具动画
function XHomeCharObj:PlayInteractFurnitureAnimation()
    if self.Furniture == nil or not self.InteractInfo then
        return false
    end

    self.Furniture:PlayInteractAnimation(self.Id)
    return true
end

--到达家具交互
function XHomeCharObj:ReachFurniture()
    if self.Furniture == nil then
        self:ChangeStatus(XHomeBehaviorStatus.IDLE)
        return false
    end
    for _, v in ipairs(self.Furniture.InteractInfoList) do
        local state = self:GetInteractInfoBehavior(v)
        if XDormConfig.GetCharacterBehavior(self.Id, state) then
            self:ChangeStatus(state)
            return true
        end
    end

    return false
end

--取消家具预关联
function XHomeCharObj:DisPreInteractFurniture()
    if self.PreInteractFurniture == nil then
        return false
    end

    for _, v in ipairs(self.PreInteractFurniture.InteractInfoList) do
        if v.CharacterId == self.Id and (v.UsedType & XFurnitureInteractUsedType.Character) > 0 then
            XHomeCharManager.SetFurnitureInteractTime(self.Id)
            v.UsedType = v.UsedType - XFurnitureInteractUsedType.Character
            v.CharacterId = nil
            break
        end
    end

    return true
end

--取消家具关联
function XHomeCharObj:DisInteractFurniture()
    if self.Furniture == nil then
        return false
    end

    for _, v in ipairs(self.Furniture.InteractInfoList) do
        if v.CharacterId == self.Id and (v.UsedType & XFurnitureInteractUsedType.Character) > 0 then
            XHomeCharManager.SetFurnitureInteractTime(self.Id)
            v.UsedType = v.UsedType - XFurnitureInteractUsedType.Character
            v.CharacterId = nil
            break
        end
    end

    self.Furniture = nil
    self.InteractInfo = nil
    return true
end

--检测是否可以取消家具关联
function XHomeCharObj:CheckDisInteractFurniture()
    if self.Furniture == nil then
        return false
    end

    for _, v in ipairs(self.Furniture.InteractInfoList) do
        if v.CharacterId == self.Id and (v.UsedType & XFurnitureInteractUsedType.Character) > 0 then
            local canReach = CS.XNavMeshUtility.CheckCanReachNavMeshSamplePosition(v.InteractPos.transform.position, CS.XHomeMapManager.Inst.CeilSize * 0.75)
            if (v.UsedType & XFurnitureInteractUsedType.Block) > 0 or not canReach then
                return false
            else
                return true
            end
        end
    end

    return true
end

--取消选择
function XHomeCharObj:UnSelected()
    XHomeCharManager.SetSelectCharacter(nil)
    self:ChangeStatus(XHomeBehaviorStatus.IDLE)
end

--设置爱抚类型
function XHomeCharObj:SetFondleType(fondleType)
    self.FondleTypeList = self.FondleTypeList or {}
    local length = #self.FondleTypeList
    if self.FondleType == fondleType then
        return
    end

    if length < 2 then
        table.insert(self.FondleTypeList, fondleType)
        return
    end

    if fondleType == XHomeCharFondleType.REFUSE then
        return
    elseif self.FondleTypeList[length] <= XHomeCharFondleType.PLAY then
        self.FondleTypeList[length] = fondleType
    end

end

--出列
function XHomeCharObj:DequeueFondleType()
    if self.FondleTypeList and #self.FondleTypeList > 0 then
        self.FondleType = table.remove(self.FondleTypeList, 1)
    end

    if not self.FondleType then
        self.FondleType = 0
    end
end

--获取爱抚类型
function XHomeCharObj:GetFondleType()
    if self.FondleTypeList and #self.FondleTypeList > 0 then
        self.FondleType = self.FondleTypeList[1]
    else
        self.FondleType = 0
    end

    return self.FondleType
end

-- 重新出生点
function XHomeCharObj:ReBorn()
    self.GameObject:SetActive(true)
    self.NavMeshAgent.IsObstacle = true
    self:ChangeStatus(XHomeBehaviorStatus.IDLE)
end

-- 刷新位置
function XHomeCharObj:ReSetPosition()
    if self.LastInteractInfoPos then
        self.LastInteractInfoPos = nil
    end

    local canReachList = self.Room:GetCanReachList()
    local isBornPos = false
    local targetPos = CS.UnityEngine.Vector2.one
    local x = 0
    local y = 0


    --最大的随机次数
    local limit = 30
    --设置随机数种子
    math.randomseed(os.time() + self.Id)
    while (not isBornPos and limit >= 0) do
        local index = math.random(1, #canReachList)
        x = canReachList[index].x
        y = canReachList[index].y
        local pos = XHomeDormManager.GetLocalPosByGrid(x, y, CS.XHomePlatType.Ground, 0)
        pos = self.Room.Transform.localToWorldMatrix:MultiplyPoint(pos)
        isBornPos, targetPos = CS.XNavMeshUtility.NavMeshSamplePositionByWalkable(pos)
        if not isBornPos then
            targetPos = pos
        end
        
        limit = limit - 1
    end

    self.Transform.position = targetPos
    self.OrignalPosition = self.Transform.position

    self.Pos = {
        ["x"] = x,
        ["y"] = y
    }

    self.Agent:SetVarDicByKey("x", x)
    self.Agent:SetVarDicByKey("y", y)
end

-- 检查是否在交互，如果在与家具交互，构造体重置到家具交互位置
function XHomeCharObj:CheckInteractFurniture()
    if self.LastInteractInfoPos then
        self.Transform.position = CS.UnityEngine.Vector3(self.LastInteractInfoPos.x, self.LastInteractInfoPos.y, self.LastInteractInfoPos.z)
        self.LastInteractInfoPos = nil
    end
end

function XHomeCharObj:OnShow(isResetPosition)
    if self.Visible then
        return
    end

    if isResetPosition then
        self:ReSetPosition()
    else
        self:CheckInteractFurniture()
    end

    self.Visible = true
    self:ReBorn()
end

function XHomeCharObj:OnHide()
    if not self.Visible then
        return
    end

    -- 保存家具交互点信息
    if self.Furniture then
        local info = self.Furniture:GetInteractById(self.Id)
        self.LastInteractInfoPos = {
            x = info.InteractPos.transform.position.x,
            y = info.InteractPos.transform.position.y,
            z = info.InteractPos.transform.position.z
        }
    end

    self:ChangeStateMachine(XHomeCharFSMType.EMPTY)
    self:HideBubble()

    self.Visible = false
end

--检测是否在家具上方
function XHomeCharObj:CheckRayCastFurnitureNode()
    return self.IsRayCastFurniture
end

--面向交互的构造体
function XHomeCharObj:InteractWith(charObj)
    local direction = charObj.Transform.position - self.Transform.position
    direction.y = 0
    local eulerAngle = CS.UnityEngine.Quaternion.LookRotation(direction).eulerAngles
    self.Agent:SetVarDicByKey("TurnTo", eulerAngle)
end

--交互家具面向方向调整
function XHomeCharObj:SetForwardToFurniture(forward)

    local furniture = self.Furniture
    local info = self.InteractInfo
    if not furniture or not info then
        return false
    end


    local interact = furniture:GetInteract(info.GridPos.x, info.GridPos.y)
    local eulerAngle = interact.InteractPos.transform.eulerAngles

    if forward < 0 then
        eulerAngle = eulerAngle + CS.UnityEngine.Vector3(0, 180, 0)
    end
    self.Agent:SetVarDicByKey("TurnTo", eulerAngle)
    return true
end

--设置构造体交互开关
function XHomeCharObj:SetCharInteractTrigger(isOn)
    self.CharInteractTrigger = isOn
end

--设置构造体长按开关
function XHomeCharObj:SetCharLongPressTrigger(isOn)
    self.CharLongPressTrigger = isOn
    return true
end

--检测构造体是否在坐标索引上
function XHomeCharObj:CheckCharInteractPosByIndex(index)
    if not self.Furniture or not self.Furniture.InteractInfoList then
        return false
    end

    for _, v in ipairs(self.Furniture.InteractInfoList) do
        if v.CharacterId == self.Id and (v.UsedType & XFurnitureInteractUsedType.Character) > 0 then
            return v.Index == index
        end
    end

    return false
end

return XHomeCharObj