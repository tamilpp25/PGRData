local XTempleGameControl = require("XModule/XTemple/XTempleGameControl")

---@class XTempleCoupleGameControl:XTempleGameControl
---@field private _Model XTempleModel
---@field private _MainControl XTempleControl
local XTempleCoupleGameControl = XClass(XTempleGameControl, "XTempleCoupleGameControl")

function XTempleCoupleGameControl:Ctor()
    self._ActionRecord = nil

    --if XMain.IsDebug then
    --    self._IsAutoSimulate = true
    --end
end

function XTempleCoupleGameControl:OnInit()
    XTempleGameControl.OnInit(self)
    XEventManager.AddEventListener(XEventId.EVENT_TEMPLE_ON_ACTION_CONFIRM, self._OnActionConfirm, self)
end

function XTempleCoupleGameControl:OnRelease()
    XTempleGameControl.OnRelease(self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TEMPLE_ON_ACTION_CONFIRM, self._OnActionConfirm, self)
end

function XTempleCoupleGameControl:_OnActionConfirm()
    if self._Game:IsSimulating() then
        return
    end
    self:SimulateCoupleStageRecord()
end

function XTempleCoupleGameControl:StartGame(...)
    XTempleGameControl.StartGame(self, ...)
    self._ActionRecord = XTool.CloneEx(self._Model:GetActionRecord(self._StageId), true)
    math.randomseed(os.time())
    self:SimulateCoupleStageRecord()
end

function XTempleCoupleGameControl:SimulateCoupleStageRecord()
    local actionRecords = self._ActionRecord
    local round = self._Game:GetOptionRound()
    local characterId = self:GetCurrentCharacterId()
    if not characterId then
        return
    end
    if actionRecords[round] then
        local smartPutDown = self._Model:GetNpcSmartPutDownBlock(characterId)
        if self._IsAutoSimulate then
            smartPutDown = 100
        end

        -- 交换两个回合
        if round < #actionRecords then
            local toExchange = math.random(round, #actionRecords)

            if actionRecords[toExchange] then
                actionRecords[round], actionRecords[toExchange] = actionRecords[toExchange], actionRecords[round]
            end

            if XMain.IsWindowsEditor then
                XLog.Error("随机交换了:" .. actionRecords[round].BlockId .. "/" .. actionRecords[toExchange].BlockId)
            end
        end

        -- put on wrong place
        if smartPutDown < math.random(0, 100) then
            actionRecords[round].X = math.random(1, self._Game:GetMap():GetColumnAmount())
            actionRecords[round].Y = math.random(1, self._Game:GetMap():GetRowAmount())
        end
        if actionRecords[round].BlockId == 0 then
            XLog.Error("当前纪录为跳过，故重新随机")
            self:SimulateCoupleStageRecord()
            return
        end
        -- 清除玩家操作，防止连续点击问题
        self._Game:ClearActionQueue()
        self._Game:SimulateActionRecordFromData(actionRecords, round, round, false)

        if self._IsAutoSimulate then
            XScheduleManager.ScheduleOnce(function()
                if XLuaUiManager.IsUiShow("UiTempleBattleCouple") then
                    if self._Game then
                        self:OnClickConfirm()
                    end
                end
            end, 300)
        end
    end
end

function XTempleCoupleGameControl:IsCoupleChapter()
    return true
end

return XTempleCoupleGameControl
