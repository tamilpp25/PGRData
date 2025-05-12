local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiFubenMaverickCharacterTalent = XClass(nil, "XUiFubenMaverickCharacterTalent")
local XUiFubenMaverickTalentGrid = require("XUi/XUiFubenMaverick/XUiGrid/XUiFubenMaverickTalentGrid")

function XUiFubenMaverickCharacterTalent:Ctor(rootUi, ui)
    self.RootUi = rootUi
    
    XTool.InitUiObjectByUi(self, ui)
    
    self:InitButtons()
    self:InitDynamicTable()
end

function XUiFubenMaverickCharacterTalent:InitDynamicTable()
    self.PanelBuff.Grid.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelBuff)
    self.DynamicTable:SetProxy(XUiFubenMaverickTalentGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenMaverickCharacterTalent:InitButtons()
    self.BtnDelete.CallBack = function()
        if self.IsMinLevel then
            return
        end
        
        if not self.MemberId then
            XLog.Error("成员数据为空！")
            return
        end
        XDataCenter.MaverickManager.ResetMember(self.MemberId, function() self.RootUi:Refresh() end)
    end
    self.BtnActive.CallBack = function()
        if self.IsMaxLevel then
            return
        end
        
        if not self.MemberId then
            XLog.Error("成员数据为空！")
            return
        end

        if self.ConsumeItemCount > self.ItemCount then
            XUiManager.TipText("MaverickUpgradeItemNotEnough")
            return
        end
        
        XDataCenter.MaverickManager.UpgradeMember(self.MemberId, function() self.RootUi:Refresh() end)
    end
    self.BtnOverview.CallBack = function() self.RootUi:OpenTalentSummary(self.MemberId)  end
end

function XUiFubenMaverickCharacterTalent:Refresh(memberId)
    self.MemberId = memberId or self.MemberId
    
    local member = XDataCenter.MaverickManager.GetMember(self.MemberId)
    --等级
    self.MinLevel = XDataCenter.MaverickManager.GetMinMemberLevel(self.MemberId)
    self.MaxLevel = XDataCenter.MaverickManager.GetMaxMemberLevel(self.MemberId)
    self.TxtLevel.text = member.Level .. "/" .. self.MaxLevel
    self.IsMinLevel = member.Level <= self.MinLevel;
    self.IsMaxLevel = member.Level >= self.MaxLevel;
    self.BtnDelete:SetDisable(self.IsMinLevel)
    self.BtnActive:SetDisable(self.IsMaxLevel)
    --消耗的道具
    local itemInfo = XDataCenter.MaverickManager.GetMemberLvUpConsumeInfo(member)
    local itemId = XDataCenter.MaverickManager.LvUpConsumeItemId
    local item = XDataCenter.ItemManager.GetItem(itemId)
    self.RImgIconItem:SetRawImage(item.Template.Icon)
    self.ItemCount = item.Count
    self.ConsumeItemCount = itemInfo.ConsumeItemCount
    if member.Level < self.MaxLevel then
        self.TxtConditionCountItem.text = self.ConsumeItemCount .. "/" .. self.ItemCount
        self.PanelCountItem.gameObject:SetActiveEx(true)
    else
        self.TxtConditionCountItem.text = ""
        self.PanelCountItem.gameObject:SetActiveEx(false)
    end
    --天赋
    self.TalentIds = XDataCenter.MaverickManager.GetMemberTalentIds(self.MemberId)
    self.DynamicTable:SetDataSource(self.TalentIds)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiFubenMaverickCharacterTalent:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.MemberId, self.TalentIds[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    end
end

return XUiFubenMaverickCharacterTalent