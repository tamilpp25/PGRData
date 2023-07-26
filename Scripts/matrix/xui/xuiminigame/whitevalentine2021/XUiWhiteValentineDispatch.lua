-- 白色情人节约会活动派遣界面
local XUiWhiteValentineDispatch = XLuaUiManager.Register(XLuaUi, "UiWhitedayReady")

function XUiWhiteValentineDispatch:OnAwake()
    XTool.InitUiObject(self)
    self.BtnClose.CallBack = function() self:OnBtnClose() end
    self.BtnStart.CallBack = function() self:OnBtnStart() end
end

function XUiWhiteValentineDispatch:OnStart(place)
    self.Place = place
    self.AttrActive.gameObject:SetActiveEx(false)
    if self.AttrInActive then self.AttrInActive.gameObject:SetActiveEx(true) end
    self.ImgAttrIcon:SetRawImage(self.Place:GetEventAttrIcon())
    if self.ImgInActiveAttrIcon then self.ImgInActiveAttrIcon:SetRawImage(self.Place:GetEventAttrIcon()) end
    self.GridChara.gameObject:SetActiveEx(false)
    self:InitPanels()
    self:RefreshPanel()
end

function XUiWhiteValentineDispatch:InitPanels()
    self:InitPanelPlace()
    self:InitPanelReward()
    self:InitPanelChara()
end

function XUiWhiteValentineDispatch:InitPanelPlace()
    local XPanelPlace = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenDispatchPanelPlace")
    self.PlacePanel = XPanelPlace.New(self, self.PanelLeft, self.Place)
end

function XUiWhiteValentineDispatch:InitPanelReward()
    local XPanelReward = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenDispatchPanelReward")
    self.RewardPanel = XPanelReward.New(self, self.PanelReward, self.Place)
end

function XUiWhiteValentineDispatch:InitPanelChara()
    local XPanelChara = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenDispatchMemberDynamicTable")
    self.CharaPanel = XPanelChara.New(self, self.MemberList)
end

function XUiWhiteValentineDispatch:SetDispatchChara(chara)
    self.RewardPanel:RefreshChara(chara)
    local isAttrActive = chara:GetAttrType() == self.Place:GetEventAttrType()
    self.AttrActive.gameObject:SetActiveEx(isAttrActive)
    if self.AttrInActive then self.AttrInActive.gameObject:SetActiveEx(not isAttrActive) end
    self.DispatchChara = chara
end

function XUiWhiteValentineDispatch:RefreshPanel()
    self.CharaPanel:UpdateData(self.Place:GetEventAttrType())
end

function XUiWhiteValentineDispatch:OnBtnClose()
    self:Close()
end

function XUiWhiteValentineDispatch:OnBtnStart()
    if self.DispatchChara then
        XDataCenter.WhiteValentineManager.CharaDispatch(self.Place, self.DispatchChara, function() self:Close() end)
    else
        XUiManager.TipMsg(CS.XTextManager.GetText("WhiteValentineNoSelectChara"))
    end
end