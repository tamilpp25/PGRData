-- 起点格子
local XUiPanelTheatre4BaseGrid = require("XUi/XUiTheatre4/Game/Grid/XUiPanelTheatre4BaseGrid")
---@class XUiPanelTheatre4StartGrid : XUiPanelTheatre4BaseGrid
local XUiPanelTheatre4StartGrid = XClass(XUiPanelTheatre4BaseGrid, "XUiPanelTheatre4StartGrid")

function XUiPanelTheatre4StartGrid:OnStart()
    self:RegisterClick(handler(self, self.OnBtnGridClick))
    XUiHelper.RegisterClickEvent(self, self.BtnGold, self.OnBtnGoldClick)
end

function XUiPanelTheatre4StartGrid:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA,
    }
end

function XUiPanelTheatre4StartGrid:OnNotify(event, ...)
    if event == XEventId.EVENT_THEATRE4_UPDATE_ASSET_DATA then
        self:RefreshGoldNum(true)
        self:RefreshBloodNum()
    end
end

function XUiPanelTheatre4StartGrid:Refresh()
    XUiPanelTheatre4BaseGrid.Refresh(self)
    -- 起点图标
    local startIcon = self:GetGridIcon()
    if startIcon then
        self.RImgTypeIcon:SetRawImage(startIcon)
    end
    -- 金币图片
    local goldIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if goldIcon then
        self.RImgGold:SetRawImage(goldIcon)
    end
    self:RefreshGoldNum()
    -- 血量图片
    local hpIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Hp)
    if hpIcon then
        self.ImgBlood:SetSprite(hpIcon)
    end
    self:RefreshBloodNum()
end

-- 刷新金币数量
function XUiPanelTheatre4StartGrid:RefreshGoldNum(tween)
    if tween then
        local target = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
        XUiHelper.TweenLabelNumber(self, self.TxtGoldNum, target, 0.5)
    else
        self.TxtGoldNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
    end
end

-- 刷新血量数量
function XUiPanelTheatre4StartGrid:RefreshBloodNum()
    self.TxtBloodNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Hp)
end

function XUiPanelTheatre4StartGrid:OnBtnGoldClick()
    -- 打开金币详情
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", nil, XEnumConst.Theatre4.AssetType.Gold)
end

function XUiPanelTheatre4StartGrid:OnBtnGridClick()
    ---@type XUiTheatre4Game
    local luaUi = XLuaUiManager.GetTopLuaUi("UiTheatre4Game")
    if luaUi then
        self:SetSelected(true)
        luaUi:ShowStartCard(function()
            self:SetSelected(false)
        end)
    end
end

-- 播放格子动画
function XUiPanelTheatre4StartGrid:GetGridAnimName()
    return "PanelStartGridEnable"
end

return XUiPanelTheatre4StartGrid
