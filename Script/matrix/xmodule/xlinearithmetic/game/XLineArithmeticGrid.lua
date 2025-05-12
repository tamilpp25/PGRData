local XLineArithmeticEnum = require("XModule/XLineArithmetic/Game/XLineArithmeticEnum")

---@class XLineArithmeticGrid
local XLineArithmeticGrid = XClass(nil, "XLineArithmeticGrid")

function XLineArithmeticGrid:Ctor()
    self._Uid = 0

    self._Id = 0
    self._Type = XLineArithmeticEnum.GRID.EMPTY
    self._Icon = false
    self._Name = false
    self._Desc = false

    self._IconSleep = nil
    self._IconAwake = nil
    self._IconFinish = nil
    self._EmoIcon = nil

    self._Number = 0
    self._Pos = Vector2(0, 0)

    self._Params = {}

    -- 预览得分
    self._NumberPreview = {}
    -- 事件确认后的分数 带正负
    self._NumberOnConfirm = {}
    -- 终点格或者停留格 已经吃掉的分数
    self._NumberExecuted = 0

    self._Event = false
end

---@param grid XLineArithmeticGrid
function XLineArithmeticGrid:Equals(grid)
    if not grid then
        XLog.Error("[XLineArithmeticGrid] 比较格子相等错误")
        return false
    end
    return self:GetUid() == grid:GetUid()
end

---@return XLuaVector2
function XLineArithmeticGrid:GetPos()
    return self._Pos
end

function XLineArithmeticGrid:GetPosClone()
    local pos = self:GetPos()
    return XLuaVector2.New(pos.x, pos.y)
end

function XLineArithmeticGrid:SetPos(pos)
    self._Pos.x = pos.x
    self._Pos.y = pos.y
end

function XLineArithmeticGrid:SetPosByXY(x, y)
    self._Pos.x = x
    self._Pos.y = y
end

---@param grid XLineArithmeticGrid
function XLineArithmeticGrid:IsNeighbour(grid)
    local pos = grid:GetPos()
    local x1 = pos.x
    local y1 = pos.y
    local selfPos = self:GetPos()
    local x2 = selfPos.x
    local y2 = selfPos.y
    if x1 == x2 + 1 and y1 == y2 then
        return true
    end
    if x1 == x2 - 1 and y1 == y2 then
        return true
    end
    if x1 == x2 and y1 == y2 - 1 then
        return true
    end
    if x1 == x2 and y1 == y2 + 1 then
        return true
    end
    return false
end

function XLineArithmeticGrid:IsFinalGrid()
    return self._Type == XLineArithmeticEnum.GRID.FINAL
end

function XLineArithmeticGrid:IsEventGrid()
    return self:IsStayEventGrid() or self:IsCrossEventGrid()
end

function XLineArithmeticGrid:IsStayEventGrid()
    return self._Type == XLineArithmeticEnum.GRID.STAY_EVENT
end

function XLineArithmeticGrid:IsCrossEventGrid()
    return self._Type == XLineArithmeticEnum.GRID.CROSS_EVENT
end

function XLineArithmeticGrid:IsNumberGrid()
    return self._Type == XLineArithmeticEnum.GRID.NUMBER
end

function XLineArithmeticGrid:GetNumber()
    return self._Number
end

function XLineArithmeticGrid:GetNumberAfterConfirm()
    if self:IsNumberGrid() then
        local number = self:GetNumber()
        local numberOnConfirm = self:GetNumberOnConfirm()
        return number + numberOnConfirm
    end
    return 0
end

function XLineArithmeticGrid:IsNumberOnPreviewChanged()
    for i, value in pairs(self._NumberPreview) do
        if value ~= 0 then
            return true
        end
    end
    return false
end

function XLineArithmeticGrid:GetNumberPreview()
    local score = 0
    for i, value in pairs(self._NumberPreview) do
        score = score + value
    end
    return score
end

function XLineArithmeticGrid:GetNumberExecuted()
    return self._NumberExecuted
end

function XLineArithmeticGrid:GetNumberOnConfirm()
    local number = 0
    for i, numberOnConfirm in pairs(self._NumberOnConfirm) do
        number = number + numberOnConfirm
    end
    return number
end

-- 终点格的分数由这三部分构成
function XLineArithmeticGrid:GetNumber4Final()
    --配置分数
    local number = self:GetNumber()
    -- 已获得分数
    local numberExecuted = self:GetNumberExecuted()
    -- 事件已获得分数
    local numberOnConfirm = self:GetNumberOnConfirm()
    return number + numberOnConfirm - numberExecuted
end

function XLineArithmeticGrid:GetNumber4NumberGrid()
    local number = self:GetNumber()
    local numberOnConfirm = self:GetNumberOnConfirm()
    return number + numberOnConfirm
end

function XLineArithmeticGrid:GetNumber4Ui()
    local number
    if self:IsFinalGrid() then
        number = self:GetNumber4Final()
        number = number + self:GetNumberPreview()

    elseif self:IsNumberGrid() then
        number = self:GetNumber4NumberGrid()
        number = number + self:GetNumberPreview()

    elseif self:IsStayEventGrid() then
        -- 这里可能有问题，如果有问题，需要改成写在ui上, 在打包后确认
        number = "∞"
    else
        number = self:GetNumber()
    end
    return number
end

function XLineArithmeticGrid:GetParams()
    return self._Params
end

function XLineArithmeticGrid:GetParams1()
    return self._Params[1]
end

function XLineArithmeticGrid:GetEventType()
    return self:GetParams1()
end

function XLineArithmeticGrid:GetParams2()
    return self._Params[2]
end

-- 区分获得方式
---@param event XLineArithmeticEvent
function XLineArithmeticGrid:SetNumberPreview(event, score)
    self._NumberPreview[event:GetUid()] = score
end

---@param event XLineArithmeticEvent
function XLineArithmeticGrid:SetNumberOnConfirm(event, score)
    self._NumberOnConfirm[event:GetUid()] = score
end

function XLineArithmeticGrid:SetNumberExecuted(score)
    self._NumberExecuted = self._NumberExecuted + score
end

function XLineArithmeticGrid:IsNumberEnough()
    local number = self:GetNumber4Final()
    return number <= 0
end

function XLineArithmeticGrid:IsFinish()
    if self:IsFinalGrid() then
        return self:IsNumberEnough()
    end
    return false
end

function XLineArithmeticGrid:GetUid()
    return self._Uid
end

function XLineArithmeticGrid:SetDataFromConfig(config)
    if not config then
        XLog.Error("[XLineArithmeticGrid] 不存在的格子配置")
        return
    end
    self._Icon = config.CellIcon[1]
    self._Name = config.CellName
    self._Desc = config.CellDesc
    self._Type = config.CellType
    self._Params = config.Params
    self._Id = config.Id
    if self:IsCrossEventGrid() then
        self._Number = self._Params[2]
        if not self._Params[2] then
            XLog.Error("[XLineArithmeticGrid] 格子配置params[2]为空:", config.Id)
        end
    else
        self._Number = self._Params[1]
        if not self._Params[1] then
            XLog.Error("[XLineArithmeticGrid] 格子配置params[1]为空:", config.Id)
        end
    end

    if self:IsFinalGrid() then
        self._IconAwake = config.CellIcon[1]
        self._IconSleep = config.CellIcon[2]
        self._IconFinish = config.CellIcon[3]
    end

    self._EmoIcon = config.EmoIcon[1]
end

function XLineArithmeticGrid:SetUid(uid)
    self._Uid = uid
end

function XLineArithmeticGrid:GetIcon()
    return self._Icon
end

function XLineArithmeticGrid:GetIconFinish()
    return self._IconFinish
end

function XLineArithmeticGrid:GetIconSleep()
    return self._IconSleep
end

function XLineArithmeticGrid:GetIconAwake()
    return self._IconAwake
end

function XLineArithmeticGrid:GetEvent()
    return self._Event
end

function XLineArithmeticGrid:SetEvent(event)
    self._Event = event
end

function XLineArithmeticGrid:SetNumber(number)
    self._Number = number
end

function XLineArithmeticGrid:ClearNumberOnConfirm()
    self._NumberOnConfirm = {}
end

function XLineArithmeticGrid:GetEmoIcon()
    return self._EmoIcon
end

function XLineArithmeticGrid:GetDesc()
    return self._Desc
end

function XLineArithmeticGrid:GetName()
    return self._Name
end

function XLineArithmeticGrid:GetId()
    return self._Id
end

function XLineArithmeticGrid:IsEmpty()
    return self._Id == 0
end

return XLineArithmeticGrid
