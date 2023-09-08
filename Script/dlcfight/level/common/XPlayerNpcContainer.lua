local XPlayerNpcContainer = XClass(nil, "XPlayerNpcContainer")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

---@param proxy StatusSyncFight.XFightScriptProxy
function XPlayerNpcContainer:Ctor(proxy)
    self._proxy = proxy
    self._localPlayerNpcId = nil ---运行脚本的主机玩家
    self._playerNpcList = {}
    self.PlayerNpcCreateCallback = nil ---@type fun(npc:number)
    self.PlayerNpcDestroyCallback = nil ---@type fun(npc:number)
end

function XPlayerNpcContainer:Init(createCallBackFunction, destroyCallbackFunction)
    self._localPlayerNpcId = self._proxy:GetLocalPlayerNpcId()
    self._playerNpcList = self._proxy:GetPlayerNpcList()
    self.PlayerNpcCreateCallback = createCallBackFunction
    self.PlayerNpcDestroyCallback = destroyCallbackFunction
    --由于初始化的时候可能已经有玩家进入了，这部分玩家的进入事件是没有被处理的，所以需要手动执行一次
    if self.PlayerNpcCreateCallback then
        for _, npc in pairs(self._playerNpcList) do
            self.PlayerNpcCreateCallback(npc)
        end
    end

    self._proxy:RegisterEvent(EWorldEvent.LevelCreateNpc)
    self._proxy:RegisterEvent(EWorldEvent.LevelDestroyNpc)
end

---@param event number
---@param args table
function XPlayerNpcContainer:HandleEvent(event, args)
    if event == EWorldEvent.LevelCreateNpc then
        if args.IsPlayer then
            local npc = args.NpcId
            self._playerNpcList[#self._playerNpcList + 1] = npc
            if self.PlayerNpcCreateCallback then
                self.PlayerNpcCreateCallback(npc)
            end
        end
    elseif event == EWorldEvent.LevelDestroyNpc then
        if args.IsPlayer then
            local npc = args.NpcId
            for i = #self._playerNpcList, 1, -1 do
                if self._playerNpcList[i] == npc then
                    table.remove(self._playerNpcList, i)
                end
            end
            if self.PlayerNpcDestroyCallback then
                self.PlayerNpcDestroyCallback(npc)
            end
        end
    end
end

---@return table<number, number> @<index, npcId>
function XPlayerNpcContainer:GetPlayerNpcList()
    return self._playerNpcList
end

return XPlayerNpcContainer