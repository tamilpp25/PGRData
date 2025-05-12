local math = math

local mathFloor = math.floor
local mathRandom = math.random
local mathModf = math.modf

XMath = XMath or {}

function XMath.RandByWeights(weights)
    local weightSum = 0
    for i = 1, #weights do
        weightSum = weightSum + weights[i]
    end

    local rand = mathRandom(weightSum)
    local curWeight = 0
    for i = 1, #weights do
        local weight = weights[i]
        curWeight = curWeight + weight
        if rand < curWeight then
            return i
        end
    end

    return #weights
end

function XMath.RandomByDoubleList(values, weights, maxValue)
    -- 最大值未指定，直接随机
    if not maxValue then
        local idx = XMath.RandByWeights(weights)
        return values[idx] or 0
    end

    -- 最大值已指定，根据最大值过滤
    local filteredValues = {}
    local filteredWeights = {}

    for i, value in ipairs(values) do
        if value <= maxValue then
            table.insert(filteredValues, value)
            table.insert(filteredWeights, weights[i])
        end
    end

    -- 过滤后无可用值
    if #filteredValues == 0 then
        return 0
    end

    local filteredIdx = XMath.RandByWeights(filteredWeights)
    return filteredValues[filteredIdx] or 0
end

function XMath.Clamp(value, min, max)
    if value < min then
        return min
    end
    if value > max then
        return max
    end
    return value
end


--==============================--
--desc: 转换成整数，浮点数四舍五入
--==============================--
XMath.ToInt = function(val)
    if not val then return end
    return mathFloor(val + 0.5)
end

--==============================--
--desc: 转换成整数，浮点数向下取整数
--==============================--
XMath.ToMinInt = function(val)
    if not val then return end
    return mathFloor(val)
end

--==============================--
--desc: 最大整数，与C#一致
--==============================--
XMath.IntMax = function()
    return 2147483647
end

--==============================--
--desc: math.floor的精度问题调整方向 eg. math.floor(0.58 * 100) = 57
--==============================--
XMath.FixFloor = function(val, precision)
    return mathFloor(val + (precision or 0.00001))
end
