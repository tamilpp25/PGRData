local XUiPanelArea = require("XUi/XUiMission/XUiPanelArea")
local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
--关卡详情界面
local XUiAreaWarStageDetail = XLuaUiManager.Register(XLuaUi, "UiAreaWarStageDetail")

function XUiAreaWarStageDetail:OnAwake()
    local closeFunc = handler(self, self.Close)
    for i = 1, 5 do
        local btnClose = self["BtnCloseMask" .. i]
        if btnClose then
            btnClose.CallBack = closeFunc
        end
    end
    
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(
            {
                XDataCenter.ItemManager.ItemId.AreaWarCoin,
                XDataCenter.ItemManager.ItemId.AreaWarActionPoint
            },
            handler(self, self.UpdateAssets),
            self.AssetActivityPanel
    )
end

function XUiAreaWarStageDetail:OnStart(isQuest, ...)
    local panel

    self.PanelSpecial.gameObject:SetActiveEx(isQuest)
    self.PanelFight.gameObject:SetActiveEx(not isQuest)
    if isQuest then
        panel = require("XUi/XUiAreaWar/XUiPanel/XUiPanelAreaWarQuestDetail").New(self.PanelSpecial, self, ...)
    else
        panel = require("XUi/XUiAreaWar/XUiPanel/XUiPanelAreaWarBlockDetail").New(self.PanelFight, self, ...)
    end
    ---@type XUiNode
    self.PanelDetail = panel
    if self.BtnCloseMask5 then
        self.BtnCloseMask5.gameObject:SetActiveEx(isQuest)
    end
    self.PanelDetail:Open()
end

function XUiAreaWarStageDetail:OnEnable()
    self:UpdateAssets()
end

function XUiAreaWarStageDetail:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE
    }
end

function XUiAreaWarStageDetail:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_BLOCK_STATUS_CHANGE then
        self:UpdateView()
    end
end

function XUiAreaWarStageDetail:UpdateView()
    self.PanelDetail:UpdateView()
end

function XUiAreaWarStageDetail:UpdateAssets()
    self.AssetActivityPanel:Refresh(
            {
                XDataCenter.ItemManager.ItemId.AreaWarCoin,
                XDataCenter.ItemManager.ItemId.AreaWarActionPoint
            },
            {
                XDataCenter.ItemManager.ItemId.AreaWarActionPoint
            }
    )
end