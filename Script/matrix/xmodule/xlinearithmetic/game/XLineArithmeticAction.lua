local XLineArithmeticEnum = require("XModule/XLineArithmetic/Game/XLineArithmeticEnum")

---@class XLineArithmeticAction
local XLineArithmeticAction = XClass(nil, "XLineArithmeticAction")

function XLineArithmeticAction:Ctor()
    self._Type = XLineArithmeticEnum.ACTION.CLICK
    self._Params = false
    self._IsEatFinalGrid = true
end

function XLineArithmeticAction:SetData(type, params)
    self._Type = type
    self._Params = params
end

function XLineArithmeticAction:SetEatFinalGrid(value)
    self._IsEatFinalGrid = value
end

---@param game XLineArithmeticGame
---@param model XLineArithmeticModel
function XLineArithmeticAction:Execute(game, model)
    if self._Type == XLineArithmeticEnum.ACTION.CLICK
            or self._Type == XLineArithmeticEnum.ACTION.DRAG
    then
        ---@type XLuaVector2
        local pos = self._Params

        ---@type XLineArithmeticGrid
        local grid = game:GetGrid(pos)
        if not grid then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LineArithmeticSelectEmpty)
            --if XMain.IsEditorDebug then
            --    XLog.Error("[XLineArithmeticGame] 点击空白格:", pos.x, pos.y)
            --end
            return
        end

        if grid:IsEmpty() then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LineArithmeticSelectEmpty)
            return
        end

        -- 移除选中的格子
        local isOnLine, index = game:IsOnLine(grid)
        if isOnLine then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LineArithmeticSelect)
            -- 拖拽时，不移除当前格
            if self._Type == XLineArithmeticEnum.ACTION.DRAG then
                game:RemoveGridOnLineFromIndex(index + 1)
            else
                game:RemoveGridOnLineFromIndex(index)
            end
            return
        end

        -- 选中第一个格子
        local tailGrid = game:GetTailGrid()
        if not tailGrid then
            if grid:IsNumberGrid() then
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LineArithmeticSelect)
                game:AddGrid2Line(grid)
            end
            return
        end

        -- 终点和停留格, 不能越过
        if tailGrid:IsFinalGrid() or tailGrid:IsStayEventGrid() then
            return
        end

        -- 选中相邻的格子
        if tailGrid:IsNeighbour(grid) then
            -- 已完成的终点格不加入
            if grid:IsFinish() then
                return
            end
            
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.LineArithmeticSelect)
            game:AddGrid2Line(grid)
            game:Execute(model)
            return
        end

        --XLog.Error("[XLineArithmeticAction] 点击存在未定义的情况")
        return
    end

    if self._Type == XLineArithmeticEnum.ACTION.CONFIRM then
        game:Execute(model)
        if self._IsEatFinalGrid then
            game:ExecuteEat(model)
        end
        return
    end
end

return XLineArithmeticAction
