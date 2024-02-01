local XUiFubenBossSingleModeBossDetailGrid = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleModeTip/XUiFubenBossSingleModeBossDetailGrid")

---@class XUiFubenBossSingleModeBossDetail : XLuaUi
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BossList UnityEngine.RectTransform
---@field PanelScoreContent UnityEngine.RectTransform
---@field GridBoss UnityEngine.RectTransform
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleModeBossDetail = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleModeBossDetail")

function XUiFubenBossSingleModeBossDetail:OnAwake()
    ---@type XUiFubenBossSingleModeBossDetailGrid[]
    self._GridBossUiList = {}
    self:_RegisterButtonClicks()
end

function XUiFubenBossSingleModeBossDetail:OnStart(bossIdList)
    for i, bossId in pairs(bossIdList) do
        local grid = XUiHelper.Instantiate(self.GridBoss, self.PanelScoreContent)

        self._GridBossUiList[i] = XUiFubenBossSingleModeBossDetailGrid.New(grid, self, bossId)
    end

    self.GridBoss.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleModeBossDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close, true)
end

return XUiFubenBossSingleModeBossDetail
