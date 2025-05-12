local XUiGridArenaAreaRecord = require("XUi/XUiArenaNew/XUiArenaBattleRoleTips/XUiGridArenaAreaRecord")

---@class XUiArenaBattleRoleTips : XLuaUi
---@field _Control XArenaControl
local XUiArenaBattleRoleTips = XLuaUiManager.Register(XLuaUi, "UiArenaBattleRoleTips")

function XUiArenaBattleRoleTips:OnStart(data)
    self._Data = data
    ---@type XUiGridArenaAreaRecord[]
    self._GridAreaRecord = {}

    self:_Init()
    self:_RegisterButtonClicks()
end

function XUiArenaBattleRoleTips:_RegisterButtonClicks()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close, true)
end

function XUiArenaBattleRoleTips:_Init()
    for i, record in pairs(self._Data) do
        if not self._GridAreaRecord[i] then
            local obj = XUiHelper.Instantiate(self.GridBattleRole, self.PanelBattleRole)
            self._GridAreaRecord[i] = XUiGridArenaAreaRecord.New(obj, self)
        end

        self._GridAreaRecord[i]:Refresh(record)
    end
    
    self.GridBattleRole.gameObject:SetActiveEx(false)
end

return XUiArenaBattleRoleTips
