XHomeCharManager = XHomeCharManager or {}

local XHomeCharObj = require("XHome/XDorm/XHomeCharObj")

---@type table<number, XHomeCharObj>
local ActiveCharacter = {}
---@type XHomeCharObj
local CurrentSelected = {}

local EventRewards = {}

local FURNITURE_INTERACT_CD = CS.XGame.ClientConfig:GetInt("DormFurnitureInteractCD")
local FURNITURE_INTERACT_DISTANCE = CS.XGame.ClientConfig:GetInt("DormFurnitureInteractDistance")

local CHARACTER_INTERACT_CD = CS.XGame.ClientConfig:GetInt("DormCharacterInteractCD")

local FurnitureLastInteractTime = {}
local CharacterLastInteractTime = {}

--初始化
function XHomeCharManager.Init()
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_ADD_EVENT_NOTIFY, function(...)
        XHomeCharManager.OnEvent(XEventId.EVENT_CHARACTER_ADD_EVENT_NOTIFY, ...)
    end)

    --爱抚
    XEventManager.AddEventListener(XEventId.EVENT_DORM_TOUCH_ENTER, function(...)
        XHomeCharManager.OnEvent(XEventId.EVENT_DORM_TOUCH_ENTER, ...)
    end)

    --进入爱抚
    XEventManager.AddEventListener(XEventId.EVENT_DORM_TOUCH_SHOW, XHomeCharManager.OnFondle)
    --爱抚结束
    XEventManager.AddEventListener(XEventId.EVENT_DORM_TOUCH_HIDE, XHomeCharManager.OnFondleEnd)

    CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_HOME_CHARACTER_STATUS_CHANGE, function()

    end)

    XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, XHomeCharManager.HandleSignOut)

end

--事件
function XHomeCharManager.OnEvent(evt, ...)

    if CurrentSelected == nil then
        return
    end

    if evt == XEventId.EVENT_DORM_TOUCH_ENTER then
        XHomeCharManager.HideAllCharacterBut(CurrentSelected.Id)
        CurrentSelected:ChangeStatus(XHomeBehaviorStatus.FONDLE)
    elseif evt == XEventId.EVENT_CHARACTER_ADD_EVENT_NOTIFY then
        local charId = ...
        local charObj = XHomeCharManager.GetActiveCharacter(charId)
        if not charObj or not charObj.IsSelf then
            return
        end
 
        local event = XHomeCharManager.GetCharacterEvent(charId, true)
        if event == nil then
            XLog.Error("找不到事件", charId)
            return
        end
        local temp = XDormConfig.GetCharacterEventById(event.EventId)
        charObj:OnEventChange(temp)
    end
end


function XHomeCharManager.HandleSignOut()
    ActiveCharacter = {}
    CurrentSelected = {}

    EventRewards = {}
end

--爱抚结束
function XHomeCharManager.OnFondleEnd()
    XHomeCharManager.ShowAllCharacter()
    if CurrentSelected then
        CurrentSelected:SetFondleType(-1)
        CurrentSelected:UnSelected()
        CurrentSelected = nil
    end
end

--爱抚中
function XHomeCharManager.OnFondle(fondleType, charId)
    if CurrentSelected == nil or CurrentSelected.Id ~= charId then
        return
    end

    CurrentSelected:SetFondleType(fondleType)
    XHomeCharManager.HideAllCharacterBut(CurrentSelected.Id)
end


--监听角色改变状态
function XHomeCharManager.OnHomeCharChangeStatus()

end

--- 设置当前选中角色
---@param homeChar XHomeCharObj
--------------------------
function XHomeCharManager.SetSelectCharacter(homeChar)
    CurrentSelected = homeChar
end

--- 获取当前选中角色
---@return XHomeCharObj
--------------------------
function XHomeCharManager.GetSelectCharacter()
    return CurrentSelected
end

--预加载构造体
function XHomeCharManager.PreLoadHomeCharacterById()
    -- XHomeCharManager.CreateHomeCharacter(charId)
end

--- 创建构造体
---@param charId number 角色id
---@param root UnityEngine.Transform 绑定角色根节点
---@return XHomeCharObj
--------------------------
function XHomeCharManager.CreateHomeCharacter(charId, root)
    local charStyleConfig = XDormConfig.GetCharacterStyleConfigById(charId)

    local homeChar = XHomeCharObj.New()
    homeChar:LoadModel(charStyleConfig.Model, root)
    homeChar.GameObject:SetActive(false)
    return homeChar
end

--- 从池里面获取构造体模型
---@param charId number 角色id
---@param root UnityEngine.Transform 绑定角色根节点
---@return XHomeCharObj
--------------------------
function XHomeCharManager.SpawnHomeCharacter(charId, root)
    local charObj = XHomeCharManager.CreateHomeCharacter(charId, root)
    ActiveCharacter[charId] = charObj

    return charObj
end

--回池
function XHomeCharManager.DespawnHomeCharacter(charId, charObj)
    if ActiveCharacter[charId] then
        ActiveCharacter[charId]:Dispose()
    end
    charObj:Dispose()
    ActiveCharacter[charId] = nil
end

--- 获取活跃中的角色
---@param charId number 角色id
---@return XHomeCharObj
--------------------------
function XHomeCharManager.GetActiveCharacter(charId)
    if not ActiveCharacter[charId] then
        XLog.Warning("ActiveCharacter not exist ", charId)
        return
    end

    return ActiveCharacter[charId]
end

--- 获取事件
---@param charId number 角色id
---@param isSelf boolean 是否是自己的角色
---@return XTable.XTableDormCharacterEvent
--------------------------
function XHomeCharManager.GetCharacterEvent(charId, isSelf)
    local charData
    if isSelf then
        charData = XDataCenter.DormManager.GetCharacterDataByCharId(charId)
    else
        charData = XDataCenter.DormManager.GetTargetCharacterDataByCharId(charId)
    end

    if not charData or not charData.EventList or #charData.EventList <= 0 then
        return
    end

    local curTime = XTime.GetServerNowTimestamp()
    local EventTemp
    for _, v in ipairs(charData.EventList) do
        if not v.EndTime or v.EndTime > curTime or v.EndTime <= 0 then
            local eventId = v.EventId
            local temp = XDormConfig.GetCharacterEventById(eventId)
            if not EventTemp or temp.Weight > EventTemp.Weight then
                if temp and temp.BehaviorId then
                    EventTemp = temp
                end
            end
        end
    end

    return EventTemp
end

---检测事件是否存在
function XHomeCharManager.CheckCharacterEventExist(charId, eventId, isSelf)
    local charData

    if isSelf then
        charData = XDataCenter.DormManager.GetCharacterDataByCharId(charId)
    else
        charData = XDataCenter.DormManager.GetTargetCharacterDataByCharId(charId)
    end

    if not charData.EventList or #charData.EventList <= 0 then
        return false
    end

    local curTime = XTime.GetServerNowTimestamp()

    for _, v in ipairs(charData.EventList) do
        if not v.EndTime or v.EndTime > curTime or v.EndTime <= 0 then
            if v.EventId == eventId then
                return true
            end
        end
    end

    return false
end

--- 检测事件是否能完成
---@param charId number 角色id
---@param completeType number 类型
---@return XTable.XTableDormCharacterEvent
--------------------------
function XHomeCharManager.CheckCharacterEventCompleted(charId, completeType, isSelf)
    local charData

    if isSelf then
        charData = XDataCenter.DormManager.GetCharacterDataByCharId(charId)
    else
        charData = XDataCenter.DormManager.GetTargetCharacterDataByCharId(charId)
    end

    if not charData.EventList or #charData.EventList <= 0 then
        return
    end
    local curTime = XTime.GetServerNowTimestamp()
    local EventTemp

    for _, v in ipairs(charData.EventList) do
        if not v.EndTime or v.EndTime > curTime or v.EndTime <= 0 then
            local eventId = v.EventId
            local temp = XDormConfig.GetCharacterEventById(eventId, true)
            local completeTypes = temp.CompletedType
            for _, var in ipairs(completeTypes) do
                if var == completeType then
                    EventTemp = temp
                    break
                end
            end
        end
    end

    return EventTemp
end

--检测人物交互
function XHomeCharManager.CheckCharacterInteracter(charId)
    local charObj = XHomeCharManager.GetActiveCharacter(charId)
    if not charObj then
        return false
    end

    if XTool.UObjIsNil(charObj.GameObject) then
        return false
    end

    if XTool.UObjIsNil(charObj.Transform) then
        return false
    end

    local time = XTime.GetServerNowTimestamp()
    local lastTime = CharacterLastInteractTime[charId]
    if lastTime and lastTime + CHARACTER_INTERACT_CD > time then
        return
    end

    for _, v in pairs(ActiveCharacter) do
        if v and not XTool.UObjIsNil(v.GameObject) and not XTool.UObjIsNil(v.Transform) and v.Id ~= charId and v.CharInteractTrigger then
            local distance = CS.UnityEngine.Vector3.Distance(charObj.Transform.position, v.Transform.position)

            lastTime = CharacterLastInteractTime[v.Id]
            local bInteract = lastTime and lastTime + CHARACTER_INTERACT_CD > time
            if not bInteract then
                local result, temp, state1, state2 = XDormConfig.GetCharacterInteractiveIndex(v.Id, charObj.Id)
                if result then
                    local minDis = XHomeDormManager.GetCeilSize() * temp.MinDis
                    local maxDis = XHomeDormManager.GetCeilSize() * temp.MaxDis
                    if distance > minDis and distance < maxDis then
                        charObj.InteractiveCharacter = v
                        v.InteractiveCharacter = charObj

                        charObj:InteractWith(v)
                        v:InteractWith(charObj)

                        charObj:ChangeStatus(state1)
                        v:ChangeStatus(state2)

                        CharacterLastInteractTime[charObj.Id] = time
                        CharacterLastInteractTime[v.Id] = time

                        return true
                    end
                end
            end
        end
    end

    return false
end

--检测家具交互
function XHomeCharManager.CheckFurnitureInteract(charId)
    local charObj = XHomeCharManager.GetActiveCharacter(charId)
    if not charObj then
        return false
    end

    local time = XTime.GetServerNowTimestamp()
    local lastTime = FurnitureLastInteractTime[charId]
    if lastTime and lastTime + FURNITURE_INTERACT_CD > time then
        return false
    end

    local interactFurniture = nil
    local interactPos = nil
    local lastDistance = 0

    local interactList = charObj.Room.InteractList
    for _, v in ipairs(interactList) do
        if v.Furniture:CheckCanInteract(v.GridPos.x, v.GridPos.y, charId) then
            local pos = XHomeDormManager.GetLocalPosByGrid(v.GridPos.x, v.GridPos.y, CS.XHomePlatType.Ground, 0)
            pos = charObj.Room.Transform.localToWorldMatrix:MultiplyPoint(pos)
            local distance = CS.UnityEngine.Vector3.Distance(charObj.Transform.position, pos)

            local tempInteracPos = v.InteractPosGo.transform.position

            if distance < XHomeDormManager.GetCeilSize() * FURNITURE_INTERACT_DISTANCE and (lastDistance <= 0 or distance < lastDistance) and CS.XNavMeshUtility.CheckCanReachNavMeshSamplePosition(tempInteracPos, CS.XHomeMapManager.Inst.CeilSize * 0.5) then
                interactFurniture = v
                lastDistance = distance
                interactPos = v.InteractPosGo.transform.position
            end
        end
    end

    if interactFurniture then
        return true, interactPos, interactFurniture
    end

    return false
end

--显示奖励
function XHomeCharManager.ShowEventReward(charId)
    if not EventRewards or not EventRewards[charId] then
        return
    end

    local rewards = EventRewards[charId]
    XUiManager.OpenUiObtain(rewards)
    EventRewards[charId] = nil
end

--设置奖励
function XHomeCharManager.SetEventReward(charId, rewards)
    EventRewards[charId] = rewards
end

--隐藏所有
function XHomeCharManager.HideAllCharacter()
    if XTool.IsTableEmpty(ActiveCharacter) then
        return
    end

    for _, v in pairs(ActiveCharacter) do
        if not XTool.UObjIsNil(v.GameObject) then
            v.GameObject:SetActive(false)
            v:OnHide()
        end
    end
end

function XHomeCharManager.ReleaseAllCharLongPressTrigger()
    if XTool.IsTableEmpty(ActiveCharacter) then
        return
    end
    for _, v in pairs(ActiveCharacter) do
        if not XTool.UObjIsNil(v.GameObject) then
            v:SetCharLongPressTrigger(true)
        end
    end
end

--隐藏所有
function XHomeCharManager.ShowAllCharacter(isResetPosition)
    if XTool.IsTableEmpty(ActiveCharacter) then
        return
    end

    for _, v in pairs(ActiveCharacter) do
        if not XTool.UObjIsNil(v.GameObject) then
            v.GameObject:SetActive(true)
            v:OnShow(isResetPosition)
        end
    end
end

--隐藏所有除了
function XHomeCharManager.HideAllCharacterBut(charId)
    if XTool.IsTableEmpty(ActiveCharacter) then
        return
    end

    for i, v in pairs(ActiveCharacter) do
        if not XTool.UObjIsNil(v.GameObject) and i ~= charId then
            v.GameObject:SetActive(false)
            v:OnHide()

        end
    end
end

--显示
function XHomeCharManager.ShowCharacter(charId)
    if XTool.IsTableEmpty(ActiveCharacter) then
        return
    end

    local character = ActiveCharacter[charId]
    if character and not XTool.UObjIsNil(character.GameObject) then
        character.GameObject:SetActive(true)
        character:OnShow()
    end
end

--设置上次家具交互时间
function XHomeCharManager.SetFurnitureInteractTime(charId)
    local time = XTime.GetServerNowTimestamp()
    FurnitureLastInteractTime[charId] = time
end

--设置上任务交互时间
function XHomeCharManager.SetCharacterInteractTime(charId1, charId2)
    local time = XTime.GetServerNowTimestamp()
    CharacterLastInteractTime[charId1] = time
    CharacterLastInteractTime[charId2] = time
end