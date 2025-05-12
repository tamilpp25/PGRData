local XUiTheatre3SettlementProficiency = require("XUi/XUiTheatre3/Settlement/XUiTheatre3SettlementProficiency")
local XUiTheatre3SettlementCollection = require("XUi/XUiTheatre3/Settlement/XUiTheatre3SettlementCollection")
local XUiTheatre3SettlementMember = require("XUi/XUiTheatre3/Settlement/XUiTheatre3SettlementMember")
local XUiTheatre3SettlementCensus = require("XUi/XUiTheatre3/Settlement/XUiTheatre3SettlementCensus")

local Page = { Collection = 1, Member = 2, Proficiency = 3, Census = 4 }

---@class XUiTheatre3Settlement : XLuaUi 冒险结算
---@field _Control XTheatre3Control
local XUiTheatre3Settlement = XLuaUiManager.Register(XLuaUi, "UiTheatre3Settlement")

function XUiTheatre3Settlement:OnAwake()
    self.BtnLast.CallBack = handler(self, self.OnBtnLast)
    self.BtnNext.CallBack = handler(self, self.OnBtnNext)
    self.BtnFinish.CallBack = handler(self, self.OnFinish)
end

function XUiTheatre3Settlement:OnStart()
    self._Page = Page.Collection
    self._Data = self._Control:GetSettleData()
    self._IsNeedShowProficiency = not XTool.IsTableEmpty(self._Data.BattleCharacters)
    self:InitCompnent()
    self:UpdateView()
end

function XUiTheatre3Settlement:OnDestroy()

end

function XUiTheatre3Settlement:InitCompnent()
    ---@type XUiTheatre3SettlementCollection
    self._Collection = XUiTheatre3SettlementCollection.New(self.PanelStep1, self)
    ---@type XUiTheatre3SettlementMember
    self._Member = XUiTheatre3SettlementMember.New(self.PanelStep2, self)
    ---@type XUiTheatre3SettlementProficiency
    self._Proficiency = XUiTheatre3SettlementProficiency.New(self.PanelStep3, self)
    ---@type XUiTheatre3SettlementCensus
    self._Census = XUiTheatre3SettlementCensus.New(self.PanelStep4, self)

    if self.TopControlWhite then
        self.TopControlWhite.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3Settlement:OnBtnBack()
    self._Control:InitAdventureData()
    self:Close()
end

function XUiTheatre3Settlement:OnBtnNext()
    if self._Page == Page.Proficiency then
        self._Proficiency:StopCharacterExpAnim()
    end
    if not self._IsNeedShowProficiency and self._Page == Page.Member then
        self._Page = self._Page + 2
    else
        self._Page = self._Page + 1
    end
    if self._Page == Page.Member then
        self:PlayAnimation("PanelStep1To2")
    elseif self._Page == Page.Proficiency then
        self:PlayAnimation("PanelStep2To3", function() 
            self._Proficiency:PlayCharacterExpAnim()
        end)
    elseif self._Page == Page.Census then
        if self._IsNeedShowProficiency then
            self:PlayAnimation("PanelStep3To4")
        else
            self:PlayAnimation("PanelStep2To4")
        end
    end
    self:UpdateView()
end

function XUiTheatre3Settlement:OnBtnLast()
    if self._Page == Page.Proficiency then
        self._Proficiency:StopCharacterExpAnim()
    end
    if not self._IsNeedShowProficiency and self._Page == Page.Census then
        self._Page = self._Page - 2
    else
        self._Page = self._Page - 1
    end
    if self._Page == Page.Collection then
        self:PlayAnimation("PanelStep2To1")
    elseif self._Page == Page.Member then
        if self._IsNeedShowProficiency then
            self:PlayAnimation("PanelStep3To2")
        else
            self:PlayAnimation("PanelStep4To2")
        end
    elseif self._Page == Page.Proficiency then
        self:PlayAnimation("PanelStep4To3")
    end
    self:UpdateView()
end

function XUiTheatre3Settlement:UpdateView()
    self.BtnLast.gameObject:SetActiveEx(self._Page ~= Page.Collection)
    self.BtnNext.gameObject:SetActiveEx(self._Page ~= Page.Census)
    self.BtnFinish.gameObject:SetActiveEx(self._Page == Page.Census)
end

function XUiTheatre3Settlement:OnFinish()
    self._Control:UpdateSettleRoleExp()
    self._Control:InitAdventureData()
    self:Close()
end

return XUiTheatre3Settlement