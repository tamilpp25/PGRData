local XUiPanelGuideGainNow = require("XUi/XUiTheatre/FieldGuide/XUiPanelGuideGainNow")
local XUiPanelGuideGainField = require("XUi/XUiTheatre/FieldGuide/XUiPanelGuideGainField")
local XUiPanelGuideProp = require("XUi/XUiTheatre/FieldGuide/XUiPanelGuideProp")
local XUiPanelDetail = require("XUi/XUiTheatre/FieldGuide/XUiPanelDetail")

--肉鸽玩法图鉴和信物选择界面
local XUiTheatreFieldGuide = XLuaUiManager.Register(XLuaUi, "UiTheatreFieldGuide")

function XUiTheatreFieldGuide:OnAwake()
    XUiHelper.NewPanelActivityAsset(XDataCenter.TheatreManager.GetAssetItemIds(), self.PanelSpecialTool)
    self:AddListener()
end

--showFieldGuideIds：要显示的页签Id列表，默认全显示
--isShowUseBtn：是否显示道具的使用按钮，同时只显示已解锁的当前等级的信物
--selectTokenCb：选择信物回调
--defaultTabIndex：打开界面默认选中的页签
--powerId：增益图鉴的势力Id
--isHideBtnMainUi：是否隐藏返回主界面按钮
function XUiTheatreFieldGuide:OnStart(showFieldGuideIds, isShowUseBtn, selectTokenCb, defaultTabIndex, powerId, isHideBtnMainUi)
    local clickSkillCallback = handler(self, self.ShowSkillDetail)
    local clickItemCallback = handler(self, self.ShowItemDetail)
    local isCurSelectSkillFunc = handler(self, self.IsCurSelectSkill)
    local isCurSelectTokenFunc = handler(self, self.IsCurSelectToken)
    self.GuideGainNowPanel = XUiPanelGuideGainNow.New(self.PanelGuideGainNow, clickSkillCallback, isCurSelectSkillFunc)
    self.GuideGainFieldPanel = XUiPanelGuideGainField.New(self.PanelGuideGainField, clickSkillCallback, isCurSelectSkillFunc, powerId)
    self.GuidePropPanel = XUiPanelGuideProp.New(self.PanelGuideProp, clickItemCallback, isCurSelectTokenFunc, isShowUseBtn)
    self.DetailPanel = XUiPanelDetail.New(self.PanelDetail, isShowUseBtn, selectTokenCb)

    self:HidePanel()
    self:InitTabGroup(showFieldGuideIds, defaultTabIndex)
    self.BtnMainUi.gameObject:SetActiveEx(not isHideBtnMainUi)
end

function XUiTheatreFieldGuide:InitTabGroup(showFieldGuideIds, defaultTabIndex)
    self.TabGroup = {}
    self.FieldGuideIdList = XTheatreConfigs.GetTheatreFieldGuideIdList(showFieldGuideIds)
    for i, id in ipairs(self.FieldGuideIdList) do
        local btnTab = i == 1 and self.BtnTog or XUiHelper.Instantiate(self.BtnTog, self.TagBtnPanel)
        local name = XTheatreConfigs.GetTheatreFieldGuideName(id)
        btnTab:SetName(name)
        table.insert(self.TabGroup, btnTab)
        self:CheckRedPoint(i)
    end
    self.TabBtnGroup:Init(self.TabGroup, function(index) self:OnSelectToggle(index) end)
    self.TabBtnGroup:SelectIndex(defaultTabIndex or 1)
end

function XUiTheatreFieldGuide:CheckRedPoint(index, isSave)
    local id = self.FieldGuideIdList[index]
    local tabBtn = self.TabGroup[index]
    if id == XTheatreConfigs.FieldGuideIds.AllSkill then
        if isSave then
            XDataCenter.TheatreManager.SaveGuideGainFieldRedPoint()
            tabBtn:ShowReddot(false)
            return
        end
        tabBtn:ShowReddot(XDataCenter.TheatreManager.CheckGuideGainFieldRedPoint())
    elseif id == XTheatreConfigs.FieldGuideIds.Item then
        if isSave then
            XDataCenter.TheatreManager.SaveGuidePropRedPoint()
            tabBtn:ShowReddot(false)
            return
        end
        tabBtn:ShowReddot(XDataCenter.TheatreManager.CheckGuidePropRedPoint())
    end
end

function XUiTheatreFieldGuide:OnSelectToggle(index)
    if self.SelectIndex == index then
        return
    end

    self:PlayAnimation("QieHuan")

    self.SelectIndex = index
    self:CheckRedPoint(index, true)
    self:Refresh()
end

function XUiTheatreFieldGuide:Refresh()
    self:HidePanel()
    local selectIndex = self.SelectIndex
    local id = self.FieldGuideIdList[selectIndex]
    if id == XTheatreConfigs.FieldGuideIds.CurSkill then
        self.GuideGainNowPanel:Show()
    elseif id == XTheatreConfigs.FieldGuideIds.AllSkill then
        self.GuideGainFieldPanel:Show()
    elseif id == XTheatreConfigs.FieldGuideIds.Item then
        self.GuidePropPanel:Show()
    end
end

function XUiTheatreFieldGuide:HidePanel()
    self.GuideGainNowPanel:Hide()
    self.GuideGainFieldPanel:Hide()
    self.GuidePropPanel:Hide()
    self.DetailPanel:HideAllDetail()
    self.IsSelectCoreGrid = false
    self.CurSelectSkillGrid = nil
    self.CurSelectSkill = nil
    self.CurSelectItemGrid = nil
    self.CurSelectToken = nil
end

--skill：XAdventureSkill
function XUiTheatreFieldGuide:IsCurSelectSkill(skill)
    if self.CurSelectSkill and skill then
        return self.CurSelectSkill:GetId() == skill:GetId()
    end

    return false
end

--isSelectCoreGrid：是否从4个装备了的核心技能中选中
function XUiTheatreFieldGuide:ShowSkillDetail(skill, grid, isSelectCoreGrid)
    if not skill then
        return
    end
    if self.CurSelectSkillGrid then
        local oldSkill = self.CurSelectSkillGrid:GetSkill()
        local newSkill = grid:GetSkill()
        if oldSkill:GetId() == newSkill:GetId() and self.IsSelectCoreGrid == isSelectCoreGrid then
            return
        end
        self.CurSelectSkillGrid:CancelSelect()
    end

    self.IsSelectCoreGrid = isSelectCoreGrid
    self.CurSelectSkillGrid = grid
    self.CurSelectSkill = skill
    self.DetailPanel:ShowSkillDetail(skill)
    self:PlayAnimation("PanelDetailEnable")
end

--token：XTheatreToken
function XUiTheatreFieldGuide:IsCurSelectToken(token)
    if not self.CurSelectToken or not token then
        return false
    end
    return self.CurSelectToken:GetId() == token:GetId()
end

function XUiTheatreFieldGuide:ShowItemDetail(token, grid)
    if self.CurSelectItemGrid then
        local oldItem = self.CurSelectItemGrid:GetToken()
        local newItem = grid:GetToken()
        if oldItem:GetId() == newItem:GetId() then
            return
        end
        self.CurSelectItemGrid:CancelSelect()
    end

    self.CurSelectItemGrid = grid
    self.CurSelectToken = token
    self.DetailPanel:ShowItemDetail(token)
    self:PlayAnimation("PanelDetailEnable")
end

function XUiTheatreFieldGuide:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "Theatre")
end