local XUiArenaBattleRoleTips = XLuaUiManager.Register(XLuaUi,"UiArenaBattleRoleTips")
local XUiGridArenaAreaRecord = require("XUi/XUiArenaTeamRank/ArenaSelfRank/XUiGridArenaAreaRecord")
function XUiArenaBattleRoleTips:OnStart(data)
    self.Data = data
    self.BtnTanchuangCloseBig.CallBack = function() 
        self:Close()
    end
    self.GridAreaRecord = {}
    self:Init()
end

function XUiArenaBattleRoleTips:Init()
    for i,record in pairs(self.Data) do
        if not self.GridAreaRecord[i] then
            local obj = CS.UnityEngine.GameObject.Instantiate(self.GridBattleRole,self.PanelBattleRole)
            self.GridAreaRecord[i] = XUiGridArenaAreaRecord.New(obj)
        end
        self.GridAreaRecord[i]:Refresh(record)
    end
    self.GridBattleRole.gameObject:SetActiveEx(false)
end


return XUiArenaBattleRoleTips