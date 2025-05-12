local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridParkourRole = XClass(nil, "XUiGridParkourRole")

function XUiGridParkourRole:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiGridParkourRole:Refresh(helperId, selectHelperId)
    self.HelperId = helperId
    self.GameObject.name = helperId
    local robotId = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
    local charId = XEntityHelper.GetCharacterIdByEntityId(robotId)
    self.ImgHeadIcon:SetRawImage(XMoeWarConfig.GetMoeWarPreparationHelperCirleIcon(helperId))
    self.TxtName.text = XEntityHelper.GetCharacterLogName(charId)

    local curMoodValue = XDataCenter.MoeWarManager.GetMoodValue(helperId)
    local moodUpLimit = XMoeWarConfig.GetPreparationHelperMoodUpLimit(helperId)
    local moodId = XMoeWarConfig.GetCharacterMoodId(curMoodValue)
    self.ImgMood:SetSprite(XMoeWarConfig.GetCharacterMoodIcon(moodId))
    self.ImgCurEnergy.fillAmount = curMoodValue / moodUpLimit
    self.TxtMoodAdd.text = curMoodValue
    self.ImgCurEnergy.color = XMoeWarConfig.GetCharacterMoodColor(moodId)
    
    self:SetSelect(helperId == selectHelperId)
end

function XUiGridParkourRole:SetSelect(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end


--=========================================类分界线=========================================--


local XUiMoeWarParkourPerson = XLuaUiManager.Register(XLuaUi, "UiMoeWarParkourPerson")
local MAX_SELECT_MEMBER = 1 --最大可选择人数


function XUiMoeWarParkourPerson:OnAwake()
    self:InitCb()
    self:InitDynamicTable()
end 

function XUiMoeWarParkourPerson:OnStart(helperId)
    self.DefaultHelperId = helperId
    self:SetupDynamicTable()
end 

function XUiMoeWarParkourPerson:InitCb()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnCancel.CallBack = function() self:Close() end
    self.BtnClose.onClick:AddListener( function() self:Close() end)
    self.BtnConfirm.CallBack = function() 
        self:OnBtnConfirmClick()
    end
    self.DrdSort.onValueChanged:AddListener(function() 
        self:SetupDynamicTable()
    end)
end 

function XUiMoeWarParkourPerson:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList)
    self.DynamicTable:SetProxy(XUiGridParkourRole)
    self.DynamicTable:SetDelegate(self)
    self.DormSelectItem.gameObject:SetActiveEx(false)
end 

function XUiMoeWarParkourPerson:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local curHelperId = XTool.IsNumberValid(self.CurrentIndex) and self.HelperIdList[self.CurrentIndex] or self.DefaultHelperId
        grid:Refresh(self.HelperIdList[index], curHelperId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickGridRole(index, grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if XTool.IsNumberValid(self.DefaultHelperId) then
            for idx, roleId in ipairs(self.HelperIdList) do
                if roleId == self.DefaultHelperId then 
                    self.CurrentIndex = idx
                    break
                end
            end
        end
        self:RefreshSelectCount()
    end
end 

function XUiMoeWarParkourPerson:SetupDynamicTable()
    local type = self.DrdSort.value
    if self.DrdSortType == type then
        return
    end
    self.HelperIdList = XDataCenter.MoeWarManager.GetOwnHelperId(type)
    local isEmpty = XTool.IsTableEmpty(self.HelperIdList)
    self.ImgNonePerson.gameObject:SetActiveEx(isEmpty)
    self.DrdSortType = type
    self.DynamicTable:SetDataSource(self.HelperIdList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiMoeWarParkourPerson:OnClickGridRole(index, grid)
    if self.CurrentIndex == index then
        return
    end
    if XTool.IsNumberValid(self.CurrentIndex) then
        local oldGrid = self.DynamicTable:GetGridByIndex(self.CurrentIndex)
        --未找到的会被 DYNAMIC_GRID_ATINDEX 事件刷新
        if oldGrid then
            oldGrid:SetSelect(false)
        end
    end
    grid:SetSelect(true)
    self.CurrentIndex = index
    
    self:RefreshSelectCount()
end

function XUiMoeWarParkourPerson:OnBtnConfirmClick()
    if not XTool.IsNumberValid(self.CurrentIndex) then
        XUiManager.TipText("MoeWarParkourFightNotCharacter")
        return
    end
    local helperId = self.HelperIdList[self.CurrentIndex]
    self:EmitSignal("UpdateParkourEntityId", helperId)
    self:Close()
end

function XUiMoeWarParkourPerson:RefreshSelectCount()
    local count = XTool.IsNumberValid(self.CurrentIndex) and 1 or 0
    self.TxtSelectCount.text = string.format("%d/%d", count, MAX_SELECT_MEMBER)
end 