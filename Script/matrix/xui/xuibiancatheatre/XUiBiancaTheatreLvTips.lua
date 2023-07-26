--肉鸽玩法二期等级提升提示
local XUiBiancaTheatreLvTips = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreLvTips")

function XUiBiancaTheatreLvTips:OnAwake()
    self:InitUiObject()
    self:AddClickListener()
end

function XUiBiancaTheatreLvTips:OnStart(callback, beforeLevel, afterLevel)
    if self.BeforeLevelTxt then
        self.BeforeLevelTxt.text = beforeLevel
    end

    if self.AfterLevelTxt then
        self.AfterLevelTxt.text = afterLevel
    end

    self.CallBack = callback
end

function XUiBiancaTheatreLvTips:InitUiObject()
    self.BeforeLevelTxt = self.Transform:Find("SafeAreaContentPane/PanelLv/Text"):GetComponent("Text")
    self.AfterLevelTxt = self.Transform:Find("SafeAreaContentPane/PanelLv/Text2"):GetComponent("Text")
end

function XUiBiancaTheatreLvTips:AddClickListener()
    self:RegisterClickEvent(self.BtnClose, function ()
        self:Close()
        if self.CallBack then
            self.CallBack()
        end
    end)
end
