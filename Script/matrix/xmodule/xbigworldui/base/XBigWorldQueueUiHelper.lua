---@class XBigWorldQueueUiHelper 队列打开UI
---@field _Queue XQueue
local XBigWorldQueueUiHelper = XClass(nil, "XBigWorldQueueUiHelper")

local tableRemove = table.remove
local tablePack = table.pack
local tableUnpack = table.unpack

local UiNameIndex = 0

function XBigWorldQueueUiHelper:Ctor()
    self._Queue = XQueue.New()
    self._DataPool = {}
    --队列中正在展示的Ui
    self._ShowingUiName = false
    
    self._OnUiDestroyCb = handler(self, self.OnUiDestroy)
end

function XBigWorldQueueUiHelper:Open(uiName, ...)
    --队列为空，直接打开UI
    if self._Queue:IsEmpty() and not self._ShowingUiName then
        self._ShowingUiName = uiName
        XLuaUiManager.Open(uiName, ...)
        self:StartListenEvent()
        return
    end
    local data = self:GetQueueData(uiName, ...)
    self._Queue:Enqueue(data)
end

function XBigWorldQueueUiHelper:DoOpenNext()
    if self._Queue:IsEmpty() then
        self._ShowingUiName = false
        self:StopListenEvent()
        return
    end
    ---@type XUiManager
    local instance = CS.XUiManager.Instance
    if instance.ClosingAll then
        self._Queue:Clear()
        self:StopListenEvent()
        self._ShowingUiName = false
        return
    end
   local data = self._Queue:Dequeue()
    self._ShowingUiName = data.UiName
    if data.Args then
        XLuaUiManager.Open(data.UiName, tableUnpack(data.Args))
    else
        XLuaUiManager.Open(data.UiName)
    end
end

---@param evt string 事件Id
---@param args System.Object[] 参数
function XBigWorldQueueUiHelper:OnUiDestroy(evt, args)
    if not args or args.Length <= 0 then
        return
    end
    local ui = args[UiNameIndex]
    if not ui or not ui.UiData then
        return
    end
    local uiName = ui.UiData.UiName
    if uiName ~= self._ShowingUiName then
        return
    end
    self:DoOpenNext()
end

function XBigWorldQueueUiHelper:GetQueueData(uiName, ...)
    local data
    if #self._DataPool > 0 then
        data = tableRemove(self._DataPool, #self._DataPool)
    else
        data = {}
    end
    data.UiName = uiName
    local n = select("#", ...)
    data.Args = n > 0 and tablePack(...) or nil
    return data
end

function XBigWorldQueueUiHelper:RecycleQueueData(data)
    self._DataPool[#self._DataPool + 1] = data
end

function XBigWorldQueueUiHelper:StartListenEvent()
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_DESTROY, self._OnUiDestroyCb)
end

function XBigWorldQueueUiHelper:StopListenEvent()
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_DESTROY, self._OnUiDestroyCb)
end

return XBigWorldQueueUiHelper