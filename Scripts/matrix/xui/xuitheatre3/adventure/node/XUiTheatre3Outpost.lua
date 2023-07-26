local XPanelTheatre3EventDialogue = require("XUi/XUiTheatre3/Adventure/Node/XPanelTheatre3EventDialogue")
local XPanelTheatre3EventOptions = require("XUi/XUiTheatre3/Adventure/Node/XPanelTheatre3EventOptions")
local XPanelTheatre3EventReward = require("XUi/XUiTheatre3/Adventure/Node/XPanelTheatre3EventReward")
local XPanelTheatre3EventShop = require("XUi/XUiTheatre3/Adventure/Node/XPanelTheatre3EventShop")

---@class XUiTheatre3Outpost : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3Outpost = XLuaUiManager.Register(XLuaUi, "UiTheatre3Outpost")

function XUiTheatre3Outpost:OnAwake()
    self:AddBtnListener()
end

---@param slot XTheatre3NodeSlot
function XUiTheatre3Outpost:OnStart(slot)
    self:UpdateSlot(slot)
    self:InitUi()
end

function XUiTheatre3Outpost:OnEnable()
    self:PlayAnimationWithMask("AnimStartAuto")
    self:RefreshUi()
end

function XUiTheatre3Outpost:OnDestroy()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self._PanelAsset)
end

function XUiTheatre3Outpost:InitUi()
    self:InitPanelAsset()
    self:InitPanelDialogue()
    self:InitPanelReward()
    self:InitPanelOption()
    self:InitPanelShop()
end

function XUiTheatre3Outpost:RefreshUi()
    if self._CurSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Event) then
        if not self._EventCfg then
            XLog.Error(string.format("Error:Event配置不存在！EventId=%s,StepId=%s", self._CurSlot:GetEventId(), self._CurSlot:GetCurStepId()),
                    self._CurSlot)
            return
        end
        self:RefreshBg(self._EventCfg.BgAsset)
        self:RefreshPanelTitle(self._EventCfg.Title, self._EventCfg.TitleContent)
        self:RefreshPanelRole(self._EventCfg.RoleIcon, self._EventCfg.RoleName, self._EventCfg.RoleContent)
        
        self:RefreshPanelDialogue()
        self:RefreshPanelOption()
        self:RefreshPanelReward()
    elseif self._CurSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Shop) then
        self:RefreshPanelShop()
    end
end

--region Data
---@param slot XTheatre3NodeSlot
function XUiTheatre3Outpost:UpdateSlot(slot)
    self._CurSlot = slot
    self._EventCfg = self._Control:GetEventCfgByIdAndStep(self._CurSlot:GetEventId(), self._CurSlot:GetCurStepId())
    self._ShopCfg = XTool.IsNumberValid(self._CurSlot:GetShopId()) and self._Control:GetShopNodeCfgById(self._CurSlot:GetShopId())
end
--endregion

--region Ui - PanelAsset
function XUiTheatre3Outpost:InitPanelAsset()
    self._PanelAsset = XUiHelper.NewPanelActivityAsset(
            {XEnumConst.THEATRE3.Theatre3InnerCoin,},
            self.PanelSpecialTool,
            nil,
            function()
                XLuaUiManager.Open("UiTheatre3Tips", XEnumConst.THEATRE3.Theatre3InnerCoin)
            end)
    self.PanelEnergyChange.gameObject:SetActiveEx(false)
    self.PanelEnergyChange2.gameObject:SetActiveEx(false)
end
--endregion

--region Ui - Bg
function XUiTheatre3Outpost:RefreshBg(bgUrl)
    if string.IsNilOrEmpty(bgUrl) then
        return
    end
    self.RImgBg:SetRawImage(bgUrl)
end
--endregion

--region Ui - PanelTitle
function XUiTheatre3Outpost:RefreshPanelTitle(title, titleContent)
    self.PanelTitle.gameObject:SetActiveEx(true)
    if not string.IsNilOrEmpty(title) then
        self.TxtTitle.text = title
    else
        self.TxtTitle.gameObject:SetActiveEx(false)
    end
    if not string.IsNilOrEmpty(titleContent) then
        self.TxtTitleContent.text = titleContent
    else
        self.TxtTitleContent.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - PanelRole
function XUiTheatre3Outpost:RefreshPanelRole(roleIcon, roleName, roleContent)
    if not string.IsNilOrEmpty(roleIcon) then
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(roleIcon)
    else
        self.RImgRole.gameObject:SetActiveEx(false)
    end
    if not string.IsNilOrEmpty(roleName) then
        self.TxtRoleName.text = roleName
        self.TxtRoleContent.text = roleContent
        self.PanelRole.gameObject:SetActiveEx(true)
    else
        self.PanelRole.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - PanelDialogue
function XUiTheatre3Outpost:InitPanelDialogue()
    self.PanelComfirm.gameObject:SetActiveEx(true)
    ---@type XPanelTheatre3EventDialogue
    self._PanelDialogue = XPanelTheatre3EventDialogue.New(self.PanelComfirm, self)
    self._PanelDialogue:Close()
end

function XUiTheatre3Outpost:RefreshPanelDialogue()
    if not (self._EventCfg.Type == XEnumConst.THEATRE3.EventStepType.Dialogue) and
            not (self._EventCfg.Type == XEnumConst.THEATRE3.EventStepType.WorkShop)
    then
        return
    end
    if XTool.IsNumberValid(self._EventCfg.StepRewardItemType) then
        return
    end
    self._PanelDialogue:Open()
    self._PanelDialogue:Refresh(self._EventCfg, self._CurSlot)
end
--endregion

--region Ui - PanelOption
function XUiTheatre3Outpost:InitPanelOption()
    self.PanelOption.gameObject:SetActiveEx(true)
    ---@type XPanelTheatre3EventOptions
    self._PanelOption = XPanelTheatre3EventOptions.New(self.PanelOption, self)
    self._PanelOption:Close()
end

function XUiTheatre3Outpost:RefreshPanelOption()
    if not (self._EventCfg.Type == XEnumConst.THEATRE3.EventStepType.Options) then
        return
    end
    self._PanelOption:Open()
    self._PanelOption:Refresh(self._EventCfg, self._CurSlot)
end
--endregion

--region Ui - PanelReward
function XUiTheatre3Outpost:InitPanelReward()
    self.PanelReward.gameObject:SetActiveEx(true)
    ---@type XPanelTheatre3EventDialogue
    self._PanelReward = XPanelTheatre3EventReward.New(self.PanelReward, self)
    self._PanelReward:Close()
end

function XUiTheatre3Outpost:RefreshPanelReward()
    if not self._CurSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Event) then
        return
    end
    if not XTool.IsNumberValid(self._EventCfg.StepRewardItemType) then
        return
    end
    self._PanelReward:Open()
    self._PanelReward:Refresh(self._EventCfg, self._CurSlot)
end
--endregion

--region Ui - PanelShop
function XUiTheatre3Outpost:InitPanelShop()
    ---@type XPanelTheatre3EventShop
    self._PanelShop = XPanelTheatre3EventShop.New(self.PanelShop, self)
    self._PanelShop:Close()
end

function XUiTheatre3Outpost:RefreshPanelShop()
    if not self._CurSlot:CheckType(XEnumConst.THEATRE3.NodeSlotType.Shop) then
        return
    end
    if not self._ShopCfg then
        XLog.Error(string.format("Error:ShopNode配置不存在！ShopId=%s", self._CurSlot:GetShopId()), self._CurSlot)
        return
    end

    self.PanelReward.gameObject:SetActiveEx(false)
    self:RefreshBg(self._ShopCfg.BgAsset)
    self:RefreshPanelRole(self._ShopCfg.RoleIcon, self._ShopCfg.RoleName, self._ShopCfg.RoleContent)
    if self._CurSlot:CheckIsShopEndBuy() then
        self:_RefreshEndBuy()
    else
        self:_RefreshBuy()
    end
end

function XUiTheatre3Outpost:_RefreshBuy()
    self:RefreshPanelTitle()
    self.PanelShop.gameObject:SetActiveEx(true)
    self._PanelShop:Open()
    self._PanelShop:Refresh(self._ShopCfg, self._CurSlot)
end

function XUiTheatre3Outpost:_RefreshEndBuy()
    self:RefreshPanelTitle(self._ShopCfg.TitleContent, self._ShopCfg.Desc)
    self._PanelDialogue:Open()
    self._PanelDialogue:RefreshOnlyDialogue(self._ShopCfg.EndDesc, self._ShopCfg.EndComfirmText)
end
--endregion

--region Ui - BtnListener
function XUiTheatre3Outpost:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiTheatre3Outpost:OnBtnBackClick()
    ---@type XTheatre3Agency
    local theatre3Agency = XMVCA:GetAgency(ModuleId.XTheatre3)
    if theatre3Agency:CheckAndOpenSettle() then
        return
    else
        self._Control:CheckAndOpenAdventureNextStep(true, true)
    end
end

function XUiTheatre3Outpost:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--endregion

return XUiTheatre3Outpost