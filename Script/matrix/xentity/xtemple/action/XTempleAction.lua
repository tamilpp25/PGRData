local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local ACTION = XTempleEnumConst.ACTION

---@class XTempleAction
local XTempleAction = XClass(nil, "XTempleAction")

function XTempleAction:Ctor()
    self._Type = ACTION.NONE
    self._Round = 0
    ---@type XLuaVector2
    self._Position = nil
    self._BlockId = nil
    self._OptionId = nil
    self._NoSpend = false
end

---@param data {Type:number, BlockId:XTempleBlock, Position:XLuaVector3, NoSpend:boolean}
function XTempleAction:SetData(data)
    self._Type = data.Type
    self._BlockId = data.BlockId
    self._OptionId = data.OptionId
    self._Position = data.Position
    self._NoSpend = data.NoSpend
end

function XTempleAction:GetType()
    return self._Type
end

function XTempleAction:GetBlockId()
    return self._BlockId
end

function XTempleAction:GetOptionId()
    return self._OptionId
end

---@param game XTempleGame
function XTempleAction:Execute(game)
    if self._Type == ACTION.SKIP then
        local skipRound = XTempleEnumConst.SKIP_SPEND
        if self._NoSpend then
            skipRound = 0
        end
        if not game:NextRound(skipRound) then
            return
        end
        if game:IsEditingBlock() then
            game:RemoveEditingBlock()
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_OPERATION)
        end
        game:SetActionRecord(nil, game:GetOptionRound() - 1)
        game:RemoveOptionScoreRecord()
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_ON_ACTION_CONFIRM)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_REQUEST_ACTION)
        return true
    end

    if self._Type == ACTION.PUT_DOWN then
        local blockId = self._BlockId
        local block = game:GetMap():GetBlockById(blockId)
        local map = game:GetMap()
        local x, y = map:GetCenterPosition()
        block:SetPositionXY(x, y)
        game:SetEditingBlock(block:Clone())
        game:SetEditingOption(self._OptionId)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_TALK, XTempleEnumConst.NPC_TALK.MOVE_BLOCK)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_OPERATION)
        return true
    end

    if self._Type == ACTION.ROTATE then
        local block = game:GetEditingBlock()
        block:Rotate90()

        local position = block:GetPosition()
        local x, y = game:ClampBlockPosition(block, position.x, position.y)
        block:SetPositionXY(x, y)

        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_OPERATION)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_TALK, XTempleEnumConst.NPC_TALK.ROTATE_BLOCK)
        return true
    end

    if self._Type == ACTION.DRAG then
        if self._Position then
            local block = game:GetEditingBlock()
            block:SetPosition(self._Position)

            local position = block:GetPosition()
            local x, y = game:ClampBlockPosition(block, position.x, position.y)
            block:SetPositionXY(x, y)

            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_OPERATION)
            return true
        end
        return false
    end

    if self._Type == ACTION.CONFIRM then
        if not game:IsEditingBlock() then
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_OPERATION)
            return false
        end
        local optionId = game:GetEditingOptionId()
        if game:InsertEditingBlock(optionId, self._NoSpend) then
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_TALK, XTempleEnumConst.NPC_TALK.CHOOSE_BLOCK)
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_REQUEST_ACTION)
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_ON_ACTION_CONFIRM)
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
            return true
        end
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_OPERATION)
        XUiManager.TipError(XUiHelper.GetText("TempleFailInsert"))
        --game:PlayMusicInsertFail()
        return false
    end

    if self._Type == ACTION.CANCEL then
        game:RemoveEditingBlock()
        game:SetActionRecord(nil, game:GetOptionRound())
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_ON_ACTION_CONFIRM)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_OPERATION)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_TALK, XTempleEnumConst.NPC_TALK.CANCEL_BLOCK)
        return true
    end
end

-- 只能向前快进
--function XTempleAction:Undo(game)
--end

function XTempleAction:GetPosition()
    return self._Position
end

return XTempleAction
