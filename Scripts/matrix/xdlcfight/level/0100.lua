---V2.9魔方嘉年华
local XLevelScript100 = XDlcScriptManager.RegLevelScript(100, "XLevelScript100")
local FuncSet = CS.StatusSyncFight.XFightScriptFuncs

local _cameraResRefTable = {
    fightStart =  "fightStart",
}


function XLevelScript100:GetCameraResRefTable()
    return _cameraResRefTable
end

--脚本构造函数
---@param proxy StatusSyncFight.XScriptLuaProxy
function XLevelScript100:Ctor(proxy)
    self._proxy = proxy
end

--初始化
function XLevelScript100:Init()

    self._localPlayerNpcId = FuncSet.GetLocalPlayerNpcId()
--[[
    -- 注册虚拟相机属性
    local testVCamAgent = XDlcScriptManager.GetSceneObjectScript(25) ---@type XSObjVCamAgent
    testVCamAgent:SetCallBackBeforeActivated(function()
        testVCamAgent:SetActorIds(0, -1, -1)
        testVCamAgent:SetCallBackBeforeActivated(nil)
    end)

    self._proxy:RegisterNpcEvent(EScriptEvent.NpcCastSkill, self._localPlayerNpcId)
    self._proxy:RegisterNpcEvent(EScriptEvent.NpcExitSkill, self._localPlayerNpcId)
]]
end

--每帧执行
---@param dt number @ delta time
function XLevelScript100:Update(dt)


end

--事件响应
---@param eventType number
---@param eventArgs userdata
function XLevelScript100:HandleEvent(eventType, eventArgs)
    self.Super.HandleEvent(self, eventType, eventArgs)
end

--脚本终止
function XLevelScript100:Terminate()

end

--资源加载完成时完成
function XLevelScript100:OnResLoadComplete()

end

return XLevelScript100