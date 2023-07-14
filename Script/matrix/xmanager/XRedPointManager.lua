--红点管理器
XRedPointManager = XRedPointManager or {}
require("XRedPoint/XRedPointConditions")

local RedPointEventDic = {}
local RedPointFiitterEvents = {}
local eventIdPool = 0

---@type XObjectPool
local RedPointEventPool

--region   ------------------local function start-------------------

--- 移除事件节点
---@param eventId number 事件Id
---@param needRelease boolean 是否需要释放
--------------------------
local function RemoveRedPointEventInternal(eventId, needRelease)
    if RedPointEventDic == nil or not RedPointEventDic[eventId] then
        return
    end

    local pointEvent = RedPointEventDic[eventId]
    RedPointEventDic[eventId] = nil
    
    if needRelease and pointEvent then
        --release 会再次释放，置空需要放到之前
        pointEvent:Release()
    end
    if pointEvent then
        RedPointEventPool:Recycle(pointEvent)
    end
end

--- 自增事件Id
---@return number
--------------------------
local function GenerateEventId()
    eventIdPool = eventIdPool + 1
    return eventIdPool
end
--endregion------------------local function finish------------------



function XRedPointManager.Init()
    RedPointEventDic = RedPointEventDic or {}
    RedPointFiitterEvents = RedPointFiitterEvents or {}
    RedPointEventPool = RedPointEventPool or XObjectPool.New(XRedPointEvent.New)
end

--添加过滤
function XRedPointManager.AddRedPointFitterEvent(conditionId)
    if not XRedPointManager[conditionId] then
        XLog.Warning("Event type not found :" .. conditionId)
        return
    end

    RedPointFiitterEvents = RedPointFiitterEvents or {}
    RedPointFiitterEvents[conditionId] = conditionId
end

--移除过滤
function XRedPointManager.RemoveRedPointFitterEvent(conditionId)
    if not RedPointFiitterEvents or not RedPointFiitterEvents[conditionId] then
        return
    end

    RedPointFiitterEvents[conditionId] = nil
end

--增加一个红点事件
function XRedPointManager.AddRedPointEvent(node, func, listener, conditionGroup, args, isCheck)

    if not node then
        XLog.Warning("该绑定节点为空，需要检查UI预设")
        return
    end

    local eventId = GenerateEventId()
    RedPointEventDic[eventId] = RedPointEventPool:Create(eventId, node, conditionGroup, listener, func, args)
    if isCheck == nil or isCheck == true then
        XRedPointManager.Check(eventId)
    end

    return eventId
end

--删除一个红点事件
function XRedPointManager.RemoveRedPointEvent(eventId)
    RemoveRedPointEventInternal(eventId, true)
end

--删除一个红点事件
function XRedPointManager.RemoveRedPointEventOnly(eventId)
    RemoveRedPointEventInternal(eventId, false)
end

--检测红点
function XRedPointManager.Check(eventId, args)
    if not eventId or eventId <= 0 then
        return
    end

    if RedPointEventDic == nil or not RedPointEventDic[eventId] then
        return
    end

    local pointEvent = RedPointEventDic[eventId]

    if pointEvent then
        pointEvent:Check(args)
    end
end

--检测红点,直接判断不持有节点
function XRedPointManager.CheckOnce(func, listener, conditionGroup, args)
    local result = -1

    for _, v in ipairs(conditionGroup) do
        if XRedPointConditions[v] ~= nil then
            if not XRedPointManager.CheckIsFitter(v) then

                local r = XRedPointConditions[v].Check(args)

                if type(r) == "number" then
                    result = result + r
                elseif r == true and result == -1 then
                    result = 0
                end

            end
        end
    end

    if func then
        func(listener, result, args)
    end
end

function XRedPointManager.CheckOnceByButton(button, conditionGroup, args)
    XRedPointManager.CheckOnce(function(_, count)
        button:ShowReddot(count >= 0)
    end, nil , conditionGroup,args)
end

--检测红点通过节点
function XRedPointManager.CheckByNode(node, args)
    if RedPointEventDic == nil then
        return
    end

    local redPointEvent = nil
    for _, v in pairs(RedPointEventDic) do
        if v:CheckNode() and v.node == node then
            redPointEvent = v
            break
        end
    end

    if redPointEvent then
        redPointEvent:Check(args)
    end
end

--检测红点过滤
function XRedPointManager.CheckIsFitter(conditionId)
    if not RedPointFiitterEvents then
        return false
    end

    if not RedPointFiitterEvents[conditionId] then
        return false
    end

    return true
end

--自动释放
function XRedPointManager.AutoReleaseRedPointEvent()
    if not RedPointEventDic then
        return
    end

    local removeEvents = {}
    for _, v in pairs(RedPointEventDic) do
        if not v:CheckNode() then
            table.insert(removeEvents, v)
        end
    end

    for _, v in ipairs(removeEvents) do
        XRedPointManager.RemoveRedPointEvent(v.id)
    end
end

--检测红点
function XRedPointManager.CheckConditions(conditions, args)
    for _, v in ipairs(conditions) do
        if XRedPointConditions[v] ~= nil then
            if not XRedPointManager.CheckIsFitter(v) then
                local r = XRedPointConditions[v].Check(args)
                if type(r) == "number" then
                    if r > 0 then return true end
                elseif r then
                    return true
                end
            end
        end
    end
    return false
end