---@class XUiPanelDownloadSet : XUiNode
local XUiPanelDownloadSet = XClass(XUiNode, "XUiPanelDownloadSet")
local XUiSafeAreaAdapter = CS.XUiSafeAreaAdapter
local SetConfigs = XSetConfigs
local MaxOff
local XUiPanelDownloadSetItem = require("XUi/XUiSet/ChildItem/XUiPanelDownloadSetItem")

function XUiPanelDownloadSet:OnStart()
    self:InitBtnGroup()
end

function XUiPanelDownloadSet:OnEnable()
    self:ShowPanel()
end

function XUiPanelDownloadSet:OnDisable()
    self:HidePanel()
end

function XUiPanelDownloadSet:OnDestroy()
end

--region Data - Setting
function XUiPanelDownloadSet:SaveChange()
    --XDataCenter.DlcManager.SetDownloadSelect(self._Select)
end

function XUiPanelDownloadSet:CancelChange()
    self:SelectSetting(self:GetSettingValue())
end

function XUiPanelDownloadSet:CheckDataIsChange()
    return self:GetSettingValue() ~= self._Select
end
--endregion

--region Ui - Panel
function XUiPanelDownloadSet:ShowPanel()
    self.IsShow = true
    self.BtnGroup:SelectIndex(self._Select)
end

function XUiPanelDownloadSet:HidePanel()
    self.IsShow = false
end
--endregion

--region Ui - Btn
function XUiPanelDownloadSet:InitBtnGroup()
    local btnList = {
        self.DownloadNormal,
        self.DownloadAll,
    }
    if XTool.IsNumberValid(self:GetSettingValue()) then
        self._Select = self:GetSettingValue()
    else
        self._Select = 1
        self:SaveChange()
    end
    self.BtnGroup:Init(btnList, handler(self, self.SelectSetting))
    self.BtnGroup:SelectIndex(self._Select)
end

function XUiPanelDownloadSet:SelectSetting(index)
    self._Select = index
end

function XUiPanelDownloadSet:GetSettingValue()
    local select = false--XDataCenter.DlcManager.GetDownloadSelect()
    return select
end
--endregion

--region Old
--function XUiPanelDownloadSet:Ctor(ui, parent)
--    self.GameObject = ui.gameObject
--    self.Transform = ui.transform
--    self.Parent = parent
--    XTool.InitUiObject(self)
--    MaxOff = CS.XGame.ClientConfig:GetFloat("SpecialScreenOff")
--    self:InitUi()
--
--    self.PanelNormal.gameObject:SetActiveEx(false)
--    self.PanelSelect.gameObject:SetActiveEx(false)
--end
--
--function XUiPanelDownloadSet:OnDestroy()
--    self.normalList = {}
--    self.selectList = {}
--    self.curIdx = 0
--end
--
--function XUiPanelDownloadSet:InitUi()
--    self.normalList = {}
--    self.selectList = {}
--    self.curIdx = 0
--
--    self:AddListener()
--end
--
--function XUiPanelDownloadSet:SetupView()
--    for k,v in pairs(self.normalList) do
--        v.GameObject:SetActiveEx(false)
--    end
--
--    for k,v in pairs(self.selectList) do
--        v.GameObject:SetActiveEx(false)
--    end
--
--    local normalIndex = 1
--    local selectIndex = 1
--    local index = 1
--    local dlcItemList = XDataCenter.DlcManager.GetAllItemList()
--    if XTool.IsTableEmpty(dlcItemList) then
--        return
--    end
--    for _, dlcItemData in ipairs(dlcItemList) do
--        local isCurrent = index == self.curIdx
--        if isCurrent then
--            local selectItem = self:GetOneItem(selectIndex,self.selectList,self.PanelSelect)
--            selectItem.Transform:SetSiblingIndex(index-1)
--            selectItem.GameObject:SetActiveEx(true)
--            selectItem:Setup(dlcItemData, index, isCurrent)
--
--            selectIndex = selectIndex+1
--        else
--            local normalItem = self:GetOneItem(normalIndex,self.normalList,self.PanelNormal)
--            normalItem.Transform:SetSiblingIndex(index-1)
--            
--            normalItem.GameObject:SetActiveEx(true)
--            normalItem:Setup(dlcItemData, index, isCurrent)
--            normalIndex = normalIndex+1
--        end
--
--        index = index + 1
--    end
--end
--
--function XUiPanelDownloadSet:GetOneItem(index,list,itemClone)
--    if list[index] == nil then
--        local go =  CS.UnityEngine.Object.Instantiate(itemClone)
--        go.transform:SetParent(self.PanelContent,false)
--        local item = XUiPanelDownloadSetItem.New(go,self)
--        list[index] = item
--    end
--    return list[index]
--end
--
--function XUiPanelDownloadSet:CheckDataIsChange()
--    return false
--end
--
--function XUiPanelDownloadSet:OnClickItem(index)
--    if self.curIdx == index then
--        self.curIdx = 0
--    else
--        self.curIdx = index
--    end
--
--    self:SetupView()
--end
--endregion

return XUiPanelDownloadSet