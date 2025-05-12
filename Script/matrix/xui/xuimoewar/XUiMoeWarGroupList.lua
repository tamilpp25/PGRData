local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XUiMoeWarGroupList = XLuaUiManager.Register(XLuaUi, "UiMoeWarGroupList")
local XUiGridGroupList = require("XUi/XUiMoeWar/ChildItem/XUiGridGroupList")
local tableInsert = table.insert
local GROUP_COUNT = 3
function XUiMoeWarGroupList:OnStart()
    self:InitUi()
end

function XUiMoeWarGroupList:OnEnable()
end

function XUiMoeWarGroupList:OnDisable()

end

function XUiMoeWarGroupList:OnGetEvents()
    return {
        XEventId.EVENT_MOE_WAR_UPDATE,
        XEventId.EVENT_MOE_WAR_ACTIVITY_END,
    }
end

function XUiMoeWarGroupList:OnNotify(event, ...)
    if event == XEventId.EVENT_MOE_WAR_UPDATE then
        local match = XDataCenter.MoeWarManager.GetCurMatch()
        if match:GetSessionId() ~= XMoeWarConfig.SessionType.Game24In12 then
            self:Close()
        end
    elseif event == XEventId.EVENT_MOE_WAR_ACTIVITY_END then
        XUiManager.TipText("MoeWarActivityOver")
        XLuaUiManager.RunMain()
    end
end

function XUiMoeWarGroupList:PlayGroupAnimation()

end

function XUiMoeWarGroupList:RegisterButtonEvent()
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnBack.CallBack = function() XLuaUiManager.Close("UiMoeWarGroupList") end
end

function XUiMoeWarGroupList:InitGroups()
    self.GridGroupList = {}
    for i = 1, GROUP_COUNT do
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridGroup, self.PanelGroup)
        local grid = XUiGridGroupList.New(obj, i)
        tableInsert(self.GridGroupList, grid)
    end
    self.GridGroup.gameObject:SetActiveEx(false)
end

function XUiMoeWarGroupList:InitUi()
	if self.PanelSpecialTool then
		self.ActInfo = XDataCenter.MoeWarManager.GetActivityInfo()
		self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
		self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
		for i = 1,#self.ActInfo.CurrencyId do
			XDataCenter.ItemManager.AddCountUpdateListener(self.ActInfo.CurrencyId[i], function()
					self.AssetActivityPanel:Refresh(self.ActInfo.CurrencyId)
				end, self.AssetActivityPanel)
		end
	end
    --self.TxtTip.text = CS.XTextManager.GetText("MoeWarGroupListTip")
    self:RegisterButtonEvent()
    self:InitGroups()
end



return XUiMoeWarGroupList