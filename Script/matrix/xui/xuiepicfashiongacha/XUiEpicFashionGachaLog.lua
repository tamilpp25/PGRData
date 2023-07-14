local XUiEpicFashionGachaLog = XLuaUiManager.Register(XLuaUi, "UiEpicFashionGachaLog")
local CurIndex = 1

local PanelDataDic = 
{
    [1] = require("XUi/XUiEpicFashionGacha/Grid/XUiPanelReward"), -- 奖励详情
    [2] = require("XUi/XUiEpicFashionGacha/Grid/XUiPanelRule"), -- 基础规则
    [3] = require("XUi/XUiEpicFashionGacha/Grid/XUiPanelDetail"), -- 掉落详情
    [4] = require("XUi/XUiEpicFashionGacha/Grid/XUiPanelRecord") -- 研发记录
}

function XUiEpicFashionGachaLog:OnAwake()
    self.PanelDic = {}
    self:InitButton()
    self:InitPanel()
end

function XUiEpicFashionGachaLog:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

function XUiEpicFashionGachaLog:InitPanel()
    local tabBtns = { 
        self.BtnTab1, 
        self.BtnTab2, 
        self.BtnTab3, 
        self.BtnTab4, 
        self.BtnTab5, 
    }
    self.PanelTabTc:Init(tabBtns, function(index) self:OnBtnTabClick(index) end)
    for index, v in pairs(PanelDataDic) do
        local panelData = v.New(self["Panel"..index], self)
        self.PanelDic[index] = panelData
    end
end

function XUiEpicFashionGachaLog:OnStart(gachaConfig, forceIndex)
    self.GachaConfig = gachaConfig
    CurIndex = forceIndex or CurIndex
end

function XUiEpicFashionGachaLog:OnEnable()
    self.PanelTabTc:SelectIndex(CurIndex)
end

function XUiEpicFashionGachaLog:OnBtnTabClick(index)
    for i, panelData in pairs(self.PanelDic) do
        if i == index then
            panelData:Show()
            panelData:RefreshUiShow(self.GachaConfig)
        else
            panelData:Hide()
        end
    end
    CurIndex = index
end
