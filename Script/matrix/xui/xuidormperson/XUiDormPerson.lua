---@class XUiDormPerson : XLuaUi
local XUiDormPerson = XLuaUiManager.Register(XLuaUi, "UiDormPerson")
local XUiDormPersonSelect = require("XUi/XUiDormPerson/XUiDormPersonSelect")


function XUiDormPerson:OnAwake()
    self:InitUi()
    self:InitCb()
end 

function XUiDormPerson:OnStart(selectType, curSceneId, curRoomId)
    self.DefaultSceneId = curSceneId
    self.DefaultRoomId = curRoomId
    self:InitChildView()
    
    self.PanelTabGroup:SelectIndex(selectType or 1)
    self:AddEventListener()
end

function XUiDormPerson:OnEnable()
    self:PlayAnimation("AnimStartEnable", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiDormPerson:OnDestroy()
    self:DelEventListener()
end

function XUiDormPerson:InitCb()
    self:BindExitBtns()
end 

function XUiDormPerson:InitUi()
    --选择入住
    self.SelectPanel = XUiDormPersonSelect.New(self.PanelSelect, self)
    self.SelectPanel.GameObject:SetActiveEx(false)
    --页签
    local tab = {
        self.BtnTabStaff,
        self.BtnTabDetail,
    }
    self.TabAnimation = { "QieHuanStaffing", "QieHuanDetails"}
    self.PanelTabGroup:Init(tab, function(index) self:OnSelectTab(index) end)
end 

function XUiDormPerson:InitChildView()
    self.StaffPanel = require("XUi/XUiDormPerson/XUiDormPersonStaff").New(self.PanelStaffList, self.DefaultSceneId, self.DefaultRoomId)
    self.DetailPanel = require("XUi/XUiDormPerson/XUiDormPersonDetails").New(self.PanelStaffDetails)
    self.ChildView = {
        self.StaffPanel,
        self.DetailPanel,
    }

    local animCb = handler(self, self.PlayAnimation)
    self.StaffPanel:RegisterAnimationCb(animCb)
    self.DetailPanel:RegisterAnimationCb(animCb)

    for _, view in pairs(self.ChildView) do
        view:Hide()
    end
end

function XUiDormPerson:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_DORM_SELECT_CHARACTER_LIST, self.OnSelectList, self)
end

function XUiDormPerson:DelEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_SELECT_CHARACTER_LIST, self.OnSelectList, self)
end

function XUiDormPerson:OnSelectTab(index)
    if self.TabIndex == index then
        return
    end
    local animName = self.TabAnimation[index]
    if animName then
        self:PlayAnimation(animName)
    end
    self:RefreshChildView(index)
end 

function XUiDormPerson:RefreshChildView(index)
    if XTool.IsNumberValid(self.TabIndex) then
        self.ChildView[self.TabIndex]:Hide()
    end
    self.ChildView[index]:Show()
    self.TabIndex = index
end 

function XUiDormPerson:OnSelectList(dormId)
    self:ShowSelectPanel(dormId)
end 

function XUiDormPerson:ShowSelectPanel(dormId)
    self.SelectPanel:SetList(dormId)
    self.SelectPanel.GameObject:SetActiveEx(true)
    self.SelectPanel:OnEnable()
    self:PlayAnimation("SelectEnable")
end

function XUiDormPerson:UpdatePersonList()
    self.StaffPanel:SetupDynamicTable()
end 