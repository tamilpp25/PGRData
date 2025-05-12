local XUiDlcMultiPlayerDataGridDetail = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerDataGridDetail")

---@class XUiDlcMultiPlayerData : XLuaUi
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field GridDetail UnityEngine.RectTransform
---@field PanelDetail UnityEngine.RectTransform
---@field _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerData = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerData")

function XUiDlcMultiPlayerData:Ctor()
    ---@type XUiDlcMultiPlayerDataGridDetail
    self._CatDetailUi = nil
    ---@type XUiDlcMultiPlayerDataGridDetail
    self._MouseDetailUi = nil
    ---@type XDlcMultiMouseHunterResult
    self._Result = nil
end

-- region 生命周期

function XUiDlcMultiPlayerData:OnAwake()
    self:_RegisterButtonClicks()
end

---@param result XDlcMultiMouseHunterResult
function XUiDlcMultiPlayerData:OnStart(result)
    self._Result = result
    self:_InitDetail()
end

-- endregion

-- region 按钮事件

function XUiDlcMultiPlayerData:OnBtnTanchuangCloseClick()
    self:Close()
end

function XUiDlcMultiPlayerData:OnBtnCloseClick()
    self:Close()
end

-- endregion

-- region 私有方法

function XUiDlcMultiPlayerData:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick, true)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
end

function XUiDlcMultiPlayerData:_InitDetail()
    if self._Result then
        local result = self._Result
        local detail = XUiHelper.Instantiate(self.GridDetail, self.PanelDetail)

        self._MouseDetailUi = XUiDlcMultiPlayerDataGridDetail.New(self.GridDetail, self, result:GetMouseCampResultList(),
            result:GetIsMouseCampWin(), false)
        self._CatDetailUi = XUiDlcMultiPlayerDataGridDetail.New(detail, self, result:GetCatCampResultList(),
            result:GetIsCatCampWin(), true)
    end
end

-- endregion

return XUiDlcMultiPlayerData
