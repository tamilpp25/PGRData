---@class XUiRogueSimLog: XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimLog = XLuaUiManager.Register(XLuaUi, "UiRogueSimLog")

function XUiRogueSimLog:OnAwake()
    -- 按钮类型
    self.BTN_TYPE = {
        NEWS = 1,   -- 传闻
        SELL = 2    -- 贸易记录
    }

    self.PanelNewsLog.gameObject:SetActiveEx(false)
    self.PanelSellLog.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiRogueSimLog:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd(true)
        end
    end)
    
    self.BtnGroup:SelectIndex(self.BTN_TYPE.NEWS)
end

function XUiRogueSimLog:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self:InitTabBtnGroup()
end

function XUiRogueSimLog:OnBtnBackClick()
    self:Close()
end

function XUiRogueSimLog:InitTabBtnGroup()
    local btns = { self.BtnNews, self.BtnSell }
    self.BtnGroup:Init(btns, function(index)
        self:OnBtnTabClick(index)
    end)
end

-- 按钮页签点击回调
function XUiRogueSimLog:OnBtnTabClick(index)
    if index == self.BTN_TYPE.NEWS then
        if self.UiPanelSellLog then
            self.UiPanelSellLog:Close()
        end
        self:OpenPanelNewsLog()
    elseif index == self.BTN_TYPE.SELL then
        if self.UiPanelNewsLog then
            self.UiPanelNewsLog:Close()
        end
        self:OpenPanelSellLog()
    end
    self:PlayAnimation("QieHuan")
end

-- 打开传闻记录面板
function XUiRogueSimLog:OpenPanelNewsLog()
    if not self.UiPanelNewsLog then
        ---@type XUiPanelRogueSimNewsLog
        self.UiPanelNewsLog = require("XUi/XUiRogueSim/Log/XUiPanelRogueSimNewsLog").New(self.PanelNewsLog, self)
    end
    self.UiPanelNewsLog:Open()
end

-- 打开销售记录面板
function XUiRogueSimLog:OpenPanelSellLog()
    if not self.UiPanelSellLog then
        ---@type XUiPanelRogueSimSellLog
        self.UiPanelSellLog = require("XUi/XUiRogueSim/Log/XUiPanelRogueSimSellLog").New(self.PanelSellLog, self)
    end
    self.UiPanelSellLog:Open()
end

return XUiRogueSimLog