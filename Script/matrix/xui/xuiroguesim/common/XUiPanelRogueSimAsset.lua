-- 资源栏
---@class XUiPanelRogueSimAsset : XUiNode
---@field private _Control XRogueSimControl
---@field BtnLv XUiComponent.XUiButton
local XUiPanelRogueSimAsset = XClass(XUiNode, "XUiPanelRogueSimAsset")

function XUiPanelRogueSimAsset:OnStart(resourceId, commodityIds, isShowLv)
    self.ResourceId = resourceId or 0
    self.CommodityIds = commodityIds or {}
    self.IsShowLv = isShowLv or false
    XUiHelper.RegisterClickEvent(self, self.BtnLv, self.OnBtnLvClick)
    ---@type XUiGridRogueSimCommodity[]
    self.GridCommodityList = {}
    self.PanelArrive.gameObject:SetActiveEx(false)
    self.PanelUpgrade.gameObject:SetActiveEx(false)
end

function XUiPanelRogueSimAsset:OnEnable()
    self:RefreshResource()
    self:RefreshCommodity()
    self:RefreshLv()
end

function XUiPanelRogueSimAsset:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_SELL,
        XEventId.EVENT_ROGUE_SIM_COMMODITY_CHANGE,
        XEventId.EVENT_ROGUE_SIM_BUFF_CHANGE,
        XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE,
        XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP,
        XEventId.EVENT_ROGUE_SIM_ADD_DATA_CHANGE,
    }
end

function XUiPanelRogueSimAsset:OnNotify(event, ...)
    if event == XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_SELL
        or event == XEventId.EVENT_ROGUE_SIM_COMMODITY_CHANGE
        or event == XEventId.EVENT_ROGUE_SIM_BUFF_CHANGE
        or event == XEventId.EVENT_ROGUE_SIM_ADD_DATA_CHANGE then
        self:RefreshCommodity()
    elseif event == XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE then
        self:RefreshResource()
        self:RefreshLvExp()
    elseif event == XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP then
        self:RefreshLv()
    end
end

function XUiPanelRogueSimAsset:RefreshResource()
    self.RImgGold:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(self.ResourceId))
    self.TxtNum.text = self._Control.ResourceSubControl:GetResourceOwnCount(self.ResourceId)
end

function XUiPanelRogueSimAsset:RefreshCommodity()
    -- 请求临时背包奖励时不刷新
    if self._Control.ResourceSubControl:GetIsTempBagReward() then
        return
    end
    for i = 1, 3 do
        local grid = self.GridCommodityList[i]
        if not grid then
            local go = self["BtnResource" .. i]
            grid = require("XUi/XUiRogueSim/Common/XUiGridRogueSimCommodity").New(go, self)
            self.GridCommodityList[i] = grid
        end
        grid:Open()
        local id = self.CommodityIds[i]
        if XTool.IsNumberValid(id) then
            grid:Refresh(id)
        else
            grid:Close()
        end
    end
end

function XUiPanelRogueSimAsset:RefreshLv()
    self.BtnLv.gameObject:SetActiveEx(self.IsShowLv)
    if not self.IsShowLv then
        return
    end
    -- 图标
    local id = XEnumConst.RogueSim.ResourceId.Exp
    self.BtnLv:SetRawImage(self._Control.ResourceSubControl:GetResourceIcon(id))
    -- 等级
    self.BtnLv:SetNameByGroup(1, self._Control:GetCurMainLevel())
    -- 经验
    self:RefreshLvExp()
end

function XUiPanelRogueSimAsset:RefreshLvExp()
    if not self.IsShowLv then
        return
    end
    local curLevel = self._Control:GetCurMainLevel()
    -- 经验
    if self._Control:CheckIsMaxLevel(curLevel) then
        self.BtnLv:SetNameByGroup(0, self._Control:GetClientConfig("MainMaxLevelDesc"))
        --self.PanelUpgrade.gameObject:SetActiveEx(false)
        --self.PanelArrive.gameObject:SetActiveEx(false)
    else
        local curExp, upExp = self._Control:GetCurExpAndLevelUpExp(curLevel)
        self.BtnLv:SetNameByGroup(0, string.format("%d/%d", curExp, upExp))
        -- 经验
        --local isExpEnough = curExp >= upExp
        -- 金币
        --local isGoldEnough = self._Control:CheckLevelUpGoldIsEnough(curLevel)
        -- 可升级
        --self.PanelUpgrade.gameObject:SetActiveEx(isExpEnough)
        -- 提示信息
        --self.PanelArrive.gameObject:SetActiveEx(isExpEnough)
        --self.PanelArriveExp.gameObject:SetActiveEx(isExpEnough and not isGoldEnough)
        --self.PanelArriveGold.gameObject:SetActiveEx(isExpEnough and isGoldEnough)
    end
end

function XUiPanelRogueSimAsset:OnBtnLvClick()
    self._Control:OnMainGridClick()
end

return XUiPanelRogueSimAsset
