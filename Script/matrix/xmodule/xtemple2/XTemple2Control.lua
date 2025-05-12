local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")

---@class XTemple2Control : XControl
---@field private _Model XTemple2Model
local XTemple2Control = XClass(XControl, "XTemple2Control")
function XTemple2Control:OnInit()
    ---@type XTemple2EditorControl
    self._EditorControl = nil
    ---@type XTemple2EditorBlockControl
    self._EditorBlockControl = nil
    ---@type XTemple2GameControl
    self._GameControl = nil
end

function XTemple2Control:OnRelease()
    XMVCA.XTemple2:ClearRequesting()
end

function XTemple2Control:AddAgencyEvent()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:CheckTime()
    end, 10 * XScheduleManager.SECOND, 0)
end

function XTemple2Control:RemoveAgencyEvent()
    XScheduleManager.UnSchedule(self._Timer)
end

---@return XTemple2EditorControl
function XTemple2Control:GetEditorControl()
    if not self._EditorControl then
        self._EditorControl = self:AddSubControl(require("XModule/XTemple2/XTemple2EditorControl"))
    end
    return self._EditorControl
end

function XTemple2Control:GetEditorBlockControl()
    if not self._EditorBlockControl then
        self._EditorBlockControl = self:AddSubControl(require("XModule/XTemple2/Editor/XTemple2EditorBlockControl"))
    end
    return self._EditorBlockControl
end

---@return XTemple2GameControl
function XTemple2Control:GetGameControl()
    if not self._GameControl then
        self._GameControl = self:AddSubControl(require("XModule/XTemple2/XTemple2GameControl"))
    end
    return self._GameControl
end

---@return XTemple2SystemControl
function XTemple2Control:GetSystemControl()
    if not self._SystemControl then
        self._SystemControl = self:AddSubControl(require("XModule/XTemple2/XTemple2SystemControl"))
    end
    return self._SystemControl
end

function XTemple2Control:CheckTime()
    local remainTime = self._Model:GetRemainTime()
    if remainTime == 0 then
        self:CloseThisModule()
    end
end

function XTemple2Control:CloseThisModule()
    XLuaUiManager.RunMain()
    XUiManager.TipText("ActivityMainLineEnd")
end

function XTemple2Control:OpenGame(stageId, npcId, isReplay)
    if not stageId then
        XLog.Error("[XTemple2Control] 打开游戏时, 不存在stageId")
        return
    end
    if not npcId then
        XLog.Error("[XTemple2Control] 打开游戏时, 不存在npcId")
        return
    end

    local record = self._Model:GetStageRecordOngoing()
    local mapId = stageId
    if record then
        if record.MapId and record.MapId ~= 0 then
            mapId = record.MapId
        else
            XLog.Error("[XTemple2Control] 已实装mapId, 对应随机关卡功能, 但目前记录还不存在mapId")
        end
    end

    local gameControl = self:GetGameControl()
    gameControl:SetSelectedStage({
        StageId = stageId,
        MapId = mapId,
        Seed = record and record.StartTime,
        NpcId = record and record.CharacterId or npcId
    })
    if record then
        gameControl:RestoreRecord(record)
    end
    if not isReplay then
        XLuaUiManager.Open("UiTemple2Game")
    end

    self._Model:SetCurrentGameStageId(stageId)
end

function XTemple2Control:GetTaskReward4Show()
    local rewardId = self._Model:GetRewardId()
    if not rewardId then
        return {}
    end
    return XRewardManager.GetRewardList(rewardId) or {}
end

function XTemple2Control:ClearCurrentGameStageId()
    self._Model:SetCurrentGameStageId(false)
end

function XTemple2Control:OpenShop()
    local shopId = XTemple2Enum.SHOP_ID
    XShopManager.GetShopInfo(shopId, function()
        local shopTimeInfo = XShopManager.GetShopTimeInfo(shopId)
        if shopTimeInfo then
            local leftTime = shopTimeInfo.ClosedLeftTime
            if leftTime > 0 then
                XLuaUiManager.Open("UiTemple2Shop")
                return
            end
        end
        XUiManager.TipText("CommonShopClosedTips")
    end)
end

return XTemple2Control