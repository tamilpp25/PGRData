local XDynamicTableIrregular = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableIrregular")
---@class XUiSkyGardenShoppingStreetPopupNewsLogs : XLuaUi
---@field BtnClose XUiComponent.XUiButton
---@field PanelTop UnityEngine.RectTransform
---@field ListNews UnityEngine.RectTransform
---@field GridNews UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetPopupNewsLogs = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetPopupNewsLogs")

local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetNewsListGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetNewsListGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetPopupNewsLogs:OnAwake()
    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetPopupNewsLogs:OnStart(...)
    local newses = self._Control:GetStageNews()
    local grapevines = self._Control:GetStageGrapevines()
    local currentTurn = self._Control:GetRunRound()
    self._ShowInfos = {}

    for i = 1, currentTurn do
        local newsData = newses[i]
        local grapevinesData = grapevines[i]
        if newsData or grapevinesData then
            local msg = {}
            if newsData then
                table.insert(msg, {
                    Id = newsData.NewsId,
                    IsNews = true,
                    IsExpired = newsData.Turn ~= currentTurn,
                    Data = newsData,
                })
            end
            if grapevinesData then
                table.insert(msg, {
                    Id = grapevinesData.GrapevineId,
                    IsNews = false,
                    IsExpired = grapevinesData.Turn ~= currentTurn,
                    Data = grapevinesData,
                })
            end
            table.insert(self._ShowInfos, { Msgs = msg, Turn = i, })
        end
    end
    
    self.DynamicTable = XDynamicTableIrregular.New(self.ListNews)
    self.DynamicTable:SetProxy("XUiSkyGardenShoppingStreetNewsListGrid", XUiSkyGardenShoppingStreetNewsListGrid, self.GridNews.gameObject, self)
    self.DynamicTable:SetDelegate(self)

    self.DynamicTable:SetDataSource(self._ShowInfos)
    self.DynamicTable:ReloadDataSync(#self._ShowInfos)

    self.GridNews.gameObject:SetActive(false)
end

function XUiSkyGardenShoppingStreetPopupNewsLogs:GetProxyType()
    return "XUiSkyGardenShoppingStreetNewsListGrid"
end

function XUiSkyGardenShoppingStreetPopupNewsLogs:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid.RootUi = self
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index, self._ShowInfos[index])
    end
end
--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetPopupNewsLogs:OnBtnCloseClick()
    self:Close()
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetPopupNewsLogs:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
end
--endregion

return XUiSkyGardenShoppingStreetPopupNewsLogs
