local XUiChannelItem = XClass(nil, "XUiChannelItem")

function XUiChannelItem:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.ChannelIndex = 0
    self.ClickFunc = nil
    self.GuildDormManager = XDataCenter.GuildDormManager
    XUiHelper.RegisterClickEvent(self, self.BtnSelf, self.OnBtnSelfClicked)
end

function XUiChannelItem:SetData(channelIndex, clickFunc)
    self.ChannelIndex = channelIndex
    self.ClickFunc = clickFunc
    local currentRommId = self.GuildDormManager.GetCurrentRoomId()
    local currentChannelMemberCount = self.GuildDormManager.GetMemberCountByChannelIndex(channelIndex)
    self.BtnSelf:SetNameByGroup(0, string.format("%s/%s", currentChannelMemberCount
        , XGuildDormConfig.GetChannelMemberCountByRoomId(currentRommId)))
    self.BtnSelf:SetNameByGroup(1, XUiHelper.GetText("GuildDormChannelName" .. channelIndex))
    self:SetSelectTagActive(XDataCenter.GuildDormManager.GetCurrentChannelIndex())
    self.ImgState:SetSprite(XGuildDormConfig.GetChannelMemberCountIcon(currentChannelMemberCount))
end

function XUiChannelItem:OnBtnSelfClicked()
    self.ClickFunc(self.ChannelIndex)
end

function XUiChannelItem:SetSelectTagActive(selectIndex)
    self.PanelTag.gameObject:SetActiveEx(selectIndex == self.ChannelIndex)
end

function XUiChannelItem:SetSelectStatus(selectIndex)
    if selectIndex == self.ChannelIndex then
        self.BtnSelf:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnSelf:SetButtonState(CS.UiButtonState.Normal)
    end
end

--######################## XUiGuildDormPanelChannel ########################
local XUiGuildDormPanelChannel = XClass(XSignalData, "XUiGuildDormPanelChannel")

function XUiGuildDormPanelChannel:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.GuildDormManager = XDataCenter.GuildDormManager
    self.ChannelItemDic = {}
    self.CurrentSelectChannelIndex = self.GuildDormManager.GetCurrentChannelIndex()
    self:RegisterUiEvents()
end

function XUiGuildDormPanelChannel:Open()
    self.GameObject:SetActiveEx(true)
    self:RefreshChannelItems()
end

function XUiGuildDormPanelChannel:RefreshChannelItems()
    local channelCount = XGuildDormConfig.GetChannelCountByRoomId(self.GuildDormManager.GetCurrentRoomId())
    self.TxtTotalCount.text = channelCount
    local item
    local clickFunc = handler(self, self.OnBtnChannelClicked)
    XUiHelper.RefreshCustomizedList(self.ChannelList, self.GridChannelItem, channelCount, function(index, child)
        item = self.ChannelItemDic[index]
        if item == nil then
            item = XUiChannelItem.New(child)
            self.ChannelItemDic[index] = item
        end
        item:SetData(index, clickFunc)
    end)
end

function XUiGuildDormPanelChannel:Close()
    self.GameObject:SetActiveEx(false)
    self:EmitSignal("ClosePanelChannel")
end

--######################## 私有方法 ########################
function XUiGuildDormPanelChannel:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnChannelSure, self.OnBtnSureClicked)
end

function XUiGuildDormPanelChannel:OnBtnSureClicked()
    -- 相同频道
    if self.CurrentSelectChannelIndex == self.GuildDormManager.GetCurrentChannelIndex() then
        XUiManager.TipErrorWithKey("GuildDormSwitchSameChannelTip")
        return
    end
    -- 二次确认
    local channelName = XUiHelper.GetText("GuildDormChannelName" .. self.CurrentSelectChannelIndex)
    XLuaUiManager.Open("UiDialog", XUiHelper.GetText("GuildDormSwitchChannelTitle", channelName)
        , XUiHelper.GetText("GuildDormSwitchChannelContent"), XUiManager.DialogType.Normal, nil, function()
        self:EmitSignal("OpenBlackScreen")
        self.GuildDormManager.SwitchChannel(self.CurrentSelectChannelIndex, function(success)
            if success then
                self:EmitSignal("OnSwitchChannelSuccess", self.CurrentSelectChannelIndex)
                self:Close()
            else
                self.GuildDormManager.RequestRoomChannelData(function()
                    self:RefreshChannelItems()
                end)
            end
            self:EmitSignal("CloseBlackScreen")
        end)
    end)
end

function XUiGuildDormPanelChannel:OnBtnChannelClicked(index)
    for _, item in pairs(self.ChannelItemDic) do
        item:SetSelectStatus(index)
    end
    self.CurrentSelectChannelIndex = index
end

return XUiGuildDormPanelChannel