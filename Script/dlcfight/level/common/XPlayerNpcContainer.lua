local XPlayerNpcContainer = XClass(nil, "XPlayerNpcContainer")

---@param proxy StatusSyncFight.XFightScriptProxy
function XPlayerNpcContainer:Ctor(proxy)
    self._proxy = proxy
    self._localPlayerNpcId = nil ---本端玩家Npc的UUID
    self._playerNpcList = {}
    self.PlayerNpcCreateCallback = nil ---@type fun(npc:number)
    self.PlayerNpcDestroyCallback = nil ---@type fun(npc:number)
end

---初始化玩家Npc容器，通过传入回调来获取创建/销毁的指定玩家Npc及其在容器中的索引(index)
---@param createCallBack @新玩家Npc创建时触发的回调
---@param destroyCallback @已有玩家Npc销毁时触发的回调
function XPlayerNpcContainer:Init(createCallBack, destroyCallback)
    self._localPlayerNpcId = self._proxy:GetLocalPlayerNpcId()
    self._playerNpcList = self._proxy:GetPlayerNpcList()
    self.PlayerNpcCreateCallback = createCallBack
    self.PlayerNpcDestroyCallback = destroyCallback
    --由于初始化的时候可能已经有玩家进入了，这部分玩家的进入事件是没有被处理的，所以需要手动执行一次
    if self.PlayerNpcCreateCallback then
        for index, npc in pairs(self._playerNpcList) do
            self.PlayerNpcCreateCallback(npc, index)
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
            local index = #self._playerNpcList + 1
            self._playerNpcList[index] = npc
            if self.PlayerNpcCreateCallback then
                self.PlayerNpcCreateCallback(npc, index)
            end
        end
    elseif event == EWorldEvent.LevelDestroyNpc then
        if args.IsPlayer then
            local npc = args.NpcId
            local index = 0
            for i = #self._playerNpcList, 1, -1 do
                if self._playerNpcList[i] == npc then
                    table.remove(self._playerNpcList, i)
                    index = i
                end
            end
            if self.PlayerNpcDestroyCallback and index > 0 then
                self.PlayerNpcDestroyCallback(npc)
            end
        end
    end
end

---获取玩家Npc列表的引用，注意该列表只允许读取不允许修改！
---@return table<number, number> @<index, npcId>
function XPlayerNpcContainer:GetPlayerNpcList()
    return self._playerNpcList
end

return XPlayerNpcContainer