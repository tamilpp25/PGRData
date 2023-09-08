local XUiSkillPanel = require("XUi/XUiBiancaTheatre/Strength/XUiSkillPanel")
local XUiSkillTipsPanel = require("XUi/XUiBiancaTheatre/Strength/XUiSkillTipsPanel")


--肉鸽玩法二期 外循环强化系统
local XUiBiancaTheatreSkill = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreSkill")

function XUiBiancaTheatreSkill:OnAwake()
    XUiHelper.NewPanelActivityAssetSafe(XDataCenter.BiancaTheatreManager.GetAssetItemIds(), self.PanelSpecialTool, self, nil, handler(self, self.OnBtnClick))
    self:InitButtonCallBack()

    local clickGridCb = handler(self, self.ClickGrid)
    self.DynamicTableCurve = XDynamicTableCurve.New(self.PanelGachaList)
    self.DynamicTableCurve:SetProxy(XUiSkillPanel, self, clickGridCb)
    self.DynamicTableCurve:SetDelegate(self)
    self.GroupIdList = XBiancaTheatreConfigs.GetStrengthenGroupIdList()
    self.GamePanel.gameObject:SetActiveEx(false)
    self.PanelTips = self.PanelTips or self.Transform:Find("SafeAreaContentPane/PanelTips")
    self.SkillTipsPanel = XUiSkillTipsPanel.New(self.PanelTips)
    self.DotList = { self.Dot }
    self.HelpAlphaGroup = self.Unlocked:GetComponent("CanvasGroup")
    self:HideTips()
    
    self:InitDynamicFirstIndex()
end

function XUiBiancaTheatreSkill:OnEnable()
    self:Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_BIANCA_THEATRE_STRENGTHEN_ACTIVE, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_BIANCA_THEATRE_GROUP_STRENGTHEN_ACTIVE, self.RefreshGroup, self)
end

function XUiBiancaTheatreSkill:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BIANCA_THEATRE_STRENGTHEN_ACTIVE, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BIANCA_THEATRE_GROUP_STRENGTHEN_ACTIVE, self.RefreshGroup, self)
end

--初始化首次打开界面时滑动到未全部激活的技能组的下标，全部技能组激活时滑动到最后一个下标
function XUiBiancaTheatreSkill:InitDynamicFirstIndex()
    for i, groupId in ipairs(self.GroupIdList) do
        if not XDataCenter.BiancaTheatreManager.IsStrengthenGroupAllBuy(groupId) then
            self.FirstIndex = i - 1
            return
        end
    end
    self.FirstIndex = #self.GroupIdList - 1
end

function XUiBiancaTheatreSkill:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    -- self:RegisterClickEvent(self.GameObject, handler(self, self.HideTips))
    -- self.GameObject:AddComponent(typeof(CS.UnityEngine.UI.XEmpty4Raycast))
    -- ScrollRect的点击和拖拽会触发关闭详细面板
    self:RegisterClickEvent(self.PanelGachaList, self.HideTips)
    local dragProxy = self.PanelGachaList.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
end

function XUiBiancaTheatreSkill:Refresh(activeId)
    self:SetCurActiveSkillId(activeId)
    local curIndex = self.FirstIndex or self.DynamicTableCurve:GetTweenIndex()
    self.FirstIndex = nil
    self.DynamicTableCurve:SetDataSource(self.GroupIdList)
    self.DynamicTableCurve:ReloadData(curIndex)
    self:RefreshDot()
end

function XUiBiancaTheatreSkill:RefreshGroup(groupId)
    if not XTool.IsNumberValid(groupId) then
        return
    end
    local index
    for i, id in ipairs(self.GroupIdList or {}) do
        if id == groupId then
            index = i
        end
    end
    local curIndex = self.DynamicTableCurve:GetTweenIndex()
    if not XTool.IsNumberValid(index) or curIndex >= index then
        return
    end
    self.DynamicTableCurve:TweenToIndex(index)
end

function XUiBiancaTheatreSkill:RefreshDot()
    local index = self.DynamicTableCurve:GetTweenIndex()
    index = index + 1 -- 下标从0开始
    for i, id in ipairs(self.GroupIdList or {}) do
        local grid = self.DotList[i]
        if not grid then
            grid = XUiHelper.Instantiate(self.Dot, self.PanelDot, false)
            grid = grid.transform:GetComponent("XUiButton")
            self.DotList[i] = grid
        end
        grid:SetButtonState(i == index and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
    self.NextPage.gameObject:SetActiveEx(index < #self.GroupIdList)
end

function XUiBiancaTheatreSkill:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.GroupIdList[index + 1], self.ActiveSkillId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        self:RefreshSkill()
        self:RefreshDot()
    end
end

--缓存激活的技能Id
function XUiBiancaTheatreSkill:SetCurActiveSkillId(skillId)
    self.ActiveSkillId = skillId
end

function XUiBiancaTheatreSkill:OnDragProxy(dragType)
    if dragType == 0 then
        --开始滑动
        self:HideTips()
    end
end

function XUiBiancaTheatreSkill:ClickGrid(skillGrid)
    self.SkillTipsPanel:Show(skillGrid)
    self.CurSelectGrid = skillGrid
end

function XUiBiancaTheatreSkill:HideTips()
    self.SkillTipsPanel:Hide()
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelectStateActive(false)
    end
end

function XUiBiancaTheatreSkill:RefreshSkill()
    local index = self.DynamicTableCurve:GetTweenIndex()
    local groupId = self.GroupIdList[index + 1]
    if groupId == self.RefreshGroupId then
        return
    end
    self.RefreshGroupId = groupId
    local preGroupId = XBiancaTheatreConfigs.GetStrengthenGroupPreStrengthenGroupId(groupId)
    local isUnlock = XDataCenter.BiancaTheatreManager.IsStrengthenGroupAllBuy(preGroupId)
    self.Unlocked.gameObject:SetActiveEx(not isUnlock)
    if isUnlock then
        self.HelpAlphaGroup.alpha = 0
    end
    self.TxtLevel.text = XBiancaTheatreConfigs.GetStrengthenGroupName(groupId)
end 

--货币点击方法
function XUiBiancaTheatreSkill:OnBtnClick(index)
    XLuaUiManager.Open("UiBiancaTheatreTips", XBiancaTheatreConfigs.TheatreOutCoin)
end