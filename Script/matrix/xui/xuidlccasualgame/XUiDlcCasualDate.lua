---@class XUiDlcCasualDate : XLuaUi
---@field BtnClose XUiComponent.XUiButton
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field PanelDetail UnityEngine.RectTransform
---@field GridPlayer UnityEngine.RectTransform
---@field _Control XDlcCasualControl
local XUiDlcCasualDate = XLuaUiManager.Register(XLuaUi, "UiDlcCasualDate")
local XUiDlcCasualDateGrid = require("XUi/XUiDlcCasualGame/XUiDlcCasualDateGrid")

function XUiDlcCasualDate:Ctor()
    ---@type XUiDlcCasualDateGrid[]
    self._PlayerList = {}
end

function XUiDlcCasualDate:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
end

---@param result XDlcCasualResult
function XUiDlcCasualDate:OnStart(result)
    local players = result:GetPlayerResultList()
    XUiHelper.RefreshCustomizedList(self.PanelDetail, self.GridPlayer, #players, function(index, grid)
        self._PlayerList[index] = XUiDlcCasualDateGrid.New(grid, self, players[index], result:IsPersonNewRecord())
    end)
end

function XUiDlcCasualDate:OnDestroy()
    self._PlayerList = nil
end

return XUiDlcCasualDate