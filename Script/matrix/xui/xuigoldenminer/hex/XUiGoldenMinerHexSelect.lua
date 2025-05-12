---@class XUiGoldenMinerHexSelect : XLuaUi
---@field _Control XGoldenMinerControl
local XUiGoldenMinerHexSelect = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerHexSelect")

function XUiGoldenMinerHexSelect:OnAwake()
    self:AddBtnListener()
end

function XUiGoldenMinerHexSelect:OnStart()
    self:InitTimes()
    self:InitHexList()
    self:InitTitleScore()
end

function XUiGoldenMinerHexSelect:OnEnable()
    self:UpdateHexList()
    self:UpdateTitleScore()
end

--region Activity - AutoClose
function XUiGoldenMinerHexSelect:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetCurActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEndTime()
            return
        end
    end, nil, 0)
end
--endregion

--region Ui - HexList
function XUiGoldenMinerHexSelect:InitHexList()
    self._SelectHexId = 0
    self._HexList = self._Control:GetMainDb():GetBeSelectHexList()
    ---@type XUiComponent.XUiButton[]
    self._GridHexList = {
        self.GridHex1,
        self.GridHex2,
        self.GridHex3,
    }
    self.PanelHexList:Init(self._GridHexList, handler(self, self.SelectHex))
    self.PanelHexList:SelectIndex(1)
end

function XUiGoldenMinerHexSelect:SelectHex(index)
    if self._SelectHexId == self._HexList[index] then
        return
    end
    self._SelectHexId = self._HexList[index]
end

function XUiGoldenMinerHexSelect:UpdateHexList()
    for index, grid in ipairs(self._GridHexList) do
        grid:SetNameByGroup(0, self._Control:GetCfgHexName(self._HexList[index]))
        grid:SetNameByGroup(1, XUiHelper.ConvertLineBreakSymbol(self._Control:GetCfgHexDesc(self._HexList[index])))
        grid:SetRawImage(self._Control:GetCfgHexIcon(self._HexList[index]))
    end
end
--endregion

--region Ui - TitleScore
function XUiGoldenMinerHexSelect:InitTitleScore()
    ---@type UnityEngine.UI.Text
    self.TextCurScore = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelResourcepoints/Txt01", "Text")
end

function XUiGoldenMinerHexSelect:UpdateTitleScore()
    if not self.TextCurScore then
        return
    end
    self.TextCurScore.text = XUiHelper.GetText("GoldenMinerPlayCurScore", self._Control:GetMainDb():GetStageScores())
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerHexSelect:AddBtnListener()
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientHelpKey())
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick)
    XUiHelper.RegisterClickEvent(self, self.Btn2, self.OnBtn2Click)
end

function XUiGoldenMinerHexSelect:OnBtnBackClick()
    self._Control:OpenGiveUpGameTip()
end

function XUiGoldenMinerHexSelect:OnBtnSelectClick()
    if not XTool.IsNumberValid(self._SelectHexId) then
        XUiManager.TipErrorWithKey("GoldenMinerPleaseSelectHex")
        return
    end
    self._Control:RequestGoldenMinerSelectHex(self._SelectHexId, function()
        self._Control:OpenGameUi()
    end)
end

function XUiGoldenMinerHexSelect:OnBtn2Click()
    XLuaUiManager.Open("UiGoldenMinerSuspend", nil, nil, true)
end
--endregion

return XUiGoldenMinerHexSelect