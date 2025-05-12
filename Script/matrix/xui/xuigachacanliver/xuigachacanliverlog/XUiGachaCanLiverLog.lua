---@class XUiGachaCanLiverLog: XLuaUi
---@field _Control XGachaCanLiverControl
local XUiGachaCanLiverLog = XLuaUiManager.Register(XLuaUi, 'UiGachaCanLiverLog')

local CurIndex = 1

local PanelDataDic =
{
    [1] = require("XUi/XUiGachaCanLiver/XUiGachaCanLiverLog/XUiPanelGachaCanLiverRewardLog"), -- 奖励详情
    [2] = require("XUi/XUiGachaCanLiver/XUiGachaCanLiverLog/XUiPanelGachaCanLiverRuleLog"), -- 基础规则
    [3] = require("XUi/XUiGachaCanLiver/XUiGachaCanLiverLog/XUiPanelGachaCanLiverDetailLog"), -- 掉落详情
    [4] = require("XUi/XUiGachaCanLiver/XUiGachaCanLiverLog/XUiPanelGachaCanLiverRecord") -- 研发记录
}

--region 生命周期

function XUiGachaCanLiverLog:OnAwake()
    self.PanelDic = {}
    self:InitButton()
    self:InitPanel()
end

function XUiGachaCanLiverLog:OnStart(gachaConfig, forceIndex)
    self.GachaConfig = gachaConfig
    CurIndex = forceIndex or CurIndex
end

function XUiGachaCanLiverLog:OnEnable()
    self.PanelTabTc:SelectIndex(CurIndex)
end
--endregion

--region 初始化
function XUiGachaCanLiverLog:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

function XUiGachaCanLiverLog:InitPanel()
    local tabBtns = {
        self.BtnTab1,
        self.BtnTab2,
        self.BtnTab3,
        self.BtnTab4,
        self.BtnTab5,
    }
    self.PanelTabTc:Init(tabBtns, function(index) self:OnBtnTabClick(index) end)
    for index, v in pairs(PanelDataDic) do
        local panelData = v.New(self["Panel"..index], self, self)
        self.PanelDic[index] = panelData
        panelData:Close()
    end
end
--endregion

--region 事件回调

function XUiGachaCanLiverLog:OnBtnTabClick(index)
    for i, panelData in pairs(self.PanelDic) do
        if i == index then
            panelData:Open()
            panelData:RefreshUiShow(self.GachaConfig)
        else
            panelData:Close()
        end
    end
    CurIndex = index
end

--endregion

return XUiGachaCanLiverLog