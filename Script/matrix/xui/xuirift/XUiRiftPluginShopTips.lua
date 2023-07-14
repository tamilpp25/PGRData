local XUiRiftPluginGrid = require("XUi/XUiRift/Grid/XUiRiftPluginGrid")

local XUiRiftPluginShopTips = XLuaUiManager.Register(XLuaUi, "UiRiftPluginShopTips")

function XUiRiftPluginShopTips:OnAwake()
	self:AddListener()
	self.PluginGrid = XUiRiftPluginGrid.New(self.GridRiftPlugin)
end

function XUiRiftPluginShopTips:OnStart(goodData)
    self.Plugin = XDataCenter.RiftManager.GetPlugin(goodData.PluginId)
    self.PluginGrid:Refresh(self.Plugin)
    self.TxtName.text = self.Plugin:GetName()
    self.TxtDescription.text = self.Plugin:GetDesc()

    -- 补正类型
    local fixTypeList = self.Plugin:GetAttrFixTypeList()
    for i = 1, XRiftConfig.PluginMaxFixCnt do
        local isShow = #fixTypeList >= i
        self["PanelAddition" .. i].gameObject:SetActiveEx(isShow)
        if isShow then
            self["TxtAddition" .. i].text = fixTypeList[i]
        end
    end

    -- 补正效果
    local fixDesc = XUiHelper.GetText("FubenHackBuffDetailTitle") .. "："
    local attrFixList = self.Plugin:GetEffectStringList()
    for index, attrFix in ipairs(attrFixList) do
    	if index == 1 then 
        	fixDesc = fixDesc .. attrFix.Name
    	else
        	fixDesc = fixDesc .. "、" .. attrFix.Name
    	end
    end
    self.TxtWorldDesc.text = fixDesc
end

function XUiRiftPluginShopTips:AddListener()
	self.BtnBack.CallBack = function()
        self:Close()
    end
	self.BtnOk.CallBack = function()
        self:Close()
    end
end