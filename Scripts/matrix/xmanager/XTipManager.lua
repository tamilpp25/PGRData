XTipManager = XTipManager or {}

local State = {
    Standby = 1,
    Suspend = 2,
    Playing = 3
}
local state = State.Standby
local first
local last

function XTipManager.Add(tip)
    if not first then
        first = {
            cb = tip,
            next = nil
        }
        last = first
    else
        local next = {
            cb = tip,
            next = nil
        }
        last.next = next
        last = next
    end

    if state == State.Standby then
        XTipManager.Execute()
    end
end

function XTipManager.Execute()
    if first then
        local cb = first.cb
        first = first.next
        state = State.Playing
        cb()
    else
        state = State.Standby
    end
end

function XTipManager.Suspend()
    if state == State.Standby then
        state = State.Suspend
    end
end