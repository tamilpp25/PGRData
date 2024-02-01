--- 幻影崩岳boss战测试关
local XLevel9999 = XDlcScriptManager.RegLevelLogicScript(9999, "XLevel9999")
local Tool = require("Level/Common/XLevelTools")

---@param proxy StatusSyncFight.XFightScriptProxy
function XLevel9999:Ctor(proxy)
    self._proxy = proxy

    self._bossBornPos = { 
    {x = 60, y = 1.95, z = 60},
    {x = 60, y = 1.95, z = 60},
    {x = 60, y = 1.95, z = 60},
     }
    self._bossBornRot = { x = 0, y = 180, z = 0 }
end

function XLevel9999:Init()
    self:InitNpc()
end

function XLevel9999:InitNpc()
    --生成怪物
    for _, v in ipairs(self._bossBornPos) do
        self._proxy:GenerateNpc(1002, ENpcCampType.Camp2, v, self._bossBornRot)
    end
    
    XLog.Debug("<color=#F0D800>[SceneHunt01]</color>召唤npc完成")
end


return XLevel9999