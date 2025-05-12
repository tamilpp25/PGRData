local XUiTheatre4SkillGird = require("XUi/XUiTheatre4/System/SkillTree/XUiTheatre4SkillGird")
local XUiTheatre4SkillTips = require("XUi/XUiTheatre4/System/SkillTree/XUiTheatre4SkillTips")

---@class XUiTheatre4Skill : XLuaUi
---@field PanelSpecialTool UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field GirdSkillPanel UnityEngine.RectTransform
---@field PanelTips UnityEngine.RectTransform
---@field BtnLeft XUiComponent.XUiButton
---@field BtnRight XUiComponent.XUiButton
---@field ListTab XUiButtonGroup
---@field BtnRed XUiComponent.XUiButton
---@field BtnYellow XUiComponent.XUiButton
---@field BtnBlud XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field ImageRedIcon UnityEngine.RectTransform
---@field ImageYellowIcon UnityEngine.RectTransform
---@field ImageBlueIcon UnityEngine.RectTransform
---@field _Control XTheatre4Control
local XUiTheatre4Skill = XLuaUiManager.Register(XLuaUi, "UiTheatre4Skill")

function XUiTheatre4Skill:OnAwake()
    ---@type XUiTheatre4SkillTips
    self._TipsUi = nil
    ---@type XUiTheatre4SkillGird
    self._SkillPanel = nil
    ---@type XUiComponent.XUiButton[]
    self._BtnListTabList = nil
    self._CurrentIndex = nil
    self._DynamicTable = nil
    ---@type XUiTheatre4SkillGird
    self._CurrentSelectPanel = nil
    ---@type XTheatre4TechEntity
    self._CurrentSelectEntity = nil
end

-- region 生命周期

function XUiTheatre4Skill:OnStart()
    self._TipsUi = XUiTheatre4SkillTips.New(self.PanelTips, self)
    self._SkillPanel = XUiTheatre4SkillGird.New(self.GirdSkillPanel, self)
    self._BtnListTabList = {
        self.BtnRed,
        self.BtnYellow,
        self.BtnBlud,
        self.BtnScience,
    }

    self._TipsUi:Close()
    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiTheatre4Skill:OnEnable()
    self:_RefreshTabRedDot()
    self:_RefreshPanel()
    self:_RegisterListeners()
end

function XUiTheatre4Skill:OnDisable()
    self:_RemoveListeners()
end

-- endregion

---@param entity XTheatre4TechEntity
---@param grid XUiTheatre4SkillGird
function XUiTheatre4Skill:ShowTipsPanel(entity, grid, isSpecial)
    if entity and not entity:IsEmpty() then
        if self._CurrentSelectEntity and self._CurrentSelectEntity:IsEquals(entity) then
            self:CloseTipsPanel()
        else
            self._TipsUi:Open()
            self._TipsUi:Refresh(entity, isSpecial)
            self.BtnClose.gameObject:SetActiveEx(true)
            self._CurrentSelectPanel = grid
            self._CurrentSelectEntity = entity
        end
    end
end

function XUiTheatre4Skill:CloseTipsPanel()
    self._TipsUi:Close()
    if self._CurrentSelectPanel then
        self._CurrentSelectPanel:CancelSelect()
        self._CurrentSelectPanel = nil
    end
    self._CurrentSelectEntity = nil
    self.BtnClose.gameObject:SetActiveEx(false)
end

function XUiTheatre4Skill:OnRefresh()
    self:_RefreshGridRedDot()
    self:_RefreshTabRedDot()
    self:_RefreshSkillPanel(self._CurrentIndex or 1)
    self:CloseTipsPanel()
end

-- region 按钮事件

function XUiTheatre4Skill:OnBtnLeftClick()
    self.ListTab:SelectIndex(self._CurrentIndex - 1)
end

function XUiTheatre4Skill:OnBtnRightClick()
    self.ListTab:SelectIndex(self._CurrentIndex + 1)
end

function XUiTheatre4Skill:OnBtnCloseClick()
    self:CloseTipsPanel()
end

function XUiTheatre4Skill:OnListTabClick(index)
    self:_ScrollTo(index)
end

function XUiTheatre4Skill:OpenItemDetail()
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", XDataCenter.ItemManager.ItemId.Theatre4TechTreeCoin)
end

-- endregion

-- region 私有方法

function XUiTheatre4Skill:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick, true)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick, true)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self.ListTab:Init(self._BtnListTabList, Handler(self, self.OnListTabClick))
end

function XUiTheatre4Skill:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_TECHS_REFRESH, self.OnRefresh, self)
end

function XUiTheatre4Skill:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_TECHS_REFRESH, self.OnRefresh, self)
end

function XUiTheatre4Skill:_RefreshHandOffTag()
    self.BtnLeft.gameObject:SetActiveEx(self._CurrentIndex - 1 >= 1)
    self.BtnRight.gameObject:SetActiveEx(self._CurrentIndex + 1 <= 3)
end

function XUiTheatre4Skill:_RefreshPanel()
    self.ListTab:SelectIndex(self._CurrentIndex or 1)
end

function XUiTheatre4Skill:_RefreshSkillPanel(index)
    local entitys = self._Control.SystemControl:GetTechEntitysByType(index)

    self._SkillPanel:Refresh(entitys)
end

function XUiTheatre4Skill:_RefreshImage()
    self.RawImage.gameObject:SetActiveEx(false)
    self.RawImage.gameObject:SetActiveEx(true)
    if self._CurrentIndex == 1 then
        self:_RefreshIcon(XEnumConst.Theatre4.TreeTalent.War)
    elseif self._CurrentIndex == 2 then
        self:_RefreshIcon(XEnumConst.Theatre4.TreeTalent.Economics)
    elseif self._CurrentIndex == 3 then
        self:_RefreshIcon(XEnumConst.Theatre4.TreeTalent.Technology)
    elseif self._CurrentIndex == 4 then
        self:_RefreshIcon(XEnumConst.Theatre4.TreeTalent.Awake)
    end
end

function XUiTheatre4Skill:_RefreshIcon(talentType)
    if talentType == XEnumConst.Theatre4.TreeTalent.War then
        self.ImageRedIcon.gameObject:SetActiveEx(true)
        self.ImageBlueIcon.gameObject:SetActiveEx(false)
        self.ImageYellowIcon.gameObject:SetActiveEx(false)
        self.ImageGreenIcon.gameObject:SetActiveEx(false)
    elseif talentType == XEnumConst.Theatre4.TreeTalent.Economics then
        self.ImageRedIcon.gameObject:SetActiveEx(false)
        self.ImageBlueIcon.gameObject:SetActiveEx(false)
        self.ImageYellowIcon.gameObject:SetActiveEx(true)
        self.ImageGreenIcon.gameObject:SetActiveEx(false)
    elseif talentType == XEnumConst.Theatre4.TreeTalent.Technology then
        self.ImageRedIcon.gameObject:SetActiveEx(false)
        self.ImageBlueIcon.gameObject:SetActiveEx(true)
        self.ImageYellowIcon.gameObject:SetActiveEx(false)
        self.ImageGreenIcon.gameObject:SetActiveEx(false)
    elseif talentType == XEnumConst.Theatre4.TreeTalent.Awake then
        self.ImageRedIcon.gameObject:SetActiveEx(false)
        self.ImageBlueIcon.gameObject:SetActiveEx(false)
        self.ImageYellowIcon.gameObject:SetActiveEx(false)
        self.ImageGreenIcon.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre4Skill:_RefreshTabRedDot()
    self.BtnRed:ShowReddot(self._Control.SystemControl:CheckRedTechRedDot())
    self.BtnYellow:ShowReddot(self._Control.SystemControl:CheckYellowTechRedDot())
    self.BtnBlud:ShowReddot(self._Control.SystemControl:CheckBlueTechRedDot())
    self.BtnScience:ShowReddot(self._Control.SystemControl:CheckAwakeTechRedDot())
end

function XUiTheatre4Skill:_RefreshGridRedDot()
    if self._CurrentSelectPanel then
        self._CurrentSelectPanel:RefreshRedDot()
    end
end

function XUiTheatre4Skill:_ScrollTo(index)
    if self._CurrentIndex ~= index then
        self._CurrentIndex = index
        self:_RefreshHandOffTag()
        self:_RefreshSkillPanel(index)
        self:_RefreshImage()
        self:CloseTipsPanel()
        self:_PlayAnimation()
    end
end

function XUiTheatre4Skill:_InitUi()
    XUiHelper.NewPanelActivityAssetSafe({
        XDataCenter.ItemManager.ItemId.Theatre4TechTreeCoin,
    }, self.PanelSpecialTool, self, nil, Handler(self, self.OpenItemDetail))
end

function XUiTheatre4Skill:_PlayAnimation()
    self:PlayAnimationWithMask("BtnQiehuan")
end

-- endregion

return XUiTheatre4Skill
