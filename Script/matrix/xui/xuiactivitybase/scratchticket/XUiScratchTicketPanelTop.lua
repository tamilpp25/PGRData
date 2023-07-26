-- 刮刮乐PanelTop面板控件
local XUiScratchTicketPanelTop = XClass(nil, "XUiScratchTicketPanelTop")

function XUiScratchTicketPanelTop:Ctor(uiGameObject, controller, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Controller = controller
    self.RootUi = rootUi
    self:InitPanel()
end

function XUiScratchTicketPanelTop:InitPanel()
    self:InitTicket()
    self:InitTime()
    self:InitBtns()
end

--=============
--初始化门票数量显示
--=============
function XUiScratchTicketPanelTop:InitTicket()
    local XUiCommonAsset = require("XUi/XUiCommon/XUiCommonAsset")
    local AssetPanel = require("XUi/XUiCommon/XUiCommonAssetPanel")
    local AssetsList = {}
    local assetItem1 = {
        ShowType = XUiCommonAsset.ShowType.BagItem,
        ItemId = self.Controller:GetSpendItemId(),
    }
    table.insert(AssetsList, assetItem1)
    self.AssetPanel = AssetPanel.New(self.GameObject, AssetsList)
end

function XUiScratchTicketPanelTop:InitTime()
    self:SetTimer()
end

function XUiScratchTicketPanelTop:SetTimer()
    if self.Timer then return end
    self.Timer = XScheduleManager.ScheduleForever(function()
            if not self.RootUi:Exist() then return end
            local endTimeSecond = self.Controller:GetEndTime()
            local now = XTime.GetServerNowTimestamp()
            local leftTime = endTimeSecond - now
            self.TxtTime.text = CS.XTextManager.GetText("ScratchTicketActivityLeftTime") .. XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
            if leftTime <= 0 then
                self.RootUi:OnGameEnd()
            end
        end, 0)
end

function XUiScratchTicketPanelTop:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiScratchTicketPanelTop:InitBtns()
    self.BtnHelp.CallBack = function() self:OnClickBtnHelp() end
end

function XUiScratchTicketPanelTop:OnClickBtnHelp()
    XUiManager.ShowHelpTip("ScratchTicketHelp")
end

function XUiScratchTicketPanelTop:OnDestroy()
    self:StopTimer()
end

return XUiScratchTicketPanelTop