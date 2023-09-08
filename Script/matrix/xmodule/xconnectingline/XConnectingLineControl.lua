---@class XConnectingLineControl : XControl
---@field private _Model XConnectingLineModel
local XConnectingLineControl = XClass(XControl, "XConnectingLineControl")
function XConnectingLineControl:OnInit()
    --初始化内部变量
end

function XConnectingLineControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XConnectingLineControl:RemoveAgencyEvent()

end

function XConnectingLineControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

---@return XConnectingLineGame
function XConnectingLineControl:GetGame()
    return self._Model:GetGame()
end

---@return XConnectingLineGame
function XConnectingLineControl:InitGame(gridX, gridY)
    self._Model:InitGame(gridX, gridY)
    local game = self._Model:GetGame()
    return game
end

---@param game XConnectingLineGame
function XConnectingLineControl:TestExecute(game, operationList)
    local OPERATION_TYPE = XEnumConst.CONNECTING_LINE.OPERATION_TYPE
    local gridSize = game:GetGridSize()
    for i = 1, #operationList do
        local data = operationList[i]

        ---@type XConnectingLineOperation
        local operation = require("XModule/XConnectingLine/XEntity/XConnectingLineOperation").New()
        operation:SetPos(data.X * gridSize.X - gridSize.X / 2, data.Y * gridSize.Y - gridSize.Y / 2)
        if i == 1 then
            operation.Type = OPERATION_TYPE.POINT_DOWN
        elseif i == #operationList then
            operation.Type = OPERATION_TYPE.POINT_UP
        else
            operation.Type = OPERATION_TYPE.POINT_MOVE
        end
        game:Execute(operation)
        game:LogBuffer()
    end
end

function XConnectingLineControl:GetUiData()
    return self._Model:GetUiData()
end

function XConnectingLineControl:Update()
    self._Model:Update()
end

function XConnectingLineControl:UpdateTime()
    self._Model:UpdateTime()
end

function XConnectingLineControl:UpdateGameInfo()
    self._Model:UpdateGameInfo()
end

function XConnectingLineControl:InitStage()
    self._Model:InitStage()
end

function XConnectingLineControl:IsLastStage()
    return self._Model:IsLastStage()
end

function XConnectingLineControl:IsGameInit()
    return self._Model:GetGame() and true or false
end

function XConnectingLineControl:IsActivityOpen()
    return self._Model:IsActivityOpen()
end

function XConnectingLineControl:IsCanStartGame()
    local itemId = XDataCenter.ItemManager.ItemId.ConnectingLine
    local itemAmount = XDataCenter.ItemManager.GetCount(itemId)
    local uiData = self:GetUiData()
    local needAmount = uiData.NeedMoney
    return itemAmount > needAmount
end

function XConnectingLineControl:GetStatus()
    return self._Model:GetStatus()
end

function XConnectingLineControl:RequestFinish()
    XNetwork.Call("ConnectingLineStageCompleteRequest", {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local data = res.ConnectingLineData
        if data.Status ~= XEnumConst.CONNECTING_LINE.STAGE_STATUS.COMPLETE then
            XLog.Error("[XConnectingLineControl] request finish success, but status is incorrect", data.Status)
        end
        self._Model:SetDataFromServer(data)
    end)
end

function XConnectingLineControl:RequestStartGame()
    XNetwork.Call("ConnectingLineStageUnlockRequest", {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local data = res.ConnectingLineData
        if data.Status ~= XEnumConst.CONNECTING_LINE.STAGE_STATUS.UNLOCK then
            XLog.Error("[XConnectingLineControl] request unlock success, but status is incorrect", data.Status)
        end
        self._Model:SetDataFromServer(data)
    end)
end

function XConnectingLineControl:RequestReward()
    XNetwork.Call("ConnectingLineStageAwardRequest", {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local data = res.ConnectingLineData
        if self._Model:IsLastStage() then
            if data.Status ~= XEnumConst.CONNECTING_LINE.STAGE_STATUS.REWARD then
                XLog.Error("[XConnectingLineControl] request reward success, but status is incorrect", data.Status)
            end
        else
            if data.Status ~= XEnumConst.CONNECTING_LINE.STAGE_STATUS.LOCK then
                XLog.Error("[XConnectingLineControl] request reward success, but status is incorrect", data.Status)
            end
        end
        self._Model:SetDataFromServer(data, false)

        if res.AwardList then
            XUiManager.OpenUiObtain(res.AwardList, nil, function()
                -- 延迟更新界面
                XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_UPDATE)
            end)
        end
    end)
end

function XConnectingLineControl:InitBubble()
    self._Model:InitBubble()
end

function XConnectingLineControl:GetUiDataReward()
    self._Model:UpdateRewardText()
    return self._Model:GetUiDataReward()
end

return XConnectingLineControl